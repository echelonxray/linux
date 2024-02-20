// SPDX-License-Identifier: GPL-2.0-only
/*
 * Copyright (C) 2024 Michael T. Kloos <michael@michaelkloos.com>
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
 * - __xyyysi3 always refers to  32-bit integers. (Only implemented for rv32)
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

#ifndef CONFIG_RISCV_ISA_M // Is M support lacking?

#include <linux/export.h>
#include <linux/linkage.h>
#include <asm/asm.h>

#ifdef CONFIG_64BIT
	#define SINGLE_SFX di3
	#define DOUBLE_SFX ti3
#else
	#define SINGLE_SFX si3
	#define DOUBLE_SFX di3
#endif

// The extra indirection of having both CONCAT3 and _CONCAT3 is needed to make
// the preprocessor resolve the definitons of macros passed as macro parameters.
// Example: "SINGLE_SFX" to "si3" as passed in the suffix parameter.
#define _CONCAT3(prefix, middle, suffix) prefix ## middle ## suffix
#define CONCAT3(prefix, middle, suffix) _CONCAT3(prefix, middle, suffix)

#define SINGLE_MUL(prefix)  CONCAT3(prefix,  __mul, SINGLE_SFX)
#define SINGLE_DIV(prefix)  CONCAT3(prefix,  __div, SINGLE_SFX)
#define SINGLE_UDIV(prefix) CONCAT3(prefix, __udiv, SINGLE_SFX)
#define SINGLE_MOD(prefix)  CONCAT3(prefix,  __mod, SINGLE_SFX)
#define SINGLE_UMOD(prefix) CONCAT3(prefix, __umod, SINGLE_SFX)

#define DOUBLE_MUL(prefix)  CONCAT3(prefix,  __mul, DOUBLE_SFX)
#define DOUBLE_DIV(prefix)  CONCAT3(prefix,  __div, DOUBLE_SFX)
#define DOUBLE_UDIV(prefix) CONCAT3(prefix, __udiv, DOUBLE_SFX)
#define DOUBLE_MOD(prefix)  CONCAT3(prefix,  __mod, DOUBLE_SFX)
#define DOUBLE_UMOD(prefix) CONCAT3(prefix, __umod, DOUBLE_SFX)

SYM_FUNC_START(SINGLE_MUL())
	li t0, (SZREG * 8) // Get Register Bitwidth
	mv t2, zero

	1:
		beqz a0, 2f
		beqz a1, 2f
		andi t1, a0, 1
		addi t0, t0, -1

		beqz t1, 3f
			add t2, t2, a1
		3:

		srli a0, a0, 1
		slli a1, a1, 1

		bnez t0, 1b
	2:

	mv a0, t2
	ret
SYM_FUNC_END(SINGLE_MUL())

SYM_FUNC_START(DOUBLE_MUL())
	li t0, (SZREG * 8 * 2) // Get Register Bitwidth x 2
	li t2, 0
	li t3, 0

	1:
		or a4, a0, a1
		or a5, a2, a3
		andi t1, a0, 1
		addi t0, t0, -1
		beqz a4, 2f
		beqz a5, 2f

		beqz t1, 3f
			add a4, t2, a2
			add t3, t3, a3
			sltu a5, a4, t2
			mv t2, a4
			add t3, t3, a5
		3:

		srli a0, a0, 1
		slli a4, a1, (SZREG * 8) - 1
		slli a3, a3, 1
		srli a5, a2, (SZREG * 8) - 1
		or a0, a0, a4
		srli a1, a1, 1
		or a3, a3, a5
		slli a2, a2, 1

		bnez t0, 1b
	2:

	mv a0, t2
	mv a1, t3
	ret
SYM_FUNC_END(DOUBLE_MUL())

SYM_FUNC_START(SINGLE_DIV())
	// Return with -1 if divisor is 0
	bnez a1, 1f
		li a0, -1
		ret
	1:

	// Store sign matching flag in the form of a positive or negative
	// number in register a7.
	xor a7, a0, a1

	// 2's compliment sign reversal if negative
	bgez a0, 1f
		not a0, a0
		addi a0, a0, 1
	1:

	// 2's compliment sign reversal if negative
	bgez a1, 1f
		not a1, a1
		addi a1, a1, 1
	1:

	li t0, 0
	li t1, 1
	li t2, 0

	// Shift divisor left until it is just greater than dividend
	1:
	bltu a0, a1, 2f
		bgez a1, 3f
			sub a0, a0, a1
			sll t2, t1, t0
			j 2f
		3:
		slli a1, a1, 1
		addi t0, t0, 1
		j 1b
	2:

	// Preform binary long division
	sll t1, t1, t0
	1:
	beqz t0, 2f
		srli a1, a1, 1
		srli t1, t1, 1
		addi t0, t0, -1
		bltu a0, a1, 3f
			sub a0, a0, a1
			or t2, t2, t1
		3:
		j 1b
	2:

	// Fix-up signage with previously stored sign flag
	bgez a7, 1f
		not t2, t2
		addi t2, t2, 1
	1:

	mv a0, t2
	ret
SYM_FUNC_END(SINGLE_DIV())

SYM_FUNC_START(DOUBLE_DIV())
	// Return with -1 if divisor is 0
	or a5, a2, a3
	bnez a5, 1f
		li a0, -1
		li a1, -1
		ret
	1:

	// Store sign matching flag in the form of a positive or negative
	// number in register a7.
	xor a7, a1, a3

	// 2's compliment sign reversal if negative
	bgez a1, 1f // Negative?
		not a0, a0
		not a1, a1
		addi a0, a0, 1
		bnez a0, 1f // Did the lower bits wrap?
			addi a1, a1, 1 // If so add 1 to the upper bits
	1:

	// 2's compliment sign reversal if negative
	bgez a3, 1f // Negative?
		not a2, a2
		not a3, a3
		addi a2, a2, 1
		bnez a2, 1f // Did the lower bits wrap?
			addi a3, a3, 1 // If so add 1 to the upper bits
	1:

	li t0, 0
	li t1, 1
	li t2, 0
	li t3, 0
	li t4, (SZREG * 8)
	li t5, 0

	// if (x == y) : bne x, y, END
	// if (x != y) : beq x, y, END
	// if (x <  y) : bge x, y, END
	// if (x >  y) : bge y, x, END
	// if (x <= y) : blt y, x, END
	// if (x >= y) : blt x, y, END

	// ?.1: MSBs
	// ?.2: LSBs
	// if (x == y) : if (x.1 == y.1 && x.2 == y.2)
	//     bne x.1, y.1, END
	//     bne x.2, y.2, END
	// if (x != y) : if (x.1 != y.1 || x.2 != y.2)
	//     beq x.1, y.1, END
	//     beq x.2, y.2, END
	// if (x <  y) : if (x.1 <  y.1 || (x.1 == y.1 && x.2 <  y.2))
	//     blt x.1, y.1, START
	//     bne x.1, y.1, END
	//     bge x.2, y.2, END
	// if (x >  y) : if (x.1 >  y.1 || (x.1 == y.1 && x.2 >  y.2))
	//     blt y.1, x.1, START
	//     bne x.1, y.1, END
	//     bge y.2, x.2, END
	// if (x <= y) : if (x.1 <  y.1 || (x.1 == y.1 && x.2 <= y.2))
	//     blt x.1, y.1, START
	//     bne x.1, y.1, END
	//     blt y.2, x.2, END
	// if (x >= y) : if (x.1 >  y.1 || (x.1 == y.1 && x.2 >= y.2))
	//     blt y.1, x.1, START
	//     bne x.1, y.1, END
	//     blt x.2, y.2, END

	// Shift divisor left until it is just greater than dividend
	1:
	bltu a3, a1, 4f
	bne  a1, a3, 2f
	bltu a0, a2, 2f
		4:
		bgez a3, 3f
			bgeu a0, a2, 7f // Will wrap?
				addi a1, a1, -1
			7:
			sub a0, a0, a2
			sub a1, a1, a3
			bltu t0, t4, 5f // if (t0 >= (SZREG * 8))
				addi t3, t0, -(SZREG * 8)
				sll t3, t1, t3
				j 2f // j 6f
			5:              // else {
				sll t2, t1, t0
			6:              // }
			j 2f
		3:

		// Shift divisor left by 1
		srli a5, a2, (SZREG * 8) - 1
		slli a3, a3, 1
		slli a2, a2, 1
		or a3, a3, a5

		addi t0, t0, 1
		j 1b
	2:

	// Preform binary long division
	bltu t0, t4, 5f // if (t0 >= (SZREG * 8))
		addi t5, t0, -(SZREG * 8)
		sll t5, t1, t5
		li t1, 0
		j 1f
	5:
		sll t1, t1, t0
	1:
	beqz t0, 2f
		// Shift divisor left by 1
		slli a5, a3, (SZREG * 8) - 1
		srli a2, a2, 1
		srli a3, a3, 1
		or a2, a2, a5

		// Shift mask left by 1
		slli t6, t5, (SZREG * 8) - 1
		srli t1, t1, 1
		srli t5, t5, 1
		or t1, t1, t6

		addi t0, t0, -1

		bltu a3, a1, 4f
		bne  a3, a1, 3f
		bltu a0, a2, 3f
			4:
			bgeu a0, a2, 7f // Will wrap?
				addi a1, a1, -1
			7:
			or t2, t2, t1
			or t3, t3, t5
			sub a1, a1, a3
			sub a0, a0, a2
		3:

		j 1b
	2:

	// Fix-up signage with previously stored sign flag
	bgez a7, 1f // Negative?
		// 2's compliment sign reversal
		not t2, t2
		not t3, t3
		addi t2, t2, 1
		bnez t2, 1f // Did the lower bits wrap?
			addi t3, t3, 1 // If so add 1 to the upper bits
	1:

	mv a0, t2
	mv a1, t3
	ret
SYM_FUNC_END(DOUBLE_DIV())

SYM_FUNC_START(SINGLE_UDIV())
	// Return with -1 if divisor is 0
	bnez a1, 1f
		li a0, -1
		ret
	1:

	li t0, 0
	li t1, 1
	li t2, 0

	// Shift divisor left until it is just greater than dividend
	1:
	bltu a0, a1, 2f
		bgez a1, 3f
			sub a0, a0, a1
			sll t2, t1, t0
			j 2f
		3:
		slli a1, a1, 1
		addi t0, t0, 1
		j 1b
	2:

	// Preform binary long division
	sll t1, t1, t0
	1:
	beqz t0, 2f
		srli a1, a1, 1
		srli t1, t1, 1
		addi t0, t0, -1
		bltu a0, a1, 3f
			sub a0, a0, a1
			or t2, t2, t1
		3:
		j 1b
	2:

	mv a0, t2
	ret
SYM_FUNC_END(SINGLE_UDIV())

SYM_FUNC_START(DOUBLE_UDIV())
	// Return with -1 if divisor is 0
	or a5, a2, a3
	bnez a5, 1f
		li a0, -1
		li a1, -1
		ret
	1:

	li t0, 0
	li t1, 1
	li t2, 0
	li t3, 0
	li t4, (SZREG * 8)
	li t5, 0

	// Shift divisor left until it is just greater than dividend
	1:
	bltu a3, a1, 4f
	bne  a1, a3, 2f
	bltu a0, a2, 2f
		4:
		bgez a3, 3f
			bgeu a0, a2, 7f // Will wrap?
				addi a1, a1, -1
			7:
			sub a0, a0, a2
			sub a1, a1, a3
			bltu t0, t4, 5f // if (t0 >= (SZREG * 8))
				addi t3, t0, -(SZREG * 8)
				sll t3, t1, t3
				j 2f // j 6f
			5:              // else {
				sll t2, t1, t0
			6:              // }
			j 2f
		3:

		// Shift divisor left by 1
		srli a5, a2, (SZREG * 8) - 1
		slli a3, a3, 1
		slli a2, a2, 1
		or a3, a3, a5

		addi t0, t0, 1
		j 1b
	2:

	// Preform binary long division
	bltu t0, t4, 5f // if (t0 >= (SZREG * 8))
		addi t5, t0, -(SZREG * 8)
		sll t5, t1, t5
		li t1, 0
		j 1f
	5:
		sll t1, t1, t0
	1:
	beqz t0, 2f
		// Shift divisor left by 1
		slli a5, a3, (SZREG * 8) - 1
		srli a2, a2, 1
		srli a3, a3, 1
		or a2, a2, a5

		// Shift mask left by 1
		slli t6, t5, (SZREG * 8) - 1
		srli t1, t1, 1
		srli t5, t5, 1
		or t1, t1, t6

		addi t0, t0, -1

		bltu a3, a1, 4f
		bne  a3, a1, 3f
		bltu a0, a2, 3f
			4:
			bgeu a0, a2, 7f // Will wrap?
				addi a1, a1, -1
			7:
			or t2, t2, t1
			or t3, t3, t5
			sub a1, a1, a3
			sub a0, a0, a2
		3:

		j 1b
	2:

	mv a0, t2
	mv a1, t3
	ret
SYM_FUNC_END(DOUBLE_UDIV())

SYM_FUNC_START(SINGLE_MOD())
	// Return with dividend if divisor is 0
	bnez a1, 1f
		ret
	1:

	// Store sign flag in the form of a positive or negative
	// number in register a7.
	mv a7, a0

	// 2's compliment sign reversal if negative
	bgez a0, 1f
		not a0, a0
		addi a0, a0, 1
	1:

	// 2's compliment sign reversal if negative
	bgez a1, 1f
		not a1, a1
		addi a1, a1, 1
	1:

	li t0, 0

	// Shift divisor left until it is just greater than dividend
	1:
	bltu a0, a1, 2f
		bgez a1, 3f
			sub a0, a0, a1
			j 2f
		3:
		slli a1, a1, 1
		addi t0, t0, 1
		j 1b
	2:

	// Preform binary long division
	1:
	beqz t0, 2f
		srli a1, a1, 1
		addi t0, t0, -1
		bltu a0, a1, 3f
			sub a0, a0, a1
		3:
		j 1b
	2:

	// Fix-up signage with previously stored sign flag
	bgez a7, 1f
		not a0, a0
		addi a0, a0, 1
	1:

	ret
SYM_FUNC_END(SINGLE_MOD())

SYM_FUNC_START(DOUBLE_MOD())
	// Return with dividend if divisor is 0
	or a5, a2, a3
	bnez a5, 1f
		ret
	1:

	// Store sign matching flag in the form of a positive or negative
	// number in register a7.
	mv a7, a1

	// 2's compliment sign reversal if negative
	bgez a3, 1f // Negative?
		not a2, a2
		not a3, a3
		addi a2, a2, 1
		bnez a2, 1f // Did the lower bits wrap?
			addi a3, a3, 1 // If so add 1 to the upper bits
	1:

	// 2's compliment sign reversal if negative
	bgez a1, 1f // Negative?
		not a0, a0
		not a1, a1
		addi a0, a0, 1
		bnez a0, 1f // Did the lower bits wrap?
			addi a1, a1, 1 // If so add 1 to the upper bits
	1:

	li t0, 0

	// Shift divisor left until it is just greater than dividend
	1:
	bltu a3, a1, 4f
	bne  a1, a3, 2f
	bltu a0, a2, 2f
		4:
		bgez a3, 3f
			bgeu a0, a2, 7f // Will wrap?
				addi a1, a1, -1
			7:
			sub a0, a0, a2
			sub a1, a1, a3
			j 2f
		3:

		// Shift divisor left by 1
		srli a5, a2, (SZREG * 8) - 1
		slli a3, a3, 1
		slli a2, a2, 1
		or a3, a3, a5

		addi t0, t0, 1
		j 1b
	2:

	beqz t0, 2f
		// Shift divisor left by 1
		slli a5, a3, (SZREG * 8) - 1
		srli a2, a2, 1
		srli a3, a3, 1
		or a2, a2, a5

		addi t0, t0, -1

		bltu a3, a1, 4f
		bne  a3, a1, 3f
		bltu a0, a2, 3f
			4:
			bgeu a0, a2, 7f // Will wrap?
				addi a1, a1, -1
			7:
			sub a1, a1, a3
			sub a0, a0, a2
		3:

		j 1b
	2:

	// Fix-up signage with previously stored sign flag
	bgez a7, 1f // Negative?
		// 2's compliment sign reversal
		not a0, a0
		not a1, a1
		addi a0, a0, 1
		bnez a0, 1f // Did the lower bits wrap?
			addi a1, a1, 1 // If so add 1 to the upper bits
	1:

	ret
SYM_FUNC_END(DOUBLE_MOD())

SYM_FUNC_START(SINGLE_UMOD())
	// Return with dividend if divisor is 0
	bnez a1, 1f
		ret
	1:

	li t0, 0

	// Shift divisor left until it is just greater than dividend
	1:
	bltu a0, a1, 2f
		bgez a1, 3f
			sub a0, a0, a1
			j 2f
		3:
		slli a1, a1, 1
		addi t0, t0, 1
		j 1b
	2:

	// Preform binary long division
	1:
	beqz t0, 2f
		srli a1, a1, 1
		addi t0, t0, -1
		bltu a0, a1, 3f
			sub a0, a0, a1
		3:
		j 1b
	2:

	ret
SYM_FUNC_END(SINGLE_UMOD())

SYM_FUNC_START(DOUBLE_UMOD())
	// Return with dividend if divisor is 0
	or a5, a2, a3
	bnez a5, 1f
		ret
	1:

	li t0, 0

	// Shift divisor left until it is just greater than dividend
	1:
	bltu a3, a1, 4f
	bne  a1, a3, 2f
	bltu a0, a2, 2f
		4:
		bgez a3, 3f
			bgeu a0, a2, 7f // Will wrap?
				addi a1, a1, -1
			7:
			sub a0, a0, a2
			sub a1, a1, a3
			j 2f
		3:

		// Shift divisor left by 1
		srli a5, a2, (SZREG * 8) - 1
		slli a3, a3, 1
		slli a2, a2, 1
		or a3, a3, a5

		addi t0, t0, 1
		j 1b
	2:

	beqz t0, 2f
		// Shift divisor left by 1
		slli a5, a3, (SZREG * 8) - 1
		srli a2, a2, 1
		srli a3, a3, 1
		or a2, a2, a5

		addi t0, t0, -1

		bltu a3, a1, 4f
		bne  a3, a1, 3f
		bltu a0, a2, 3f
			4:
			bgeu a0, a2, 7f // Will wrap?
				addi a1, a1, -1
			7:
			sub a1, a1, a3
			sub a0, a0, a2
		3:

		j 1b
	2:

	ret
SYM_FUNC_END(DOUBLE_UMOD())

EXPORT_SYMBOL(SINGLE_MUL());
EXPORT_SYMBOL(SINGLE_DIV());
EXPORT_SYMBOL(SINGLE_UDIV());
EXPORT_SYMBOL(SINGLE_MOD());
EXPORT_SYMBOL(SINGLE_UMOD());
EXPORT_SYMBOL(DOUBLE_MUL());
EXPORT_SYMBOL(DOUBLE_DIV());
EXPORT_SYMBOL(DOUBLE_UDIV());
EXPORT_SYMBOL(DOUBLE_MOD());
EXPORT_SYMBOL(DOUBLE_UMOD());

SYM_FUNC_ALIAS(SINGLE_MUL(__pi_),  SINGLE_MUL())
SYM_FUNC_ALIAS(SINGLE_DIV(__pi_),  SINGLE_DIV())
SYM_FUNC_ALIAS(SINGLE_UDIV(__pi_), SINGLE_UDIV())
SYM_FUNC_ALIAS(SINGLE_MOD(__pi_),  SINGLE_MOD())
SYM_FUNC_ALIAS(SINGLE_UMOD(__pi_), SINGLE_UMOD())
SYM_FUNC_ALIAS(DOUBLE_MUL(__pi_),  DOUBLE_MUL())
SYM_FUNC_ALIAS(DOUBLE_DIV(__pi_),  DOUBLE_DIV())
SYM_FUNC_ALIAS(DOUBLE_UDIV(__pi_), DOUBLE_UDIV())
SYM_FUNC_ALIAS(DOUBLE_MOD(__pi_),  DOUBLE_MOD())
SYM_FUNC_ALIAS(DOUBLE_UMOD(__pi_), DOUBLE_UMOD())

#ifdef CONFIG_EFI_STUB
SYM_FUNC_ALIAS(SINGLE_MUL(__efistub_),  SINGLE_MUL())
SYM_FUNC_ALIAS(SINGLE_DIV(__efistub_),  SINGLE_DIV())
SYM_FUNC_ALIAS(SINGLE_UDIV(__efistub_), SINGLE_UDIV())
SYM_FUNC_ALIAS(SINGLE_MOD(__efistub_),  SINGLE_MOD())
SYM_FUNC_ALIAS(SINGLE_UMOD(__efistub_), SINGLE_UMOD())
SYM_FUNC_ALIAS(DOUBLE_MUL(__efistub_),  DOUBLE_MUL())
SYM_FUNC_ALIAS(DOUBLE_DIV(__efistub_),  DOUBLE_DIV())
SYM_FUNC_ALIAS(DOUBLE_UDIV(__efistub_), DOUBLE_UDIV())
SYM_FUNC_ALIAS(DOUBLE_MOD(__efistub_),  DOUBLE_MOD())
SYM_FUNC_ALIAS(DOUBLE_UMOD(__efistub_), DOUBLE_UMOD())
#endif

#endif
