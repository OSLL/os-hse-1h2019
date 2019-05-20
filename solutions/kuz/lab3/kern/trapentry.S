/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>



###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */
#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
#define TH(N) TRAPHANDLER(handler_##N, N)
#define THN(N) TRAPHANDLER_NOEC(handler_##N, N)

THN(0)
THN(1)
THN(2)
THN(3)
THN(4)
THN(5)
THN(6)
THN(7)
TH(8)
TH(10)
TH(11)
TH(12)
TH(13)
TH(14)
THN(16)
TH(17)
THN(18)
THN(19)
THN(48)

/*
 * Lab 3: Your code here for _alltraps
 */

.data
.globl handlers
handlers:
	.long handler_0
	.long handler_1
	.long handler_2
	.long handler_3
	.long handler_4
	.long handler_5
	.long handler_6
	.long handler_7
	.long handler_8
	.long 0
	.long handler_10
	.long handler_11
	.long handler_12
	.long handler_13
	.long handler_14
	.long 0
	.long handler_16
	.long handler_17
	.long handler_18
	.long handler_19


_alltraps:
	pushl %ds
	pushl %es
	pushal
	pushl $GD_KD
	pushl $GD_KD
	popl %es
	popl %ds
	pushl %esp
	call trap
