// See LICENSE for license details.
void exit(int code);
int main();

void _start(void)
{
  exit(main());
}

// Test of PMP functionality.

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

//--------------------------------------------------------------------------
// Macros

// Set HOST_DEBUG to 1 if you are going to compile this for a host
// machine (ie Athena/Linux) for debug purposes and set HOST_DEBUG
// to 0 if you are compiling with the smips-gcc toolchain.

#ifndef HOST_DEBUG
#define HOST_DEBUG 0
#endif

// Set PREALLOCATE to 1 if you want to preallocate the benchmark
// function before starting stats. If you have instruction/data
// caches and you don't want to count the overhead of misses, then
// you will need to use preallocation.

#ifndef PREALLOCATE
#define PREALLOCATE 0
#endif

// Set SET_STATS to 1 if you want to carve out the piece that actually
// does the computation.

#if HOST_DEBUG
#include <stdio.h>
static void setStats(int enable) {}
#else
extern void setStats(int enable);
#endif

#include <stdint.h>

extern int have_vec;

#define static_assert(cond) switch(0) { case 0: case !!(long)(cond): ; }

static void printArray(const char name[], int n, const int arr[])
{
#if HOST_DEBUG
  int i;
  printf( " %10s :", name );
  for ( i = 0; i < n; i++ )
    printf( " %3d ", arr[i] );
  printf( "\n" );
#endif
}

static void printDoubleArray(const char name[], int n, const double arr[])
{
#if HOST_DEBUG
  int i;
  printf( " %10s :", name );
  for ( i = 0; i < n; i++ )
    printf( " %g ", arr[i] );
  printf( "\n" );
#endif
}

static int verify(int n, const volatile int* test, const int* verify)
{
  int i;
  // Unrolled for faster verification
  for (i = 0; i < n/2*2; i+=2)
  {
    int t0 = test[i], t1 = test[i+1];
    int v0 = verify[i], v1 = verify[i+1];
    if (t0 != v0) return i+1;
    if (t1 != v1) return i+2;
  }
  if (n % 2 != 0 && test[n-1] != verify[n-1])
    return n;
  return 0;
}

static int verifyDouble(int n, const volatile double* test, const double* verify)
{
  int i;
  // Unrolled for faster verification
  for (i = 0; i < n/2*2; i+=2)
  {
    double t0 = test[i], t1 = test[i+1];
    double v0 = verify[i], v1 = verify[i+1];
    int eq1 = t0 == v0, eq2 = t1 == v1;
    if (!(eq1 & eq2)) return i+1+eq1;
  }
  if (n % 2 != 0 && test[n-1] != verify[n-1])
    return n;
  return 0;
}

static uint64_t lfsr(uint64_t x)
{
  uint64_t bit = (x ^ (x >> 1)) & 1;
  return (x >> 1) | (bit << 62);
}

static uintptr_t insn_len(uintptr_t pc)
{
  return (*(unsigned short*)pc & 3) ? 4 : 2;
}

#ifdef __riscv
#include "encoding.h"
#endif

#define stringify_1(s) #s
#define stringify(s) stringify_1(s)
#define stats(code, iter) do { \
    unsigned long _c = -read_csr(mcycle), _i = -read_csr(minstret); \
    code; \
    _c += read_csr(mcycle), _i += read_csr(minstret); \
    if (cid == 0) \
      printf("\n%s: %ld cycles, %ld.%ld cycles/iter, %ld.%ld CPI\n", \
             stringify(code), _c, _c/iter, 10*_c/iter%10, _c/_i, 10*_c/_i%10); \
  } while(0)

static volatile int trap_expected;

#define INLINE inline __attribute__((always_inline))

void exit(int code)
{
  while (1)
    asm("wfi");
}

static uintptr_t handle_trap(uintptr_t cause, uintptr_t epc, uintptr_t regs[32])
{
  if (cause == CAUSE_ILLEGAL_INSTRUCTION)
    exit(0); // no PMP support

  if (!trap_expected || cause != CAUSE_LOAD_ACCESS)
    exit(1);
  trap_expected = 0;

  return epc + insn_len(epc);
}

#define SCRATCH RISCV_PGSIZE
static uintptr_t scratch[RISCV_PGSIZE / sizeof(uintptr_t)] __attribute__((aligned(RISCV_PGSIZE)));
static uintptr_t l1pt[RISCV_PGSIZE / sizeof(uintptr_t)] __attribute__((aligned(RISCV_PGSIZE)));
static uintptr_t l2pt[RISCV_PGSIZE / sizeof(uintptr_t)] __attribute__((aligned(RISCV_PGSIZE)));
#if __riscv_xlen == 64
static uintptr_t l3pt[RISCV_PGSIZE / sizeof(uintptr_t)] __attribute__((aligned(RISCV_PGSIZE)));
#else
#define l3pt l2pt
#endif

