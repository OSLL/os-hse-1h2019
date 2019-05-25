/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>

#include <kern/picirq.h>


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

#define TRAPHANDLER_FROM_NUM(num) TRAPHANDLER(handler ## num, num)
#define TRAPHANDLER_NOEC_FROM_NUM(num) TRAPHANDLER_NOEC(handler ## num, num)

TRAPHANDLER_NOEC_FROM_NUM(0)
TRAPHANDLER_NOEC_FROM_NUM(1)
TRAPHANDLER_NOEC_FROM_NUM(2)
TRAPHANDLER_NOEC_FROM_NUM(3)
TRAPHANDLER_NOEC_FROM_NUM(4)
TRAPHANDLER_NOEC_FROM_NUM(5)
TRAPHANDLER_NOEC_FROM_NUM(6)
TRAPHANDLER_NOEC_FROM_NUM(7)
TRAPHANDLER_FROM_NUM(8)

TRAPHANDLER_FROM_NUM(10)
TRAPHANDLER_FROM_NUM(11)
TRAPHANDLER_FROM_NUM(12)
TRAPHANDLER_FROM_NUM(13)
TRAPHANDLER_FROM_NUM(14)

TRAPHANDLER_NOEC_FROM_NUM(16)
TRAPHANDLER_FROM_NUM(17)
TRAPHANDLER_NOEC_FROM_NUM(18)
TRAPHANDLER_NOEC_FROM_NUM(19)

TRAPHANDLER_NOEC_FROM_NUM(48)

.data
.globl handlers_array
handlers_array:
	.long handler0
	.long handler1
	.long handler2
	.long handler3
	.long handler4
	.long handler5
	.long handler6
	.long handler7
	.long handler8
	.long 0
	.long handler10
	.long handler11
	.long handler12
	.long handler13
	.long handler14
	.long 0
	.long handler16
	.long handler17
	.long handler18
	.long handler19

_alltraps:
	pushl %ds
	pushl %es
	pushal

	pushl $GD_KD
	pushl $GD_KD
	popl %ds
	popl %es

	pushl %esp

	call trap
