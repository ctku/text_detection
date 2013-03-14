
#include "../../include/system.h"
#include "../../include/imfeat.h"
#include <stdio.h>
#include <stdlib.h>

void get_Perimeter(IN p4_t pt, IN p1_t feat_in, OUT p1_t *feat_out)
{
	LinkedPoint *pt_all_start = (LinkedPoint *)pt.val[0];
	int pt_all_no = pt.val[1];
	LinkedPoint *pt_inv_start = (LinkedPoint *)pt.val[2];
	int pt_inv_no = pt.val[3];

	int p = feat_in.val[0];

	// label all original pixels as 1
	LinkedPoint *cur = pt_all_start;
	int invalid = 0, k = 0;
	for (int i=0; i<pt_all_no; i++, cur=cur->next) {
		if (cur==pt_inv_start) invalid = 1;
		if (invalid==1)	cur->val = 1;
		if (invalid==1) k++;
		if (k==pt_inv_no) invalid = 0;
	}
	// calc perimeter
	cur = pt_all_start; invalid = 0; k = 0;
	for (int i=0; i<pt_all_no; i++, cur=cur->next) {
		if (cur==pt_inv_start) invalid = 1;
		if (invalid==0) {
			// process each new added pixels here
			// (1) calc num of adjacent edge q with accumulated map
			int q = 0;
			if (cur->l)
				if (cur->l->val==1)
					q = q + 1;
			if (cur->t)
				if (cur->t->val==1)
					q = q + 1;
			if (cur->r)
				if (cur->r->val==1)
					q = q + 1;
			if (cur->b)
				if (cur->b->val==1)
					q = q + 1;
			// (2) calc edge no change: 4 - 2{q:qAp^C(q)<=C(p)}
			p = p + (4 - 2*q);
			// (3) set cur pt as 1
			cur->val = 1;
		}
		if (invalid==1) k++;
		if (k==pt_inv_no) invalid = 0;
	}

	feat_out->val[0] = p;
}
