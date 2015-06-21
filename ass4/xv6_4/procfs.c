#include "procfs_helpers.h"

#define DE_SZ sizeof(struct dirent)
#define BUFFER_SIZE DE_SZ*(NPROC+2)

uint procinum = -1;

int 
procfsisdir(struct inode *ip) {
	// minor 0 -> /proc
	// minor 1 -> /proc/PID
	// minor 2 -> /proc/PID/fdinfo
	// minor 3 -> /proc/PID/fdinfo/{somefile}
	// in minor 2, some files are folders (fdinfo), and some are files
	return (ip->minor == 0 || ip->minor == 1 || (ip->minor == 2 && (ip->inum/100) == (FD_ENTRIES_PREFIX/100)));
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

	de.inum = inum - FDINFO_PREFIX;
	strncpy(de.name, "..", DIRSIZ);
	memmove(buf + DE_SZ, (char *)&de, DE_SZ);

	denum = 2;

	p = getProcByPtableLoc(inum - FD_ENTRIES_PREFIX);

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
		p = getProcByPtableLoc(i);

		if (p->state == UNUSED)
			continue;

		de.inum = BASE_INUM + i;
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
	int entryCount = 0;

	de.inum = inum;
	strncpy(de.name, ".", DIRSIZ);
	memmove(buf + DE_SZ*entryCount, (char *)&de, DE_SZ);
	entryCount++;

	de.inum = procinum;
	strncpy(de.name, "..", DIRSIZ);
	memmove(buf + DE_SZ*entryCount, (char *)&de, DE_SZ);
	entryCount++;

	p = getProcByPtableLoc(inum - BASE_INUM);

	if (p->state == UNUSED){
		return DE_SZ*entryCount;
	}

	if (p->cwd) {
		de.inum = p->cwd->inum;
		strncpy(de.name, "cwd", DIRSIZ);
		memmove(buf + DE_SZ*entryCount, (char *)&de, DE_SZ);
		entryCount++;
	}

	if (p->exe){
		de.inum = p->exe->inum;
		strncpy(de.name, "exe", DIRSIZ);
		memmove(buf + DE_SZ*entryCount, (char *)&de, DE_SZ);
		entryCount++;
	}

	de.inum = CMDLINE_PREFIX + inum;
	strncpy(de.name, "cmdline", DIRSIZ);
	memmove(buf + DE_SZ*entryCount, (char *)&de, DE_SZ);
	entryCount++;

	de.inum = STATUS_PREFIX + inum;
	strncpy(de.name, "status", DIRSIZ);
	memmove(buf + DE_SZ*entryCount, (char *)&de, DE_SZ);
	entryCount++;

	de.inum = FDINFO_PREFIX + inum;
	strncpy(de.name, "fdinfo", DIRSIZ);
	memmove(buf + DE_SZ*entryCount, (char *)&de, DE_SZ);
	entryCount++;

	return DE_SZ*entryCount;
}

void 
procfsiread(struct inode* dp, struct inode *ip) {
	if (ip->inum < BASE_INUM){
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
createLevel1Dir(struct inode *ip, char *buff){
	return createProcfsEntries(buff);
}

int
createLevel2Dir(struct inode *ip, char *buff){
	return createProcfsPerProcEntries(ip->inum, buff);
}

int
createLevel3Dir(struct inode *ip, char *buff){
	switch((ip->inum)/100) {
		case ((CMDLINE_PREFIX+BASE_INUM)/100):
			return addInfoAboutCMDLineToBuf(ip->inum, buff);
		case ((STATUS_PREFIX+BASE_INUM)/100):
			return addInfoAboutStatusToBuf(ip->inum, buff);
		case ((FDINFO_PREFIX+BASE_INUM)/100):
			return createProcfFDsEntries(ip->inum, buff);
	}
	return 0;
}

int
createLevel4Dir(struct inode *ip, char *buff){
	if (ip->inum >= (NOFILE*FD_ENTRIES_PREFIX) && ip->inum < ((NPROC+501)*NOFILE)) {
		return addInfoAboutFDToBuf(ip->inum, buff);
	}
	return 0;
}

int
procfsread(struct inode *ip, char *dst, int off, int n) {
	int size = 0;
	int temp;
	char buf[BUFFER_SIZE];

	// inode depth
	switch(ip->minor) {
		case 0:
			procinum = ip->inum;
			size = createLevel1Dir(ip, buf);
			break;
		case 1:
			size = createLevel2Dir(ip, buf);
			break;
		case 2:
			size = createLevel3Dir(ip, buf);
			break;
		case 3:
			size = createLevel4Dir(ip, buf);
			break;
		default:
			break;
	}

	if (off < size) {
		temp = size - off;
		if (n < temp){
			temp = n;
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
