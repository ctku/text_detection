
#include "../../include/system.h"
#include "../../include/imfeat.h"
#include "imfeat_internal.h"

void imfeat_util_preproc_label_pixels(p7_t *pt)
{
	LinkedPoint *pt_all_start = (LinkedPoint *)pt->val[0];
	int pt_all_no = pt->val[1];
	LinkedPoint *pt_ori_start = (LinkedPoint *)pt->val[2];
	int pt_ori_no = pt->val[3];

	// prerocess: label pixels
	LinkedPoint *cur = pt_all_start;
	int ori = 0, k = 0;
	for (int i=0; i<pt_all_no; i++, cur=cur->next) {
		cur->val = 0; // clear before use
		if (cur==pt_ori_start) ori = 1;

		if (ori==1) {
			cur->val |= PXL_ORI;
			cur->val |= PXL_ACU;
			ROW_SEE_ORI(cur);
		}							   
		if (ori==0) {
			cur->val |= PXL_NEW;
			ROW_SEE_NEW(cur);
		}

		if (ori==1) k++;
		if (k==pt_ori_no) ori = 0;
	}
}