
/*=================================================================
 * 
 * version: 01/27/2013 13:59
 *
 * Matlab: [num, out, pxl] = imfeat_entree_get_ERs(I', reverse)
 *
 * Input - I (u8 array): image data.
 *           Rember to have an transpose on "I" like "I'" when calling in Matlab, 
 *           to compensate the different memory layout between Matlab & C.
 *       - reverse (int): reverse input image data (1) or not (0)
 * Output - num (int): number of ERs
 *          out (int array): it contains all ERs information without ordering.
 *          pxl (int array): returned pixel order map with the same size as image.
 * 
 * Input example: I = [3 4 2;    reverse = 0;
 *                     4 4 2;
 *                     2 2 3];
 * Output example:
 *  
 *  pxl = [5, 2, 6, 7, 8, 0, 3, 4, 1];
 *         ~~~~~~~~~~~~~~~~~~~~~~~~~
 *        it means the following table
 *        
 *        pxl   value  implied   relation
 *        seq           (x,y)    img_w=3   
 *        ---------------------------------
 *        [0]     5     (2,1)    2+1*3 = 5
 *        [1]     2     (2,0)    2+0*3 = 2
 *        [2]     6     (0,2)    0+2*3 = 6
 *        [3]     7     (1,2)    1+2*3 = 7
 *        [4]     8     (2,2)    2+2*3 = 8
 *        [5]     0     (0,0)    0+0*3 = 0
 *        [6]     3     (0,1)    0+1*3 = 3
 *        [7]     4     (1,1)    1+1*3 = 4
 *        [8]     1     (1,0)    1+0*3 = 1
 *
 *  num = 2 (means there are 2 ERs in "out" info)
 *
 *  out = [3, 1, 5, 2, 2, 2, 2, 2, 0, 3, 5, 0, 0, .... , 0];
 *         ~~~~~~~  ~~~~~~~  ~~~~~~~  ~~~~~~~  ~~~~~~~~~~~
 *         1st ER   2nd ER   3rd ER   4th ER   rest are all 0  
 *
 * For each ER: 1st element means gray level
 *              2nd element means number of pixels
 *              3rd element means start position in pixel sequence (need to refer "pxl" array)
 *
 *  Therefore, from "out" we can know
 *    ER1: graylevel is 3, has 1 points, start from pxl 5. => (0,0)
 *    ER2: graylevel is 2, has 2 points, start from pxl 2. => (0,2)(1,2)
 *    ER3: graylevel is 2, has 2 points, start from pxl 0. => (2,1)(2,0)
 *    ER4: graylevel is 3, has 5 points, start from pxl 0. => (2,1)(2,0)(0,2)(1,2)(2,2)
 *  Actually there always exists an extra ER which contains all pixels, 
 *  which we do not include in our output.
 *
 *=================================================================*/

#include "../../include/system.h"
#include "../../include/imfeat.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/features2d/features2d.hpp>
#include <opencv2/nonfree/nonfree.hpp>
#include <opencv2/nonfree/features2d.hpp>
#include <opencv2/calib3d/calib3d.hpp> // for homography
#include <opencv2/imgproc/imgproc.hpp>
using namespace cv;

#define debug_print if(debug)printf //printf
#define cor2idx(x,y,w)	(x+(y)*(w))
typedef unsigned char u8;
typedef unsigned short int u16;
typedef unsigned long int u32;

typedef struct MSERConnectedComp
{
	LinkedPoint* head;
	LinkedPoint* tail;
	ER_t* history;
	unsigned long grey_level;
	int size;
	int dvar; // the derivative of last var
	float var; // the current variation (most time is the variation of one-step back)
}
MSERConnectedComp;

// clear the connected component in stack
static void
initMSERComp( MSERConnectedComp* comp )
{
	comp->size = 0;
	comp->var = 0;
	comp->dvar = 1;
	comp->history = NULL;
}

// add a pixel to the pixel list
static void accumulateMSERComp( MSERConnectedComp* comp, LinkedPoint* point )
{
	if ( comp->size > 0 )
	{
		point->prev = comp->tail;
		comp->tail->next = point;
		point->next = NULL;
	} else {
		point->prev = NULL;
		point->next = NULL;
		comp->head = point;
	}
	comp->tail = point;
	comp->size++;
}

