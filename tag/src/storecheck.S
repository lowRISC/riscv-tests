# See LICENSE for license details.

#*****************************************************************************
# storecheck.S
#-----------------------------------------------------------------------------
#
# Test exceptions when storing to locations with certain tag values.
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
  slli x1, x1, TSHIM_STORE_CHECK
  csrs tagctrl, x1

  # Stores should be unaffected when the destination address has no tags
  li   TESTNUM, 2
  sd   x0, 0(x10)

  # The store check should be performed based on the tag of the target memory
  # location rather than the tag of the data being written
  li   TESTNUM, 3
  li   x5, 0xf
  tagw x5, x5
  sd   x5, 0(x10)

  # Attempts to store to tdat should now trigger an exception
  # NOTE: fences will become unnecessary once the hardware generates precise
  # tag exceptions
  li   TESTNUM, 4
  sd   x0, 0(x10)
  fence.i
  j    fail

  li   TESTNUM, 5
  sw   x0, 0(x10)
  fence.i
  j    fail

  li   TESTNUM, 6
  sh   x0, 0(x10)
  fence.i
  j    fail

  li   TESTNUM, 7
  sb   x0, 0(x10)
  fence.i
  j    fail

  # The failed attempts to write to the tagged location should not have changed
  # the memory contents
  li   TESTNUM, 8
  ld   x5, 0(x10)
  li   x29, 0xf
  bne  x5, x29, fail

  # Storing to a location with a tag that doesn't match the 'storecheck' mask
  # shouldn't cause an exception
  li   TESTNUM, 9
  la   x10, tdat2
  li   x5, 0x6
  tagw x5, x5
  sd   x5, 0(x10)
  li   x5, 0xf
  tagw x5, x5
  sd   x5, 0(x10)


  TEST_PASSFAIL

# Trap handler: if the excpetion was a tag exception that was expected for
# this test number, then jump over the next instruction
mtvec_handler:
  li   x16, 4
  beq  TESTNUM, x16, expected_tag_xcpt
  li   x16, 5
  beq  TESTNUM, x16, expected_tag_xcpt
  li   x16, 6
  beq  TESTNUM, x16, expected_tag_xcpt
  li   x16, 7
  beq  TESTNUM, x16, expected_tag_xcpt
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

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

  tdat:  .dword 0x0000ffff0f0f0f0f
  tdat2: .dword 0x0000ffff0f0f0f0f

RVTEST_DATA_END
