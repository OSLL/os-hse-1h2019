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

# failed to find in the manual information about error codes

TRAPHANDLER_NOEC(f0, T_DIVIDE)
TRAPHANDLER_NOEC(f1, T_DEBUG)
TRAPHANDLER(f2, T_NMI)
TRAPHANDLER_NOEC(f3, T_BRKPT)
TRAPHANDLER(f4, T_OFLOW)
TRAPHANDLER(f5, T_BOUND)
TRAPHANDLER_NOEC(f6, T_ILLOP)
TRAPHANDLER(f7, T_DEVICE)
TRAPHANDLER(f8, T_DBLFLT)
TRAPHANDLER(f10, T_TSS)
TRAPHANDLER(f11, T_SEGNP)
TRAPHANDLER(f12, T_STACK)
TRAPHANDLER(f13, T_GPFLT)
TRAPHANDLER(f14, T_PGFLT)
TRAPHANDLER(f16, T_FPERR)
TRAPHANDLER(f17, T_ALIGN)
TRAPHANDLER(f18, T_MCHK)
TRAPHANDLER(f19, T_SIMDERR)
TRAPHANDLER_NOEC(f48, T_SYSCALL)


/*
 * Lab 3: Your code here for _alltraps
 */

_alltraps:
	pushl %ds
	pushl %es	
	pushal
	movl $GD_KD, %eax
	movl %eax, %ds
	movl %eax, %es
	pushl %esp
	call trap