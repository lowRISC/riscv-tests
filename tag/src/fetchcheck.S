# See LICENSE for license details.

#*****************************************************************************
# fetchcheck.S
#-----------------------------------------------------------------------------
#
# Test exceptions when executing an instruction matching the fetchcheck mask
#

#include "tag_macro.h"
#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64U
RVTEST_CODE_BEGIN

  # Test setup
  li   x1, TMASK_STORE_PROP
  csrw tagctrl, x1

  # Apply tags to the appropriate point in each test
  la   x5, t2_0b11
  li   x4, 0x3
  lw   x6, 0(x5)
  tagw x6, x4
  sw   x6, 0(x5)

  la   x5, t3_0b10
  li   x4, 0x2
  lw   x6, 0(x5)
  tagw x6, x4
  sw   x6, 0(x5)

  la   x5, t4_0b0100
  li   x4, 0x4
  lw   x6, 0(x5)
  tagw x6, x4
  sw   x6, 0(x5)

  la   x5, t5_0b01
  li   x4, 0x1
  lw   x6, 0(x5)
  tagw x6, x4
  sw   x6, 0(x5)

  li   x10, 0xf00

  # An exception should take place immediately if the mask matches, and the
  # tagged instruction should not be executed
  li   TESTNUM, 2
  li   x1, 0x1
  slli x1, x1, TSHIM_FETCH_CHECK
  csrw tagctrl, x1
.align 8
t2_0b11:
  li   x10, 0x0
  j    fail
  beq  x10, x0, fail

  li   TESTNUM, 3
  li   x1, 0x2
  slli x1, x1, TSHIM_FETCH_CHECK
  csrw tagctrl, x1
.align 8
t3_0b10:
  li   x10, 0x0
  j    fail
  beq  x10, x0, fail

  # The 4-bit tag should be split across the two instruction in a 64-bit word
  li   TESTNUM, 4
  li   x1, 0x1
  slli x1, x1, TSHIM_FETCH_CHECK
  csrw tagctrl, x1
.align 8
t4_0b0100:
  nop
  li   x10, 0x0
  j    fail
  beq  x10, x0, fail

  # No exception should take place if the mask doesn't match
  li   TESTNUM, 5
  li   x1, 0x2
  slli x1, x1, TSHIM_FETCH_CHECK
  csrw tagctrl, x1
.align 8
t5_0b01:


  TEST_PASSFAIL

# Trap handler: if the excpetion was a tag exception that was expected for
# this test number, then jump over the next two instructions
mtvec_handler:
  li   x16, 5
  beq  TESTNUM, x16, fail
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
.align 6
         .dword 0x0000000000000000
.align 6
         .dword 0x0000000000000000
  tdat2: .dword 0x0000ffff0f0f0f0f

RVTEST_DATA_END
