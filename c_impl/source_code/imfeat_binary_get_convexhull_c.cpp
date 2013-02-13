//#define MATLAB

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
#define IMFEAT_BINARY_GET_CONVEXHULL_C
#else
#include "c_implement.h"
#endif

#ifdef IMFEAT_BINARY_GET_CONVEXHULL_C

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct 
{
        double x;
        double y;
} point_t;

int jarvis(point_t *cloud, int n);
int graham(point_t *cloud, int n);

static point_t base;

int is_inside_segment (point_t *p0, point_t *p1, point_t *p2)
{
	if ((p1->x < p2->x) && (p0->x >= p1->x) && (p0->x <= p2->x)) return 1;
	if ((p1->x > p2->x) && (p0->x <= p1->x) && (p0->x >= p2->x)) return 1;
	if ((p1->y < p2->y) && (p0->y >= p1->y) && (p0->y <= p2->y)) return 1;
	if ((p1->y > p2->y) && (p0->y <= p1->y) && (p0->y >= p2->y)) return 1;

    return 0;
}

double ccw(point_t *p1, point_t *p2, point_t *p3)
{
	double v = (p2->x - p1->x)*(p3->y - p1->y) - (p3->x - p1->x)*(p2->y - p1->y);
	return v;
}

void swap (point_t *cloud, int i, int j)
{
	point_t tmp;

	tmp.x = (cloud+i)->x; tmp.y = (cloud+i)->y;
	(cloud+i)->x = (cloud+j)->x;
	(cloud+i)->y = (cloud+j)->y;
	(cloud+j)->x = tmp.x;
	(cloud+j)->y = tmp.y;
}

int compar_cotan(const void *a, const void *b)
{
	point_t *p1 = (point_t *)a;
	point_t *p2 = (point_t *)b;
	double cotan1, cotan2;

	if ( (p1->x == base.x) && (p1->y == base.y) ) return -1;
	if ( (p2->x == base.x) && (p2->y == base.y) ) return 1;

	/* p1, p2 and base are on the same vertical line */
	if ( (p1->x == base.x) && (p2->x == base.x) ) {
		if (p1->y < p2->y) return -1;
		return 1;
	}

	/* p1, p2 and base are on the same horizontal line 
	   per Graham algo, base has the lowest x-coordinate. 
	   Sort p1 and p2 according to the lowest x-coordinate */
	if ( (p1->y == base.y) && (p2->y == base.y) ) {
		if (p1->x < p2->x) return -1;
		return 1;
	}

	cotan1 = (p1->x - base.x)/(p1->y - base.y);
	cotan2 = (p2->x - base.x)/(p2->y - base.y);

	if (cotan1 > cotan2) return -1;
	if (cotan1 < cotan2) return  1;
	if (cotan1 == cotan2) { /* both points are aligned on the same side of base point - closest point is the first */
		if (cotan1 < 0) {   /* Angle > 90 */
			if (p1->x < p2->x) return -1;
			if (p2->x < p1->x) return 1;
		}
		if (cotan1 > 0) { /* Angle < 90 */
			if (p1->x < p2->x) return 1;
			if (p2->x < p1->x) return -1;
		}
	}

	return 0;
}

int jarvis(point_t *cloud, int n)
{
	int i, b=0, a=0, minx, np;

	minx = cloud[0].x;
	np = 1;
	for (i=1; i < n; i++)
	{
		if (cloud[i].x < minx) {
			minx = cloud[i].x;
			a = i;
		}
	}
	swap(cloud, a, 0);
	while(1) {
		a = np-1;
		if ( a == 0 ) {
			b = 1;
			for (i=2; i < n; i++)
				if (ccw(cloud+a, cloud+b, cloud+i) > 0) b = i;
				else if (ccw(cloud+a, cloud+b, cloud+i) == 0) {
					/* If the 3 points are aligned, update b only if i is between a and b */
					if (is_inside_segment(cloud+i, cloud+a, cloud+b))
						b = i;
				}		
		}
		else {
			b = 0;
			for (i=1; i <n; i++) {
				if (i == a) continue;
				if (ccw(cloud+a, cloud+b, cloud+i) > 0) b = i;
				else if (ccw(cloud+a, cloud+b, cloud+i) == 0) {
					if (is_inside_segment(cloud+i, cloud+a, cloud+b))
						b = i;
				}		
			}
		}
		if (b == 0) break;
		swap(cloud, np++, b);
	}
	return np;
}

int graham (point_t *cloud, int n)
{
	int i, a0, m;

	a0 = 0;
	for (i=1; i < n; i++) {
		if (cloud[a0].y > cloud[i].y)
			a0 = i;
		if (cloud[a0].y == cloud[i].y)
			if (cloud[a0].x > cloud[i].x)
				a0 = i;
	}	
	base.x = cloud[a0].x; base.y = cloud[a0].y;
	cloud[n].x = base.x; cloud[n].y = base.y;
	qsort(cloud, n+1, sizeof(point_t), compar_cotan);
	cloud[0].x = cloud[n].x; cloud[0].y = cloud[n].y;

	m = 2;
	for (i=3; i<=n; i++) {
		while (ccw(cloud+m-1, cloud+m, cloud+i) <= 0)
			m--;
		m++;
		swap(cloud, m, i);
	}
	/* Swap back the last point to avoid corrupting the initial set */
	swap(cloud, m, n);
	return m;
}


#ifndef MATLAB
int main(void)
{
	u8 img_cum[21] = {0,0,0,1,0,0,0,
                      0,0,0,0,0,0,0,
					  0,1,0,0,0,1,0};
	int w = 7, h = 3;
	point_t *points = (point_t*)malloc(sizeof(point_t *)*w*h);
	memset(points, 0, sizeof(point_t)*w*h);

	int n = 0;
	for (int i=0; i<h; i++) {
		for (int j=0; j<w; j++) {
			if (img_cum[i*w+j]==1) {
				points[n].x = j;
				points[n].y = i;
				n = n + 1;
			}
		}
	}
	int hull_size = 0;
	int m = jarvis(points, n);

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