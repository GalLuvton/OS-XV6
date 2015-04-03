#include "types.h"
#include "stat.h"
#include "user.h"

#define STDIN 0

int
main(void)
{
	char buffer[2];
	
	buffer[1]= 0;
	for (;;){
		read(STDIN, buffer, 1);
		if (buffer[0] == 'q'){
			exit(0);
		}
		printf(1, buffer);
	}
	exit(0);
}