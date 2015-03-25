#include "types.h"
#include "stat.h"
#include "user.h"

void
oldKill(int argc, char **argv)
{
	int i;

	if(argc < 1){
		printf(2, "usage: kill pid...\n");
		exit(0);
	}
	for(i=1; i<argc; i++)
		kill(atoi(argv[i]));
	exit(0);
}

void
newKill(int argc, char **argv)
{
	int pidtokill;
	
	if (argc != 2){
		printf(1, "Please execute as 'kill <pid>'\n");
		exit(1);
	}
	
	pidtokill= atoi(argv[1]);
	kill(pidtokill);
	
	exit(0);
}

int
main(int argc, char **argv)
{
	newKill(argc, argv);
	
	exit(-1);
}
