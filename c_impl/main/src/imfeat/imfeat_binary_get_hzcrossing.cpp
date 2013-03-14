
#include "../../include/system.h"
#include "../../include/imfeat.h"
#include "imfeat_internal.h"
#include <stdio.h>
#include <stdlib.h>

void get_HzCrossing(IN p7_t pt, IN p1_t feat_in, OUT p1_t *feat_out)
{
	LinkedPoint *pt_all_start = (LinkedPoint *)pt.val[0];
	int pt_all_no = pt.val[1];
	LinkedPoint *pt_ori_start = (LinkedPoint *)pt.val[2];
	int pt_ori_no = pt.val[3];
	LinkedPoint *pts = (LinkedPoint *)pt.val[4];
	int img_rows = pt.val[5];
	int img_cols = pt.val[6];
	int *feat_i = (int *)feat_in.val[0];
	int *feat_o = (int *)feat_out->val[0];

	// proprocess
	imfeat_util_preproc_label_pixels(&pt);
	
	// calc hohrizontal crossing
	LinkedPoint *row_1st_pt = pts;
	for (int h=0; h<img_rows; h++, row_1st_pt=row_1st_pt->b) {
		LinkedPoint *cur = row_1st_pt;
		if (!ROW_HAS_NEW(cur)) {
			continue;
		}
		int q = 0;
		while (!PXL_IS_IMG_EDG(cur->val)) {
			if PXL_IS_NEW(cur->val) {
				if (!PXL_IS_ACU(cur->l->val) && !PXL_IS_ACU(cur->r->val))
					q = q + 2;
				if (PXL_IS_ACU(cur->l->val) && PXL_IS_ACU(cur->r->val))
					q = q - 2;
				PXL_GO_ACU(cur->val);
			}
			cur = cur->r;
		}
		*feat_o = *feat_i + q;
		feat_i++; 
		feat_o++;
	}
}
