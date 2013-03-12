//#define MATLAB

/*=================================================================
 * 
 * version: 01/27/2013 00:38
 *
 * Matlab: [out] = imfeat_binary_get_shapecontext_c(new, cum)
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
#define IMFEAT_BINARY_GET_SHAPECONTEXT_C
#else
#include "c_implement.h"
#endif

#ifdef IMFEAT_BINARY_GET_SHAPECONTEXT_C

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

typedef unsigned char u8;
typedef unsigned short int u16;
typedef unsigned long int u32;

//Parameter of the shape context
int		nbins_theta	= 12;		//Number of bins in angle
								//Decreasing nbins_theta to eight for the first iteration does not improve the performance.
int		nbins_r		= 5;		//Number of bins in distance
double	r_inner		= 1.0/8;	//The minimum distance
double	r_outer		= 2.0;		//The maximum distance
double	mean_dist_deform, mean_dist_model;  //Mean distances
double	dum_ratio = 0.25;			// Dummy points ratio
double	eps_dum=0.25;				// Cost for a point to match a dummy point
double	r=1;						// annealing rate
double	beta_init=1;				// initial regularization parameter (normalized)

//Some global variables
double	r_bins_edges[10];		//Lattice of radius
double	**SCModel	= NULL;		//Shape contexts for the model shape
double  **SCDeform	= NULL;		//Shape contexts for the deformed shape	
double	**r_array	= NULL;		//Distance array
double  **theta_array=NULL;		//Theta angle array
double  **costmat	= NULL;		//Matrix of the shape context distances between points from two shapes
double  *TPS		= NULL;		//Matrix of the TPS transform
double  *InvTPS		= NULL;		//Inversion of the matrix of the TPS transform

#define ZeroMemory RtlZeroMemory
#define RtlZeroMemory(Destination,Length) memset((Destination),0,(Length))

#ifndef PI
#define	PI		3.1415926535898
#endif //PI

#ifndef		MAX_NEIGHBOR_SIZE
#define		MAX_NEIGHBOR_SIZE	30
#endif

struct MYPOINT{
	double	x;	//X coordinate
	double  y;	//Y coordinate
	double	nAngleToCenter;	//Angle from this point to the mass center of the shape
	int		nMatch;			//Matching result
	int		nTrueMatch;		//The true match, used to testing
	int		nNumNeighbor;	//Number of neighbors of this point 
							//It is just the number of edges connecting this point in the graph
	int		nNeighborList[MAX_NEIGHBOR_SIZE];	//Neighbor list
};

/*************************************************************************************
/*	Name:		GetSquareDistance
/*	Function:	Get square of the Euclidean distance of two points
/*	Parameter:	pnt1 -- Point 1
/*				pnt2 -- Point 2
/*	Return:		Squared distance of two points
/**************************************************************************************/
double GetSquareDistance ( MYPOINT &pnt1, MYPOINT &pnt2 )
{
    double dx = pnt1.x - pnt2.x ;
    double dy = pnt1.y - pnt2.y ;
    return dx*dx + dy*dy;
}

/*****************************************************************************
/*	Name:		CalPointDist
/*	Function:	Calculate the distance array
/*	Parameter:	Pnt       -- Points set
/*				nPnt      -- Number of points
/*				r_array   -- Distance array
/*				mean_dist -- Mean distance
/*	Return:		0 -- Succeed
/*****************************************************************************/
int	CalPointDist(MYPOINT *Pnt, int nPnt, double **r_array, double &mean_dist)
{
	//Calculate the raw Euclidean distance matrix
	int i, j;
	for( i=0; i<nPnt; i++ )
		for( j=0; j<nPnt; j++ )
			r_array[i][j] = sqrt( GetSquareDistance( Pnt[i], Pnt[j] ) );

	//Calculate the mean distance
	mean_dist = 0;
	int		nValid = 0;
	for( i=0; i<nPnt; i++ )
	{
		if( Pnt[i].nMatch == -1 )
			continue;
		for( j=0; j<nPnt; j++ )
		{
			if( Pnt[j].nMatch == -1 )
				continue;
			mean_dist += r_array[i][j];
			nValid++;
		}
	}
	mean_dist /= nValid;
	return 0;
}

