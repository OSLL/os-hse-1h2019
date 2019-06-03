/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>



###################################################################
# exceptions/interrupts
###################################################################

#define PROCESSOR(N) PROCESSOR##N
#define TRAP_PROC(N) TRAPHANDLER(PROCESSOR(N), N)
#define TRAP_NOEC(N) TRAPHANDLER_NOEC(PROCESSOR(N), N)

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

TRAP_NOEC(0)
TRAP_NOEC(1)
TRAP_NOEC(2)
TRAP_NOEC(3)
TRAP_NOEC(4)
TRAP_NOEC(5)
TRAP_NOEC(6)
TRAP_NOEC(7)
TRAP_PROC(8)
TRAP_PROC(10)
TRAP_PROC(11)
TRAP_PROC(12)
TRAP_PROC(13)
TRAP_PROC(14)
TRAP_NOEC(16)
TRAP_PROC(17)
TRAP_NOEC(18)
TRAP_NOEC(19)
TRAP_NOEC(48)

/*
 * Lab 3: Your code here for _alltraps
 */

.global _alltraps
_alltraps:
    pushl %ds
    pushl %es
    pushal
    movl $GD_KD, %eax
    movl %eax, %ds
    movl %eax, %es
    pushl %esp
    call trap