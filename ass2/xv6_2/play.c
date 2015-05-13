#include "types.h"
#include "stat.h"
#include "user.h"
#include "kthread.h"


void*
func(void){
	int id;
	
	id = kthread_id();
	printf(1, "in thread %d\n", id);
	while(1);
	
	kthread_exit();
}

int
main(int argc, char *argv[])
{
	void *add;
	void*(*start_func)();
	int id;
	
	printf(1, "main\n");
	start_func = &func;

	add = (void*)malloc(4000);
	id = kthread_create(start_func, add, 4000);
	
	//id = kthread_join(id);
	sleep(50);
	
	printf(1, "main exiting: %d\n", id);
	
	exit();
}

