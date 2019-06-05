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

TRAPHANDLER_NOEC(divide_error, T_DIVIDE);
TRAPHANDLER_NOEC(debug_exception, T_DEBUG);
TRAPHANDLER_NOEC(non_maskable_interrupt, T_NMI);
TRAPHANDLER_NOEC(break_point, T_BRKPT);
TRAPHANDLER_NOEC(overflow, T_OFLOW);
TRAPHANDLER_NOEC(bounds_check, T_BOUND);
TRAPHANDLER_NOEC(illegal_opcode, T_ILLOP);
TRAPHANDLER_NOEC(device_not_available, T_DEVICE);
TRAPHANDLER(double_fault, T_DBLFLT);
TRAPHANDLER(invalid_task_switch_segment, T_TSS);
TRAPHANDLER(segment_not_present, T_SEGNP);
TRAPHANDLER(stack_exception, T_STACK);
TRAPHANDLER(general_protection_fault, T_GPFLT);
TRAPHANDLER(page_fault, T_PGFLT);
TRAPHANDLER_NOEC(floating_point_error, T_FPERR);
TRAPHANDLER(aligment_check, T_ALIGN);
TRAPHANDLER_NOEC(machine_check, T_MCHK);
TRAPHANDLER_NOEC(simd_floating_point_error, T_SIMDERR);
TRAPHANDLER_NOEC(system_call, T_SYSCALL);

_alltraps:
	pushl %ds
	pushl %es
	pushal
	movw $GD_KD, %eax
	movw %eax, %ds
	movw %eax, %es
	pushl %esp
	call trap
