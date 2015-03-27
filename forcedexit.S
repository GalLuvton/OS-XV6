# Context switch
#
#   void swtch(struct context **old, struct context *new);
# 
# Save current register context in old
# and then load register context from new.

#include "syscall.h"
#include "traps.h"

# Exec will copy this to every user process
.globl forcedexit_start
forcedexit_start:
  pushl %eax
  pushl $0
  movl $SYS_exit, %eax
  int $T_SYSCALL
.globl forcedexit_end
forcedexit_end: