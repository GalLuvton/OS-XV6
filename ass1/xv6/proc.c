#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "x86.h"
#include "proc.h"
#include "spinlock.h"

// runtime variable to count how many times till QUANTA
#if defined(_policy_FRR) || defined(_policy_DEFAULT) || defined(_policy_CFS)
int runtime;
#endif

#if defined(_policy_FRR) || defined(_policy_FCFS)
int  pop();
void push(int pid);
#endif

#if defined(_policy_CFS)
int set_priority(int priority);
#endif

static const char* S_EMBRYO = "Embryo";
static const char* S_SLEEPING = "Sleeping";
static const char* S_RUNNABLE = "Runnable";
static const char* S_RUNNING = "Running";
static const char* S_ZOMBIE = "Zombie";

struct {
  struct spinlock lock;
  struct proc proc[NPROC];
  #if defined(_policy_FRR) || defined(_policy_FCFS)
    int  fifoPIDQueue[NPROC];
    int  firstPos;		// first position containing a meaningful value
	int  lastPos;		// first position not containing a meaningful value
	int  isFull;		// states if the array is full
  #endif
} ptable;

static struct proc *initproc;

int nextpid = 1;
extern void forkret(void);
extern void trapret(void);

static void wakeup1(void *chan);

void
pinit(void)
{
  initlock(&ptable.lock, "ptable");
  #if defined(_policy_FRR) || defined(_policy_FCFS)
	ptable.firstPos = -1;
	ptable.lastPos = 0;
	ptable.isFull = 0;
  #endif
}

