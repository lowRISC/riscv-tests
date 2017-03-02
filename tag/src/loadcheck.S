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

  # Test setup
  la   x10, tdat
  li   x1, TMASK_LOAD_PROP
  csrw tagctrl, x1
  li   x1, TMASK_STORE_PROP
  csrs tagctrl, x1
  li   x1, 0x9
  slli x1, x1, TSHIM_LOAD_CHECK
  csrs tagctrl, x1

  # Loads should be unaffected when the destination address has no tags
  li   TESTNUM, 2
  ld   x0, 0(x10)

  # The load check should be performed based on the tag of the target memory
  # location rather than the tag of register used for the address
  li   TESTNUM, 3
  addi x5, x10, 0
  li   x6, 0xf
  tagw x5, x6
  ld   x5, 0(x5)

  # Loading from a location with a tag that doesn't match the 'loadcheck' mask
  # shouldn't cause an exception
  li   TESTNUM, 8
  la   x10, tdat2
  li   x5, 0x6
  tagw x5, x5
  sd   x5, 0(x10)
  ld   x5, 0(x10)

  # All tests from this point on (other than test 8) are expected to trigger a tag exception

  # Attempts to load from a tagged tdat should trigger an exception
  li   TESTNUM, 4
  li   x5, 0xf00d
  li   x6, 0x9
  tagw x5, x6
  sd   x5, 0(x10)
  tagw x5, x0
  li   x5, 0xd00d
  ld   x5, 0(x10)
  fence
  j    fail

  li   TESTNUM, 5
  lw   x5, 0(x10)
  fence
  j    fail

  li   TESTNUM, 6
  lh   x5, 0(x10)
  fence
  j    fail

  li   TESTNUM, 7
  lb   x5, 0(x10)
  fence
  j    fail

  # Loads that failed the tag check should leave x5 unmodified
  li   TESTNUM, 8
  li   x6, 0xd00d
  bne  x5, x6, fail

  # Exceptions should be triggered regardless of whether load propagation is
  # enabled
  li   x1, TMASK_LOAD_PROP
  csrc tagctrl, x1

  li   TESTNUM, 9
  lw   x0, 0(x10)
  fence
  j    fail

  li   TESTNUM, 10
  lw   x0, 0(x10)
  fence
  j    fail

  li   TESTNUM, 11
  lh   x0, 0(x10)
  fence
  j    fail

  li   TESTNUM, 12
  lb   x0, 0(x10)
  fence
  j    fail


  TEST_PASSFAIL

# Trap handler: if the excpetion was a tag exception that was expected for
# this test number, then jump over the next instruction
mtvec_handler:
  li   x16, 8
  beq  TESTNUM, x16, fail
  li   x16, 4
  bge  TESTNUM, x16, expected_tag_xcpt
  j    fail

expected_tag_xcpt:
  li   x16, CAUSE_TAG_CHECK_FAIL
  csrr x17, mcause
  bne  x16, x17, fail
  csrr x16, mepc
  addi x16, x16, 12
  csrw mepc, x16
  EXIT_TAG_MACHINE
  mret

RVTEST_CODE_END

.align 6
.data
RVTEST_DATA_BEGIN

  TEST_DATA

tdat:   .dword 0x0000ffff0f0f0f0f
tdat2:  .dword 0x000ffff0f0f0f0f1


RVTEST_DATA_END
