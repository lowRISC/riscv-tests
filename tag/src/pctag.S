# See LICENSE for license details.

#*****************************************************************************
# pctag.S
#-----------------------------------------------------------------------------
#
# Test pc tag.
#

#include "riscv_test.h"
#include "test_macros.h"
#include "tag_macro.h"

RVTEST_RV64S
RVTEST_CODE_BEGIN

#ifdef __MACHINE_MODE
  #define sscratch mscratch
  #define sstatus mstatus
  #define scause mcause
  #define sepc mepc
  #define sret mret
  #define stvec_handler mtvec_handler
  #undef SSTATUS_SPP
  #define SSTATUS_SPP MSTATUS_MPP
#endif

# normal branch
        li   TESTNUM, 2         ;
        li   x1, 1              ;
        bne  x1, x0, 1f         ;
        j    fail               ;
1:

# jump to user land to test exception
        li   t0, SSTATUS_SPP
        csrc sstatus, t0
        la   t0, 1f
        csrw sepc, t0
        sret
1:

# branch with pc tag check
        li   TESTNUM, 3         ;
        slli x2, x1, TSHIM_CFLOW_DIR_TGT ;
        csrw tagctrl, x2        ;
        li   x2, TMASK_STORE_PROP ;
        csrs tagctrl, x2        ;
        li   x2, TMASK_LOAD_PROP ;
        csrs tagctrl, x2        ;
        la   x10, 1f            ;
        lw   x9, 0(x10)         ;
        tagw x9, x1             ;
        sw   x9, 0(x10)         ;
        fence.i                 ;
        bne  x1, x0, 1f         ;
        j    fail               ;
.align 6
1:      csrw tagctrl, x0        ;

  TEST_PASSFAIL

stvec_handler:
        li   x15, CAUSE_TAG_CHECK_FAIL
        csrr x16, scause
        beq  x15, x16, fail
        li   x15, CAUSE_USER_ECALL
        bne  x15, x16, fail
1:      RVTEST_PASS

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
