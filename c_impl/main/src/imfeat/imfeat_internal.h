
#ifndef IMFEAT_INTERNAL_H_
#define IMFEAT_INTERNAL_H_

#define PXL_ORI			0x001
#define PXL_NEW			0x002
#define PXL_ACU			0x004
#define PXL_IMG_EDG		0x010
#define PXL_ERS_EDG		0x020
#define ROW_ORI			0x100
#define ROW_NEW			0x200

#define PXL_IS_ORI(x)		(x&PXL_ORI)
#define PXL_IS_NEW(x)		(x&PXL_NEW)
#define PXL_IS_ACU(x)		(x&PXL_ACU)
#define PXL_IS_IMG_EDG(x)	(x&PXL_IMG_EDG)
#define PXL_IS_ERS_EDG(x)	(x&PXL_ERS_EDG)
#define ROW_HAS_ORI(x)		(x->prev->val&ROW_ORI)
#define ROW_HAS_NEW(x)		(x->prev->val&ROW_NEW)

#define PXL_GO_ORI(x)		(x|=PXL_ORI)
#define PXL_GO_ACU(x)		(x|=PXL_ACU)
#define ROW_SEE_ORI(x)		(x->prev->val|=ROW_ORI)
#define ROW_SEE_NEW(x)		(x->prev->val|=ROW_NEW)

extern void imfeat_util_preproc_label_pixels(p7_t *pt);

#endif