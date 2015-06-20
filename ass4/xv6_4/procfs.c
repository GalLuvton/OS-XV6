#include "procfs_helpers.h"

#define DE_SZ sizeof(struct dirent)
#define BUFFER_SIZE DE_SZ*(NPROC+2)
#define BASE_INUM 300

uint procinum = -1;

int 
procfsisdir(struct inode *ip) {
	// minor 0 -> /proc
	// minor 1 -> /proc/PID
	// minor 2 -> /proc/PID/{somefile}
	// in minor 2, some files are folders (fdinfo), and some are files
	return (ip->minor == 0 || ip->minor == 1 || (ip->minor == 2 && ip->inum / 100 == 5));
}

// creates the /proc/PID/fdinfo folder info
int
createProcfFDsEntries(int inum, char *buf) {
	int denum, i;
	struct proc *p;	
	struct dirent de;

	de.inum = inum;
	strncpy(de.name, ".", DIRSIZ);
	memmove(buf, (char *)&de, DE_SZ);

	de.inum = inum - 300;
	strncpy(de.name, "..", DIRSIZ);
	memmove(buf + DE_SZ, (char *)&de, DE_SZ);

	denum = 2;

	#if defined(TEST)
	p = &ptable.proc[inum - 500];
	#else
	p = getProcByID(inum - 500);
	#endif

	for (i = 0; i < NOFILE; i++) {
		if (p->ofile[i] == FD_NONE)
			continue;
		de.inum = inum * NOFILE + i;
		itoa(i, de.name);
		memmove(buf + DE_SZ * denum++, (char *)&de, DE_SZ);	
	}

	return DE_SZ * denum;
}

// creates the /proc folder info
int
createProcfsEntries(char *buf) {
	int denum, i;
	struct dirent de;
	struct proc *p;

	de.inum = procinum;
	strncpy(de.name, ".", DIRSIZ);
	memmove(buf, (char *)&de, DE_SZ);

	de.inum = ROOTINO;
	strncpy(de.name, "..", DIRSIZ);
	memmove(buf + DE_SZ, (char *)&de, DE_SZ);

	denum = 2;

	for (i = 0; i < NPROC; i++) {
		p = getProcByID(i);

		if (p->state == UNUSED)
			continue;

		de.inum = 200 + i;
		itoa(p->pid, de.name);
		memmove(buf + DE_SZ * denum++, (char *)&de, DE_SZ);
	}

	return denum * DE_SZ;
}

// creates the /proc/PID folder info
int
createProcfsPerProcEntries(int inum, char *buf) {
	struct proc *p;	
	struct dirent de;

	de.inum = inum;
	strncpy(de.name, ".", DIRSIZ);
	memmove(buf, (char *)&de, DE_SZ);

	de.inum = procinum;
	strncpy(de.name, "..", DIRSIZ);
	memmove(buf + DE_SZ, (char *)&de, DE_SZ);

	p = getProcByID(inum - 200);

	if (p->state == UNUSED)
		return DE_SZ * 2;

	if (p->cwd) {
		de.inum = p->cwd->inum;
	strncpy(de.name, "cwd", DIRSIZ);
	memmove(buf + DE_SZ * 2, (char *)&de, DE_SZ);	
	}

	if (p->exe)
		de.inum = p->exe->inum;
	strncpy(de.name, "exe", DIRSIZ);
	memmove(buf + DE_SZ * 3, (char *)&de, DE_SZ);	

	de.inum = 100 + inum;
	strncpy(de.name, "cmdline", DIRSIZ);
	memmove(buf + DE_SZ * 4, (char *)&de, DE_SZ);

	de.inum = 200 + inum;
	strncpy(de.name, "status", DIRSIZ);
	memmove(buf + DE_SZ * 5, (char *)&de, DE_SZ);

	de.inum = 300 + inum;
	strncpy(de.name, "fdinfo", DIRSIZ);
	memmove(buf + DE_SZ * 6, (char *)&de, DE_SZ);

	return DE_SZ * 7;
}

void 
procfsiread(struct inode* dp, struct inode *ip) {
	if (ip->inum < 200){
		return;
	}
	ip->type = T_DEV;
	ip->major = PROCFS;
	if (dp->inum < ip->inum){
		ip->minor =  dp->minor + 1;
	} else {
		ip->minor = dp->minor - 1;
	}
	ip->size = 0;
	ip->nlink = 1;	
    ip->flags = I_VALID;
}


int
procfsread(struct inode *ip, char *dst, int off, int n) {
	int size = 0;
	int temp;
	char buf[BUFFER_SIZE];

	switch(ip->minor) {
	case 0:
		procinum = ip->inum;
		size = createProcfsEntries(buf);
		break;
	case 1:
		size = createProcfsPerProcEntries(ip->inum, buf);
		break;
	case 2:
		switch(ip->inum / 100) {
			case 3:
				size = addInfoAboutCMDLineToBuf(ip->inum, buf);
				break;
			case 4:
				size = addInfoAboutStatusToBuf(ip->inum, buf);
				break;
			case 5:
				size = createProcfFDsEntries(ip->inum, buf);
				break;
		}
		break;
	case 3:
		if (ip->inum >= 500 * NOFILE && ip->inum < (501 + NPROC) * NOFILE) {
			size = addInfoAboutFDToBuf(ip->inum, buf);
		}
		break;
	}

	if (off < size) {
		temp = size - off;
		if (n < temp){
			temp = n;
		} else {
			temp = temp;
		}
		memmove(dst, buf + off, temp);
		return temp;
	}
	return 0;
}

int
procfswrite(struct inode *ip, char *buf, int n) {
	return 0;
}

void
procfsinit(void)
{
  devsw[PROCFS].isdir = procfsisdir;
  devsw[PROCFS].iread = procfsiread;
  devsw[PROCFS].write = procfswrite;
  devsw[PROCFS].read = procfsread;
}
