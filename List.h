#include "types.h"
#include "user.h"
#include "fcntl.h"

#define NULL 0

typedef struct List
{
    void* data;
    struct List* nextLink;
} List;


List* createNode(void* data, List* next);

void deleteNode(List* node);

int searchInList(List* list, void* data);

List* addToList(List* list, void* data);

List* deleteFromList(List* list, void* data);

void freeList(List* list);
