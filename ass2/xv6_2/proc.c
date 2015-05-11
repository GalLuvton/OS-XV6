#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "x86.h"
#include "proc.h"
#include "spinlock.h"

struct {
  struct spinlock lock;
  struct proc proc[NPROC];
} ptable;

static struct proc *initproc;

int nextpid = 1;
int nexttid = 1;
extern void forkret(void);
extern void trapret(void);

static void wakeup1(void *chan);

void
pinit(void)
{
  initlock(&ptable.lock, "ptable");
}

//PAGEBREAK: 32
// Look in the process table for an UNUSED proc.
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
  struct proc *p;
  struct thread *t;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
  p->pid = nextpid++;
  release(&ptable.lock);

  t = p->threads; // the first thread struct
  t->state = T_EMBRYO;
  t->tid = nexttid++;
  t->parent = p;
  t->chan = 0;
  t->killed = 0;
  
  // Allocate kernel stack.
  if((t->kstack = kalloc()) == 0){
    p->state = UNUSED;
	t->state = T_FREE;
    return 0;
  }
  sp = t->kstack + KSTACKSIZE;
  
  // Leave room for trap frame.
  sp -= sizeof *t->tf;
  t->tf = (struct trapframe*)sp;
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
  *(uint*)sp = (uint)trapret;

  sp -= sizeof *t->context;
  t->context = (struct context*)sp;
  memset(t->context, 0, sizeof *t->context);
  t->context->eip = (uint)forkret;
  
  return p;
}

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
  initproc = p;
  if((p->pgdir = setupkvm()) == 0)
    panic("userinit: out of memory?");
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
  p->sz = PGSIZE;
  memset(p->threads->tf, 0, sizeof(*p->threads->tf));
  p->threads->tf->cs = (SEG_UCODE << 3) | DPL_USER;
  p->threads->tf->ds = (SEG_UDATA << 3) | DPL_USER;
  p->threads->tf->es = p->threads->tf->ds;
  p->threads->tf->ss = p->threads->tf->ds;
  p->threads->tf->eflags = FL_IF;
  p->threads->tf->esp = PGSIZE;
  p->threads->tf->eip = 0;  // beginning of initcode.S

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");
  
  initlock(&p->lock, "init");

  p->state = RUNNABLE;
  p->threads->state = T_RUNNABLE;
}

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  uint sz;
  struct proc *curProc = curThread->parent;
  acquire(&curProc->lock);

  sz = curProc->sz;
  if(n > 0){
    if((sz = allocuvm(curProc->pgdir, sz, sz + n)) == 0)
      return -1;
  } else if(n < 0){
    if((sz = deallocuvm(curProc->pgdir, sz, sz + n)) == 0)
      return -1;
  }
  curProc->sz = sz;
  switchuvm(curProc);
  
  release(&curProc->lock);
  return 0;
}

// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
    return -1;

  struct proc *curProc = curThread->parent;
	
  // Copy process state from p.
  if((np->pgdir = copyuvm(curProc->pgdir, curProc->sz)) == 0){
    kfree(np->threads->kstack);	// the alloced process only has one thread
    np->threads->kstack = 0;
    np->state = UNUSED;
    return -1;
  }
  np->sz = curProc->sz;
  np->parent = curProc;
  *np->threads->tf = *curThread->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->threads->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
    if(curProc->ofile[i])
      np->ofile[i] = filedup(curProc->ofile[i]);
  np->cwd = idup(curProc->cwd);

  safestrcpy(np->name, curProc->name, sizeof(curProc->name));
 
  pid = np->pid;
  initlock(&np->lock, np->name);

  // lock to force the compiler to emit the np->state write last.
  acquire(&ptable.lock);
  np->state = RUNNABLE;
  np->threads->state = T_RUNNABLE;
  release(&ptable.lock);
  
  return pid;
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
  struct proc *p;
  int fd;

  struct proc *curProc = curThread->parent;
  
  if(curProc == initproc)
    panic("init exiting");

  struct thread *t;
  for(t = curProc->threads; t < &curProc->threads[NTHREAD]; t++){
	if (t != curThread && t->state != T_FREE){
		t->killed = 1;
	}
  }
  /*
  int alive = 1;
  while (alive){ // busywait on all threads to die
    alive = 0;
	for(t = curProc->threads; t < &curProc->threads[NTHREAD]; t++){
		if (t != curThread){
			if (t->state != T_ZOMBIE || t->state != T_FREE){
				alive = 1;
			}
		}
	}
  }
  */
	
  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
    if(curProc->ofile[fd]){
      fileclose(curProc->ofile[fd]);
      curProc->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(curProc->cwd);
  end_op();
  curProc->cwd = 0;

  acquire(&ptable.lock);

  // Parent might be sleeping in wait().
  wakeup1(curProc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->parent == curProc){
      p->parent = initproc;
      if(p->state == ZOMBIE)
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  curProc->state = ZOMBIE;
  curThread->state = T_ZOMBIE;
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
  struct proc *p;
  struct thread *t;
  int havekids, pid;

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != curThread->parent)
        continue;
      havekids = 1;
      if(p->state == ZOMBIE){
        // Found one.
        pid = p->pid;
		for(t = p->threads; t < &p->threads[NTHREAD]; t++){
			if (t->state != T_FREE){
				kfree(p->threads->kstack);
				t->kstack = 0;
				t->tid = 0;
				t->parent = 0;
				t->tf = 0;
				t->context = 0;
				t->chan = 0;
				t->killed = 0;
				t->state = T_FREE;
			}
		}
        freevm(p->pgdir);
        p->state = UNUSED;
        p->pid = 0;
        p->parent = 0;
        p->name[0] = 0;
        p->killed = 0;
        release(&ptable.lock);
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || curThread->killed || curThread->parent->killed){
      release(&ptable.lock);
      return -1;
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(curThread->parent, &ptable.lock);  //DOC: wait-sleep
  }
}

