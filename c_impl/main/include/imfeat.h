
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
	/* public used */
	struct LinkedPoint* prev;
	struct LinkedPoint* next;
	struct LinkedPoint* l;
	struct LinkedPoint* t;
	struct LinkedPoint* r;
	struct LinkedPoint* b;
	struct Points pt;

	/* free to use */
	int val;
}
LinkedPoint;

// Extreamal region tree node
typedef struct ER_t
{
	/* public used */
	int ER_id;
	int ER_val;
	int ER_size;
	int ER_parent;
	int ER_firstChild;
	int ER_nextSibling;
	int ER_prevSibling;
	struct ER_t* to_parent;
	struct ER_t* to_firstChild;
	struct ER_t* to_nextSibling;
	struct ER_t* to_prevSibling;
	LinkedPoint* ER_head;
	LinkedPoint* ER_tail;

	/* free to use after get_ERs */
	int val;
	int size;
}
ER_t;

/* Provided feature API */
extern int get_ERs(IN u8 *img_data, IN int img_rows, IN int img_cols, IN int reverse, OUT ER_t *ERs, OUT LinkedPoint *pts);
extern void get_BoundingBox(IN p7_t pt, IN p4_t feat_in, OUT p4_t *feat_out);
extern void get_Perimeter(IN p7_t pt, IN p1_t feat_in, OUT p1_t *feat_out);
extern void get_EulerNo(IN p7_t pt, IN p1_t feat_in, OUT p1_t *feat_out);
extern void get_HzCrossing(IN p7_t pt, IN p1_t feat_in, OUT p1_t *feat_out);

#endif