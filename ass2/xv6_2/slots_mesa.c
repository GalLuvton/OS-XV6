#include "types.h"
#include "stat.h"
#include "user.h"
#include "mesa_slots_monitor.h"

#define STACK_SIZE 1000

int slotsPerRound;
mesa_slots_monitor_t *monitor;


void*
student(void){
	int id;
	
	id = kthread_id();
	printf(1, "Student %d says: good morning!\n", id);
	
	mesa_slots_monitor_takeslot(monitor);
	printf(1, "Student %d says: slots left: %d\n", id, monitor->count);

	printf(1, "Student %d says: bye bye!\n", id);
	
	kthread_exit();
}

void*
grader(void){
	int id;
	
	id = kthread_id();
	printf(1, "Grader %d says: I hate this job!\n", id);
	
	while (mesa_slots_monitor_addslots(monitor, slotsPerRound) > -1){
		printf(1, "Grader %d says: slots left: %d\n", id, monitor->count);
	}
	
	printf(1, "Grader %d says: fuck you BGU!\n", id);
	
	kthread_exit();
}

int
main(int argc, char *argv[])
{
	int studentNum, graderId, res, i;
	int studentId[100];
	void *stack;
	void*(*start_func)();
	
	if (argc != 3){
		printf(1, "please enter 2 arguments- number of students, and number of slots the grader adds each time\n");
		exit();
	}
	
	printf(1, "main- parsing args\n");

	studentNum = atoi(argv[1]);
	slotsPerRound = atoi(argv[2]);

	printf(1, "main- got n-%d ; m-%d\n", studentNum, slotsPerRound);

	monitor = mesa_slots_monitor_alloc();
	
	printf(1, "main- monitor allocated- address %p\n", monitor);
	
	stack = (void*)malloc(STACK_SIZE);
	if (stack <= 0){
		goto bad_alloc;
	}
	start_func = &grader;
	graderId = kthread_create(start_func, stack, STACK_SIZE);
	if (graderId <= 0){
		goto bad_grader_create;
	}
	
	printf(1, "main- grader allocated\n");

	start_func = &student;
	for (i = 0; i < studentNum; i++){
		stack = (void*)malloc(STACK_SIZE);
		if (stack <= 0){
			goto bad_alloc;
		}
		studentId[i] = kthread_create(start_func, stack, STACK_SIZE);
		if (studentId[i] <= 0){
			goto bad_student_create;
		}
		printf(1, "main- student %d created\n", studentId[i]);
	}
	
	printf(1, "main- waiting for students\n");

	i = 0;
	while (i < studentNum){
		res = kthread_join(studentId[i]);
		if (res > -1){
			i++;
		}
	}
	
	printf(1, "main- killing grader\n");
	
	while ((res = mesa_slots_monitor_stopadding(monitor) < 0));
	
	printf(1, "main- waiting for grader\n");
	
	while ((res = kthread_join(graderId) < 0));

	printf(1, "main- done!!\n");
	
	mesa_slots_monitor_dealloc(monitor);

	printf(1, "main- exiting\n");
	exit();

bad_grader_create:
	printf(1, "main- failed to create grader thread, exiting\n");
	exit();
bad_student_create:
	printf(1, "main- failed to create students threads, exiting\n");
	exit();
bad_alloc:
	printf(1, "main- failed to allocate enough memory, exiting\n");
	exit();
}
