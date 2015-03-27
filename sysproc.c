#include "types.h"
#include "x86.h"
#include "defs.h"
#include "date.h"
#include "param.h"
#include "memlayout.h"
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
  return fork();
}

int
sys_exit(void)
{
  int status;

  if(argint(0, &status) < 0)
    return -1;
  
  exit(status);
  // never gets here
  return -1;
}

int
sys_wait(void)
{
  int statusPh;
  int *status;
  
  if(argint(0, &statusPh) < 0)
    return -1;
  status= (int*)statusPh;
  return wait(status);
}

int
sys_waitpid(void)
{
  int pid, options, statusPh;
  int *status;

  if(argint(0, &pid) < 0)
    return -1;
  if(argint(1, &statusPh) < 0)
    return -1;
  if(argint(2, &options) < 0)
    return -1;
  status= (int*)statusPh;
  return waitpid(pid, status, options);
}

int
sys_wait_stat(void)
{
  int wtimePh, rtimePh, iotimePh;
  int *wtime, *rtime, *iotime;

  if(argint(0, &wtimePh) < 0)
    return -1;
  if(argint(1, &rtimePh) < 0)
    return -1;
  if(argint(2, &iotimePh) < 0)
    return -1;
  wtime= (int*)wtimePh;
  rtime= (int*)rtimePh;
  iotime= (int*)iotimePh;
  return wait_stat(wtime, rtime, iotime);
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
  return proc->pid;
}

int
sys_sbrk(void)
{
  int addr;
  int n;

  if(argint(0, &n) < 0)
    return -1;
  addr = proc->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

int
sys_sleep(void)
{
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(proc->killed){
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