// *******************************************************************
static int debug = 0;
static ER_t* hist_start; //kevin added
// add history of size to a connected component
static void
MSERNewHistory( MSERConnectedComp* comp, ER_t* history )
{
	history->ER_id = (history-hist_start);
	// child of last history is itself
	//history->child = history; //kevin marked
	// comp->history always link to previous created history
	if ( NULL == comp->history )
	{
		//history->shortcut = history; //kevin marked
		//history->stable = 0; //kevin marked
	} else {
		//comp->history->child = history; //kevin marked
		//history->shortcut = comp->history->shortcut; //kevin marked
		//history->stable = comp->history->stable;  //kevin marked
		
		if ( -1 == history->ER_firstChild )
		{
			// when new a hist, if comp has hist and cur hist has no child, assin it
			history->ER_firstChild = comp->history->ER_id;
			history->to_firstChild = comp->history;
		}
		comp->history->ER_parent = history->ER_id;
		comp->history->to_parent = history;

		// when new a hist, check if comp's hist has sibling, if yes, assign same parent to all sibling 
		ER_t* cur = comp->history->to_nextSibling;
		while ( cur )
		{
			cur->ER_parent = history->ER_id;
			cur->to_parent = history;
			cur = cur->to_nextSibling;
		}
	}
	history->val = comp->grey_level;
	history->size = comp->size;
	// update comp->history as the last created history
	comp->history = history;
	// update ER region info
	history->ER_val = comp->grey_level; //kevin added
	history->ER_size = comp->size;      //kevin added
	history->ER_head = comp->head;      //kevin added
	history->ER_tail = comp->tail;      //kevin added
	debug_print("update hst %d val=%d(x) size=%d(x) ER_val=%d(v) ER_size=%d(v) in MSERNewHistory <========== \n", 
		history-hist_start, history->val, history->size, history->ER_val, history->ER_size);
}
static MSERConnectedComp* cmp_start; //kevin added
// merging two connected component
static void
MSERMergeComp( MSERConnectedComp* comp1,
		  MSERConnectedComp* comp2,
		  MSERConnectedComp* comp,
		  ER_t* history )
{
	LinkedPoint* head;
	LinkedPoint* tail;
	comp->grey_level = comp2->grey_level;
	debug_print("update cmp %d grey_level %d in MSERMergeComp \n", comp-cmp_start, comp->grey_level);
	//history->child = history; //kevin marked
	history->ER_id = (history-hist_start);
	// select the winner by size
	if ( comp1->size >= comp2->size )
	{
		if ( NULL == comp1->history )
		{
			//history->shortcut = history; //kevin marked
			//history->stable = 0;  //kevin marked
		} else {
			//comp1->history->child = history; //kevin marked
			//history->shortcut = comp1->history->shortcut; //kevin marked
			//history->stable = comp1->history->stable; //kevin marked
		}
		//if ( NULL != comp2->history && comp2->history->stable > history->stable )  //kevin marked
		//	history->stable = comp2->history->stable;    //kevin marked
		history->val = comp1->grey_level;
		history->size = comp1->size;
		// put comp1 to history
		comp->var = comp1->var;
		comp->dvar = comp1->dvar;
		if ( comp1->size > 0 && comp2->size > 0 )
		{
			comp1->tail->next = comp2->head;
			comp2->head->prev = comp1->tail;
		}
		head = ( comp1->size > 0 ) ? comp1->head : comp2->head;
		tail = ( comp2->size > 0 ) ? comp2->tail : comp1->tail;
		// always made the newly added in the last of the pixel list (comp1 ... comp2)
	} else {
		if ( NULL == comp2->history )
		{
			//history->shortcut = history; //kevin marked
			//history->stable = 0;  //kevin marked
		} else {
			//comp2->history->child = history; //kevin marked
			//history->shortcut = comp2->history->shortcut; //kevin marked
			//history->stable = comp2->history->stable;  //kevin marked
		}
		//if ( NULL != comp1->history && comp1->history->stable > history->stable )  //kevin marked
		//	history->stable = comp1->history->stable;  //kevin marked
		history->val = comp2->grey_level;
		history->size = comp2->size;
		// put comp2 to history
		comp->var = comp2->var;
		comp->dvar = comp2->dvar;
		if ( comp1->size > 0 && comp2->size > 0 )
		{
			comp2->tail->next = comp1->head;
			comp1->head->prev = comp2->tail;
		}
		head = ( comp2->size > 0 ) ? comp2->head : comp1->head;
		tail = ( comp1->size > 0 ) ? comp1->tail : comp2->tail;
		// always made the newly added in the last of the pixel list (comp2 ... comp1)
	}

	// update ER region info
	history->ER_val = comp1->grey_level; //kevin added
	history->ER_size = comp1->size;      //kevin added
	history->ER_head = comp1->head;      //kevin added
	history->ER_tail = comp1->tail;      //kevin added
	if ( NULL != comp1->history )
	{
		if ( -1 == history->ER_firstChild )
		{
			// when merge, if comp has hist but cur hist has no child, assign it
			history->ER_firstChild = comp1->history->ER_id;
			history->to_firstChild = comp1->history;
		} 
		comp1->history->ER_parent = history->ER_id;
		comp1->history->to_parent = history;
	}
	if ( NULL != comp2->history )
	{
		// every hist exists in comp's hist is cur hist's sibling
		history->ER_nextSibling = comp2->history->ER_id;
		history->to_nextSibling = comp2->history;
		comp2->history->ER_prevSibling = history->ER_id;
		comp2->history->to_prevSibling = history;
	}

	comp->head = head;
	comp->tail = tail;
	comp->history = history;
	comp->size = comp1->size + comp2->size;

	debug_print("update hst %d val=%d(x) size=%d(x) ER_val=%d(v) ER_size=%d(v) comp2_size=%d in MSERMergeComp <========== \n", 
		history-hist_start, history->val, history->size, history->ER_val, history->ER_size, comp2->size);
}