/*****************************************************************************
/*	Name:		AllocateMemory
/*	Function:	Allocate memory for global variables
/*	Parameter:	nMaxPnt	-- Maximum point number
/*	Return:		0 -- Succeed
/*****************************************************************************/
int	AllocateMemory( int nMaxPnt )
{
	SCModel = (double**)malloc( sizeof(double*)*nMaxPnt );
	SCDeform = (double**)malloc( sizeof(double*)*nMaxPnt );

	r_array = (double**)malloc( sizeof(double*)*nMaxPnt );
	theta_array = (double**)malloc( sizeof(double*)*nMaxPnt );

	int nTotalPnt = (int)( (1+dum_ratio)*nMaxPnt );
	costmat = (double**)malloc( sizeof(double*)*nTotalPnt );
	if( SCModel == NULL || SCDeform == NULL || 
		r_array == NULL || theta_array == NULL ||
		costmat == NULL )
	{
		printf( "Memory used up!\n" );
		return -1;
	}

	int nFeature = nbins_theta*nbins_r;
	for( int ii=0; ii<nMaxPnt; ii++ )
	{
		SCModel[ii] = (double*)malloc( sizeof(double)*nFeature );
		SCDeform[ii] = (double*)malloc( sizeof(double)*nFeature );
		r_array[ii] = (double*)malloc( sizeof(double)*nMaxPnt );
		theta_array[ii] = (double*)malloc( sizeof(double)*nMaxPnt );
	}
	for( int iii=0; iii<nTotalPnt; iii++ )
	{
		costmat[iii] = (double*)malloc( sizeof(double)*nTotalPnt );
		for( int j=0; j<nTotalPnt; j++ )
			costmat[iii][j] = eps_dum;

	}
	TPS = (double*)malloc( sizeof(double)*(nMaxPnt+3)*(nMaxPnt+3) );
	InvTPS = (double*)malloc( sizeof(double)*(nMaxPnt+3)*(nMaxPnt+3) );
	return 0;
}

/*****************************************************************************
/*	Name:		FreeMemory
/*	Function:	Free memory used by global variables
/*	Parameter:	nMaxPnt	-- Maximum point number
/*	Return:		0 -- Succeed
/*****************************************************************************/
int FreeMemory( int nMaxPnt )
{
	int	i;
	if( SCModel != NULL )
	{
		for( int i=0; i<nMaxPnt; i++ )
			free( SCModel[i] );
		free( SCModel );
	}

	if( SCDeform != NULL )
	{
		for( int i=0; i<nMaxPnt; i++ )
			free( SCDeform[i] );
		free( SCDeform );
	}

	if( r_array != NULL )
	{
		for( int i=0; i<nMaxPnt; i++ )
			free( r_array[i] );
		free( r_array );
	}

	if( theta_array != NULL )
	{
		for( int i=0; i<nMaxPnt; i++ )
			free( theta_array[i] );
		free( theta_array );
	}

	if( costmat != NULL )
	{
		int nTotalPnt = (int)( (1+dum_ratio)*nMaxPnt );
		for( i=0; i<nTotalPnt; i++ )
			free( costmat[i] );
		free( costmat );
	}

	if( TPS != NULL )
		free( TPS );
	if( InvTPS != NULL )
		free( InvTPS );
	return 0;
}

