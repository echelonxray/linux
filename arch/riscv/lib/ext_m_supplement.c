// SPDX-License-Identifier: GPL-2.0-only
/*
 * Copyright (C) 2022 Michael T. Kloos <michael@michaelkloos.com>
 */

/*
 * The GNU manual page here:
 * https://gcc.gnu.org/onlinedocs/gccint/Integer-library-routines.html
 * describes these functions in terms of signed and unsigned, int and long.
 * However, these prototypes are wrong when the size of int and long are
 * considered per the RISC-V ABI specification.  The RISC-V port of the GCC
 * complier does not follow the standard of those prototypes.  This is
 * discussed in this thread:
 * https://github.com/riscv-collab/riscv-gcc/issues/324
 *
 * On the RISC-V Architecture:
 * - __xyyysi3 always refers to  32-bit integers.
 * - __xyyydi3 always refers to  64-bit integers.
 * - __xyyyti3 always refers to 128-bit integers. (Only implemented for rv64)
 *
 * Per the RISC-V ABI specification, the C base types are:
 * - int:       32-bits wide.
 * - long:      XLEN-bits wide.  It matches the register width.
 * - long long: 64-bits wide.
 *
 * Therefore, the correct RISC-V function prototypes are:
 * - signed int __mulsi3(signed int a, signed int b);
 * - signed long long __muldi3(signed long long a, signed long long b);
 * - signed __int128 __multi3(signed __int128 a, signed __int128 b);
 *
 * - signed int __divsi3(signed int a, signed int b);
 * - signed long long __divdi3(signed long long a, signed long long b);
 * - signed __int128 __divti3(signed __int128 a, signed __int128 b);
 *
 * - unsigned int __udivsi3(unsigned int a, unsigned int b);
 * - unsigned long long __udivdi3(unsigned long long a, unsigned long long b);
 * - unsigned __int128 __udivti3(unsigned __int128 a, unsigned __int128 b);
 *
 * - signed int __modsi3(signed int a, signed int b);
 * - signed long long __moddi3(signed long long a, signed long long b);
 * - signed __int128 __modti3(signed __int128 a, signed __int128 b);
 *
 * - unsigned int __umodsi3(unsigned int a, unsigned int b);
 * - unsigned long long __umoddi3(unsigned long long a, unsigned long long b);
 * - unsigned __int128 __umodti3(unsigned __int128 a, unsigned __int128 b);
 */

/*
 * This C code is not portable across architectures.  It is RISC-V specific.
 */

#ifndef CONFIG_RISCV_ISA_M

#include <linux/export.h>

#define UINT_MSB (((unsigned       int)1) <<  (32 - 1))
#define  ULL_MSB (((unsigned long long)1) <<  (64 - 1))
#ifdef CONFIG_64BIT
#define U128_MSB (((unsigned  __int128)1) << (128 - 1))
#endif

signed int noinline __mulsi3(signed int a, signed int b)
{
	unsigned int ua;
	unsigned int ub;
	unsigned int j;
	unsigned int i;
	signed int r;

	ua = a;
	ub = b;

	j = 0;
	for (i = 0; i < sizeof(signed int) * 8; i++) {
		if (!ua || !ub)
			break;
		if (ua & 0x1)
			j += ub;
		ua >>= 1;
		ub <<= 1;
	}

	r = j;

	return r;
}
EXPORT_SYMBOL(__mulsi3);

signed long long noinline __muldi3(signed long long a, signed long long b)
{
	unsigned long long ua;
	unsigned long long ub;
	unsigned long long j;
	unsigned int i;
	signed long long r;

	ua = a;
	ub = b;

	j = 0;
	for (i = 0; i < sizeof(signed long long) * 8; i++) {
		if (!ua || !ub)
			break;
		if (ua & 0x1)
			j += ub;
		ua >>= 1;
		ub <<= 1;
	}

	r = j;

	return r;
}
EXPORT_SYMBOL(__muldi3);

#ifdef CONFIG_64BIT
signed __int128 noinline __multi3(signed __int128 a, signed __int128 b)
{
	unsigned __int128 ua;
	unsigned __int128 ub;
	unsigned __int128 j;
	unsigned int i;
	signed __int128 r;

	ua = a;
	ub = b;

	j = 0;
	for (i = 0; i < sizeof(signed __int128) * 8; i++) {
		if (!ua || !ub)
			break;
		if (ua & 0x1)
			j += ub;
		ua >>= 1;
		ub <<= 1;
	}

	r = j;

	return r;
}
EXPORT_SYMBOL(__multi3);
#endif

signed int noinline __divsi3(signed int a, signed int b)
{
	unsigned int ua;
	unsigned int ub;
	unsigned int j;
	unsigned int i;
	signed int r;

	if (b == 0)
		return (signed int)(-1);

	ua = a;
	ub = b;
	if (a < 0)
		ua = -a;
	if (b < 0)
		ub = -b;

	j = 0;
	i = 0;
	while (ua >= ub) {
		if (ub & UINT_MSB) {
			ua -= ub;
			j |= 1u << i;
			break;
		}
		ub <<= 1;
		i++;
	}
	while (i > 0) {
		i--;
		ub >>= 1;
		if (ua >= ub) {
			ua -= ub;
			j |= 1u << i;
		}
	}

	r = j;
	if ((a < 0) != ((b < 0)))
		r = -r;

	return r;
}
EXPORT_SYMBOL(__divsi3);

