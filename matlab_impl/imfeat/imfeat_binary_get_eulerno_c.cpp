#define MATLAB

/*=================================================================
 * 
 * version: 01/26/2013 21:33
 *
 * Matlab: [out] = imfeat_binary_get_eulerno_c(new, cum)
 *
 * Input - new (u8 array): newly-added binary map (see ps.1)
 *       - cum (u8 array): accumulated binary map (see ps.1)
 *           
 * Output - out (int): change of eulerno
 *
 * ps.1: Rember to have an transpose on this parameter when calling in Matlab, 
 *       to compensate the different memory layout between Matlab & C.
 *=================================================================*/

#ifdef MATLAB
#include "mex.h"
#include "matrix.h"
#define IMFEAT_BINARY_GET_EULERNO_C
#else
#include "c_implement.h"
#endif

#ifdef IMFEAT_BINARY_GET_EULERNO_C

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define cor2idx(x,y,w)	(x+(y)*(w))
typedef unsigned char u8;
typedef unsigned short int u16;
typedef unsigned long int u32;

int imfeat_eulerno_change_algo(u8 *img_new, u8 *img_cum, int img_rows, int img_cols)
{
	// new_img: newly-added binary map
	// cum_img: accumulated binary map
    
	// calc Euler no difference for each new pixel
	int p = -1;
	int H = img_rows;
	int W = img_cols;
	// enlarge 1 pxl to avoid bondary checking
	u8 *cums = (u8 *)malloc((W+2)*(H+2)*sizeof(u8));
	u8 *news = (u8 *)malloc((W+2)*(H+2)*sizeof(u8));
	u8 *coms = (u8 *)malloc((W+2)*(H+2)*sizeof(u8));
	int *psi = (int *)malloc((W+2)*(H+2)*sizeof(int));
	memset(cums, 0, (W+2)*(H+2)*sizeof(u8));
	memset(news, 0, (W+2)*(H+2)*sizeof(u8));
	for (int y=0; y<H; y++) {
		memcpy(&cums[cor2idx(1,y+1,W+2)], &img_cum[y*W], W*sizeof(u8));
		memcpy(&news[cor2idx(1,y+1,W+2)], &img_new[y*W], W*sizeof(u8));
	}
	memcpy(coms, cums, (W+2)*(H+2));
	for (int h=1; h<H+1; h++) {
		for (int w=1; w<W+1; w++) {
			if (news[cor2idx(w,h,W+2)]==0)
				continue;
			// for each new pixel p
			p = p + 1;
			// (1) add each new pixel into com for later used in step 2
			coms[cor2idx(w,h,W+2)] = 1;
			// (2) match 3 kinds of 2x2 quads (Q1,Q3,Qd) with com(newly-combined) 
			//     and cum(previously-accumulated) seperately centered at p(h,w).
			//     So subindex y goes from -1 to 0, x from -1 to 0.
			//     if mached with com: score q plus 1.
			//     if mached with cum: score q minus 1.
			int q1 = 0, q3 = 0, qd = 0;
			for (int y=-1; y<=0; y++) {
				for (int x=-1; x<=0; x++) {
					int sum_com = coms[cor2idx(w+x,h+y,W+2)] + coms[cor2idx(w+x+1,h+y,W+2)] + coms[cor2idx(w+x,h+y+1,W+2)] + coms[cor2idx(w+x+1,h+y+1,W+2)];
					int sum_cum = cums[cor2idx(w+x,h+y,W+2)] + cums[cor2idx(w+x+1,h+y,W+2)] + cums[cor2idx(w+x,h+y+1,W+2)] + cums[cor2idx(w+x+1,h+y+1,W+2)];
					if (sum_com==1) q1 = q1 + 1;
					if (sum_cum==1) q1 = q1 - 1;
					if (sum_com==3) q3 = q3 + 1;
					if (sum_cum==3) q3 = q3 - 1;
					if ((coms[cor2idx(w+x,h+y,  W+2)]==1 && coms[cor2idx(w+x+1,h+y,  W+2)]==0 && 
						 coms[cor2idx(w+x,h+y+1,W+2)]==0 && coms[cor2idx(w+x+1,h+y+1,W+2)]==1) || 
						(coms[cor2idx(w+x,h+y,  W+2)]==0 && coms[cor2idx(w+x+1,h+y,  W+2)]==1 && 
						 coms[cor2idx(w+x,h+y+1,W+2)]==1 && coms[cor2idx(w+x+1,h+y+1,W+2)]==0))
						qd = qd + 1;
					if ((cums[cor2idx(w+x,h+y,  W+2)]==1 && cums[cor2idx(w+x+1,h+y,  W+2)]==0 &&
						 cums[cor2idx(w+x,h+y+1,W+2)]==0 && cums[cor2idx(w+x+1,h+y+1,W+2)]==1) ||
						(cums[cor2idx(w+x,h+y,  W+2)]==0 && cums[cor2idx(w+x+1,h+y,  W+2)]==1 &&
						 cums[cor2idx(w+x,h+y+1,W+2)]==1 && cums[cor2idx(w+x+1,h+y+1,W+2)]==0))
						qd = qd - 1;
				}
			}
			// (3) cal Euler no change: psi(p) = 1/4 * (q1 - q3 + 2*qd)
			psi[p] = (q1 - q3 + 2*qd) / 4;
			// (4) add each new pixel into cum for next loop
			cums[cor2idx(w, h, W+2)] = 1;
		}
	}

	// update Euler no change
	int phi = 0;
	for (int i=0; i<=p; i++) {
		phi = phi + psi[i];
	}

	//release memory
	free(cums);
	free(news);
	free(coms);
	free(psi);

	return phi;

}

#ifndef MATLAB
int main(void)
{
	u8 img_cum[15] = {0,0,0,0,0,
                      0,0,0,0,0,
					  0,0,0,0,0};
	u8 img_new[15] = {1,0,1,1,1,
                      0,0,1,0,1,
					  0,1,1,1,1};
	int out = imfeat_eulerno_change_algo(img_new, img_cum, 3, 5);

	return 0;
}
#else
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    u8 *img_new = (u8*)mxGetPr(prhs[0]); // transposed input matrix is expected
    u8 *img_cum = (u8*)mxGetPr(prhs[1]); // transposed input matrix is expected
    int img_rows = (int)mxGetN(prhs[0]); // switch rows & cols
    int img_cols = (int)mxGetM(prhs[0]); // switch rows & cols
    
    plhs[0] = mxCreateNumericMatrix(1, 1, mxINT32_CLASS, mxREAL);
    int *out = (int*)mxGetPr(plhs[0]);

    *out = imfeat_eulerno_change_algo(img_new, img_cum, img_rows, img_cols);
}
#endif

#endif