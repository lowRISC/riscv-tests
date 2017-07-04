# See LICENSE for license details.

#*****************************************************************************
# tagctrl-prvcheck.S
#-----------------------------------------------------------------------------
#
# Basic test of utagctrl/stagctrl
#

#define __TAG_MODE
#include "riscv_test.h"
#include "test_macros.h"

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

  # enable delegation and change into user mode
  li t0, SSTATUS_SPP
  csrc sstatus, t0
  la t0, test_start
  csrw sepc, t0
  sret


test_start:
  #---------------------------------------------------------------#      
  # Basic checks to make sure the tagctrl registers are unaliased #
  #---------------------------------------------------------------# 
  # Check that writing to utagctrl actually writes to utagctrl
  li   TESTNUM, 2
  li   x4, TMASK_ALU_CHECK
  csrw utagctrl, x4
  csrr x2, utagctrl
  bne  x2, x4, fail

  # check that stagctrl is unchanged by writing to utagctrl
  li   TESTNUM, 3
  ecall
  nop

  # check that mtagctrl is unchanged by writing to utagctrl
  li   TESTNUM, 4
  ecall
  nop

  # Check that writing to stagctrl actually writes to stagctrl        
  li   TESTNUM, 5
  ecall
  nop

  # check that utagctrl is unchanged
  li   TESTNUM, 6
  csrr x2, utagctrl
  li   x4, TMASK_ALU_CHECK
  bne  x2, x4, fail

  # check that mtagctrl is unchanged
  li   TESTNUM, 7
  ecall
  nop
 
  # Check that writing to mtagctrl actually writes to mtagctrl
  li   TESTNUM, 8
  ecall
  nop

  # Check that utagctrl is unchanged
  li   TESTNUM, 9
  csrr x2, utagctrl
  li   x4, TMASK_ALU_CHECK
  bne  x2, x4, fail

  # Check that stagctrl is unchanged
  li   TESTNUM, 10
  ecall
  nop

  #---------------------------------------------------------------#              
  # Test that tagctrl registers can only be written to with the   #
  # appropriate privelege level                                   # 
  #---------------------------------------------------------------#
        
  # Test that user mode can't write to stagctrl
  li   TESTNUM, 11
  csrw stagctrl, zero
  li   x10, 0
  beq  x10, x0, fail      
  
  # Test that user mode can't write to mtagctrl
  li   TESTNUM, 12
  csrw mtagctrl, zero
  li   x10, 0
  beq  x10, x0, fail      
 

  # Test that supervisor mode can't write to mtagctrl
  li   TESTNUM, 13
  ecall
  nop

  #---------------------------------------------------------------#
  # Simple test to check that each privelege level uses the       #
  # appropriate registers                                         #
  #---------------------------------------------------------------#
  # utagctrl should be TMASK_ALU_CHECK
  li   TESTNUM, 14
  li   x2, 1
  li   x1, 5
  tagw x1, x2
  add  x3, x1, x2
  li   x10, 0
  beq  x10, x0, fail

  li   TESTNUM, 15
  ecall
  nop

  li   TESTNUM, 16
  ecall
  nop
    
  TEST_PASSFAIL

# Trap handler: if the exception was a tag exception that was expected for
# this test number, then jump over the next instruction
stvec_handler:
  csrr x17, scause
  li   x16, CAUSE_USER_ECALL
  bne  x16, x17, 1f

  li   x16, 3      
  beq  TESTNUM, x16, stest_3

  li   x16, 4
  beq  TESTNUM, x16, cause_exception

  li   x16, 5
  beq  TESTNUM, x16, stest_5

  li   x16, 7
  beq  TESTNUM, x16, cause_exception

  li   x16, 8
  beq  TESTNUM, x16, cause_exception

  li   x16, 10
  beq  TESTNUM, x16, stest_10

  li   x16, 13
  beq  TESTNUM, x16, stest_13

  li   x16, 15
  beq  TESTNUM, x16, stest_15

  li   x16, 16
  beq  TESTNUM, x16, cause_exception
        
  j    pass
1:
  li   x16, CAUSE_TAG_CHECK_FAIL
  bne  x16, x17, fail

  li   x16, 14
  beq  TESTNUM, x16, sdone

  j    fail

stest_3:
  # verify that stagctrl is unchanged
  add  x10, x0, x0
  j    check_stagctrl

stest_4:
  j    cause_exception
        
stest_5:
  # change stagctrl
  li   x10, TMASK_ALU_PROP
  csrw stagctrl, x10
  # verify stagctrl changed
  j    check_stagctrl

stest_10:
  li   x10, TMASK_ALU_PROP
  j    check_stagctrl

stest_13:      
  csrw mtagctrl, zero
  li   x10, 0
  beq  x10, x0, fail      
  j    sdone

stest_15:       
  # stagctrl should be TMASK_ALU_PROP
  add  x3, x1, x2
  tagr x4, x3
  li   x5, 1
  bne  x4, x5, fail
  j    sdone

cause_exception:
  # try to write to mcause to cause an exception to jump to
  # machine mode
  csrw mcause, zero
  nop
  j    sdone

check_stagctrl:
  csrr x4, stagctrl
  bne  x10, x4, fail
  j    sdone

sdone:
  csrr x16, sepc
  addi x16, x16, 8
  csrw sepc, x16
  sret

        
mtvec_handler:
  # restore mtagctrl from before we entered trap vector
  EXIT_TAG_MACHINE
  li   x16, 4
  beq  TESTNUM, x16, mtest_4

  li   x16, 7
  beq  TESTNUM, x16, mtest_7

  li   x16, 8
  beq  TESTNUM, x16, mtest_8

  li   x16, 11
  beq  TESTNUM, x16, mtest_11

  li   x16, 12
  beq  TESTNUM, x16, mtest_12

  li   x16, 13
  beq  TESTNUM, x16, mtest_13

  li   x16, 16
  beq  TESTNUM, x16, mtest_16
        
  # otherwise, we shouldn't be here
  j    fail

mtest_4:
  add  x10, x0, x0
  j    check_mtagctrl        

mtest_7:
  add  x10, x0, x0
  j    check_mtagctrl

mtest_8:
  li   x10, TMASK_STORE_PROP
  li   x11, TMASK_LOAD_PROP
  or   x10, x10, x11
  csrw mtagctrl, x10
  j    check_mtagctrl

mtest_11:
  li   x4, TMASK_ALU_PROP
  csrr x2, stagctrl
  bne  x4, x2, fail
  j    mdone

mtest_12:
  li   x10, TMASK_STORE_PROP
  li   x11, TMASK_LOAD_PROP
  or   x10, x10, x11
  j    check_mtagctrl

mtest_13:
  li   x10, TMASK_STORE_PROP
  li   x11, TMASK_LOAD_PROP
  or   x10, x10, x11
  j    check_mtagctrl
        
mtest_16:
  # mtagctrl should be TMASK_STORE_PROP | TMASK_LOAD_PROP
  la    x4, tdat
  li    x2, 1
  li    x3, 5
  tagw  x3, x2
  sd    x3, 0(x4)
  ld    x5, 0(x4)
  tagr  x5, x5
  bne   x5, x2, fail
  j     mdone

check_mtagctrl: 
  csrr  x4, mtagctrl
  bne   x4, x10, fail
  j     mdone
        
mdone:
  csrr x16, mepc
  addi x16, x16, 8
  csrw mepc, x16
  mret

RVTEST_CODE_END

.align 6
.data
RVTEST_DATA_BEGIN

  TEST_DATA
  tdat:  .dword 0x0000ffff0f0f0f0f

RVTEST_DATA_END
