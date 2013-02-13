//#define MATLAB

/*=================================================================
 * 
 * version: 01/26/2013 23:49
 *
 * Matlab: [out] = imfeat_binary_get_hzcrossing_c(new, cum)
 *
 * Input - new (u8 array): newly-added binary map (see ps.1)
 *       - cum (u8 array): accumulated binary map (see ps.1)
 *           
 * Output - out (int): change of horizontal crossing
 *
 * ps.1: Rember to have an transpose on this parameter when calling in Matlab, 
 *       to compensate the different memory layout between Matlab & C.
 *=================================================================*/

#ifdef MATLAB
#include "mex.h"
#include "matrix.h"
#define IMFEAT_BINARY_GET_HZCROSSING_C
#else
#include "c_implement.h"
#endif

#ifdef IMFEAT_BINARY_GET_HZCROSSING_C

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void imfeat_hzcrossing_change_algo(u8 *img_new, u8 *img_cum, int img_rows, int img_cols, int *out)
{
	// new_img: newly-added binary map
	// cum_img: accumulated binary map
    
	// calc hzcrossing vector difference for each new pixel
	int p = -1;
	int H = img_rows;
	int W = img_cols;
	// enlarge 1 pxl to avoid bondary checking
	u8 *cums = (u8 *)malloc((W+2)*(H+2)*sizeof(u8));
	u8 *news = (u8 *)malloc((W+2)*(H+2)*sizeof(u8));
	memset(cums, 0, (W+2)*(H+2)*sizeof(u8));
	memset(news, 0, (W+2)*(H+2)*sizeof(u8));
	memset(out, 0, H*sizeof(int));

	for (int y=0; y<H; y++) {
		memcpy(&cums[cor2idx(1,y+1,W+2)], &img_cum[y*W], W*sizeof(u8));
		memcpy(&news[cor2idx(1,y+1,W+2)], &img_new[y*W], W*sizeof(u8));
	}
	for (int h=1; h<H+1; h++) {
		for (int w=1; w<W+1; w++) {
			if (news[cor2idx(w,h,W+2)]==0)
				continue;
			// for each new pixel p
			p = p + 1;
			// (1) calc change by check adjacent pxl in accumulated map
			int q = 0;
			if (cums[cor2idx(w-1,h,W+2)]==0 && cums[cor2idx(w+1,h,W+2)]==0) 
				q = q + 2; // -1 is due to 1 pxl enlarge
			if (cums[cor2idx(w-1,h,W+2)]==1 && cums[cor2idx(w+1,h,W+2)]==1) 
				q = q - 2; // -1 is due to 1 pxl enlarge
			out[h-1] = out[h-1] + q;
			// (2) add each new pixel into cum for next loop
			cums[cor2idx(w,h,W+2)] = 1;
		}
	}
	//release memory
	free(cums);
	free(news);

	return;

}

#ifndef MATLAB
int main(void)
{
	u8 img_cum[28] = {0,0,0,0,0,0,0,
                      0,0,0,0,0,0,0,
                      0,0,0,0,0,0,0,
					  0,0,0,0,0,0,0};
	u8 img_new[28] = {0,0,0,0,0,1,1,
                      0,1,1,0,1,1,1,
                      0,1,1,0,1,0,1,
					  0,0,0,0,0,0,1};
	int out[4];
	imfeat_hzcrossing_change_algo(img_new, img_cum, 4, 7, out);

	return 0;
}
#else
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    u8 *img_new = (u8*)mxGetPr(prhs[0]); // transposed input matrix is expected
    u8 *img_cum = (u8*)mxGetPr(prhs[1]); // transposed input matrix is expected
    int img_rows = (int)mxGetN(prhs[0]); // switch rows & cols
    int img_cols = (int)mxGetM(prhs[0]); // switch rows & cols
    
    plhs[0] = mxCreateNumericMatrix(1, img_rows, mxINT32_CLASS, mxREAL);
    int *out = (int*)mxGetPr(plhs[0]);

    imfeat_hzcrossing_change_algo(img_new, img_cum, img_rows, img_cols, out);
}
#endif

#endif