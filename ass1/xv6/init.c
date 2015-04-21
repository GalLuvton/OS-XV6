// init: The initial user-level program

#include "types.h"
#include "stat.h"
#include "user.h"
#include "fcntl.h"

char *argv[] = { "sh", 0 };

int
main(void)
{
  int pid, wpid, exit_code;

  if(open("console", O_RDWR) < 0){
    mknod("console", 1, 1);
    open("console", O_RDWR);
  }
  dup(0);  // stdout
  dup(0);  // stderr

  for(;;){
    printf(1, "init: starting sh\n");
	
	#if defined(_policy_DEFAULT)
    printf(1, "Chosen scheduling policy: DEFAULT\n");
    #endif
    
    #if defined(_policy_FRR)
    printf(1, "Chosen scheduling policy: FRR\n");
    #endif
    
    #if defined(_policy_FCFS)
    printf(1, "Chosen scheduling policy: FCFS\n");
    #endif
	
    pid = fork();
    if(pid < 0){
      printf(1, "init: fork failed\n");
      exit(0);
    }
    if(pid == 0){
      exec("sh", argv);
      printf(1, "init: exec sh failed\n");
      exit(0);
    }
    while((wpid=wait(&exit_code)) >= 0 && wpid != pid)
      printf(1, "zombie!\n");
  }
}
