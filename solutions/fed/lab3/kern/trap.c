#include <inc/mmu.h>
#include <inc/x86.h>
#include <inc/assert.h>

#include <kern/pmap.h>
#include <kern/trap.h>
#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/env.h>
#include <kern/syscall.h>

static struct Taskstate ts;

/* For debugging, so print_trapframe can distinguish between printing
 * a saved trapframe and printing the current trapframe and print some
 * additional information in the latter case.
 */
static struct Trapframe *last_tf;

/* Interrupt descriptor table.  (Must be built at run time because
 * shifted function addresses can't be represented in relocation records.)
 */
struct Gatedesc idt[256] = { { 0 } };
struct Pseudodesc idt_pd = {
	sizeof(idt) - 1, (uint32_t) idt
};


static const char *trapname(int trapno)
{
	static const char * const excnames[] = {
		"Divide error",
		"Debug",
		"Non-Maskable Interrupt",
		"Breakpoint",
		"Overflow",
		"BOUND Range Exceeded",
		"Invalid Opcode",
		"Device Not Available",
		"Double Fault",
		"Coprocessor Segment Overrun",
		"Invalid TSS",
		"Segment Not Present",
		"Stack Fault",
		"General Protection",
		"Page Fault",
		"(unknown trap)",
		"x87 FPU Floating-Point Error",
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
}


void
trap_init(void)
{
	extern struct Segdesc gdt[];

	// LAB 3: My code here.
	extern void idt_divide();
	extern void idt_debug();
	extern void idt_nmi();
	extern void idt_brkpt();
	extern void idt_oflow();
	extern void idt_bound();
	extern void idt_illop();
	extern void idt_device();
	extern void idt_dblflt();
	extern void idt_tss();
	extern void idt_segnp();
	extern void idt_stack();
	extern void idt_gpflt();
	extern void idt_pgflt();
	extern void idt_fperr();
	extern void idt_align();
	extern void idt_mchk();
	extern void idt_simderr();
	extern void idt_syscall();
	extern void idt_irq_timer();
	extern void idt_irq_kbd();
	extern void idt_irq_serial();
	extern void idt_irq_spurious();
	extern void idt_irq_ide();
	extern void idt_irq_error();

	SETGATE(idt[T_DIVIDE], 1, GD_KT, idt_divide, 0);
	SETGATE(idt[T_DEBUG], 1, GD_KT, idt_debug, 0);
	SETGATE(idt[T_NMI], 0, GD_KT, idt_nmi, 0);
	SETGATE(idt[T_BRKPT], 1, GD_KT, idt_brkpt, 3);
	SETGATE(idt[T_OFLOW], 1, GD_KT, idt_oflow, 0);
	SETGATE(idt[T_BOUND], 1, GD_KT, idt_bound, 0);
	SETGATE(idt[T_ILLOP], 1, GD_KT, idt_illop, 0);
	SETGATE(idt[T_DEVICE], 1, GD_KT, idt_device, 0);
	SETGATE(idt[T_DBLFLT], 1, GD_KT, idt_dblflt, 0);
	SETGATE(idt[T_TSS], 1, GD_KT, idt_tss, 0);
	SETGATE(idt[T_SEGNP], 1, GD_KT, idt_segnp, 0);
	SETGATE(idt[T_STACK], 1, GD_KT, idt_stack, 0);
	SETGATE(idt[T_GPFLT], 1, GD_KT, idt_gpflt, 0);
	SETGATE(idt[T_PGFLT], 1, GD_KT, idt_pgflt, 0);
	SETGATE(idt[T_FPERR], 1, GD_KT, idt_fperr, 0);
	SETGATE(idt[T_ALIGN], 1, GD_KT, idt_align, 0);
	SETGATE(idt[T_MCHK], 1, GD_KT, idt_mchk, 0);
	SETGATE(idt[T_SIMDERR], 1, GD_KT, idt_simderr, 0);
	SETGATE(idt[T_SYSCALL], 0, GD_KT, idt_syscall, 3);
	SETGATE(idt[IRQ_OFFSET + IRQ_TIMER], 0, GD_KT, idt_irq_timer, 0);
	SETGATE(idt[IRQ_OFFSET + IRQ_KBD], 0, GD_KT, idt_irq_kbd, 0);
	SETGATE(idt[IRQ_OFFSET + IRQ_SERIAL], 0, GD_KT, idt_irq_serial, 0);
	SETGATE(idt[IRQ_OFFSET + IRQ_SPURIOUS], 0, GD_KT, idt_irq_spurious, 0);
	SETGATE(idt[IRQ_OFFSET + IRQ_IDE], 0, GD_KT, idt_irq_ide, 0);
	SETGATE(idt[IRQ_OFFSET + IRQ_ERROR], 0, GD_KT, idt_irq_error, 0);

	// Per-CPU setup 
	trap_init_percpu();
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
	ts.ts_ss0 = GD_KD;

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
					sizeof(struct Taskstate), 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
		cprintf("  cr2  0x%08x\n", rcr2());
	cprintf("  err  0x%08x", tf->tf_err);
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
	cprintf("  eip  0x%08x\n", tf->tf_eip);
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
	if ((tf->tf_cs & 3) != 0) {
		cprintf("  esp  0x%08x\n", tf->tf_esp);
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
	}
}

void
print_regs(struct PushRegs *regs)
{
	cprintf("  edi  0x%08x\n", regs->reg_edi);
	cprintf("  esi  0x%08x\n", regs->reg_esi);
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
	cprintf("  edx  0x%08x\n", regs->reg_edx);
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
	cprintf("  eax  0x%08x\n", regs->reg_eax);
}

static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: My code is here.
	if (tf->tf_trapno == T_PGFLT) {
		page_fault_handler(tf);
		return;
	}
	if (tf->tf_trapno == T_BRKPT) {
		monitor(tf);
		return;
	}
	if (tf->tf_trapno == T_SYSCALL) {
		tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx,
			tf->tf_regs.reg_ebx, tf->tf_regs.reg_edi, tf->tf_regs.reg_esi);
		return;
	}

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
	if (tf->tf_cs == GD_KT)
		panic("unhandled trap in kernel");
	else {
		env_destroy(curenv);
		return;
	}
}

void
trap(struct Trapframe *tf)
{
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));

	cprintf("Incoming TRAP frame at %p\n", tf);

	if ((tf->tf_cs & 3) == 3) {
		// Trapped from user mode.
		assert(curenv);

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
	env_run(curenv);
}


void
page_fault_handler(struct Trapframe *tf)
{
	uint32_t fault_va;

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: My code is here.
	if (!(tf->tf_cs & 3)) {
		panic("page_fault_handler: page fault in kernel mode.");
		return;
	}

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
	env_destroy(curenv);
}

