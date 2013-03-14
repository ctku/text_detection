
#include "../../include/system.h"
#include "../../include/imfeat.h"
#include "imfeat_internal.h"
#include <stdio.h>
#include <stdlib.h>

void get_EulerNo(IN p7_t pt, IN p1_t feat_in, OUT p1_t *feat_out)
{
	LinkedPoint *pt_all_start = (LinkedPoint *)pt.val[0];
	int pt_all_no = pt.val[1];
	LinkedPoint *pt_inv_start = (LinkedPoint *)pt.val[2];
	int pt_inv_no = pt.val[3];

	int u = feat_in.val[0];

	// proprocess
	imfeat_util_preproc_label_pixels(&pt);

	// calc euler no
	LinkedPoint *cur = pt_all_start;
	for (int i=0; i<pt_all_no; i++, cur=cur->next) {
		if PXL_IS_NEW(cur->val) {
			// (1) add each new pixel into com for later used in step 2
			PXL_GO_ACU(cur->val);
			// (2) match 3 kinds of 2x2 quads (Q1,Q3,Qd) with com(newly-combined) 
			//     and cum(previously-accumulated) seperately centered at p(h,w).
			//     So subindex y goes from -1 to 0, x from -1 to 0.
			//     if mached with com: score q plus 1.
			//     if mached with cum: score q minus 1.
			int q1 = 0, q3 = 0, qd = 0;
			int acu_lt = PXL_IS_ACU(cur->l->t->val), acu_ct = PXL_IS_ACU(cur->t->val), acu_rt = PXL_IS_ACU(cur->r->t->val);
			int acu_lc = PXL_IS_ACU(cur->l->val),    acu_cc = PXL_IS_ACU(cur->val),    acu_rc = PXL_IS_ACU(cur->r->val);
			int acu_lb = PXL_IS_ACU(cur->l->b->val), acu_cb = PXL_IS_ACU(cur->b->val), acu_rb = PXL_IS_ACU(cur->r->b->val);
			int acu_sum_lt_block = (acu_lt + acu_lc + acu_ct + acu_cc);
			int acu_sum_rt_block = (acu_rt + acu_rc + acu_ct + acu_cc);
			int acu_sum_lb_block = (acu_lb + acu_lc + acu_cb + acu_cc);
			int acu_sum_rb_block = (acu_rb + acu_rc + acu_cb + acu_cc);
			int ori_lt = PXL_IS_ORI(cur->l->t->val), ori_ct = PXL_IS_ORI(cur->t->val), ori_rt = PXL_IS_ORI(cur->r->t->val);
			int ori_lc = PXL_IS_ORI(cur->l->val),    ori_cc = PXL_IS_ORI(cur->val),    ori_rc = PXL_IS_ORI(cur->r->val);
			int ori_lb = PXL_IS_ORI(cur->l->b->val), ori_cb = PXL_IS_ORI(cur->b->val), ori_rb = PXL_IS_ORI(cur->r->b->val);
			int ori_sum_lt_block = (ori_lt + ori_lc + ori_ct + ori_cc);
			int ori_sum_rt_block = (ori_rt + ori_rc + ori_ct + ori_cc);
			int ori_sum_lb_block = (ori_lb + ori_lc + ori_cb + ori_cc);
			int ori_sum_rb_block = (ori_rb + ori_rc + ori_cb + ori_cc);
			q1 =  (acu_sum_lt_block==1) + (acu_sum_rt_block==1) + (acu_sum_lb_block==1) + (acu_sum_rb_block==1)
				- (ori_sum_lt_block==1) - (ori_sum_rt_block==1) - (ori_sum_lb_block==1) - (ori_sum_rb_block==1);
			q3 =  (acu_sum_lt_block==3) + (acu_sum_rt_block==3) + (acu_sum_lb_block==3) + (acu_sum_rb_block==3)
				- (ori_sum_lt_block==3) - (ori_sum_rt_block==3) - (ori_sum_lb_block==3) - (ori_sum_rb_block==3);
			qd =  ((acu_sum_lt_block==2) && (acu_lt!=acu_ct)) + ((acu_sum_rt_block==2) && (acu_rt!=acu_ct))
				+ ((acu_sum_lb_block==2) && (acu_lb!=acu_cb)) + ((acu_sum_rb_block==2) && (acu_rb!=acu_cb))
				- ((ori_sum_lt_block==2) && (ori_lt!=ori_ct)) - ((ori_sum_rt_block==2) && (ori_rt!=ori_ct))
				- ((ori_sum_lb_block==2) && (ori_lb!=ori_cb)) - ((ori_sum_rb_block==2) && (ori_rb!=ori_cb));
			// (3) cal Euler no change: psi(p) = 1/4 * (q1 - q3 + 2*qd)
			u = u + (q1 - q3 + 2*qd) / 4;
			// (4) add each new pixel into cum for next loop
			PXL_GO_ORI(cur->val);
		}
	}

	feat_out->val[0] = u;
}

