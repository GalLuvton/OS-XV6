#include "types.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "x86.h"
#include "proc.h"
#include "spinlock.h"
#include "kthread.h"

struct {
  struct spinlock lock;
  struct proc proc[NPROC];
} ptable;

struct {
  struct spinlock lock;
  struct kthread_mutex_t mutexes[MAX_MUTEXES];
} mutable;

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

void
muinit(void)
{
  int id = 1;
  struct kthread_mutex_t *mutex;
  struct mu_block *oneBlock;
  
  for (mutex = mutable.mutexes; mutex < &mutable.mutexes[MAX_MUTEXES]; mutex++){
	mutex->id = id++;
	mutex->state = MU_FREE;
	for (oneBlock = mutex->waitingLine; oneBlock < &mutex->waitingLine[MUTEX_WAITING_SIZE]; oneBlock++){
		oneBlock->thread = 0;
		oneBlock->chan = oneBlock;
	}
  }

  initlock(&mutable.lock, "mutable");
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
  t = p->threads; // the first thread struct
  t->state = T_EMBRYO;
  t->tid = nexttid++;
  release(&ptable.lock);
  
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

void joinAllThreads(struct thread *thread){
	struct thread *t;
	struct proc *curProc = thread->parent;
	
	acquire(&ptable.lock);

	for(t = curProc->threads; t < &curProc->threads[NTHREAD]; t++){
		if ((t->state == T_RUNNING || t->state == T_RUNNABLE || t->state == T_SLEEPING) && t->tid != thread->tid){
			t->killed = 1;
			if (t->state == T_SLEEPING){
				t->state = T_RUNNABLE;
			}
		}
	}
	
	release(&ptable.lock);
	
	// wait on all threads to die
	for(t = curProc->threads; t < &curProc->threads[NTHREAD]; t++){
		if ((t->state == T_RUNNING || t->state == T_RUNNABLE || t->state == T_SLEEPING) && t->tid != thread->tid){
			kthread_join(t->tid);
		}
	}
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

	
  joinAllThreads(curThread);

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
				kfree(t->kstack);
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

	for (p = ptable.proc; p < &ptable.proc[NPROC]; p++){
		for (t = p->threads; t < &p->threads[NTHREAD]; t++){
			if (t->state == T_SLEEPING && t->chan == chan){
				t->state = T_RUNNABLE;
				//p->state = RUNNABLE;
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

int
kthread_create(void*(*start_func)(), void* stack, uint stack_size)
{
	char *sp;
	struct proc *curProc = curThread->parent;
	struct thread *t;
	
	if (stack_size > MAX_STACK_SIZE){
		return -1;
	}
	
	acquire(&ptable.lock);
	for(t = curProc->threads; t < &curProc->threads[NTHREAD]; t++){
		if (t->state == T_FREE){
			goto t_found;
		}
	}
	// no free threads
	release(&ptable.lock);
	return -1;
	
t_found:
	t->tid = nexttid++;
	
	// Allocate kernel stack.
	if((t->kstack = kalloc()) == 0){
		t->state = T_FREE;
		release(&ptable.lock);
		return -1;
	}
	
	sp = t->kstack + KSTACKSIZE;
	// Leave room for trap frame.
	sp -= sizeof *t->tf;
	t->tf = (struct trapframe*)sp;
	*t->tf = *curThread->tf;
	
	t->parent = curProc;
	t->chan = 0;
	t->killed = 0;

	// Set up new context to start executing at forkret,
	// which returns to trapret.
	sp -= 4;
	*(uint*)sp = (uint)trapret;

	sp -= sizeof *t->context;
	t->context = (struct context*)sp;
	memset(t->context, 0, sizeof *t->context);
	t->context->eip = (uint)forkret;
	
	t->tf->eip = (uint)start_func;
	t->tf->esp = (uint)stack + stack_size;
	
	t->state = T_RUNNABLE;
	release(&ptable.lock);

	return t->tid;
}

int
kthread_id(void)
{
	return curThread->tid;
}

void
kthread_exit(void)
{
	struct proc *curProc;
	struct thread *t;
	int amIAllAlone;

	acquire(&ptable.lock);

	// Parent might be sleeping in wait().
	wakeup1(curThread);

	amIAllAlone = 1;
	curProc = curThread->parent;
	for(t = curProc->threads; t < &curProc->threads[NTHREAD]; t++){
		if (t->tid != curThread->tid && t->state != T_FREE){
			amIAllAlone = 0;
			break;
		}
	}

	if (amIAllAlone){
		release(&ptable.lock);
		exit();
	}
	
	// Jump into the scheduler, never to return.
	curThread->state = T_ZOMBIE;
	sched();
	panic("zombie thread exit");
}

int
kthread_join(int thread_id)
{
	struct proc *curProc = curThread->parent;
	struct thread *t;
	int found;
	
	acquire(&ptable.lock);
	for(;;){
		// Scan through table looking for zombie children.
		found = 0;
		for(t = curProc->threads; t < &curProc->threads[NTHREAD]; t++){
			if (t->tid != thread_id){
				continue;
			}
			found = 1;
			if (t->state == T_ZOMBIE){
				// Found one.
				kfree(t->kstack);
				t->kstack = 0;
				t->tid = 0;
				t->parent = 0;
				t->tf = 0;
				t->context = 0;
				t->chan = 0;
				t->killed = 0;
				t->state = T_FREE;
				release(&ptable.lock);
				return 0;
			}
			break;
		}

		// No point waiting if this thread doesnt exist.
		if(!found || curThread->killed || curThread->parent->killed){
		  release(&ptable.lock);
		  return -1;
		}

		// Wait for thread to exit.  (See wakeup1 call in proc_exit.)
		sleep(t, &ptable.lock);  //DOC: wait-sleep
	}
}


int
checkRange(int mutex_id){
	return (mutex_id > 0 && mutex_id <= MAX_MUTEXES);
}


int
kthread_mutex_alloc(void){
	struct kthread_mutex_t *mutex;

	acquire(&mutable.lock);
	
	for (mutex = mutable.mutexes; mutex < &mutable.mutexes[MAX_MUTEXES]; mutex++){
		if (mutex->state == MU_FREE){
			goto mu_found;
		}
	}
	
	release(&mutable.lock);
	return -1;
  
mu_found:
	mutex->state = MU_UNLOCKED;
	release(&mutable.lock);
	return mutex->id;
}

int
kthread_mutex_dealloc(int mutex_id){
	struct kthread_mutex_t *mutex;

	if (!checkRange(mutex_id)){
		return -1;
	}
	
	acquire(&mutable.lock);
	
	for (mutex = mutable.mutexes; mutex < &mutable.mutexes[MAX_MUTEXES]; mutex++){
		if (mutex->id == mutex_id){
			break;
		}
	}

	if (mutex->state != MU_UNLOCKED){
		release(&mutable.lock);
		return -1;
	}
	mutex->state = MU_FREE;
	
	release(&mutable.lock);
	return 0;
}

int
kthread_mutex_lock(int mutex_id){
	struct kthread_mutex_t *mutex;
	struct mu_block *oneBlock;
	
	if (!checkRange(mutex_id)){
		return -1;
	}
	
	acquire(&mutable.lock);

	for (mutex = mutable.mutexes; mutex < &mutable.mutexes[MAX_MUTEXES]; mutex++){
		if (mutex->id == mutex_id){
			break;
		}
	}
	
	for (oneBlock = mutex->waitingLine; oneBlock < &mutex->waitingLine[MUTEX_WAITING_SIZE]; oneBlock++){
		if (oneBlock->thread == 0){
			break;
		}
	}
	
	if (mutex->state == MU_FREE){
		release(&mutable.lock);
		return -1;
	}
	
	oneBlock->thread = curThread;
	
	if (mutex->state == MU_LOCKED){
		sleep(oneBlock->chan, &mutable.lock);
	}

	mutex->state = MU_LOCKED;
	release(&mutable.lock);

	return 0;
}

int
kthread_mutex_unlock1(int mutex_id){
	struct kthread_mutex_t *mutex;
	void *oneBlockChan;
	int i;

	if (!checkRange(mutex_id)){
		return -1;
	}

	for (mutex = mutable.mutexes; mutex < &mutable.mutexes[MAX_MUTEXES]; mutex++){
		if (mutex->id == mutex_id){
			break;
		}
	}

	if (mutex->state != MU_LOCKED){
		return -1;
	}
	
	oneBlockChan = mutex->waitingLine[0].chan;
	for (i = 1; i < MUTEX_WAITING_SIZE; i++){
		mutex->waitingLine[i-1].thread = mutex->waitingLine[i].thread;
		mutex->waitingLine[i-1].chan = mutex->waitingLine[i].chan;
	}
	mutex->waitingLine[MUTEX_WAITING_SIZE-1].thread = 0;
	mutex->waitingLine[MUTEX_WAITING_SIZE-1].chan = oneBlockChan;
	
	if (mutex->waitingLine[0].thread == 0){
		mutex->state = MU_UNLOCKED;
		return 0;
	}

	wakeup(mutex->waitingLine[0].chan);

	return 0;
}

int
kthread_mutex_unlock(int mutex_id){
	int ans;
	
	acquire(&mutable.lock);
	ans = kthread_mutex_unlock1(mutex_id);
	release(&mutable.lock);

	return ans;
}

int
kthread_mutex_yieldlock(int mutex_id1, int mutex_id2){
	struct kthread_mutex_t *mutex1;
	struct kthread_mutex_t *mutex2;

	if (!checkRange(mutex_id1) || !checkRange(mutex_id2)){
		return -1;
	}
	
	acquire(&mutable.lock);
	
	for (mutex1 = mutable.mutexes; mutex1 < &mutable.mutexes[MAX_MUTEXES]; mutex1++){
		if (mutex1->id == mutex_id1){
			break;
		}
	}
	
	if (mutex1->state != MU_LOCKED){
		release(&mutable.lock);
		return -1;
	}
	
	for (mutex2 = mutable.mutexes; mutex2 < &mutable.mutexes[MAX_MUTEXES]; mutex2++){
		if (mutex2->id == mutex_id2){
			break;
		}
	}
	
	if (mutex2->state == MU_FREE){
		release(&mutable.lock);
		return -1;
	}
	
	
	kthread_mutex_unlock1(mutex2->id);
	
	if (mutex2->waitingLine[0].thread == 0){
		kthread_mutex_unlock1(mutex1->id);
	}
	else{
		mutex1->waitingLine[0].thread = mutex2->waitingLine[0].thread;
	}

	release(&mutable.lock);
	return 0;
}

/* helper systemcalls */
void
top(void){
	struct proc *p;
	struct thread *t;

	acquire(&ptable.lock);

	for (p = ptable.proc; p < &ptable.proc[NPROC]; p++){
		if (p->state != RUNNABLE){
			continue;
		}
		cprintf("proc %d(%s):\n", p->pid, p->name);
		for(t = p->threads; t < &p->threads[NTHREAD]; t++){
			if (t->state == T_FREE){
				continue;
			}
			switch(t->state){
				case T_RUNNING:
				cprintf("	thread %d: RUNNING\n", t->tid);
				break;
				case T_RUNNABLE:
				cprintf("	thread %d: RUNNABLE\n", t->tid);
				break;
				case T_SLEEPING:
				cprintf("	thread %d: SLEEPING\n", t->tid);
				break;
				case T_ZOMBIE:
				cprintf("	thread %d: ZOMBIE\n", t->tid);
				break;
				default:
				cprintf("	thread %d: WUT?!\n", t->tid);
			}
		}
	}
	
	release(&ptable.lock);
}

void
mu_top(void){
	struct kthread_mutex_t *mutex;
	struct mu_block *oneBlock;
	struct thread *thread;
	
	acquire(&mutable.lock);

	for (mutex = mutable.mutexes; mutex < &mutable.mutexes[MAX_MUTEXES]; mutex++){
		if (mutex->state != MU_FREE){
			cprintf("mutex %d: ", mutex->id);
			if (mutex->state == MU_UNLOCKED){
				cprintf("UNLOCKED\n");
				continue;
			}
			thread = mutex->waitingLine[0].thread;
			if (thread == 0){
				cprintf("LOCKED with thread==0! Something went wrong! unlocking mutex\n");
				kthread_mutex_unlock1(mutex->id);
				continue;
			}
			cprintf("LOCKED by thread %d in proc %d(%s):\n", thread->tid, thread->parent->pid, thread->parent->name);
			cprintf("	");
			for (oneBlock = mutex->waitingLine; oneBlock < &mutex->waitingLine[MUTEX_WAITING_SIZE]; oneBlock++){
				if (oneBlock->thread == 0){
					break;
				}
				cprintf("thread %d; ", oneBlock->thread->tid);
			}
			cprintf("\n");
		}
	}
	
	release(&mutable.lock);
}