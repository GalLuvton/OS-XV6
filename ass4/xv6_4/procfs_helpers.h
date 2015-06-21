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

#define BASE_INUM 200
#define CMDLINE_PREFIX 100
#define STATUS_PREFIX 200
#define FDINFO_PREFIX 300
#define FD_ENTRIES_PREFIX 500

struct proc* getProcByPtableLoc(int id);

void itoa(int x, char *buf);

char* getProcState(struct proc *p);

char* getTypeForFile(struct file *f);

int addInfoAboutFDToBuf(int inum, char *buf);

int addInfoAboutCMDLineToBuf(int inum, char *buf);

int addInfoAboutStatusToBuf(int inum, char *buf);
