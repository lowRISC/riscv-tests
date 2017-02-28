# See LICENSE for license details.

#*****************************************************************************
# loadcheck.S
#-----------------------------------------------------------------------------
#
# Test tagged related load tag check.
#

#include "tag_macro.h"
#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64U
RVTEST_CODE_BEGIN




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
