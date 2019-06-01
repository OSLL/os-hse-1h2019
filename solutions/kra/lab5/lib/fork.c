// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>

// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800
extern void _pgfault_upcall(void);

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;

	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	if (((err & FEC_WR) != FEC_WR) || !(uvpt[PGNUM(addr)] & PTE_COW)) {
		panic("pgfault failed");
	}

	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.
	//   No need to explicitly delete the old page's mapping.

	// LAB 4: Your code here.
	r = sys_page_alloc(0, (void *)PFTEMP, PTE_P | PTE_U | PTE_W);
	if (r < 0) {
		panic("pgfault failed");
	}

	addr = ROUNDDOWN(addr, PGSIZE);
	memcpy((void *)PFTEMP, addr, PGSIZE);
	r = sys_page_map(0, PFTEMP, 0, addr, PTE_P | PTE_U | PTE_W);
	if (r < 0) {
		panic("pgfault failed");		
	}
	r = sys_page_unmap(0, PFTEMP);
	if (r < 0) {
		panic("pgfault failed");		
	}
}

//
// Map our virtual page pn (address pn*PGSIZE) into the target envid
// at the same virtual address.  If the page is writable or copy-on-write,
// the new mapping must be created copy-on-write, and then our mapping must be
// marked copy-on-write as well.  (Exercise: Why do we need to mark ours
// copy-on-write again if it was already copy-on-write at the beginning of
// this function?)
//
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
static int
duppage(envid_t envid, unsigned pn)
{
	int r;
	void* va = (void *)(pn * PGSIZE);
	if (uvpt[pn] & PTE_SHARE) {
		r = sys_page_map(0, va, envid, va, uvpt[pn] & PTE_SYSCALL);
		if (r < 0) {
			return r;
		}
	} else 
	{	if (uvpt[pn] & (PTE_W | PTE_COW)) {
			r = sys_page_map(0, va, envid, va, PTE_P | PTE_U | PTE_COW);
			if (r < 0) {
				return r;
			}

			r = sys_page_map(0, va, 0, va, PTE_P | PTE_U | PTE_COW);
			if (r < 0) {
				return r;
			}
		} else {
			r = sys_page_map(0, va, envid, va, uvpt[pn] & PTE_SYSCALL);
			if (r < 0) {
				return r;
			}
		}
	}
	return 0;
}

//
// User-level fork with copy-on-write.
// Set up our page fault handler appropriately.
// Create a child.
// Copy our address space and page fault handler setup to the child.
// Then mark the child as runnable and return.
//
// Returns: child's envid to the parent, 0 to the child, < 0 on error.
// It is also OK to panic on error.
//
// Hint:
//   Use uvpd, uvpt, and duppage.
//   Remember to fix "thisenv" in the child process.
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
	// LAB 4: Your code here.
	set_pgfault_handler(pgfault);

	envid_t child = sys_exofork();
	if (child < 0) {
		panic("fork failed");
	}
	if (child == 0) {
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	}
	for (uintptr_t va = UTEXT; va < USTACKTOP; va += PGSIZE) {
		if ((uvpd[PDX(va)] & PTE_P) && (uvpt[PGNUM(va)] & PTE_P) && 
			(uvpt[PGNUM(va)] & PTE_U)) {
			duppage(child, PGNUM(va));
		}
	}
	int result = sys_page_alloc(child, (void *)(UXSTACKTOP - PGSIZE), PTE_P | PTE_U | PTE_W);
	if (result < 0) {
		return result;
	}

	result = sys_env_set_pgfault_upcall(child, _pgfault_upcall);
	if (result < 0) {
		return result;
	}

	result = sys_env_set_status(child, ENV_RUNNABLE);
	if (result) {
		return result;
	}

	return child;
}

// Challenge!
int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}

