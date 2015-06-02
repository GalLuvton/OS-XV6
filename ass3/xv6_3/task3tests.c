#include "param.h"
#include "types.h"
#include "stat.h"
#include "user.h"
#include "syscall.h"
#include "memlayout.h"

#define PAGE_SIZE 4096
#define INFINITY_AND_BEYOND 100000

void
stackOverflow(){
	stackOverflow();
}

void
allocToTheMoon(){
	char* addr;
	
	printf(1, "testing allocToTheMoon\n");
	if (fork() == 0){
		addr = (char*)2;
		while (addr > 0){
			addr = malloc(PAGE_SIZE*INFINITY_AND_BEYOND);
		}
		exit();
	}
	wait();
	printf(1, "allocToTheMoon ok!\n");
}

void
hugeAlloc(){
	char* addr;
	
	printf(1, "testing hugeAlloc\n");
	addr = malloc(PAGE_SIZE*100);
	*addr = 'a';
	*(addr + 60) = 'b';
	*(addr + 7000) = 'c';
	
	printf(1, "*addr = %d\n", *addr);
	printf(1, "*(addr + 50) = %d\n", *(addr + 50));
	printf(1, "*(addr + 6666) = %d\n", *(addr + 6666));
	free(addr);
	printf(1, "hugeAlloc ok!\n");
}

void
invalidMemAccess(){
	char* a;
	
	printf(1, "testing invalidMemAccess\n");
	if (fork() == 0){
		for(a = (char*)(KERNBASE); a < (char*) (KERNBASE+2000000); a += 50000){
			printf(1, "oops could read %x = %x\n", a, *a);
			exit();
		}
	}
	wait();
	printf(1, "invalidMemAccess ok!\n");
}

void
overflow(){
	printf(1, "testing overflow\n");
	if (fork() == 0){
		stackOverflow();
	}
	wait();
	printf(1, "overflow ok!\n");
}


int
main(int argc, char *argv[])
{
	printf(1, "task3tests starting\n");
	
	invalidMemAccess();
	overflow();
	allocToTheMoon();
	hugeAlloc();
	
	printf(1, "task3tests exiting\n");
	
	exit();
}

