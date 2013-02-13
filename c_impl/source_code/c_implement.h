#ifndef C_IMPLEMENT_H
#define C_IMPLEMENT_H

// unmark one of the following to enable the file for compiling
//#define IMFEAT_ERTREE_GET_ERS_C
//#define IMFEAT_BINARY_GET_EULERNO_C
//#define IMFEAT_BINARY_GET_HZCROSSING_C
//#define IMFEAT_BINARY_GET_PERIMETER_C
#define IMFEAT_BINARY_GET_CONVEXHULL_C

#define cor2idx(x,y,w)	(x+(y)*(w))
typedef unsigned char u8;
typedef unsigned short int u16;
typedef unsigned long int u32;

#endif