signed long long noinline __divdi3(signed long long a, signed long long b)
{
	unsigned long long ua;
	unsigned long long ub;
	unsigned long long j;
	unsigned int i;
	signed long long r;

	if (b == 0)
		return (signed long long)(-1);

	ua = a;
	ub = b;
	if (a < 0)
		ua = -a;
	if (b < 0)
		ub = -b;

	j = 0;
	i = 0;
	while (ua >= ub) {
		if (ub & ULL_MSB) {
			ua -= ub;
			j |= 1ull << i;
			break;
		}
		ub <<= 1;
		i++;
	}
	while (i > 0) {
		i--;
		ub >>= 1;
		if (ua >= ub) {
			ua -= ub;
			j |= 1ull << i;
		}
	}

	r = j;
	if ((a < 0) != ((b < 0)))
		r = -r;

	return r;
}
EXPORT_SYMBOL(__divdi3);

#ifdef CONFIG_64BIT
signed __int128 noinline __divti3(signed __int128 a, signed __int128 b)
{
	unsigned __int128 ua;
	unsigned __int128 ub;
	unsigned __int128 j;
	unsigned int i;
	signed __int128 r;

	if (b == 0)
		return (signed __int128)(-1);

	ua = a;
	ub = b;
	if (a < 0)
		ua = -a;
	if (b < 0)
		ub = -b;

	j = 0;
	i = 0;
	while (ua >= ub) {
		if (ub & U128_MSB) {
			ua -= ub;
			j |= ((unsigned __int128)1) << i;
			break;
		}
		ub <<= 1;
		i++;
	}
	while (i > 0) {
		i--;
		ub >>= 1;
		if (ua >= ub) {
			ua -= ub;
			j |= ((unsigned __int128)1) << i;
		}
	}

	r = j;
	if ((a < 0) != ((b < 0)))
		r = -r;

	return r;
}
EXPORT_SYMBOL(__divti3);
#endif

unsigned int noinline __udivsi3(unsigned int a, unsigned int b)
{
	unsigned int j;
	unsigned int i;

	if (b == 0)
		return (signed int)(-1);

	j = 0;
	i = 0;
	while (a >= b) {
		if (b & UINT_MSB) {
			a -= b;
			j |= 1u << i;
			break;
		}
		b <<= 1;
		i++;
	}
	while (i > 0) {
		i--;
		b >>= 1;
		if (a >= b) {
			a -= b;
			j |= 1u << i;
		}
	}

	return j;
}
EXPORT_SYMBOL(__udivsi3);

unsigned long long noinline __udivdi3(unsigned long long a, unsigned long long b)
{
	unsigned long long j;
	unsigned long long i;

	if (b == 0)
		return (signed long long)(-1);

	j = 0;
	i = 0;
	while (a >= b) {
		if (b & ULL_MSB) {
			a -= b;
			j |= 1ull << i;
			break;
		}
		b <<= 1;
		i++;
	}
	while (i > 0) {
		i--;
		b >>= 1;
		if (a >= b) {
			a -= b;
			j |= 1ull << i;
		}
	}

	return j;
}
EXPORT_SYMBOL(__udivdi3);

#ifdef CONFIG_64BIT
unsigned __int128 noinline __udivti3(unsigned __int128 a, unsigned __int128 b)
{
	unsigned __int128 j;
	unsigned __int128 i;

	if (b == 0)
		return (signed __int128)(-1);

	j = 0;
	i = 0;
	while (a >= b) {
		if (b & U128_MSB) {
			a -= b;
			j |= ((unsigned __int128)1) << i;
			break;
		}
		b <<= 1;
		i++;
	}
	while (i > 0) {
		i--;
		b >>= 1;
		if (a >= b) {
			a -= b;
			j |= ((unsigned __int128)1) << i;
		}
	}

	return j;
}
EXPORT_SYMBOL(__udivti3);
#endif

signed int noinline __modsi3(signed int a, signed int b)
{
	unsigned int ua;
	unsigned int ub;
	unsigned int i;
	signed int r;

	if (b == 0)
		return a;

	ua = a;
	ub = b;
	if (a < 0)
		ua = -a;
	if (b < 0)
		ub = -b;

	i = 0;
	while (ua >= ub) {
		if (ub & UINT_MSB) {
			ua -= ub;
			break;
		}
		ub <<= 1;
		i++;
	}
	while (i > 0) {
		i--;
		ub >>= 1;
		if (ua >= ub)
			ua -= ub;
	}

	r = ua;
	if (a < 0)
		r = -r;

	return r;
}
EXPORT_SYMBOL(__modsi3);

