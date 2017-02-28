# See LICENSE for license details.

#*****************************************************************************
# pctag.S
#-----------------------------------------------------------------------------
#
# Test pc tag.
#

#include "tag_macro.h"
#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64U
RVTEST_CODE_BEGIN

# normal branch
        li   TESTNUM, 2         ;
        li   x1, 1              ;
        bne  x1, x0, 1f         ;
        j    fail               ;
1:

# enable direct control flow target
        slli x3, x1, TSHIM_CFLOW_DIR_TGT ;
        li   x2, TMASK_STORE_PROP;
        or   x3, x3, x2         ;
        li   x2, TMASK_LOAD_PROP;
        or   x3, x3, x2         ;
        csrw tagctrl, x3        ;

# branch with pc tag check ok, cache miss
        li   TESTNUM, 3         ;
        la   x10, 1f            ;
        lw   x9, 0(x10)         ;
        tagw x9, x1             ;
        sw   x9, 0(x10)         ;
        fence.i                 ;
        bne  x1, x0, 1f         ;
        j    fail               ;
.align 6
1:

# branch with pc tag check ok, no cache miss
        li   TESTNUM, 4         ;
        la   x10, 1f            ;
        lw   x9, 0(x10)         ;
        tagw x9, x1             ;
        sw   x9, 0(x10)         ;
        fence.i                 ;
.align 6
        bne  x1, x0, 1f         ;
        j    fail               ;
.align 3
1:

# branch with pc tag check fail, cache miss
        li   TESTNUM, 5         ;
        bne  x1, x0, 1f         ;
        j    fail               ;
.align 6
1:      j    fail               ;

# branch with pc tag check fail, no cache miss
        li   TESTNUM, 6         ;
.align 6
        bne  x1, x0, 1f         ;
        j    fail               ;
.align 3
1:      j    fail               ;

# branch with pc tag check ok, force no take_pc
        li   TESTNUM, 7         ;
        la   x10, 1f            ;
        lw   x9, 0(x10)         ;
        tagw x9, x1             ;
        sw   x9, 0(x10)         ;
        li   x2, 16             ;
        fence.i                 ;
# train branch prediction and BTB if any
.align 3
1:      addi x2, x2, -1         ;
        bne  x2, x0, 1b         ;

# branch with not taken, force no take_pc
        li   TESTNUM, 8         ;
        la   x10, 1f            ;
        lw   x9, 0(x10)         ;
        tagw x9, x1             ;
        sw   x9, 0(x10)         ;
        li   x2, 16             ;
        fence.i                 ;
# train branch prediction and BTB if any
.align 3
2:      addi x2, x2, -1         ;
        beq  x2, x0, 1f         ;
        la   x3, 2b             ;
        jalr x0, x3, 0          ;
.align 3
1:

# jump with pc tag check ok
        li   TESTNUM, 9         ;
        la   x10, 1f            ;
        lw   x9, 0(x10)         ;
        tagw x9, x1             ;
        sw   x9, 0(x10)         ;
        fence.i                 ;
        j    1f                 ;
.align 3
1:


# jump with pc tag check fail, cache miss
        li   TESTNUM, 10        ;
.align 6
        j    1f                 ;
.align 3
1:      j    fail               ;

# jump with pc tag check ok, force no take_pc
        li   TESTNUM, 11        ;
        la   x10, 1f            ;
        lw   x9, 0(x10)         ;
        tagw x9, x1             ;
        sw   x9, 0(x10)         ;
        lw   x9, 16(x10)        ;
        tagw x9, x1             ;
        sw   x9, 16(x10)        ;
        li   x2, 16             ;
        fence.i                 ;
.align 3
1:      addi x2, x2, -1         ;
        beq  x2, x0, 1f         ;
        j    1b                 ;
        nop                     ;
1:


  TEST_PASSFAIL

mtvec_handler:
        li   x16, 5             ;
        beq  TESTNUM, x16, 1f   ;
        li   x16, 6             ;
        beq  TESTNUM, x16, 1f   ;
        li   x16, 10            ;
        beq  TESTNUM, x16, 1f   ;
        j    2f                 ;
# test case 5/6
1:      li   x16, CAUSE_TAG_CHECK_FAIL ;
        csrr x17, mcause        ;
        bne  x16, x17, fail     ;
        csrr x16, mepc          ;
        tagr x17, x16           ;
        bne  x17, x0, fail      ;
        addi x16, x16, 4        ;
        csrw mepc, x16          ;
        EXIT_TAG_MACHINE        ;
        mret                    ;
2:      j fail

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
