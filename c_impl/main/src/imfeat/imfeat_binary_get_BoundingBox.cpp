
#include "../../include/system.h"
#include "../../include/imfeat.h"
#include <stdio.h>
#include <stdlib.h>

void get_BoundingBox(IN p5_t pt, IN p4_t feat_in, OUT p4_t *feat_out)
{
	int *pt_tbl = (int *)pt.val[0];
	int pt_all_start = pt.val[1];
	int pt_all_no = pt.val[2];
	u32 *pt_mask = (u32 *)pt.val[3];
	int pt_img_cols = pt.val[4];
	int l = feat_in.val[0];
	int t = feat_in.val[1];
	int r = feat_in.val[2];
	int b = feat_in.val[3];
	/*
	if (l<0 || t<0 || r<0 || b<0) {
		l = r = cur->pt.x;
		t = b = cur->pt.y;
	}*/
	u32 *msk_ptr = pt_mask;
	for (int i=0; i<pt_all_no; i++, cur=cur->next) {
		if (i%32==31) msk_ptr++;
		if (!msk_ptr[i%32]) continue;
		x = floor(pt_tbl[i]/pt_img_cols);
		y = floor(pt_
		l = MIN(l, cur->pt.x);
		t = MIN(t, cur->pt.y);
		r = MAX(r, cur->pt.x);
		b = MAX(b, cur->pt.y);
	}
	feat_out->val[0] = l;
	feat_out->val[1] = t;
	feat_out->val[2] = r;
	feat_out->val[3] = b;
}
