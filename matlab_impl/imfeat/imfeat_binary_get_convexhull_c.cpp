#define MATLAB

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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>
#include <fstream>
#include <utility>
#include <vector>
#include <string>
#include <algorithm>
#include <time.h>
#include <math.h>
using namespace std;
using namespace cv;
typedef unsigned char u8;
typedef unsigned short int u16;
typedef unsigned long int u32;

class plane{
protected:
  //member variables
  vector< pair<int, int> > points; //contains points
  //member functions
public:
  void set_points(int *x, int *y, int n); //loads file of points
  //pre: a txt file, first line number of points, rest lines points
  //post: nothing returned
};

class hull:public plane{
public:
  hull(){};
  //member variables
  vector<pair <int, int> > convex;
  //member functions
  void divide(); //divides points into upper and lower hulls
  //pre: populated hull object
  //post: nothing returned
  pair <int, int> findMax(pair <int, int> Ap, pair <int, int> Bp, hull suspects);
  //identifes farthes point from given line
  //pre: two points, and a hull
  //post: point within hull that is farthest away
  void convexify(pair <int, int> A, pair <int, int> B, hull toCheck);
  //recursively identifies convex hull
  //pre: two points and a hull
  //post: nothing returned
};

int determinant(pair<int, int> mtrx [3]){
  int dtr; //result

  dtr = (mtrx[0].first*mtrx[1].second) + (mtrx[1].first*mtrx[2].second) + (mtrx[2].first*mtrx[0].second) - (mtrx[2].first*mtrx[1].second) - (mtrx[1].first*mtrx[0].second) - (mtrx[0].first*mtrx[2].second);

  return dtr;
}

void plane::set_points(int *x, int *y, int n){

  pair <int, int> point; //contains x and y
  for (int i=0; i<n; i++) {
	  point.first = x[i];
	  point.second = y[i];
	  points.push_back(point);
  }
  sort (points.begin(), points.end()); //overloaded by <utility>
}

void hull::divide(){
  
  hull lower, upper; //upper and lower sections

  int dtrm;
  pair <int, int> mtrxsend [3] = {points.front(), points.back()};

  convex.push_back(points.front());
  convex.push_back(points.back());
  
  points.erase(points.begin());
  points.pop_back();

  vector< pair<int, int> >::iterator it;
  for (it=points.begin(); it<points.end(); ++it){

    mtrxsend[2] = *it;
    dtrm = determinant(mtrxsend);

    if(dtrm>0){
      upper.points.push_back(*it);} //upper hull
    else if(dtrm<0){
      lower.points.push_back(*it);} //lower hull

  }
  convexify(convex[0], convex[1], upper);
  convexify(convex[0], convex[1], lower);
}

pair <int, int> hull::findMax(pair <int, int> Ap, pair <int, int> Bp, hull suspects){
  float dist;
  float prev = 0;
  int dtrm;
  int baseLen = ((Bp.first-Ap.first)^2 + (Bp.second-Ap.second)^2)^(1/2);

  pair <int, int> pointfar;

  pair <int, int> mtrxsend [3] = {Ap, Bp};
  vector< pair <int, int> >::iterator it;
  for (it = suspects.points.begin(); it< suspects.points.end(); ++it){

    mtrxsend[2] = *it;

    dtrm = determinant(mtrxsend);
    if (dtrm < 0) {dtrm*=-1;};

    dist = dtrm/baseLen;
    if (dist >= prev){
      pointfar = *it;
      prev = dist;
    };
    
  }

  return pointfar;

}

void hull::convexify(pair <int, int> A, pair <int, int> B, hull toCheck){

  if (toCheck.points.size() == 0){return;};


  int dtrm;
  hull nextCheck, nextCheckTwo;

  pair <int, int> maxPoint = findMax(A, B, toCheck);
  convex.push_back(maxPoint);

  pair <int, int> mtrxsend [3] = {A, maxPoint};
  vector< pair<int, int> >::iterator it;
  for (it=toCheck.points.begin(); it<toCheck.points.end(); ++it){
    if (*it==maxPoint){
      //convex.push_back(*it);
      continue;
    }
    mtrxsend[2] = *it;
    dtrm = determinant(mtrxsend);

    if (maxPoint.second<A.second){
      if(dtrm<=0){
        nextCheck.points.push_back(*it);
      }
    }
    else if (dtrm>=0)
      nextCheck.points.push_back(*it);
  }

  pair <int, int> mtrxsendTwo [3] = {maxPoint, B};
  vector< pair<int, int> >::iterator i;
  for (i=toCheck.points.begin(); i<toCheck.points.end(); ++i){
    if (*i==maxPoint){
      continue;
    }
    mtrxsendTwo[2] = *i;
    dtrm = determinant(mtrxsendTwo);
    
    if (maxPoint.second<A.second){
      if(dtrm<=0){
        nextCheckTwo.points.push_back(*it);
      }
    }
    else if (dtrm>=0)
      nextCheckTwo.points.push_back(*it);
  }

  convexify(A, maxPoint, nextCheck);
  convexify(maxPoint, B, nextCheckTwo);    
}

//  Public-domain function by Darel Rex Finley, 2006.
double polygonArea(double *X, double *Y, int points) {

	double area=0. ;
	int i, j=points-1  ;

	for (i=0; i<points; i++) {
	area += (X[j]+X[i])*(Y[j]-Y[i]); j=i; }

	return area*.5; 
}

double get_convex_hull_area_by_xy(int *x, int *y, int n) {
	hull my_hull;

	// set points
	my_hull.set_points(x,y,n);

	// calculate convex hull points
	my_hull.divide();

	// collect points
	int p = 0;
	double *x_db = (double*)malloc(sizeof(double)*my_hull.convex.size());
	double *y_db = (double*)malloc(sizeof(double)*my_hull.convex.size());
	for (vector<pair<int, int>>::iterator i = my_hull.convex.begin(); i != my_hull.convex.end(); ++i)
	{
		x_db[p] = (double)(i->first);
		y_db[p] = (double)(i->second);
		p = p + 1;
	}

	// calculate size
	double area = polygonArea(x_db, y_db, my_hull.convex.size());

	// release memory
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
	double size = get_convex_hull_area_by_xy(x,y,n);
	free(x);
	free(y);

	return size;
}

#ifndef MATLAB
int main(void)
{
	u8 img[15]={0,0,1,0,0,
	            0,0,1,0,0,
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
    double *out = (double*)mxGetPr(plhs[0]);

    *out = get_convex_hull_area_by_img(img, img_rows, img_cols);
}
#endif

#endif