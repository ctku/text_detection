
#include "../../include/system.h"
#include "../../include/imfeat.h"
#include <stdio.h>
#include <stdlib.h>

void get_BoundingBox(IN p4_t pt, IN p4_t feat_in, OUT p4_t *feat_out)
{
	LinkedPoint *pt_all_start = (LinkedPoint *)pt.val[0];
	int pt_all_no = pt.val[1];
	LinkedPoint *pt_inv_start = (LinkedPoint *)pt.val[2];
	int pt_inv_no = pt.val[3];
	int l = feat_in.val[0];
	int t = feat_in.val[1];
	int r = feat_in.val[2];
	int b = feat_in.val[3];
	LinkedPoint* cur = pt_all_start;
	if (l<0 || t<0 || r<0 || b<0) {
		l = r = cur->pt.x;
		t = b = cur->pt.y;
	}
	int invalid = 0, k = 0;
	for (int i=0; i<pt_all_no; i++, cur=cur->next) {
		if (cur==pt_inv_start) invalid = 1;
		if (invalid==0) {
			l = MIN(l, cur->pt.x);
			t = MIN(t, cur->pt.y);
			r = MAX(r, cur->pt.x);
			b = MAX(b, cur->pt.y);
		}
		if (invalid==1) k++;
		if (k==pt_inv_no) invalid = 0;
	}
	feat_out->val[0] = l;
	feat_out->val[1] = t;
	feat_out->val[2] = r;
	feat_out->val[3] = b;
}
