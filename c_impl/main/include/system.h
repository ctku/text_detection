
#ifndef SYSTEM_H_
#define SYSTEM_H_

#define IN
#define OUT

#define MIN(x,y) ((x) < (y) ? (x) : (y))
#define MAX(x,y) ((x) > (y) ? (x) : (y))

typedef unsigned char u8;
typedef unsigned short int u16;
typedef unsigned long int u32;

typedef struct p1_t
{
	u32 val[1];
} p1_t;

typedef struct p2_t
{
	u32 val[2];
} p2_t;

typedef struct p3_t
{
	u32 val[3];
} p3_t;

typedef struct p4_t
{
	u32 val[4];
} p4_t;

typedef struct p5_t
{
	u32 val[5];
} p5_t;

typedef struct p6_t
{
	u32 val[6];
} p6_t;

typedef struct p7_t
{
	u32 val[7];
} p7_t;

#endif