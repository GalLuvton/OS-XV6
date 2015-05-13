#include "types.h"
#include "x86.h"
#include "defs.h"
#include "date.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "proc.h"
#include "kthread.h"

int
sys_fork(void)
{
  return fork();
}

int
sys_exit(void)
{
  exit();
  return 0;  // not reached
}

int
sys_wait(void)
{
  return wait();
}

int
sys_kill(void)
{
  int pid;

  if(argint(0, &pid) < 0)
    return -1;
  return kill(pid);
}

int
sys_getpid(void)
{
  struct proc *curProc = curThread->parent;
  return curProc->pid;
}

int
sys_sbrk(void)
{
  int addr;
  int n;
  struct proc *curProc = curThread->parent;

  if(argint(0, &n) < 0)
    return -1;
  addr = curProc->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

int
sys_sleep(void)
{
  int n;
  uint ticks0;
  struct proc *curProc = curThread->parent;
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(curProc->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
  uint xticks;
  
  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}


int
sys_kthread_create(void)
{
  void* start_func;
  void* stack;
  uint stack_size;
  int start_func_ph, stack_ph, stack_size_ph;
  
  if(argint(0, &start_func_ph) < 0)
    return -1;
  if(argint(1, &stack_ph) < 0)
    return -1;
  if(argint(2, &stack_size_ph) < 0)
    return -1;
  start_func = (void*) start_func_ph;
  stack = (void*) stack_ph;
  stack_size = (uint)stack_size_ph;
  
  return kthread_create(start_func, stack, stack_size);
}

int
sys_kthread_id(void)
{
  return kthread_id();
}

int
sys_kthread_exit(void)
{
  kthread_exit();
  return 0;  // not reached
}

int
sys_kthread_join(void)
{
  int id;
  
  if(argint(0, &id) < 0)
    return -1;

  return kthread_join(id);
}

int
sys_kthread_mutex_alloc(void)
{
  return kthread_mutex_alloc();
}

int
sys_kthread_mutex_dealloc(void)
{
  int id;
  
  if(argint(0, &id) < 0)
    return -1;

  return kthread_mutex_dealloc(id);
}

int
sys_kthread_mutex_lock(void)
{
  int id;
  
  if(argint(0, &id) < 0)
    return -1;

  return kthread_mutex_lock(id);
}

int
sys_kthread_mutex_unlock(void)
{
  int id;
  
  if(argint(0, &id) < 0)
    return -1;

  return kthread_mutex_unlock(id);
}

int
sys_kthread_mutex_yieldlock(void)
{
  int id1, id2;
  
  if(argint(0, &id1) < 0)
    return -1;
  if(argint(1, &id2) < 0)
    return -1;

  return kthread_mutex_yieldlock(id1, id2);
}
