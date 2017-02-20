# See LICENSE for license details.

#*****************************************************************************
# store.S
#-----------------------------------------------------------------------------
#
# Test tagged store.
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

        la   x10, tdat          ;
        
        li   x1, TMASK_LOAD_PROP ;
        csrw tagctrl, x1        ;
        li   x1, TMASK_STORE_PROP ;
        csrs tagctrl, x1        ;

# lb, lw, lh has no different in set tag
        TEST_CASE( 2, x5, 1,     \
        li   x1, 1              ;\
        tagw x1, x1             ;\
        sb   x1, 0(x10)         ;\
        nop                     ;\
        ld   x5, 0(x10)         ;\
        tagr x5, x5             ;\
        )

        TEST_CASE( 3, x5, 2,     \
        li   x1, 2              ;\
        tagw x1, x1             ;\
        sh   x1, 0(x10)         ;\
        nop                     ;\
        ld   x5, 0(x10)         ;\
        tagr x5, x5             ;\
        )

        TEST_CASE( 4, x5, 3,     \
        li   x1, 3              ;\
        tagw x1, x1             ;\
        sw   x1, 0(x10)         ;\
        nop                     ;\
        ld   x5, 0(x10)         ;\
        tagr x5, x5             ;\
        )

        TEST_CASE( 5, x5, 4,     \
        li   x1, 4              ;\
        tagw x1, x1             ;\
        sd   x1, 0(x10)         ;\
        nop                     ;\
        ld   x5, 0(x10)         ;\
        tagr x5, x5             ;\
        )

  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

tdat:  .dword 0x0000ffff0f0f0f0f

RVTEST_DATA_END
