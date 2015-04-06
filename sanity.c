#include "types.h"
#include "stat.h"
#include "user.h"
#define HIGH          1
#define MEDIUM        2
#define LOW           3

#define NUMBER_OF_CHILDS 5 // should be 20
#define TIME_TO_WAIT     5000 // should be 30


void
timeConsumingcalculation(void)
{
	int startingTime, currentTime;
	
	startingTime = uptime();
	for(;;){
		currentTime = uptime();
		if (currentTime >= (startingTime + TIME_TO_WAIT)){
			return;
		}
	}
}


int
main(int argc, char *argv[])
{
	#if defined(_policy_CFS)
	set_priority(HIGH);
	#endif
	int status;
	int runnableTime, runningTime, sleepingTime;
    int i, validChilds=0;
	int runnableTimeAvg=0, runningTimeAvg=0, sleepingTimeAvg=0;
	int waitPid;
	
	printf(1,"starting sanity test\n");
    for(i = 0; i < NUMBER_OF_CHILDS; i++){
        if(fork() == 0){
			//Child
			#if defined(_policy_CFS)
			set_priority((i%3)+1);
			#endif
			timeConsumingcalculation();
            exit(getpid());
        }
	}
	for(i = 0; i < NUMBER_OF_CHILDS; i++){
		waitPid = wait_stat(&runnableTime, &runningTime, &sleepingTime, &status);
			
		//printf(1,"caught pid %d in round %d\n", waitPid, i);
		
		if (waitPid != status){
			printf(1, "validitaion was not correct\n");
			printf(1, "waitPid is %d, status is %d \n", waitPid, status);
		} else {
			validChilds++;
			runnableTimeAvg += runnableTime;
			runningTimeAvg += runningTime;
			sleepingTimeAvg += sleepingTime;
			printf(1, "pid %d: runnable time: %d, running time: %d; sleeping time: %d \n",waitPid, runnableTime,runningTime, sleepingTime);
		}
	}
	printf(1, "average runnable time: %d; average running time: %d; average sleeping time: %d \n",
	(runnableTimeAvg/validChilds), (runningTimeAvg/validChilds),(sleepingTimeAvg/validChilds));
	return 0;
}
