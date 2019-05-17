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

	void division_by_zero();
	void debug_error();
	void non_maskable();
	void breakpoint_i();
	void overflow();
	void bounds_check();
	void illegal_opcode();
	void device_not_avai();
	void double_fault();
	// Missing 9
	void invalid_tss();
	void segment_not_present();
	void stack_exception();
	void general_protection();
	void page_fault();
	// Missing 15
	void floating_point();

	void alignment_check();
	void machine_check();
	void simd_floating_point();

	void syscall_i();
	void catchall_i();


	// LAB 3: Your code here.
	SETGATE(idt[0], 1, GD_KT, division_by_zero, 0);
	SETGATE(idt[1], 1, GD_KT, debug_error, 0);
	SETGATE(idt[2], 0, GD_KT, non_maskable, 0);
	SETGATE(idt[3], 1, GD_KT, breakpoint_i, 3);
	SETGATE(idt[4], 1, GD_KT, overflow, 0);
	SETGATE(idt[5], 1, GD_KT, bounds_check, 0);
	SETGATE(idt[6], 1, GD_KT, illegal_opcode, 0);
	SETGATE(idt[7], 1, GD_KT, device_not_avai, 0);
	SETGATE(idt[8], 0, GD_KT, double_fault, 0);
	// Missing 9
	SETGATE(idt[10], 1, GD_KT, invalid_tss, 0);
	SETGATE(idt[11], 1, GD_KT, segment_not_present, 0);
	SETGATE(idt[12], 1, GD_KT, stack_exception, 0);
	SETGATE(idt[13], 1, GD_KT, general_protection, 0);
	SETGATE(idt[14], 1, GD_KT, page_fault, 0);
	// Missing 15
	SETGATE(idt[16], 1, GD_KT, floating_point, 0);

	SETGATE(idt[17], 1, GD_KT, alignment_check, 0);
	SETGATE(idt[18], 0, GD_KT, machine_check, 0);
	SETGATE(idt[19], 1, GD_KT, simd_floating_point, 0);	

	SETGATE(idt[48], 1, GD_KT, syscall_i, 3);
	// SETGATE(idt[500], 0, GD_KD, catchall_i, 0);

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
	// LAB 3: Your code here.

	if (tf->tf_trapno == T_PGFLT) {
		page_fault_handler(tf);
		return;
	}
	else if (tf->tf_trapno == T_BRKPT) {
		monitor(tf);
		return;
	}
	else if (tf->tf_trapno == T_SYSCALL) {
		uint32_t syscallno = tf->tf_regs.reg_eax;
		uint32_t a1 = tf->tf_regs.reg_edx;
		uint32_t a2 = tf->tf_regs.reg_ecx;
		uint32_t a3 = tf->tf_regs.reg_ebx;
		uint32_t a4 = tf->tf_regs.reg_edi;
		uint32_t a5 = tf->tf_regs.reg_esi;

		uint32_t ret = syscall(syscallno, a1, a2, a3, a4, a5);
		tf->tf_regs.reg_eax = ret;
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

	// LAB 3: Your code here.
	if ((tf->tf_cs & 3) == 0) {
		panic("kernel page fault va %08x ip %08x\n", curenv->env_id, fault_va, tf->tf_eip);
	}

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
	env_destroy(curenv);
}

