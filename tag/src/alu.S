# See LICENSE for license details.

#*****************************************************************************
# alu.S
#-----------------------------------------------------------------------------
#
# Test alu tag propagation.
#

#include "riscv_test.h"
#include "test_macros.h"
#include "tag_macro.h"

RVTEST_RV64U
RVTEST_CODE_BEGIN

# disable tag control CSR
        csrw tagctrl, x0        ;

# x0 should have a zero tag
        TEST_CASE( 2, x5, 0,     \
        tagr x5, x0             ;\
        )

# x1 should have a zero initial tag
        TEST_CASE( 3, x5, 0,     \
        tagr x5, x1             ;\
        )

# enable alu propagation with 0x1
        li   x1, 0x1            ;
        slli x1, x1, TSHIM_ALU  ;
        csrw tagctrl, x1        ;

# propagate zero tag
        TEST_CASE( 4, x5, 0,     \
        add  x1, x0, x1         ;\
        tagr x5, x1             ;\
        )

# propagate 0x1 tag
        TEST_CASE( 5, x5, 0x1,   \
        tagw x1, x1             ;\
        add  x1, x0, x1         ;\
        tagr x5, x1             ;\
        )

# enable alu propagation with 0x2
        li   x2, 0x2            ;
        slli x2, x2, TSHIM_ALU  ;
        csrw tagctrl, x2        ;

# propagate 0x2 tag
        TEST_CASE( 6, x5, 0x2,   \
        tagw x2, x2             ;\
        add  x2, x1, x2         ;\
        tagr x5, x2             ;\
        )

# enable alu progagation with 0x3
        li   x3, 0x3            ;
        slli x3, x3, TSHIM_ALU  ;
        csrw tagctrl, x3        ;

# propagate 0x3 tag
        TEST_CASE( 7, x5, 0x3,   \
        and x3, x1, x2          ;\
        tagr x5, x3             ;\
        )

# immediate instruction
        TEST_CASE( 8, x5, 0x3,   \
        andi x3, x3, 0x0        ;\
        tagr x5, x3             ;\
        )

# mov instruction
        TEST_CASE( 9, x5, 0x3,   \
        addi x4, x3, 0          ;\
        tagr x5, x4             ;\
        )

# alu's impact on tagr
        csrw tagctrl, x0        ;
        TEST_CASE(10, x5, 0x3,   \
        tagr x5, x4             ;\
        )

# alu's impact on tagw
        TEST_CASE(11, x5, 0xf,   \
        li   x2, 0xf            ;\
        tagw x4, x2             ;\
        tagr x5, x4             ;\
        )

# clear tag
        TEST_CASE(12, x5, 0x0,   \
        addi x3, x4, 0          ;\
        tagr x5, x3             ;\
        )

  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END

