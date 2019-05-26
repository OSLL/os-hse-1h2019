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

TRAPHANDLER_NOEC( divide_interrupt_handler,  T_DIVIDE )
TRAPHANDLER_NOEC( debug_interrupt_handler,   T_DEBUG  )
TRAPHANDLER_NOEC( nmi_interrupt_handler,     T_NMI    )
TRAPHANDLER_NOEC( brkpt_interrupt_handler,   T_BRKPT  )
TRAPHANDLER_NOEC( oflow_interrupt_handler,   T_OFLOW  )
TRAPHANDLER_NOEC( bound_interrupt_handler,   T_BOUND  )
TRAPHANDLER_NOEC( illop_interrupt_handler,   T_ILLOP  )
TRAPHANDLER_NOEC( device_interrupt_handler,  T_DEVICE )
TRAPHANDLER(      dblflt_interrupt_handler,  T_DBLFLT )
/*TRAPHANDLER_NOEC( coproc_interrupt_handler,  T_COPROC )*/
TRAPHANDLER(      tss_interrupt_handler,     T_TSS    )
TRAPHANDLER(      segnp_interrupt_handler,   T_SEGNP  )
TRAPHANDLER(      stack_interrupt_handler,   T_STACK  )
TRAPHANDLER(      gpflt_interrupt_handler,   T_GPFLT  )
TRAPHANDLER(      pgflt_interrupt_handler,   T_PGFLT  )
/*TRAPHANDLER_NOEC( res_interrupt_handler,     T_RES    )*/
TRAPHANDLER_NOEC( fperr_interrupt_handler,   T_FPERR  )
TRAPHANDLER(      align_interrupt_handler,   T_ALIGN  )
TRAPHANDLER_NOEC( mchk_interrupt_handler,    T_MCHK   )
TRAPHANDLER_NOEC( simderr_interrupt_handler, T_SIMDERR)

TRAPHANDLER_NOEC( syscall_interrupt_handler, T_SYSCALL)

TRAPHANDLER_NOEC( irq_handler_0,  IRQ_OFFSET + 0 )
TRAPHANDLER_NOEC( irq_handler_1,  IRQ_OFFSET + 1 )
TRAPHANDLER_NOEC( irq_handler_2,  IRQ_OFFSET + 2 )
TRAPHANDLER_NOEC( irq_handler_3,  IRQ_OFFSET + 3 )
TRAPHANDLER_NOEC( irq_handler_4,  IRQ_OFFSET + 4 )
TRAPHANDLER_NOEC( irq_handler_5,  IRQ_OFFSET + 5 )
TRAPHANDLER_NOEC( irq_handler_6,  IRQ_OFFSET + 6 )
TRAPHANDLER_NOEC( irq_handler_7,  IRQ_OFFSET + 7 )
TRAPHANDLER_NOEC( irq_handler_8,  IRQ_OFFSET + 8 )
TRAPHANDLER_NOEC( irq_handler_9,  IRQ_OFFSET + 9 )
TRAPHANDLER_NOEC( irq_handler_10, IRQ_OFFSET + 10)
TRAPHANDLER_NOEC( irq_handler_11, IRQ_OFFSET + 11)
TRAPHANDLER_NOEC( irq_handler_12, IRQ_OFFSET + 12)
TRAPHANDLER_NOEC( irq_handler_13, IRQ_OFFSET + 13)
TRAPHANDLER_NOEC( irq_handler_14, IRQ_OFFSET + 14)
TRAPHANDLER_NOEC( irq_handler_15, IRQ_OFFSET + 15)

_alltraps:
	push %es
	push %ds
	pushal
	pushl $(GD_KD)
	pushl $(GD_KD)
	popl %ds
	popl %es
	pushl %esp
	call trap

