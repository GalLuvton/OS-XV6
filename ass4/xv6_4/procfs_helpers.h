#include "types.h"
#include "stat.h"
#include "defs.h"
#include "param.h"
#include "traps.h"
#include "spinlock.h"
#include "fs.h"
#include "file.h"
#include "memlayout.h"
#include "mmu.h"
#include "proc.h"
#include "x86.h"

struct proc* getProcByID(int id);

void itoa(int x, char *buf);

char* getProcState(struct proc *p);

char* getTypeForFile(struct file *f);

int addInfoAboutFDToBuf(int inum, char *buf);

int addInfoAboutCMDLineToBuf(int inum, char *buf);

int addInfoAboutStatusToBuf(int inum, char *buf);