static void init_pt()
{
  l1pt[0] = ((uintptr_t)l2pt >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V;
  l3pt[SCRATCH / RISCV_PGSIZE] = ((uintptr_t)scratch >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_A | PTE_D | PTE_V | PTE_R | PTE_W;
#if __riscv_xlen == 64
  l2pt[0] = ((uintptr_t)l3pt >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V;
  uintptr_t vm_choice = SPTBR_MODE_SV39;
#else
  uintptr_t vm_choice = SPTBR_MODE_SV32;
#endif
  write_csr(sptbr, ((uintptr_t)l1pt >> RISCV_PGSHIFT) |
                   (vm_choice * (SPTBR_MODE & ~(SPTBR_MODE<<1))));
  write_csr(pmpcfg0, (PMP_NAPOT | PMP_R) << 16);
  write_csr(pmpaddr2, -1);
}

static uintptr_t va2pa(uintptr_t va)
{
  if (va < SCRATCH || va >= SCRATCH + RISCV_PGSIZE)
    exit(3);
  return va - SCRATCH + (uintptr_t)scratch;
}

#define GRANULE (1UL << PMP_SHIFT)

typedef struct {
  uintptr_t cfg;
  uintptr_t a0;
  uintptr_t a1;
} pmpcfg_t;

static int pmp_ok(pmpcfg_t p, uintptr_t addr, uintptr_t size)
{
  if ((p.cfg & PMP_A) == 0)
    return 1;

  if ((p.cfg & PMP_A) != PMP_TOR) {
    uintptr_t range = 1;

    if ((p.cfg & PMP_A) == PMP_NAPOT) {
      range <<= 1;
      for (uintptr_t i = 1; i; i <<= 1) {
        if ((p.a1 & i) == 0)
          break;
        p.a1 &= ~i;
        range <<= 1;
      }
    }

    p.a0 = p.a1;
    p.a1 = p.a0 + range;
  }

  p.a0 *= GRANULE;
  p.a1 *= GRANULE;
  addr = va2pa(addr);

  uintptr_t hits = 0;
  for (uintptr_t i = 0; i < size; i += GRANULE) {
    if (p.a0 <= addr + i && addr + i < p.a1)
      hits += GRANULE;
  }

  return hits == 0 || hits >= size;
}

INLINE void test_one(uintptr_t addr, uintptr_t size)
{
  uintptr_t new_mstatus = (read_csr(mstatus) & ~MSTATUS_MPP) | (MSTATUS_MPP & (MSTATUS_MPP >> 1)) | MSTATUS_MPRV;
  switch (size) {
    case 1: asm volatile ("csrrw %0, mstatus, %0; lb x0, (%1); csrw mstatus, %0" : "+&r" (new_mstatus) : "r" (addr)); break;
    case 2: asm volatile ("csrrw %0, mstatus, %0; lh x0, (%1); csrw mstatus, %0" : "+&r" (new_mstatus) : "r" (addr)); break;
    case 4: asm volatile ("csrrw %0, mstatus, %0; lw x0, (%1); csrw mstatus, %0" : "+&r" (new_mstatus) : "r" (addr)); break;
#if __riscv_xlen >= 64
    case 8: asm volatile ("csrrw %0, mstatus, %0; ld x0, (%1); csrw mstatus, %0" : "+&r" (new_mstatus) : "r" (addr)); break;
#endif
    default: __builtin_unreachable();
  }
}

static void test_all_sizes(pmpcfg_t p, uintptr_t addr)
{
  for (size_t size = 1; size <= sizeof(uintptr_t); size *= 2) {
    if (addr & (size - 1))
      continue;
    trap_expected = !pmp_ok(p, addr, size);
    test_one(addr, size);
    if (trap_expected)
      exit(2);
  }
}

static void test_range_once(pmpcfg_t p, uintptr_t base, uintptr_t range)
{
  for (uintptr_t addr = base; addr < base + range; addr += GRANULE)
    test_all_sizes(p, addr);
}

INLINE pmpcfg_t set_pmp(pmpcfg_t p)
{
  uintptr_t cfg0 = read_csr(pmpcfg0);
  write_csr(pmpcfg0, cfg0 & ~0xff00);
  write_csr(pmpaddr0, p.a0);
  write_csr(pmpaddr1, p.a1);
  write_csr(pmpcfg0, ((p.cfg << 8) & 0xff00) | (cfg0 & ~0xff00));
  asm volatile ("sfence.vma" ::: "memory");
  return p;
}

INLINE pmpcfg_t set_pmp_range(uintptr_t base, uintptr_t range)
{
  pmpcfg_t p;
  p.cfg = PMP_TOR | PMP_R;
  p.a0 = base >> PMP_SHIFT;
  p.a1 = (base + range) >> PMP_SHIFT;
  return set_pmp(p);
}

INLINE pmpcfg_t set_pmp_napot(uintptr_t base, uintptr_t range)
{
  pmpcfg_t p;
  p.cfg = PMP_R | (range > GRANULE ? PMP_NAPOT : PMP_NA4);
  p.a0 = 0;
  p.a1 = (base + (range/2 - 1)) >> PMP_SHIFT;
  return set_pmp(p);
}

static void test_range(uintptr_t addr, uintptr_t range)
{
  pmpcfg_t p = set_pmp_range(va2pa(addr), range);
  test_range_once(p, addr, range);

  if ((range & (range - 1)) == 0 && (addr & (range - 1)) == 0) {
    p = set_pmp_napot(va2pa(addr), range);
    test_range_once(p, addr, range);
  }
}

static void test_ranges(uintptr_t addr, uintptr_t size)
{
  for (uintptr_t range = GRANULE; range <= size; range += GRANULE)
    test_range(addr, range);
}

static void exhaustive_test(uintptr_t addr, uintptr_t size)
{
  for (uintptr_t base = addr; base < addr + size; base += GRANULE)
    test_ranges(base, size - (base - addr));
}

int main()
{
  init_pt();

  const int max_exhaustive = 32;
  exhaustive_test(SCRATCH, max_exhaustive);
  exhaustive_test(SCRATCH + RISCV_PGSIZE - max_exhaustive, max_exhaustive);

  test_range(SCRATCH, RISCV_PGSIZE);
  test_range(SCRATCH, RISCV_PGSIZE / 2);
  test_range(SCRATCH + RISCV_PGSIZE / 2, RISCV_PGSIZE / 2);

  return 0;
}
