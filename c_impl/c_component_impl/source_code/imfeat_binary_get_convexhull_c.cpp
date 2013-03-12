//#define MATLAB

/*=================================================================
 * 
 * version: 02/14/2013 11:29
 *
 * Matlab: [out] = imfeat_binary_get_convexhull_c(img)
 *
 * Input - img (u8 array): newly-added binary map (see ps.1)
 *           
 * Output - out (double): size of convex hull
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

//#include "bool.h"
//#include "geometry.h"
#include "stdlib.h"
#include "stdio.h"

typedef unsigned char u8;
typedef unsigned short int u16;
typedef unsigned long int u32;

#define	PI	3.1415926	/* ratio of circumference to diameter */
#define EPSILON	0.000001	/* a quantity small enough to be zero */

typedef struct {
	double a;		/* x-coefficient */
	double b;		/* y-coefficient */
	double c;		/* constant term */
} line;

#define DIMENSION	2	/* dimension of points */
#define X		0	/* x-coordinate index */
#define	Y		1	/* y-coordinate index */

typedef double point[DIMENSION];

typedef struct {
	int n;			/* number of points in polygon */
	point *p;       /* array of points in polygon */
} polygon;


typedef struct {
	point p1,p2;		/* endpoints of line segment */
} segment;

typedef point triangle[3];	/* triangle datatype */

typedef struct {
	point c;		/* center of circle */
	double r;		/* radius of circle */
} circle;


/*	Comparison macros 	*/

#define	max(A, B)		((A) > (B) ? (A) : (B))
#define min(A, B)		((A) < (B) ? (A) : (B))

void copy_point(point a, point b)
{
	int i;			/* counter */

	for (i=0; i<DIMENSION; i++) b[i] = a[i];
}

#include <math.h>

point first_point;		/* first hull point */

int comp( const void * , const void * ) ; 

int leftlower(const void *_p1, const void *_p2)
{
	point *p1 = (point *)_p1;
	point *p2 = (point *)_p2;
	if ((*p1)[X] < (*p2)[X]) return (-1);
	if ((*p1)[X] > (*p2)[X]) return (1);
	if ((*p1)[Y] < (*p2)[Y]) return (-1);
	if ((*p1)[Y] > (*p2)[Y]) return (1);

	return(0);
}

void sort_and_remove_duplicates(point in[], int *n)
{
	int i;                  /* counter */
	int oldn;               /* number of points before deletion */
	int hole;               /* index marked for potential deletion */
	//bool leftlower();

	qsort(in, *n, sizeof(point), leftlower);

	oldn = *n;
	hole = 1;
	for (i=1; i<oldn; i++) {
		if ((in[hole-1][X] == in[i][X]) && (in[hole-1][Y] == in[i][Y])) 
			(*n)--;
		else {
			copy_point(in[i],in[hole]);
			hole = hole + 1;
		}
	}
	//copy_point(in[oldn-1],in[hole]);
}

double signed_triangle_area(point a, point b, point c)
{
	return( (a[X]*b[Y] - a[Y]*b[X] + a[Y]*c[X] 
		- a[X]*c[Y] + b[X]*c[Y] - c[X]*b[Y]) / 2.0 );
}

bool collinear(point a, point b, point c)
{
	//double signed_triangle_area();

	return (fabs(signed_triangle_area(a,b,c)) <= EPSILON);
}

double distance(point a, point b)
{
        int i;			/* counter */
        double d=0.0;		/* accumulated distance */

        for (i=0; i<DIMENSION; i++)
                d = d + (a[i]-b[i]) * (a[i]-b[i]);

        return( sqrt(d) );
}

bool ccw(point a, point b, point c)
{
	//double signed_triangle_area();

	return (signed_triangle_area(a,b,c) > EPSILON);
}

int smaller_angle(const void *_p1, const void *_p2)
{
	point *p1 = (point *)_p1;
	point *p2 = (point *)_p2;
	if (collinear(first_point,*p1,*p2)) {
		if (distance(first_point,*p1) <= distance(first_point,*p2))
			return(-1);
		else
			return(1);
	}

	if (ccw(first_point,*p1,*p2))
		return(-1);
	else
		return(1);
}


