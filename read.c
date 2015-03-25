// Test that fork fails gracefully.
// Tiny executable so that the limit can be filling the proc table.

#include "types.h"
#include "stat.h"
#include "user.h"

int
main(void)
{
	char buffer[2];
	
	buffer[1]= 0;
	for (;;){
		read(0, buffer, 1);
		printf(1, buffer);
	}
	exit(0);
}