// to preprocess src image to following format
// 32-bit image
// > 0 is available, < 0 is visited
// 17~19 bits is the direction
// 8~11 bits is the bucket it falls to (for BitScanForward)
// 0~8 bits is the color
static int* preprocessMSER_8UC1( CvMat* img,
			int*** heap_cur,
			CvMat* src,
			CvMat* mask,
			int reverse )
{
	int srccpt = src->step-src->cols;
	int cpt_1 = img->cols-src->cols-1;
	int* imgptr = img->data.i;
	int* startptr;

	int level_size[256];
	for ( int i = 0; i < 256; i++ )
		level_size[i] = 0;
	// let 1st row be empty to avoid boundary checking
	for ( int i = 0; i < src->cols+2; i++ )
	{
		*imgptr = -1;
		imgptr++;
	}
	imgptr += cpt_1-1;
	u8* srcptr = src->data.ptr;
	if ( mask )
	{
		startptr = 0;
		u8* maskptr = mask->data.ptr;
		for ( int i = 0; i < src->rows; i++ )
		{
			*imgptr = -1;
			imgptr++;
			for ( int j = 0; j < src->cols; j++ )
			{
				if ( *maskptr )
				{
					if ( !startptr )
						startptr = imgptr;
					*srcptr = 0xff-*srcptr;
					level_size[*srcptr]++;
					*imgptr = ((*srcptr>>5)<<8)|(*srcptr);
				} else {
					*imgptr = -1;
				}
				imgptr++;
				srcptr++;
				maskptr++;
			}
			*imgptr = -1;
			imgptr += cpt_1;
			srcptr += srccpt;
			maskptr += srccpt;
		}
	} else {
		startptr = imgptr/*+img->cols*/+1; // let 1st row be empty to avoid boundary checking
		if (reverse) {
			for ( int i = 0; i < src->rows; i++ )
			{
				*imgptr = -1; // let 1st col be empty to avoid boundary checking
				imgptr++;
				for ( int j = 0; j < src->cols; j++ )
				{
					*srcptr = 0xff-*srcptr; // 2->253; 1->243; 0->255 (reverse here!!)
					level_size[*srcptr]++;
					*imgptr = ((*srcptr>>5)<<8)|(*srcptr); // upper 3 bits + original 8 bits
					imgptr++;
					srcptr++;
				}
				*imgptr = -1; // let last col be empty to avoid boundary checking
				imgptr += cpt_1; // add img padding to next row
				srcptr += srccpt;// add src padding to next row
			}
		} else {
			for ( int i = 0; i < src->rows; i++ )
			{
				*imgptr = -1; // let 1st col be empty to avoid boundary checking
				imgptr++;
				for ( int j = 0; j < src->cols; j++ )
				{
					level_size[*srcptr]++;
					*imgptr = ((*srcptr>>5)<<8)|(*srcptr); // upper 3 bits + original 8 bits
					imgptr++;
					srcptr++;
				}
				*imgptr = -1; // let last col be empty to avoid boundary checking
				imgptr += cpt_1; // add img padding to next row
				srcptr += srccpt;// add src padding to next row
			}
		}
	}
	// let last row be empty to avoid boundary checking
	for ( int i = 0; i < src->cols+2; i++ )
	{
		*imgptr = -1;
		imgptr++;
	}
	// initialize heap, in each level, 1st u32 is for stop, rest num of u32 is dor storing pixels 
	heap_cur[0][0] = 0;
	for ( int i = 1; i < 256; i++ )
	{
		heap_cur[i] = heap_cur[i-1]+level_size[i-1]+1;
		heap_cur[i][0] = 0;
	}
	return startptr; // pointed to 1st available data (exclude boundary) in img 
}
static int heap_idx[256]; // kevin added
static int extractMSER_8UC1_Pass( int* ioptr,
			  int* imgptr,
			  int*** heap_cur,
			  LinkedPoint* ptsptr,
			  ER_t* histptr,
			  MSERConnectedComp* comptr,
			  int step,
			  int stepmask,
			  int stepgap,
			  int color,
			  CvSeq* contours,
			  LinkedPoint *pts_map)
{
	//kevin added
	for ( int i = 0; i < 256; i++ )
	{
		heap_idx[i] = 0;
	}
	cmp_start = comptr+1;
	hist_start = histptr;

	debug_print("[A->B->C->E]\n");
	debug_print("update cmp-1 grey_level 256 \n");
	comptr->grey_level = 256;
	comptr++; 
	comptr->grey_level = (*imgptr)&0xff;
	initMSERComp( comptr );
	debug_print("create cmp 0 grey_level %d \n", comptr->grey_level);
	*imgptr |= 0x80000000;
	heap_cur += (*imgptr)&0xff;
	int dir[] = { 1, step, -1, -step };

	for ( ; ; )
	{
		// take tour of all the 4 directions
		while ( ((*imgptr)&0x70000) < 0x40000 ) //0x00000:right 0x10000:bottom 0x20000:left 0x30000:top
		{
			if (((*imgptr)&0x70000)==0x00000) debug_print("chk point (%d,%d) %d at Right \n", ((int)(imgptr-ioptr))&stepmask, ((int)(imgptr-ioptr))>>stepgap, (*imgptr)&0xff);
			if (((*imgptr)&0x70000)==0x10000) debug_print("chk point (%d,%d) %d at Bottom \n", ((int)(imgptr-ioptr))&stepmask, ((int)(imgptr-ioptr))>>stepgap, (*imgptr)&0xff);
			if (((*imgptr)&0x70000)==0x20000) debug_print("chk point (%d,%d) %d at Left \n", ((int)(imgptr-ioptr))&stepmask, ((int)(imgptr-ioptr))>>stepgap, (*imgptr)&0xff);
			if (((*imgptr)&0x70000)==0x30000) debug_print("chk point (%d,%d) %d at Top \n", ((int)(imgptr-ioptr))&stepmask, ((int)(imgptr-ioptr))>>stepgap, (*imgptr)&0xff);
			// get the neighbor
			int* imgptr_nbr = imgptr+dir[((*imgptr)&0x70000)>>16];
			if ( *imgptr_nbr >= 0 ) // if the neighbor is not visited yet (boundary:0xffffffff<0)
			{
				debug_print("[E->F]\n");
				*imgptr_nbr |= 0x80000000; // mark it as visited
				if ( ((*imgptr_nbr)&0xff) < ((*imgptr)&0xff) )
				{
					debug_print("[F->D->C->E]\n");
					// when the value of neighbor smaller than current
					// push current to boundary heap and make the neighbor to be the current one
					// create an empty comp
					heap_idx[(*imgptr)&0xff]++; //kevin added
					debug_print("put point (%d,%d) %d into heap %d idx become %X \n", ((int)(imgptr-ioptr))&stepmask, ((int)(imgptr-ioptr))>>stepgap, (*imgptr)&0xff, (*imgptr)&0xff, heap_idx[(*imgptr)&0xff]);

					(*heap_cur)++;
					**heap_cur = imgptr;
					*imgptr += 0x10000;
					heap_cur += ((*imgptr_nbr)&0xff)-((*imgptr)&0xff);
					imgptr = imgptr_nbr;

					debug_print("use point (%d,%d) %d from neighbor \n", ((int)(imgptr-ioptr))&stepmask, ((int)(imgptr-ioptr))>>stepgap, (*imgptr)&0xff);

					comptr++;
					initMSERComp( comptr );
					comptr->grey_level = (*imgptr)&0xff;
					debug_print("create cmp %d grey_level %d \n", (comptr-cmp_start), comptr->grey_level);
					continue;
				} else {
					debug_print("[F->G->E]\n");
					// otherwise, push the neighbor to boundary heap
					heap_cur[((*imgptr_nbr)&0xff)-((*imgptr)&0xff)]++;             // go to nbr's heap data_ptr (heap_cur[..]), move nbr's data_ptr forward one u32 (heap_cur++)
					*heap_cur[((*imgptr_nbr)&0xff)-((*imgptr)&0xff)] = imgptr_nbr; // go to nbr's heap data_ptr (heap_cur[..]), store nbr's data_ptr into heap.

					heap_idx[(*imgptr_nbr)&0xff]++; //kevin added
					debug_print("put point (%d,%d) %d into heap %d idx become %X \n", ((int)(imgptr_nbr-ioptr))&stepmask, ((int)(imgptr_nbr-ioptr))>>stepgap, (*imgptr_nbr)&0xff, (*imgptr_nbr)&0xff, heap_idx[(*imgptr_nbr)&0xff]);
				}
			}
			*imgptr += 0x10000; // change direction
		}
		debug_print("[E->H->I]\n");
		int i = (int)(imgptr-ioptr);
		ptsptr->pt.x = i&stepmask;
		ptsptr->pt.y = i>>stepgap;
		ptsptr->val = 0;
		u32 *ptsmap_ptr = (u32 *)pts_map;
		memcpy(&ptsmap_ptr[i+step+1], &ptsptr, sizeof(u32));
		//ptsptr->pt = cvPoint( i&stepmask, i>>stepgap ); // from index i to coordinate (x,y)

		debug_print("put point (%d,%d) %d into cmp %d\n", i&stepmask, i>>stepgap, (*imgptr)&0xff, (comptr-cmp_start));
		// get the current location
		accumulateMSERComp( comptr, ptsptr );
		ptsptr++;
		debug_print("[I->J]\n");
		// get the next pixel from boundary heap
		if ( **heap_cur )
		{
			debug_print("[J->K->E]\n");
			imgptr = **heap_cur;
			(*heap_cur)--;

			heap_idx[(*imgptr)&0xff]--; //kevin added
			debug_print("pop point (%d,%d) %d from heap %d idx become %X \n", ((int)(imgptr-ioptr))&stepmask, ((int)(imgptr-ioptr))>>stepgap, (*imgptr)&0xff, (*imgptr)&0xff, heap_idx[(*imgptr)&0xff]);
		} else {
			heap_cur++; // examine next pixel level in heap
			unsigned long pixel_val = 0;
			for ( unsigned long i = ((*imgptr)&0xff)+1; i < 256; i++ )
			{
				// find the next queued pixel in heap by increasing grey-level index of heap 
				if ( **heap_cur )
				{
					pixel_val = i;
					break;
				}
				heap_cur++; // examine next pixel level in heap
			}

			// if it's not empty
			if ( pixel_val )
			{
				debug_print("[J->K]\n");
				imgptr = **heap_cur; // get data_ptr in heap as new imgptr
				(*heap_cur)--;

				heap_idx[(*imgptr)&0xff]--; //kevin added
				debug_print("pop point (%d,%d) %d from heap %d idx become %X \n", ((int)(imgptr-ioptr))&stepmask, ((int)(imgptr-ioptr))>>stepgap, (*imgptr)&0xff, (*imgptr)&0xff, heap_idx[(*imgptr)&0xff]);

				debug_print("[K->L->M]\n");
				// check if "new grey-level < 2nd on stack?"
				debug_print("New(%d) < 2nd_on_stack(%d) ?", pixel_val, comptr[-1].grey_level);
				if ( pixel_val < comptr[-1].grey_level )
				{
					debug_print("Yes! \n");
					debug_print("[M->E]\n");
					// check the stablity and push a new history, increase the grey level
					debug_print("create hst %d\n", (histptr-hist_start));
					MSERNewHistory( comptr, histptr );
					comptr[0].grey_level = pixel_val;
					debug_print("update cmp %d grey_level %d \n", (comptr-cmp_start), pixel_val);
					histptr++;
				} else {
					debug_print("No! \n");
					// keep merging top two comp in stack until the grey level >= pixel_val
					for ( ; ; )
					{
						debug_print("[M->N->O]\n");
						comptr--;
						MSERMergeComp( comptr+1, comptr, comptr, histptr );
						histptr++;
						if ( pixel_val <= comptr[0].grey_level )
						{
							debug_print("[O->E]\n");
							break;
						} else {
							debug_print("[O->Y->L->M]\n");
						}
						if ( pixel_val < comptr[-1].grey_level )
						{
							debug_print("[M->E]\n");
							debug_print("create hst %d\n", (histptr-hist_start));
							MSERNewHistory( comptr, histptr );
							comptr[0].grey_level = pixel_val;
							debug_print("update cmp %d grey_level %d \n", (comptr-cmp_start), pixel_val);
							histptr++;
							break;
						}
					}
				}
			} else {
				debug_print("[J->Z]\n");
				break;
			}
		}
	}
	return (histptr-hist_start);
}