void updateProcRelatedTimers() {
  struct proc *p;
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++) {
    switch(p->state){
		case SLEEPING:
		p->stime++;
		break;
		case RUNNABLE:
		p->retime++;
		break;
		case RUNNING:
		p->rutime++;
		break;
		default:
		break;
	}
  }
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
  p->exitStatus = 0;
  p->killed = 0;
  p->ctime = ticks;
  p->ttime = 0;
  p->stime = 0;
  p->retime = 0;
  p->rutime = 0;
  p->jobID = 0;
  #if defined(_policy_CFS)
  p->priority = MEDIUM;
  #endif
  release(&ptable.lock);

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
    p->state = UNUSED;
    return 0;
  }
  sp = p->kstack + KSTACKSIZE;
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
  p->tf = (struct trapframe*)sp;
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
  *(uint*)sp = (uint)trapret;

  sp -= sizeof *p->context;
  p->context = (struct context*)sp;
  memset(p->context, 0, sizeof *p->context);
  p->context->eip = (uint)forkret;

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
  memset(p->tf, 0, sizeof(*p->tf));
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
  p->tf->es = p->tf->ds;
  p->tf->ss = p->tf->ds;
  p->tf->eflags = FL_IF;
  p->tf->esp = PGSIZE;
  p->tf->eip = 0;  // beginning of initcode.S

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");
  p->jobID = 0;

  p->state = RUNNABLE;
  #if defined(_policy_FRR) || defined(_policy_FCFS)
	push(p->pid);
  #endif
}

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  uint sz;
  
  sz = proc->sz;
  if(n > 0){
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
      return -1;
  } else if(n < 0){
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
      return -1;
  }
  proc->sz = sz;
  switchuvm(proc);
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

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
    kfree(np->kstack);
    np->kstack = 0;
    np->state = UNUSED;
    return -1;
  }
  np->sz = proc->sz;
  np->parent = proc;
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);

  safestrcpy(np->name, proc->name, sizeof(proc->name));
 
  pid = np->pid;
  np->ctime = ticks;
  np->jobID = proc->jobID;
  #if defined(_policy_CFS)
  np->priority = proc->priority;
  #endif
  
  // lock to force the compiler to emit the np->state write last.
  acquire(&ptable.lock);
  np->state = RUNNABLE;
  #if defined(_policy_FRR) || defined(_policy_FCFS)
	push(pid);
  #endif
  release(&ptable.lock);
  
  return pid;
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(int status)
{
  struct proc *p;
  int fd;
  
  if(proc == initproc)
    panic("init exiting");

  // set exit status
  proc->exitStatus= status;
	
  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
    if(proc->ofile[fd]){
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(proc->cwd);
  end_op();
  proc->cwd = 0;

  acquire(&ptable.lock);

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->parent == proc){
      p->parent = initproc;
      if(p->state == ZOMBIE)
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
  proc->ttime = ticks;
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(int *status)
{
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
      havekids = 1;
      if(p->state == ZOMBIE){
        // Found one.
		if (status){
			*status= p->exitStatus;
		}
	
        pid = p->pid;
        kfree(p->kstack);
        p->kstack = 0;
        freevm(p->pgdir);
        p->state = UNUSED;
        p->pid = 0;
        p->parent = 0;
        p->name[0] = 0;
        p->killed = 0;
		p->exitStatus = 0;
		p->ctime = 0;
		p->ttime = 0;
		p->stime = 0;
		p->retime = 0;
		p->rutime = 0;
		p->jobID = 0;
        release(&ptable.lock);
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
      release(&ptable.lock);
      return -1;
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
  }
}

// Wait for a process with pid of 'pid' to exit and return its pid.
int
waitpid(int pid, int *status, int options)
{
  struct proc *p;
  int pidExists;

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie processes.
	pidExists= 0;
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if (p->pid != pid){
		continue;
	  }
      pidExists= 1;
      if (p->state == ZOMBIE){
		// Found the proc.
		if (status != 0){
			*status= p->exitStatus;
		}

		kfree(p->kstack);
		p->kstack = 0;
		freevm(p->pgdir);
		p->state = UNUSED;
		p->pid = 0;
		p->parent = 0;
		p->name[0] = 0;
		p->killed = 0;
		p->exitStatus = 0;
		p->ctime = 0;
		p->ttime = 0;
		p->stime = 0;
		p->retime = 0;
		p->rutime = 0;
		p->jobID = 0;
		release(&ptable.lock);
		return pid;
	  }
	  break;
    }

	// if NONBLOCKING flag is on, do not wait for the process.
    // No point waiting if we are killed.
    if(!pidExists || (options == NONBLOCKING) || proc->killed){
      release(&ptable.lock);
      return -1;
    }

	if (p->parent->pid == proc->pid){
		// Wait for children to exit.  (See wakeup1 call in proc_exit.)
		sleep(proc, &ptable.lock);  //DOC: wait-sleep
	} else {
		release(&ptable.lock);
		yield();
		acquire(&ptable.lock);
	}
  }
}

int
wait_stat(int *wtime, int *rtime, int *iotime, int *status)
{
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
      havekids = 1;
      if(p->state == ZOMBIE){
        // Found one.
		if (status != 0){
			*status= p->exitStatus;
		}
		*wtime= p->retime;
		*rtime= p->rutime;
		*iotime= p->stime;
	
        pid = p->pid;
        kfree(p->kstack);
        p->kstack = 0;
        freevm(p->pgdir);
        p->state = UNUSED;
        p->pid = 0;
        p->parent = 0;
        p->name[0] = 0;
        p->killed = 0;
		p->exitStatus = 0;
		p->ctime = 0;
		p->ttime = 0;
		p->stime = 0;
		p->retime = 0;
		p->rutime = 0;
		p->jobID = 0;
        release(&ptable.lock);
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
      release(&ptable.lock);
      return -1;
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
  }
}

