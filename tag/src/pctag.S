# See LICENSE for license details.

#*****************************************************************************
# pctag.S
#-----------------------------------------------------------------------------
#
# Test pc tag.
#

#include "tag_macro.h"
#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64U
RVTEST_CODE_BEGIN

# normal branch
        li   TESTNUM, 2         ;
        li   x1, 1              ;
        bne  x1, x0, 1f         ;
        j    fail               ;
1:

# enable direct control flow target
        slli x3, x1, TSHIM_CFLOW_DIR_TGT ;
        li   x2, TMASK_STORE_PROP;
        or   x3, x3, x2         ;
        li   x2, TMASK_LOAD_PROP;
        or   x3, x3, x2         ;
        csrw tagctrl, x3        ;

# branch with pc tag check ok
        li   TESTNUM, 3         ;
        la   x10, 1f            ;
        lw   x9, 0(x10)         ;
        tagw x9, x1             ;
        sw   x9, 0(x10)         ;
        fence.i                 ;
        bne  x1, x0, 1f         ;
        j    fail               ;
.align 6
1:

# branch with pc tag check fail
        li   TESTNUM, 4         ;
        bne  x1, x0, 1f         ;
        j    fail               ;
.align 3
1:

# branch with pc tag check fail


  TEST_PASSFAIL

mtvec_handler:
        li   x16, 4             ;
        bne  TESTNUM, x16, 1f   ;
# test case 4
        li   x16, CAUSE_TAG_CHECK_FAIL ;
        csrr x17, mcause        ;
        bne  x16, x17, fail     ;
        csrr x16, mepc          ;
        tagr x17, x16           ;
        bne  x17, x0, fail      ;
        lw   x17, 0(x16)        ;
        tagw x17, x1            ;
        sw   x17, 0(x16)        ;
        fence.i                 ;
        EXIT_TAG_MACHINE        ;
        mret                    ;
1:      j fail

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
