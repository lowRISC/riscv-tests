# See LICENSE for license details.

#*****************************************************************************
# store.S
#-----------------------------------------------------------------------------
#
# Test tagged store.
#

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

        la x10, tdat            ;

# get the auto-size tag mask x11 and size x12
        li x11, -1              ;
        tagw x11, x11           ;
        tagr x11, x11           ;
        addi x12, x11, 0        ;
        li   x1, 0              ;
1:      addi x1, x1, 1          ;
        srli x12, x12, 1        ;
        bne  x12, x0, 1b        ;
        addi x12, x1, 0         ;
        
# enable load/store tag propagation
        slli x1, x12, 1         ;
        sll  x1, x11, x1        ;
        csrw tagctrl, x1        ;
        slli x1, x12, 2         ;
        sll  x1, x11, x1        ;
        csrs tagctrl, x1        ;

# lb, lw, lh has no different in set tag
        TEST_CASE( 2, x5, 1,     \
        li x1, 1                ;\
        tagw x1, x1             ;\
        sb x1, 0(x10)           ;\
        nop                     ;\
        ld x5, 0(x10)           ;\
        tagr x5, x5             ;\
        )

        TEST_CASE( 3, x5, 2,     \
        li x1, 2                ;\
        tagw x1, x1             ;\
        sh x1, 0(x10)           ;\
        nop                     ;\
        ld x5, 0(x10)           ;\
        tagr x5, x5             ;\
        )

        TEST_CASE( 4, x5, 3,     \
        li x1, 3                ;\
        tagw x1, x1             ;\
        sw x1, 0(x10)           ;\
        nop                     ;\
        ld x5, 0(x10)           ;\
        tagr x5, x5             ;\
        )

        TEST_CASE( 5, x5, 4,     \
        li x1, 4                ;\
        tagw x1, x1             ;\
        sd x1, 0(x10)           ;\
        nop                     ;\
        ld x5, 0(x10)           ;\
        tagr x5, x5             ;\
        )

  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

tdat:  .dword 0x0000ffff0f0f0f0f

RVTEST_DATA_END
