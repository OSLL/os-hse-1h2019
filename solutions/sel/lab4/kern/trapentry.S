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

TRAPHANDLER_NOEC(t_divide, T_DIVIDE)
TRAPHANDLER_NOEC(t_debug, T_DEBUG)
TRAPHANDLER_NOEC(t_nmi, T_NMI)
TRAPHANDLER_NOEC(t_brkpt, T_BRKPT)
TRAPHANDLER_NOEC(t_oflow, T_OFLOW)
TRAPHANDLER_NOEC(t_bound, T_BOUND)
TRAPHANDLER_NOEC(t_illop, T_ILLOP)
TRAPHANDLER_NOEC(t_device, T_DEVICE)

TRAPHANDLER(t_dblflt, T_DBLFLT)

TRAPHANDLER(t_tss, T_TSS)
TRAPHANDLER(t_segnp, T_SEGNP)
TRAPHANDLER(t_stack, T_STACK)
TRAPHANDLER(t_gpflt, T_GPFLT)
TRAPHANDLER(t_pgflt, T_PGFLT)

TRAPHANDLER_NOEC(t_fperr, T_FPERR)
TRAPHANDLER(t_align, T_ALIGN)
TRAPHANDLER_NOEC(t_mchk, T_MCHK)
TRAPHANDLER_NOEC(t_simderr, T_SIMDERR)

TRAPHANDLER_NOEC(t_syscall, T_SYSCALL)

TRAPHANDLER_NOEC(t_handler32, 32);
TRAPHANDLER_NOEC(t_handler33, 33);
TRAPHANDLER_NOEC(t_handler34, 34);
TRAPHANDLER_NOEC(t_handler35, 35);
TRAPHANDLER_NOEC(t_handler36, 36);
TRAPHANDLER_NOEC(t_handler37, 37);
TRAPHANDLER_NOEC(t_handler38, 38);
TRAPHANDLER_NOEC(t_handler39, 39);
TRAPHANDLER_NOEC(t_handler40, 40);
TRAPHANDLER_NOEC(t_handler41, 41);
TRAPHANDLER_NOEC(t_handler42, 42);
TRAPHANDLER_NOEC(t_handler43, 43);
TRAPHANDLER_NOEC(t_handler44, 44);
TRAPHANDLER_NOEC(t_handler45, 45);
TRAPHANDLER_NOEC(t_handler46, 46);
TRAPHANDLER_NOEC(t_handler47, 47);


_alltraps:
	pushl %ds
	pushl %es
	pushal

	movl $GD_KD, %eax
	movl %eax, %ds
	movl %eax, %es

	pushl %esp
	call trap