signed long long noinline __moddi3(signed long long a, signed long long b)
{
	unsigned long long ua;
	unsigned long long ub;
	unsigned int i;
	signed long long r;

	if (b == 0)
		return a;

	ua = a;
	ub = b;
	if (a < 0)
		ua = -a;
	if (b < 0)
		ub = -b;

	i = 0;
	while (ua >= ub) {
		if (ub & ULL_MSB) {
			ua -= ub;
			break;
		}
		ub <<= 1;
		i++;
	}
	while (i > 0) {
		i--;
		ub >>= 1;
		if (ua >= ub)
			ua -= ub;
	}

	r = ua;
	if (a < 0)
		r = -r;

	return r;
}
EXPORT_SYMBOL(__moddi3);

#ifdef CONFIG_64BIT
signed __int128 noinline __modti3(signed __int128 a, signed __int128 b)
{
	unsigned __int128 ua;
	unsigned __int128 ub;
	unsigned int i;
	signed __int128 r;

	if (b == 0)
		return a;

	ua = a;
	ub = b;
	if (a < 0)
		ua = -a;
	if (b < 0)
		ub = -b;

	i = 0;
	while (ua >= ub) {
		if (ub & U128_MSB) {
			ua -= ub;
			break;
		}
		ub <<= 1;
		i++;
	}
	while (i > 0) {
		i--;
		ub >>= 1;
		if (ua >= ub)
			ua -= ub;
	}

	r = ua;
	if (a < 0)
		r = -r;

	return r;
}
EXPORT_SYMBOL(__modti3);
#endif

unsigned int noinline __umodsi3(unsigned int a, unsigned int b)
{
	unsigned int i;

	if (b == 0)
		return a;

	i = 0;
	while (a >= b) {
		if (b & UINT_MSB) {
			a -= b;
			break;
		}
		b <<= 1;
		i++;
	}
	while (i > 0) {
		i--;
		b >>= 1;
		if (a >= b)
			a -= b;
	}

	return a;
}
EXPORT_SYMBOL(__umodsi3);

unsigned long long noinline __umoddi3(unsigned long long a, unsigned long long b)
{
	unsigned long long i;

	if (b == 0)
		return a;

	i = 0;
	while (a >= b) {
		if (b & ULL_MSB) {
			a -= b;
			break;
		}
		b <<= 1;
		i++;
	}
	while (i > 0) {
		i--;
		b >>= 1;
		if (a >= b)
			a -= b;
	}

	return a;
}
EXPORT_SYMBOL(__umoddi3);

#ifdef CONFIG_64BIT
unsigned __int128 noinline __umodti3(unsigned __int128 a, unsigned __int128 b)
{
	unsigned __int128 i;

	if (b == 0)
		return a;

	i = 0;
	while (a >= b) {
		if (b & U128_MSB) {
			a -= b;
			break;
		}
		b <<= 1;
		i++;
	}
	while (i > 0) {
		i--;
		b >>= 1;
		if (a >= b)
			a -= b;
	}

	return a;
}
EXPORT_SYMBOL(__umodti3);
#endif

/*
 * The EFI Stub uses a symbol prefix to attempt to identify and isolate all the components of the stub.
 * However, we need to provide support for M in the stub.  So we will wrapper the supplement functions.
 * This should be safe to do outside of libstub because RISC-V has a very large position relative
 * addressing range.
 */
#ifdef CONFIG_EFI_STUB
signed int noinline __efistub___mulsi3(signed int a, signed int b) {
	return __mulsi3(a, b);
}
signed int noinline __efistub___divsi3(signed int a, signed int b) {
	return __divsi3(a, b);
}
unsigned int noinline __efistub___udivsi3(unsigned int a, unsigned int b) {
	return __udivsi3(a, b);
}
signed int noinline __efistub___modsi3(signed int a, signed int b) {
	return __modsi3(a, b);
}
unsigned int noinline __efistub___umodsi3(unsigned int a, unsigned int b) {
	return __umodsi3(a, b);
}

signed long long noinline __efistub___muldi3(signed long long a, signed long long b) {
	return __muldi3(a, b);
}
signed long long noinline __efistub___divdi3(signed long long a, signed long long b) {
	return __divdi3(a, b);
}
unsigned long long noinline __efistub___udivdi3(unsigned long long a, unsigned long long b) {
	return __udivdi3(a, b);
}
signed long long noinline __efistub___moddi3(signed long long a, signed long long b) {
	return __moddi3(a, b);
}
unsigned long long noinline __efistub___umoddi3(unsigned long long a, unsigned long long b) {
	return __umoddi3(a, b);
}

#ifdef CONFIG_64BIT
signed __int128 noinline __efistub___multi3(signed __int128 a, signed __int128 b) {
	return __multi3(a, b);
}
signed __int128 noinline __efistub___divti3(signed __int128 a, signed __int128 b) {
	return __divti3(a, b);
}
unsigned __int128 noinline __efistub___udivti3(unsigned __int128 a, unsigned __int128 b) {
	return __udivti3(a, b);
}
signed __int128 noinline __efistub___modti3(signed __int128 a, signed __int128 b) {
	return __modti3(a, b);
}
unsigned __int128 noinline __efistub___umodti3(unsigned __int128 a, unsigned __int128 b) {
	return __umodti3(a, b);
}
#endif
#endif

#endif
