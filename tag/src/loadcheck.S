# See LICENSE for license details.

#*****************************************************************************
# loadcheck.S
#-----------------------------------------------------------------------------
#
# Test tagged related load tag check.
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
#endif




  TEST_PASSFAIL

RVTEST_CODE_END

.align 6
.data
RVTEST_DATA_BEGIN

  TEST_DATA

tdat0:  .dword 0x0000ffff0f0f0f0f
.align 6
tdat1:  .dword 0x000ffff0f0f0f0f1
.align 6
tdat2:  .dword 0x00ffff0f0f0f0f12
.align 6
tdat3:  .dword 0x0ffff0f0f0f0f123


RVTEST_DATA_END