void convex_hull(point in[], int n, polygon *hull)
{
	int i;			/* input counter */
	int top;		/* current hull size */
	//bool smaller_angle();
	
	if (n <= 3) { 		/* all points on hull! */
		for (i=0; i<n; i++)
			copy_point(in[i],hull->p[i]);
		hull->n = n;
		return;
	}

	sort_and_remove_duplicates(in,&n);
	copy_point(in[0],first_point);

	qsort(&in[1], n-1, sizeof(point), smaller_angle);

	copy_point(first_point,hull->p[0]);
	copy_point(in[1],hull->p[1]);

	copy_point(first_point,in[n]);	/* sentinel to avoid special case */
	top = 1;
	i = 2;

	while (i <= n) {
		if (!ccw(hull->p[top-1], hull->p[top], in[i])) 
			top = top-1;	/* top not on hull */
		else {
			top = top+1;
                    	copy_point(in[i],hull->p[top]);
			i = i+1;
		}
	}

	hull->n = top;
}

void print_polygon(polygon *p)
{
	int i;			/* counter */

        for (i=0; i<p->n; i++)
                printf("(%lf,%lf)\n",p->p[i][X],p->p[i][Y]);
}

//  Public-domain function by Darel Rex Finley, 2006.
double polygonArea(double *x, double *y, int points) {

	double area=0. ;
	int i, j=points-1  ;

	for (i=0; i<points; i++) {
	area += (x[j]+x[i])*(y[j]-y[i]); j=i; }

	return area*.5; 
}

double get_convex_hull_area_by_xy(int *x, int *y, int n, int max_size) {

	// calculate convex hull
	point *in = (point *)malloc(sizeof(point)*n);
	for (int i=0; i<n; i++) {
		in[i][X] = x[i];
		in[i][Y] = y[i];
	}
	polygon my_hull;
	my_hull.n = 0;
	my_hull.p = (point *)malloc(sizeof(point)*max_size);

	//sort_and_remove_duplicates(in,&n);
	convex_hull(in, n, &my_hull);

	// collect points
	int p = 0;
	double *x_db = (double*)malloc(sizeof(double)*my_hull.n);
	double *y_db = (double*)malloc(sizeof(double)*my_hull.n);
	for (int i=0; i<my_hull.n; i++) {
		x_db[p] = (double)(my_hull.p[i][X]);
		y_db[p] = (double)(my_hull.p[i][Y]);
		p = p + 1;
	}

	// calculate size
	double area = polygonArea(x_db, y_db, my_hull.n);

	// release memory
	//free(in);
	free(x_db);
	free(y_db);

	return area;
}

double get_convex_hull_area_by_img(u8 *img, int row, int col) {

	int *x = (int*)malloc(sizeof(int)*row*col);
	int *y = (int*)malloc(sizeof(int)*row*col);
	int n = 0;
	for (int i=0; i<row; i++) {
		for (int j=0; j<col; j++) {
			if (img[i*col+j]>0) {
				x[n] = j;
				y[n] = i;
				n = n + 1;
			}
		}
	}
	double size = get_convex_hull_area_by_xy(x,y,n,row*col);
	free(x);
	free(y);

	return size;
}

#ifndef MATLAB

int main(void)
{
	u8 img[15]={0,0,1,0,0,
	            0,1,1,1,0,
	            1,1,1,1,1};
	int row = 3;
	int col = 5;
	double size = get_convex_hull_area_by_img(img, row, col);

	return 0;
}

#else
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    u8 *img = (u8*)mxGetPr(prhs[0]); // transposed input matrix is expected
    int img_rows = (int)mxGetN(prhs[0]); // switch rows & cols
    int img_cols = (int)mxGetM(prhs[0]); // switch rows & cols
    
    plhs[0] = mxCreateNumericMatrix(1, 1, mxDOUBLE_CLASS, mxREAL);
    int *out = (int*)mxGetPr(plhs[0]);

    *out = get_convex_hull_area_by_img(img, img_rows, img_cols);
}
#endif

#endif