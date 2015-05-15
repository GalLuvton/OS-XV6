#include "types.h"
#include "stat.h"
#include "user.h"
#include "kthread.h"

int mutex;

void*
func(void){
	int id;
	
	id = kthread_id();
	if (id > 100){
		printf(1, "BOOM\n");
		exit();
	}
	sleep(50);
	
	kthread_exit();
}

int
main(int argc, char *argv[])
{
	void *add;
	void*(*start_func)();
	int id[16];
	int i,j;
	
	printf(1, "main\n");
	start_func = &func;

	for (j = 0; j < 25; j++){
		for (i = 0; i < 15; i++){
			add = (void*)malloc(4000);
			id[i] = kthread_create(start_func, add, 4000);
		}
		printf(1, "main waiting\n");
		for (i = 0; i < 15; i++){
			kthread_join(id[i]);
		}
		sleep(50);
		printf(1, "batch %d done\n", j);
	}
	
	printf(1, "main exiting\n");
	
	exit();
}

