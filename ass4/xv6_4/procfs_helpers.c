#include "procfs_helpers.h"


extern struct {
  struct spinlock lock;
  struct proc proc[NPROC];
} ptable;

struct proc*
getProcByID(int id)
{
	struct proc *p;
	
	for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
		if ((p->state != UNUSED) && (p->pid == id)){
			break;
		}
	}
	return p;
}

char*
getProcState(struct proc *p)
{
	static char *states[] = {
	[UNUSED]    "unused",
	[EMBRYO]    "embryo",
	[SLEEPING]  "sleep ",
	[RUNNABLE]  "runble",
	[RUNNING]   "run   ",
	[ZOMBIE]    "zombie"
	};

	if(p->state >= 0 && p->state < NELEM(states) && states[p->state]){
		return states[p->state];
	}
	return "undef ";
}

char*
getTypeForFile(struct file *f)
{
	static char *fdNames[] = {
	[FD_NONE]    "unused",
	[FD_PIPE]    "pipe",
	[FD_INODE]   "inode",
	};

	if(f->type >= 0 && f->type < NELEM(fdNames) && fdNames[f->type]){
		return fdNames[f->type];
	}
	return "undef";
}

char*
getReadFlagsForFile(struct file *f)
{
	if(f->readable == 0){
		return "non-readable";
	}
	return "readable";
}

char*
getWriteFlagsForFile(struct file *f)
{
	if(f->writable == 0){
		return "non-writeable";
	}
	return "writeable";
}

void
itoa(int x, char *buf)
{
	static char digits[] = "0123456789";
	int i = 0;
	char tmp;

	do{
		buf[i++] = digits[x % 10];
	}while((x /= 10) != 0);
	buf[i] = '\0';

	for (i = 0; i < strlen(buf) / 2; i++) {
		tmp = buf[i];
		buf[i] = buf[strlen(buf) - i - 1];
		buf[strlen(buf) - i - 1] = tmp;
	}
}

int
addInfoAboutFDToBuf(int inum, char *buf) {
	struct proc *p;
	int fd;
	char* temp;

	p = getProcByID(inum / NOFILE - 500);

	fd = inum % NOFILE;

	strncpy(buf, "Type- ", strlen("Type- ") + 1);
	strncpy(buf + strlen(buf), getTypeForFile(p->ofile[fd]), strlen(getTypeForFile(p->ofile[fd])) + 1);
	if (p->ofile[fd]->type == FD_INODE) {
		strncpy(buf + strlen(buf), " (", strlen(" (") + 1);
		itoa(p->ofile[fd]->ip->inum, buf + strlen(buf));
		strncpy(buf + strlen(buf), ")", strlen(")") + 1);
	}
	strncpy(buf + strlen(buf), "\n", strlen("\n") + 1);
	strncpy(buf + strlen(buf), "Offset- ", strlen("Offset- ") + 1);
	itoa(p->ofile[fd]->off, buf + strlen(buf));
	strncpy(buf + strlen(buf), "\n", strlen("\n") + 1);
	strncpy(buf + strlen(buf), "Flags- ", strlen("Flags- ") + 1);
	strncpy(buf + strlen(buf), "\n", strlen("\n") + 1);
	strncpy(buf + strlen(buf), "Read- ", strlen("Read- ") + 1);
	temp = getReadFlagsForFile(p->ofile[fd]);
	strncpy(buf + strlen(buf), temp, strlen(temp) + 1);
	strncpy(buf + strlen(buf), "\n", strlen("\n") + 1);
	strncpy(buf + strlen(buf), "Write- ", strlen("Write- ") + 1);
	temp = getWriteFlagsForFile(p->ofile[fd]);
	strncpy(buf + strlen(buf), temp, strlen(temp) + 1);
	strncpy(buf + strlen(buf), "\n", strlen("\n") + 1);

	return strlen(buf);	
}

int
addInfoAboutCMDLineToBuf(int inum, char *buf) {
	int i;
	struct proc *p;

	p = getProcByID(inum - 300);
	
	strncpy(buf, "Cmdline- ", strlen("Cmdline- ") + 1);
	strncpy(buf + strlen(buf), p->path, strlen(p->path) + 1);
	for (i = 0; i < p->argc; i++) {
		strncpy(buf + strlen(buf), " ", strlen(" ") + 1);
		strncpy(buf + strlen(buf), p->argv[i], strlen(p->argv[i]) + 1);
	}
	strncpy(buf + strlen(buf), "\n", strlen("\n") + 1);
	return strlen(buf);
}

int
addInfoAboutStatusToBuf(int inum, char *buf) {	
	struct proc *p;	
	char b[100];

	p = getProcByID(inum - 400);

	strncpy(buf, "Status: ", strlen("Status: ") + 1);
	strncpy(buf + strlen(buf), getProcState(p), strlen(getProcState(p)) + 1);	
	strncpy(buf + strlen(buf), "\nSize: ", strlen("\nSize: ") + 1);
	itoa(p->sz, b);
	strncpy(buf + strlen(buf), b, strlen(b) + 1);
	strncpy(buf + strlen(buf), "\n", strlen("\n") + 1);

	return strlen(buf);
}
