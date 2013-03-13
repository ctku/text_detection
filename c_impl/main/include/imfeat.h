
#ifndef IMFEAT_H_
#define IMFEAT_H_

#include "system.h"

typedef struct Points
{
	int x;
	int y;
}
Points;

struct LinkedPoint;
typedef struct LinkedPoint
{
	struct LinkedPoint* prev;
	struct LinkedPoint* next;
	struct Points pt;
	int pt_order;
}
LinkedPoint;

// Extreamal region tree node
typedef struct ER_t
{
	/* public used */
	int ER_id;
	int ER_val;
	int ER_size;
	int ER_pxl_start;
	int ER_parent;
	int ER_firstChild;
	int ER_nextSibling;
	int ER_prevSibling;
	struct ER_t* to_parent;
	struct ER_t* to_firstChild;
	struct ER_t* to_nextSibling;
	struct ER_t* to_prevSibling;

	/* private used */
	LinkedPoint* ER_head;
	LinkedPoint* ER_tail;
	int val;
	int size;
}
ER_t;

/* Provided feature API */
extern void get_BoundingBox(IN p3_t pt, IN p4_t feat_in, OUT p4_t *feat_out);

#endif