int
wait_jobid(int jobid)
{
  struct proc *p;
  int found, foundAlive=-1;

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for the job.
    found = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->jobID != jobid)
        continue;
      found = 1;
      if(p->state == ZOMBIE){
        // Found one.
        kfree(p->kstack);
        p->kstack = 0;
        freevm(p->pgdir);
        p->state = UNUSED;
        p->pid = 0;
        p->parent = 0;
        p->name[0] = 0;
        p->killed = 0;
		p->exitStatus = 0;
		p->ctime = 0;
		p->ttime = 0;
		p->stime = 0;
		p->retime = 0;
		p->rutime = 0;
		p->jobID = 0;
      } else {
		foundAlive=0;
	  }
	  break;
    }

    // No point waiting if we don't have any processes in this job.
    if(!found || proc->killed){
      release(&ptable.lock);
      return foundAlive;
    }

	if (p->parent->pid == proc->pid){
		// Wait for children to exit.  (See wakeup1 call in proc_exit.)
		sleep(proc, &ptable.lock);  //DOC: wait-sleep
	} else {
		release(&ptable.lock);
		yield();
		acquire(&ptable.lock);
	}
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
  #if defined(_policy_DEFAULT)
    for(;;){
        // Enable interrupts on this processor.
        sti();
        // Loop over process table looking for process to run.
        acquire(&ptable.lock);
        for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
			if(p->state != RUNNABLE)
				continue;
			// Switch to chosen process.  It is the process's job
			// to release ptable.lock and then reacquire it
			// before jumping back to us.
			proc = p;
			switchuvm(p);
			p->state = RUNNING;
			swtch(&cpu->scheduler, proc->context);
			switchkvm();

			// Process is done running for now.
			// It should have changed its p->state before coming back.
			proc = 0;
        }
        release(&ptable.lock);
    }
  #elif defined(_policy_FRR) || defined(_policy_FCFS)
    for(;;){
        // Enable interrupts on this processor.
        sti();

        acquire(&ptable.lock);
		// Get the next process to run.

		int nextProc;
		
		nextProc = pop();
		for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
            // Check if pid is the current pid in the top of the queue
			if(nextProc != p->pid)
                continue;
			
			if (p->state != RUNNABLE){
				panic("process in queue is not RUNNABLE!");
			}
            // Switch to chosen process.  It is the process's job
            // to release ptable.lock and then reacquire it
            // before jumping back to us.
            proc = p;
            switchuvm(p);
            p->state = RUNNING;
            swtch(&cpu->scheduler, proc->context);
            switchkvm();
            // Process is done running for now.
            // It should have changed its p->state before coming back.
            proc = 0;
        }
        release(&ptable.lock);
    }
  #elif defined(_policy_CFS)
	struct proc *nextProc = 0;
    for(;;){
        // Enable interrupts on this processor.
        sti();

        acquire(&ptable.lock);
		// Get the next process to run.
        for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
			if(p->state != RUNNABLE)
				continue;
				
            if (nextProc == 0){
				nextProc = p;
			}
			else {
				if ((p->rutime * p->priority) < (nextProc->rutime * nextProc->priority)){
					nextProc = p;
				}
			}
        }
		if (nextProc){
			// Switch to chosen process.  It is the process's job
			// to release ptable.lock and then reacquire it
			// before jumping back to us.
			proc = nextProc;
			switchuvm(nextProc);
			nextProc->state = RUNNING;
			swtch(&cpu->scheduler, proc->context);
			switchkvm();
			// Process is done running for now.
			// It should have changed its p->state before coming back.
			proc = 0;
			nextProc = 0;
		}
		release(&ptable.lock);
    }
  #endif
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
  if(proc->state == RUNNING)
    panic("sched running");
  if(readeflags()&FL_IF)
    panic("sched interruptible");
  intena = cpu->intena;
  swtch(&proc->context, cpu->scheduler);
  cpu->intena = intena;
}

