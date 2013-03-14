
#include "../../include/system.h"
#include "../../include/imfeat.h"
#include "imfeat_internal.h"
#include <stdio.h>
#include <stdlib.h>

void get_Perimeter(IN p7_t pt, IN p1_t feat_in, OUT p1_t *feat_out)
{
	LinkedPoint *pt_all_start = (LinkedPoint *)pt.val[0];
	int pt_all_no = pt.val[1];
	LinkedPoint *pt_ori_start = (LinkedPoint *)pt.val[2];
	int pt_ori_no = pt.val[3];

	int p = feat_in.val[0];

	// proprocess
	imfeat_util_preproc_label_pixels(&pt);
	
	// calc perimeter
	LinkedPoint *cur = pt_all_start;
	for (int i=0; i<pt_all_no; i++, cur=cur->next) {
		if PXL_IS_NEW(cur->val) {
			// process each new added pixels here
			// (1) calc num of adjacent edge q with accumulated map
			int q = 0;
			if (cur->l)
				if PXL_IS_ACU(cur->l->val)
					q = q + 1;
			if (cur->t)
				if PXL_IS_ACU(cur->t->val)
					q = q + 1;
			if (cur->r)
				if PXL_IS_ACU(cur->r->val)
					q = q + 1;
			if (cur->b)
				if PXL_IS_ACU(cur->b->val)
					q = q + 1;
			// (2) calc edge no change: 4 - 2{q:qAp^C(q)<=C(p)}
			p = p + (4 - 2*q);
			// (3) set cur pt as 1
			PXL_GO_ACU(cur->val);
		}
	}

	feat_out->val[0] = p;
}