int _get_ERs(
			 CvMat *src,
			 ER_t *ERs,
			 LinkedPoint *pts,
			 int reverse)
{
	int step = 8;
	int stepgap = 3;
	while (step < src->step+2)
	{
		step <<= 1;
		stepgap++;
	}
	int stepmask = step-1;

	// to speedup the process, make the width to be 2^N
	CvMat img;// = cvCreateMat( src->rows+2, step, CV_32SC1 );
	int* img_data = (int*)malloc((src->rows+2)*step*sizeof(int));
	img.rows = src->rows+2;
	img.cols = step;
	img.step = step;
	img.type = 1111638020;//CV_32SC1;
	img.data.i = img_data;

	int* ioptr = img.data.i+step+1;
	int* imgptr;

	// pre-allocate boundary heap
	int** heap = (int **)malloc((src->rows*src->cols+256)*sizeof(heap[0]));
	int** heap_start[256];
	heap_start[0] = heap;

	// pre-allocate point map buffer, used for assigning pts' l,r,t,b
	LinkedPoint *pts_map = (LinkedPoint *)malloc((src->rows+2)*step*sizeof(LinkedPoint *));
	memset(pts_map, 0, (src->rows+2)*step*sizeof(LinkedPoint *));
	for (int i=0; i<(src->rows*src->cols); i++) {
		ERs[i].val = -1;
		ERs[i].size = -1;
		ERs[i].ER_id = -1;
		ERs[i].ER_val = -1;
		ERs[i].ER_size = -1;
		ERs[i].ER_parent = -1;
		ERs[i].ER_firstChild = -1;
		ERs[i].ER_nextSibling = -1;
		ERs[i].ER_prevSibling = -1;
		ERs[i].to_parent = NULL;
		ERs[i].to_firstChild = NULL;
		ERs[i].to_nextSibling = NULL;
		ERs[i].to_prevSibling = NULL;
	}
	//MemStorage storage;

	// darker to brighter (MSER-)
	CvMat* mask = 0;
	CvSeq* contours = 0;
	MSERConnectedComp comp[257];
	imgptr = preprocessMSER_8UC1( &img, heap_start, src, mask, reverse );
	int no_ER = extractMSER_8UC1_Pass( ioptr, imgptr, heap_start, pts, ERs, comp, step, stepmask, stepgap, -1, contours, pts_map);

	// add root node
	ER_t *root = &ERs[no_ER];
	root->ER_id = no_ER;
	root->ER_size = src->rows*src->cols;
	int max_val = 0;
	for (int i=0; i<src->rows*src->cols; i++) {
		if (ERs[i].ER_parent==-1) {
			if (ERs[i].ER_prevSibling==-1) {
				ER_t* cur = &ERs[i];
				root->ER_firstChild = i;
				root->to_firstChild = cur;
				root->ER_head = cur->ER_head;
				while (cur)
				{
					cur->ER_parent = root->ER_id;
					cur->to_parent = root;
					if (cur->ER_val > max_val) max_val = cur->ER_val;
					cur = cur->to_nextSibling;
				}
				break;
			}
		}
	}
	root->ER_val = max_val;
	no_ER ++;

	// add l,t,r,b ptr for each point
	u32 *ptsmap_ptr = (u32 *)pts_map;
	for (int i=step; i<(src->rows+2)*step; i++) {
		LinkedPoint *cur_pt = (LinkedPoint *)ptsmap_ptr[i];
		if (cur_pt!=NULL) {
			cur_pt->l = (LinkedPoint *)ptsmap_ptr[i-1];
			cur_pt->r = (LinkedPoint *)ptsmap_ptr[i+1];
			cur_pt->t = (LinkedPoint *)ptsmap_ptr[i-step];
			cur_pt->b = (LinkedPoint *)ptsmap_ptr[i+step];
		}
	}

	// clean up
	free(heap);
	free(img_data);
	free(pts_map);

	return no_ER;
}