// Give up the CPU for one scheduling round.
void
yield(void)
{
  acquire(&ptable.lock);  //DOC: yieldlock
  proc->state = RUNNABLE;
  #if defined(_policy_FRR) || defined(_policy_DEFAULT)
	runtime = 0;
  #endif
  #if defined(_policy_FRR) || defined(_policy_FCFS)
	push(proc->pid);
  #endif
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
  if(proc == 0)
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
  proc->chan = chan;
  proc->state = SLEEPING;
  sched();

  // Tidy up.
  proc->chan = 0;

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

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == SLEEPING && p->chan == chan){
      p->state = RUNNABLE;
	  #if defined(_policy_FRR) || defined(_policy_FCFS)
		push(p->pid);
	  #endif
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
      if(p->state == SLEEPING){
        p->state = RUNNABLE;
		#if defined(_policy_FRR) || defined(_policy_FCFS)
		  push(p->pid);
	    #endif
	  }
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
  return -1;
}

int
set_priority(int priority)
{
	#if defined(_policy_CFS)
	int oldPriority;
	
	acquire(&ptable.lock);
	oldPriority = proc->priority;
	proc->priority = priority;
	release(&ptable.lock);
	return oldPriority;
	#else
	panic("set_priority called while not in CFS mode!");
	#endif
}

int
set_jobID(void)
{
	acquire(&ptable.lock);
	proc->jobID = proc->pid;
	release(&ptable.lock);
	return proc->jobID;
}

int
print_jobID(int jobID, char *command)
{
	struct proc *p;
	int found= -1;
  
	for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(((p->state == SLEEPING) || (p->state == RUNNABLE) || (p->state == RUNNING)) &&
		  (p->jobID == jobID) && (!(p->name[0] == 's' && p->name[1] == 'h' && p->name[2] == 0))){
        // Found one.
		if (found == -1){
			cprintf("Job %d: %s\n", jobID, command);
			found = 0;
		}
        cprintf("%d: %s\n", p->pid, p->name);
      }
    }
	return found;
}

void
top(void){
	struct proc *p;
	const char *state;
	
	cprintf("Format: pid ; name ; jobid ; state\n");
	for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
		switch (p->state){
		case EMBRYO:
			state = S_EMBRYO;
		break;
		case SLEEPING:
			state = S_SLEEPING;
		break;
		case RUNNABLE:
			state = S_RUNNABLE;
		break;
		case RUNNING:
			state = S_RUNNING;
		break;
		case ZOMBIE:
			state = S_ZOMBIE;
		break;
		default:
		continue;
		}
		cprintf("%d ; %s ; %d ; %s\n", p->pid, p->name, p->jobID, state);
	}
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
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
	////////////////////////////////
	cprintf("ctime %d; ttime %d; stime %d; retime %d; rutime %d\n", p->ctime, p->ttime, p->stime, p->retime, p->rutime);
	////////////////////////////////
  }
}

#if defined(_policy_FRR) || defined(_policy_FCFS)
/*
 * QUEUE MANIPULATION FUNCTIONS
 */

// pops the first item in queue, and return it
int
pop(void)
{
    int firstPid;
	
	if ((ptable.firstPos == ptable.lastPos) && !ptable.isFull){
		//panic("proc.c:pop: nothing to pop!");
		return -1;
	}
	firstPid = ptable.fifoPIDQueue[ptable.firstPos];
	ptable.firstPos++;
	if (ptable.firstPos >= NPROC){
		ptable.firstPos = 0;
	}
	if (ptable.isFull != 0){
		ptable.isFull = 0;
	}
	
	return firstPid;
}

// push the given PID to the queue
void
push(int pid)
{
	if (ptable.isFull){
		panic("proc.c:push: queue is full!");
	}
	if (ptable.firstPos == -1){
		ptable.firstPos = 0;
	}
    ptable.fifoPIDQueue[ptable.lastPos] = pid;
	ptable.lastPos++;
	if (ptable.lastPos >= NPROC){
		ptable.lastPos = 0;
	}
	if (ptable.firstPos == ptable.lastPos){
		ptable.isFull = 1;
	}
}
#endif