#if 0
int imfeat_eulerno_change_algo(u8 *img_new, u8 *img_cum, int img_rows, int img_cols)
{
	// new_img: newly-added binary map
	// cum_img: accumulated binary map
    
	// calc Euler no difference for each new pixel
	int p = -1;
	int H = img_rows;
	int W = img_cols;
	// enlarge 1 pxl to avoid bondary checking
	u8 *cums = (u8 *)malloc((W+2)*(H+2)*sizeof(u8));
	u8 *news = (u8 *)malloc((W+2)*(H+2)*sizeof(u8));
	u8 *coms = (u8 *)malloc((W+2)*(H+2)*sizeof(u8));
	int *psi = (int *)malloc((W+2)*(H+2)*sizeof(int));
	memset(cums, 0, (W+2)*(H+2)*sizeof(u8));
	memset(news, 0, (W+2)*(H+2)*sizeof(u8));
	for (int y=0; y<H; y++) {
		memcpy(&cums[cor2idx(1,y+1,W+2)], &img_cum[y*W], W*sizeof(u8));
		memcpy(&news[cor2idx(1,y+1,W+2)], &img_new[y*W], W*sizeof(u8));
	}
	memcpy(coms, cums, (W+2)*(H+2));
	for (int h=1; h<H+1; h++) {
		for (int w=1; w<W+1; w++) {
			if (news[cor2idx(w,h,W+2)]==0)
				continue;
			// for each new pixel p
			p = p + 1;
			// (1) add each new pixel into com for later used in step 2
			coms[cor2idx(w,h,W+2)] = 1;
			// (2) match 3 kinds of 2x2 quads (Q1,Q3,Qd) with com(newly-combined) 
			//     and cum(previously-accumulated) seperately centered at p(h,w).
			//     So subindex y goes from -1 to 0, x from -1 to 0.
			//     if mached with com: score q plus 1.
			//     if mached with cum: score q minus 1.
			int q1 = 0, q3 = 0, qd = 0;
			for (int y=-1; y<=0; y++) {
				for (int x=-1; x<=0; x++) {
					int sum_com = coms[cor2idx(w+x,h+y,W+2)] + coms[cor2idx(w+x+1,h+y,W+2)] + coms[cor2idx(w+x,h+y+1,W+2)] + coms[cor2idx(w+x+1,h+y+1,W+2)];
					int sum_cum = cums[cor2idx(w+x,h+y,W+2)] + cums[cor2idx(w+x+1,h+y,W+2)] + cums[cor2idx(w+x,h+y+1,W+2)] + cums[cor2idx(w+x+1,h+y+1,W+2)];
					if (sum_com==1) q1 = q1 + 1;
					if (sum_cum==1) q1 = q1 - 1;
					if (sum_com==3) q3 = q3 + 1;
					if (sum_cum==3) q3 = q3 - 1;
					if ((coms[cor2idx(w+x,h+y,  W+2)]==1 && coms[cor2idx(w+x+1,h+y,  W+2)]==0 && 
						 coms[cor2idx(w+x,h+y+1,W+2)]==0 && coms[cor2idx(w+x+1,h+y+1,W+2)]==1) || 
						(coms[cor2idx(w+x,h+y,  W+2)]==0 && coms[cor2idx(w+x+1,h+y,  W+2)]==1 && 
						 coms[cor2idx(w+x,h+y+1,W+2)]==1 && coms[cor2idx(w+x+1,h+y+1,W+2)]==0))
						qd = qd + 1;
					if ((cums[cor2idx(w+x,h+y,  W+2)]==1 && cums[cor2idx(w+x+1,h+y,  W+2)]==0 &&
						 cums[cor2idx(w+x,h+y+1,W+2)]==0 && cums[cor2idx(w+x+1,h+y+1,W+2)]==1) ||
						(cums[cor2idx(w+x,h+y,  W+2)]==0 && cums[cor2idx(w+x+1,h+y,  W+2)]==1 &&
						 cums[cor2idx(w+x,h+y+1,W+2)]==1 && cums[cor2idx(w+x+1,h+y+1,W+2)]==0))
						qd = qd - 1;
				}
			}
			// (3) cal Euler no change: psi(p) = 1/4 * (q1 - q3 + 2*qd)
			psi[p] = (q1 - q3 + 2*qd) / 4;
			// (4) add each new pixel into cum for next loop
			cums[cor2idx(w, h, W+2)] = 1;
		}
	}

	// update Euler no change
	int phi = 0;
	for (int i=0; i<=p; i++) {
		phi = phi + psi[i];
	}

	//release memory
	free(cums);
	free(news);
	free(coms);
	free(psi);

	return phi;
}
#endif