int get_ERs(
			 IN u8 *img_data,
			 IN int img_rows,
			 IN int img_cols,
			 IN int reverse,
			 OUT ER_t *ERs,
			 OUT LinkedPoint *pts)
{
    // use reverse plus 2 to indicate debug mode 
    if (reverse>=2) {
            debug = 1;
            reverse-=2;
    }
	struct CvMat img;
	img.type = 0; //CV_8UC1
	img.data.ptr = img_data;
	img.rows = img_rows;
	img.cols = img_cols;
	img.step = img_cols;

	return _get_ERs(&img, ERs, pts, reverse);
}

void ER_tree_traversal(ER_t *v)
{
	ER_t *c = v->to_firstChild;
	while (c) {
		ER_tree_traversal(c);
		
		// visit v as follows
		printf("ER_id %d is visited\n", c->ER_id);

		c = c->to_nextSibling;
	}
}


int main_sample(void) 
{
	int img_cols = 4;
	int img_rows = 4;
	u8* img_data = (u8*)malloc(img_cols*img_rows*sizeof(u8));
	u8* img_ptr = img_data;
	img_ptr[0] =  1; img_ptr[1] =  2; img_ptr[2] =  3; img_ptr[3] =  1;
	img_ptr[4] =  2; img_ptr[5] =  2; img_ptr[6] =  3; img_ptr[7] =  2;
	img_ptr[8] =  3; img_ptr[9] =  3; img_ptr[10] = 4; img_ptr[11] = 4;
	img_ptr[12] = 2; img_ptr[13] = 1; img_ptr[14] = 4; img_ptr[15] = 3;

	ER_t* ERs = (ER_t *)malloc(img_rows*img_cols*sizeof(ERs[0]));
	LinkedPoint* pts = (LinkedPoint*)malloc(img_rows*img_cols*sizeof(pts[0]));

	int no_ER = get_ERs(img_data, img_rows, img_cols, 0/*2:see debug msg*/, ERs, pts);

	ER_t *ER_cur = &ERs[0];
	ER_t *ER_nxt = &ERs[1];
	p4_t pt;
	pt.val[0] = (u32)ER_nxt->ER_head;
	pt.val[1] = ER_nxt->ER_size;
	pt.val[2] = (u32)ER_cur->ER_head;
	pt.val[3] = ER_cur->ER_size;

	// bounding box
	p4_t featBB_in, featBB_out;
	featBB_in.val[0] = featBB_in.val[1] = featBB_in.val[2] = featBB_in.val[3] = 2;
	get_BoundingBox(IN pt, IN featBB_in, OUT &featBB_out);

	// perimeter
	p1_t featPR_in, featPR_out;
	featPR_in.val[0] = 4;
	get_Perimeter(IN pt, IN featPR_in, OUT &featPR_out);

	//ER_tree_traversal(&ERs[no_ER-1]);
	printf("this test is good\n");
	char ch;
	scanf("%c", &ch);


	free(ERs);
	free(pts);
	
	return 0;
}
