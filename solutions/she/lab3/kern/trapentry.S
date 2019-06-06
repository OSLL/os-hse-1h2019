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

TRAPHANDLER_NOEC(division_by_zero,  T_DIVIDE)
TRAPHANDLER_NOEC(debug_error, T_DEBUG)
TRAPHANDLER_NOEC(non_maskable, T_NMI)
TRAPHANDLER_NOEC(breakpoint_i, T_BRKPT)
TRAPHANDLER_NOEC(overflow, T_OFLOW)
TRAPHANDLER_NOEC(bounds_check, T_BOUND)
TRAPHANDLER_NOEC(illegal_opcode, T_ILLOP)
TRAPHANDLER_NOEC(device_not_avai, T_DEVICE)
TRAPHANDLER(double_fault, T_DBLFLT)
// Missing 9
TRAPHANDLER(invalid_tss, T_TSS)
TRAPHANDLER(segment_not_present, T_SEGNP)
TRAPHANDLER(stack_exception, T_STACK)
TRAPHANDLER(general_protection, T_GPFLT)
TRAPHANDLER(page_fault, T_PGFLT)
// Missing 15
TRAPHANDLER_NOEC(floating_point, T_FPERR)

TRAPHANDLER(alignment_check, T_ALIGN)
TRAPHANDLER_NOEC(machine_check, T_MCHK)
TRAPHANDLER_NOEC(simd_floating_point, T_SIMDERR)

TRAPHANDLER_NOEC(syscall_i, T_SYSCALL)
TRAPHANDLER_NOEC(catchall_i, T_DEFAULT)




/*
 * Lab 3: Your code here for _alltraps
 */

_alltraps:
	// pushw $0
	pushl %ds
	// pushw $0
	pushl %es
	pushal

	pushw $GD_KD
	pushw $GD_KD
	popw %ds
	popw %es

	pushl %esp
	call trap