#define MATLAB

/*=================================================================
 * 
 * version: 01/27/2013 00:38
 *
 * Matlab: [out] = imfeat_binary_get_perimeter_c(new, cum)
 *
 * Input - new (u8 array): newly-added binary map (see ps.1)
 *       - cum (u8 array): accumulated binary map (see ps.1)
 *           
 * Output - out (int): change of perimeter
 *
 * ps.1: Rember to have an transpose on this parameter when calling in Matlab, 
 *       to compensate the different memory layout between Matlab & C.
 *=================================================================*/

#ifdef MATLAB
#include "mex.h"
#include "matrix.h"
#define IMFEAT_BINARY_GET_PERIMETER_C
#else
#include "c_implement.h"
#endif

#ifdef IMFEAT_BINARY_GET_PERIMETER_C

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define cor2idx(x,y,w)	(x+(y)*(w))
typedef unsigned char u8;
typedef unsigned short int u16;
typedef unsigned long int u32;

int imfeat_perimeter_change_algo(u8 *img_new, u8 *img_cum, int img_rows, int img_cols)
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
	int *psi = (int *)malloc((W+2)*(H+2)*sizeof(int));
	memset(cums, 0, (W+2)*(H+2)*sizeof(u8));
	memset(news, 0, (W+2)*(H+2)*sizeof(u8));
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
			// (1) calc num of adjacent edge q with accumulated map
			int q = 0;
			if (cums[cor2idx(w,h-1,W+2)]==1) q = q + 1;
			if (cums[cor2idx(w-1,h,W+2)]==1) q = q + 1;
			if (cums[cor2idx(w+1,h,W+2)]==1) q = q + 1;
			if (cums[cor2idx(w,h+1,W+2)]==1) q = q + 1;
			// (2) calc edge no change: psi(p) = 4 - 2{q:qAp^C(q)<=C(p)}
			psi[p] = 4 - 2*q;
			// (3) add each new pixel into cum for next loop
			cums[cor2idx(w,h,W+2)] = 1;
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
	free(psi);

	return phi;
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
	imfeat_perimeter_change_algo(img_new, img_cum, 4, 7, out);

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

    *out = imfeat_perimeter_change_algo(img_new, img_cum, img_rows, img_cols);
}
#endif

#endif