//PAGEBREAK: 42
// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
  struct proc *p;
  struct thread *t;

  for(;;){
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
		if (p->state != RUNNABLE){
			continue;
		}
		for(t = p->threads; t < &p->threads[NTHREAD]; t++){
			if (t->state != T_RUNNABLE){
				continue;
			}
			// Switch to chosen process.  It is the process's job
			// to release ptable.lock and then reacquire it
			// before jumping back to us.
			curThread = t;
			switchuvm(t->parent);
			t->state = T_RUNNING;
			swtch(&cpu->scheduler, t->context);
			switchkvm();

			// Process is done running for now.
			// It should have changed its p->state before coming back.
			curThread = 0;
		}
    }
    release(&ptable.lock);
  }
}

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
  int intena;

  if(!holding(&ptable.lock))
    panic("sched ptable.lock");
  if(cpu->ncli != 1)
    panic("sched locks");
  if(curThread->state == T_RUNNING)
    panic("sched running");
  if(readeflags()&FL_IF)
    panic("sched interruptible");
  intena = cpu->intena;
  swtch(&curThread->context, cpu->scheduler);
  cpu->intena = intena;
}

// Give up the CPU for one scheduling round.
void
yield(void)
{
  acquire(&ptable.lock);  //DOC: yieldlock
  curThread->state = T_RUNNABLE;
  sched();
  release(&ptable.lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);

  if (first) {
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
    initlog();
  }
  
  // Return to "caller", actually trapret (see allocproc).
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  if(curThread == 0)
    panic("sleep");

  if(lk == 0)
    panic("sleep without lk");

  // Must acquire ptable.lock in order to
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
    acquire(&ptable.lock);  //DOC: sleeplock1
    release(lk);
  }

  // Go to sleep.
  curThread->chan = chan;
  curThread->state = T_SLEEPING;
  sched();

  // Tidy up.
  curThread->chan = 0;

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
    release(&ptable.lock);
    acquire(lk);
  }
}

//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
	struct proc *p;
	struct thread *t;

	for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
		for(t = p->threads; t < &p->threads[NTHREAD]; t++){
			if(t->chan == chan){
				t->state = T_RUNNABLE;
				p->state = RUNNABLE;
			}
		}
	}
}

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
  acquire(&ptable.lock);
  wakeup1(chan);
  release(&ptable.lock);
}

// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->pid == pid){
      p->killed = 1;
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
  return -1;
}

//PAGEBREAK: 36
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
  static char *states[] = {
  [UNUSED]    "unused",
  [EMBRYO]    "embryo",
  [SLEEPING]  "sleep ",
  [RUNNABLE]  "runble",
  [RUNNING]   "run   ",
  [ZOMBIE]    "zombie"
  };
  int i;
  struct proc *p;
  struct thread *t;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
	if(p->state == SLEEPING){
		for(t = p->threads; t < &p->threads[NTHREAD]; t++){
			if(t->state != T_FREE){
				getcallerpcs((uint*)t->context->ebp+2, pc);
			    for(i=0; i<10 && pc[i] != 0; i++){
					cprintf(" %p", pc[i]);
				}
				cprintf("\n");
			}
		}
    }
    cprintf("\n");
  }
}