/*****************************************************************************
/*	Name:		CalShapeContext
/*	Function:	Compute the shape context
/*	Parameter:	Pnt				-- Points set
/*				nPnt			-- Number of points
/*				nbins_theta		-- Number of bins in angle
/*				nbins_r         -- Number of bins in radius
/*				r_bins_edges    -- Edges of the bins in radius
/*				SC              -- Shape context for each point
/*				r_array			-- Distance array
/*				mean_dist       -- Mean distance
/*				bRotateInvariant-- Rotation invariance or not
/*	Return:		0 -- Succeed
/*****************************************************************************/
int	CalShapeContext(MYPOINT *Pnt, int nPnt, int nbins_theta, int nbins_r, 
			   double *r_bins_edges, double **SC, double **r_array, double mean_dist, int bRotateInvariant)
{
	//Calculate the quantized angle matrix
	int i, j, k;
	for( i=0; i<nPnt; i++ )
	{
		for( j=0; j<nPnt; j++ )
		{
			if( i==j )
				theta_array[i][j] = 0;
			else
			{
				theta_array[i][j] = atan2( Pnt[j].y - Pnt[i].y, Pnt[j].x - Pnt[i].x );
				if( bRotateInvariant )
					theta_array[i][j] -= Pnt[i].nAngleToCenter;
				//put the theta in [0, 2*pi)
				theta_array[i][j] = fmod(fmod(theta_array[i][j]+1e-5,2*PI)+2*PI,2*PI);
				//Qualization
				theta_array[i][j] = floor( theta_array[i][j]*nbins_theta/(2*PI) );
			}
		}
	}

	//Normalization and qualization of radius matrix
	for( i=0; i<nPnt; i++ )
	{
		for( j=0; j<nPnt; j++ )
		{
			r_array[i][j] /= mean_dist;
			for( k=0; k<nbins_r; k++ )
				if( r_array[i][j] <= r_bins_edges[k] )
					break;
			r_array[i][j] = nbins_r-1-k;
		}
	}

	//Counting points inside each bin
	for( i=0; i<nPnt; i++ )
	{
		ZeroMemory( SC[i], sizeof(double)*nbins_r*nbins_theta );
		for( j=0; j<nPnt; j++ )
		{
			if( i == j )	//Do not count the point itself. This is a bug in the original shape context.
				continue;

			if( Pnt[j].nMatch == -1 )
				continue;
			if( r_array[i][j] < 0 )	// Out of range
				continue;

			int	index = r_array[i][j]*nbins_theta + theta_array[i][j];
			SC[i][index]++;
		}
	}

	return 0;
}

/*****************************************************************************
/*	Name:		CalRBinEdge
/*	Function:	Calculate radius bin edges
/*	Parameter:	nbins_r -- Number of bins in radius
/*				r_inner -- Radius of the inner bin
/*				r_outer -- Radius of the outer bin
/*	Return:		0 -- Succeed
/*****************************************************************************/
int	CalRBinEdge( int nbins_r, double r_inner, double r_outer, double *r_bins_edges )
{
	double	nDist = ( log10(r_outer) - log10(r_inner) ) / (nbins_r-1);
	for( int i=0; i<nbins_r; i++ )
		r_bins_edges[i] = pow(10, log10(r_inner)+nDist*i);
	return 0;
}

#ifndef MATLAB
int main(void)
{
	u8 img_cum[64] = {0,0,0,0,0,0,0,0
                      0,1,1,1,1,1,1,0
                      0,1,0,0,0,0,1,0
                      0,1,0,0,0,0,1,0
                      0,1,0,0,0,0,1,0
                      0,1,0,0,0,0,1,0
                      0,1,1,1,1,1,1,0
					  0,0,0,0,0,0,0,0};

	//Allocate memory
	int nPntModel = 100;
	int nMaxPnt = nPntModel;
	int nbins_r = 3;
	int r_inner = 10;
	int r_outer = 30;
	MYPOINT	*PntModel2	= new MYPOINT[nPntModel];	//Working point set for shape matching

	AllocateMemory( nMaxPnt );
	CalRBinEdge( nbins_r, r_inner, r_outer, r_bins_edges);

	CalPointDist( PntModel2, nPntModel, r_array, mean_dist_model );

	//Compute shape context for all points on the model shape
	int nbins_theta = 12;
	int nCurIter = 1;
	int rotate_invariant_flag = 0;
	CalShapeContext(PntModel2, nPntModel, nbins_theta, nbins_r, r_bins_edges, SCModel, r_array, mean_dist_model, nCurIter==1 && rotate_invariant_flag);

	int out[4];
	//imfeat_perimeter_change_algo(img_new, img_cum, 4, 7);

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