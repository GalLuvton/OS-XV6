// System call numbers
#define SYS_fork    	 1
#define SYS_exit    	 2
#define SYS_wait		 3
#define SYS_waitpid	  	 4
#define SYS_wait_stat 	 5
#define SYS_wait_jobid   6
#define SYS_pipe    	 7
#define SYS_read    	 8
#define SYS_kill    	 9
#define SYS_exec    	 10
#define SYS_fstat   	 11
#define SYS_chdir   	 12
#define SYS_dup    		 13
#define SYS_getpid 		 14
#define SYS_sbrk   		 15
#define SYS_sleep  		 16
#define SYS_uptime 		 17
#define SYS_open   		 18
#define SYS_write  		 19
#define SYS_mknod  		 20
#define SYS_unlink 		 21
#define SYS_link   		 22
#define SYS_mkdir  		 23
#define SYS_close  		 24
#define SYS_set_priority 25
#define SYS_set_jobID	 26
#define SYS_print_jobID	 27
#define SYS_top			 28

// waitpid 'options' field
#define NONBLOCKING   0
#define BLOCKING      1
