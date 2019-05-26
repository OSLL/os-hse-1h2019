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
	int ret;

	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	if (!(err & FEC_WR)) {
		panic("pgfault: not a write error");
	}
	if (!(uvpt[PGNUM(addr)] & PTE_COW)) {
		panic("pgfault: not a COW page");
	}

	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.
	//   No need to explicitly delete the old page's mapping.

	ret = sys_page_alloc(0, PFTEMP, PTE_P | PTE_U | PTE_W);
	if (ret < 0) {
		panic("pgfault: failed allocating new page: %e", ret);
	}
	void* page_start = ROUNDDOWN(addr, PGSIZE);
	memcpy(PFTEMP, page_start, PGSIZE);
	ret = sys_page_map(0, PFTEMP, 0, page_start, PTE_P | PTE_U | PTE_W);
	if (ret < 0) {
		panic("pgfault: failed remaping faulted page: %e", ret);
	}
	ret = sys_page_unmap(0, PFTEMP);
	if (ret < 0) {
		panic("pgfault: failed unmapping tmp page: %e", ret);
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
	int ret;
	void *page_start = (void*)(pn * PGSIZE);
	int cow = (uvpt[pn] & PTE_W) || (uvpt[pn] & PTE_COW);
	int perms = PTE_P | PTE_U;
	if (cow) {
		perms |= PTE_COW;
	}

	ret = sys_page_map(0, page_start, envid, page_start, perms);
	if (ret < 0) {
		return ret;
	}

	if (cow) {
		ret = sys_page_map(0, page_start, 0, page_start, perms);
		if (ret < 0) {
			return ret;
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
	int ret;
	set_pgfault_handler(pgfault);
	int childid = sys_exofork();

	if (childid < 0) {
		return childid;
	}
	if (childid == 0) {
		thisenv = &envs[ENVX(sys_getenvid())];
		return childid;
	}

	ret = sys_page_alloc(childid, (void*)(UXSTACKTOP - PGSIZE), PTE_P | PTE_U | PTE_W);
	if (ret < 0) {
		return ret;
	}

	for (int i = 0; i < USTACKTOP / PGSIZE; ++i) {
		if ((uvpd[PDX(i * PGSIZE)] & PTE_P) && (uvpt[i] & PTE_P) && (uvpt[i] & PTE_U)) {
			ret = duppage(childid, i);
			if (ret < 0) {
				return ret;
			}
		}
	}

	ret = sys_env_set_pgfault_upcall(childid, thisenv->env_pgfault_upcall);
	if (ret < 0) {
		return ret;
	}
	ret = sys_env_set_status(childid, ENV_RUNNABLE);
	if (ret < 0) {
		return ret;
	}
	return childid;
}

// Challenge!
int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}
