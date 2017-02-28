// See LICENSE for license details.

//*****************************************************************************
// tag_macro.h
//-----------------------------------------------------------------------------
//
// macros used to operate the tagctrl CSR.
//


#ifndef TAG_MACRO_H
#define TAG_MACRO_H

#define __TAG_MODE

#define TAG_BITS                4
#define TAG_INST_BITS           2

#define TMASK_ALU               (0x000000000000000f)
#define TMASK_LOAD_CHECK        (0x00000000000000f0)
#define TMASK_LOAD_PROP         (0x0000000000000f00)
#define TMASK_STORE_CHECK       (0x000000000000f000)
#define TMASK_STORE_PROP        (0x00000000000f0000)
#define TMASK_STORE_KEEP        (0x0000000000f00000)
#define TMASK_CFLOW_DIR_TGT     (0x0000000003000000)
#define TMASK_CFLOW_INDIR_TGT   (0x000000000c000000)
#define TMASK_JMP_CHECK         (0x00000000f0000000)
#define TMASK_JMP_PROP          (0x0000000f00000000)
#define TMASK_FETCH_CHECK       (0x0000003000000000)

#define TSHIM_ALU               0
#define TSHIM_LOAD_CHECK        4
#define TSHIM_LOAD_PROP         8
#define TSHIM_STORE_CHECK       12
#define TSHIM_STORE_PROP        16
#define TSHIM_STORE_KEEP        20
#define TSHIM_CFLOW_DIR_TGT     24
#define TSHIM_CFLOW_INDIR_TGT   26
#define TSHIM_JMP_CHECK         28
#define TSHIM_JMP_PROP          32
#define TSHIM_FETCH_CHECK       36

#endif
