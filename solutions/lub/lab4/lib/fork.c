// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>

// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800

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

	if (!(err & FEC_WR) || !(uvpt[PGNUM(addr)] & PTE_COW)) {
		panic("pgfault: %x", addr);
	}	

	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.
	//   No need to explicitly delete the old page's mapping.
	
	int code = sys_page_alloc(0, PFTEMP, PTE_U | PTE_P | PTE_W);
	if (code < 0) {
		panic("pgfault: sys_page_alloc: %e", code);
	}
	
	void* src_page_addr = ROUNDDOWN(addr, PGSIZE);
	memcpy(PFTEMP, src_page_addr, PGSIZE);
	
	code = sys_page_map(0, PFTEMP, 0, src_page_addr, PTE_U | PTE_P | PTE_W);
	if (code < 0) {
		panic("pgfault: sys_page_map: %e", code);
	}

	code = sys_page_unmap(0, PFTEMP);
	if (code < 0) {
		panic("pgfault: sys_page_unmap: %e", code);
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

	void* addr = (void*)(pn * PGSIZE);
	if ((uvpt[pn] & PTE_COW) || (uvpt[pn] & PTE_W)) {
		r = sys_page_map(0, addr, envid, addr, PTE_COW | PTE_U | PTE_P);
		if (r < 0) {
			return r;
		}

		r = sys_page_map(0, addr, 0, addr, PTE_COW | PTE_U | PTE_P);
		if (r < 0) {
			return r;
		}
	} else {
		r = sys_page_map(0, addr, envid, addr, PTE_U | PTE_P);
		if (r < 0) {
			return r;
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
	int r;

	set_pgfault_handler(pgfault);
	int child_envid = sys_exofork();
	
	if (child_envid < 0) {
		return child_envid;
	} else if (child_envid == 0) {
		thisenv = envs + ENVX(sys_getenvid());
		return 0;
	}

	for (int i = 0; i < USTACKTOP / PGSIZE; i++) {
		if ((uvpd[PDX(i * PGSIZE)] & PTE_P) 
				&& (uvpt[i] & PTE_P) 
				&& (uvpt[i] & PTE_U)) {
			duppage(child_envid, i);
		}
	}

	if ((r = sys_env_set_pgfault_upcall(child_envid, thisenv->env_pgfault_upcall)) < 0) {
		return r;
	}

	if ((r = sys_page_alloc(child_envid, (void*)(UXSTACKTOP - PGSIZE), 
				PTE_U | PTE_P | PTE_W)) < 0) {
		return r;	
        }

	if ((r = sys_env_set_status(child_envid, ENV_RUNNABLE)) < 0) {
		return r;
	}

	return child_envid;
}

// Challenge!
int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}
