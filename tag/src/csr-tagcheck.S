# See LICENSE for license details.

#*****************************************************************************
# csr-tagcheck.S
#-----------------------------------------------------------------------------
#
# Tests that tags propagate properly when values are read from/written to
# CSRs with tags        
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
  # setup for test
  # x2: has value (8) to store with tag (1)
  # x3: has tag value (1)         
  li x2, 8
  li x3, 1
  tagw x2, x3
  # jump right away to supervisor mode to check supervisor CSRs
  li TESTNUM, 2
  ecall

  TEST_PASSFAIL

#define TEST_CSR(csr) \
  /* test w instruction and save csr */ \
  csrrw x10, csr, x2   ;\
  li     x5, 0         ;\
  tagw   x5, x0        ;\
  csrrw x5, csr, x0    ;\
  bne   x5, x2, fail   ;\
  tagr  x5, x5         ;\
  bne   x5, x3, fail   ;\
  /* test s instruction and clear tag on x5 */ \
  csrrs x5, csr, x2    ;\
  bne   x5, x0, fail   ;\
  tagr  x5, x5         ;\
  bne   x5, x0, fail   ;\
  csrrw x5, csr, x0    ;\
  bne   x5, x2, fail   ;\
  tagr  x5, x5         ;\
  bne   x5, x3, fail   ;\
  /* write value to test c instruction */ \
  tagw  x5, x0         ;\
  li    x5, 8          ;\
  csrrw x7, csr, x5    ;\
  /* test c instruction */ \
  csrrc x6, csr, x2    ;\
  bne   x6, x5, fail   ;\
  tagr  x6, x6         ;\
  bne   x6, x0, fail   ;\
  csrrw x5, csr, x0    ;\
  bne   x5, x0, fail   ;\
  tagr  x5, x5         ;\
  bne   x5, x3, fail   ;\
  /* tag csr to make sure immediate instructions */ \
  /* preserve tags. clear x5 */ \
  csrrw  x5, csr, x2   ;\
  /* test wi instruction */ \
  csrrwi x5, csr, 12   ;\
  bne    x5, x2, fail  ;\
  tagr   x5, x5        ;\
  bne    x5, x3, fail  ;\
  li     x5, 0         ;\
  csrrw  x5, csr, x2   ;\
  li     x6, 12        ;\
  bne    x5, x6, fail  ;\
  tagr   x5, x5        ;\
  bne    x5, x0, fail  ;\
  /* test si instruction */ \
  li     x5, 0         ;\
  tagw   x5, x0        ;\
  csrrsi x5, csr, 12   ;\
  bne    x5, x2, fail  ;\
  tagr   x5, x5        ;\
  bne    x5, x3, fail  ;\
  li     x5, 0         ;\
  csrrw  x5, csr, x2   ;\
  li     x6, 12        ;\
  bne    x5, x6, fail  ;\
  tagr   x5, x5        ;\
  bne    x5, x0, fail  ;\
  /* test ci instruction */ \
  li     x5, 0         ;\
  tagw   x5, x0        ;\
  csrrci x5, csr, 8    ;\
  bne    x5, x2, fail  ;\
  tagr   x5, x5        ;\
  bne    x5, x3, fail  ;\
  tagw   x5, x0        ;\
  /* restore csr value and read csr */ \
  csrrw x5, csr, x10   ;\
  bne   x5, x0, fail   ;\
  tagr  x5, x5         ;\
  bne   x5, x0, fail   ;

        
        
stvec_handler:
  csrr x17, scause
  li   x16, CAUSE_USER_ECALL
  bne  x16, x17, fail

  li x16, 2
  bne TESTNUM, x16, pass
  csrw stagctrl, zero
  TEST_CSR(sepc);
  li TESTNUM, 3
  TEST_CSR(sscratch);
  li TESTNUM, 4
  TEST_CSR(stvec);
  li TESTNUM, 5
  TEST_CSR(stagctrl_scratch);

  li TESTNUM, 6        
  csrw mcause, zero

  # Turn on check flags and try again.
  # This should raise no exceptions
  li x7, TMASK_STORE_CHECK
  li x6, TMASK_LOAD_CHECK
  or x7, x7, x6
  li x6, TMASK_ALU_CHECK
  or x7, x7, x6
  csrw stagctrl, x7

  li TESTNUM, 10
  TEST_CSR(sepc);
  li TESTNUM, 11
  TEST_CSR(sscratch);
  li TESTNUM, 12
  TEST_CSR(stvec);
  li TESTNUM, 13
  TEST_CSR(stagctrl_scratch);

  # clear stagctrl, so we don't raise accidental exceptions
  csrw stagctrl, zero

  li   TESTNUM, 14
  csrw mcause, zero

sdone:
  csrr x16, sepc
  addi x16, x16, 4
  csrw sepc, x16
  sret
  
mtvec_handler:  
  csrw mtagctrl, zero
  csrr x17, mcause
  li   x16, CAUSE_ILLEGAL_INSTRUCTION
  bne  x17, x16, fail
   
  li x16, 6
  beq TESTNUM, x16, test_no_tagctrl

  li x16, 14
  beq TESTNUM, x16, test_with_tagctrl

  # otherwise, we shouldn't be here        
  j fail

test_no_tagctrl:
  TEST_CSR(mepc);
  li TESTNUM, 7
  TEST_CSR(mscratch);
  li TESTNUM, 8
  TEST_CSR(mtvec);
  li TESTNUM, 9
  TEST_CSR(mtagctrl_scratch);
  j mdone

test_with_tagctrl:     
  # Turn on check flags and try again.
  # This should raise no exceptions
  li x7, TMASK_STORE_CHECK
  li x6, TMASK_LOAD_CHECK
  or x7, x7, x6
  li x6, TMASK_ALU_CHECK
  or x7, x7, x6
  csrw stagctrl, x7

  li TESTNUM, 10
  TEST_CSR(mepc);
  li TESTNUM, 11
  TEST_CSR(mscratch);
  li TESTNUM, 12
  TEST_CSR(mtvec);
  li TESTNUM, 13
  TEST_CSR(mtagctrl_scratch);

  # zero mtagctrl so we dont accidentally cause exceptions
  csrw mtagctrl, zero
  j    mdone

        
mdone:
  csrr x16, mepc
  addi x16, x16, 4
  csrw mepc, x16
  mret

RVTEST_CODE_END

.align 6
.data
RVTEST_DATA_BEGIN

  TEST_DATA
  tdat:  .dword 0x0000ffff0f0f0f0f

RVTEST_DATA_END
