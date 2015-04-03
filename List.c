#include "List.h"


List* createNode(void* data, List* next){
	List* newNode;
	
	newNode= (List*)malloc(sizeof(List));
	newNode->data= data;
	newNode->nextLink= next;
	return newNode;
}

void deleteNode(List* node){
	free(node->data);
	free(node);
}

int searchInList(List* list, void* data){
	List* currentLink= list;
	int i= 0;
	while (currentLink){
		if(currentLink->data == data){
			return i;
		}
		currentLink= currentLink->nextLink;
		i++;
	}
	return -1;
}

List* addToList(List* list, void* data){
	List* newNode;
	List* currentLink;
	List* prevLink;
	if (!list){
		newNode= createNode(data, 0);
		list= newNode;
	}
	else {
		currentLink= list;
		while (currentLink){
			if(currentLink->data == data){
				break;
			}
			prevLink= currentLink;
			currentLink= currentLink->nextLink;
		}
		if (!currentLink){
			newNode= createNode(data, 0);
			prevLink->nextLink= newNode;
		}
	}
	return list;
}

List* deleteFromList(List* list, void* data){
	int i;
	List* currentLink= list;
	List* tmpNode;
	if (!list){
		return NULL;
	}
	if (currentLink->data == data){
		list= currentLink->nextLink;
		deleteNode(currentLink);
		return list;
	}
	while (currentLink){
		if((currentLink->nextLink) && (currentLink->data == data)){
			break;
		}
		currentLink= currentLink->nextLink;
		i++;
	}
	if (!currentLink){
		return list;
	}
	tmpNode= currentLink;
	currentLink= currentLink->nextLink;
	tmpNode->nextLink= currentLink->nextLink;
	deleteNode(currentLink);
	return list;
}

void freeList(List* list){
	List* currentLink= list;
	List* tempLink;
	while (currentLink){
		tempLink= currentLink->nextLink;
		deleteNode(currentLink);
		currentLink= tempLink;
	}
}
