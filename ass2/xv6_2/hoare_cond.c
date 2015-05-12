#include "hoare_cond.h"


hoare_cond_t* hoare_cond_alloc(){
	int mutex_id;
	hoare_cond_t* condition;
	
	mutex_id = kthread_mutex_alloc();
	if (mutex_id < 0 ){
		return 0;
	}
	condition = ( hoare_cond_t*)malloc(sizeof( hoare_cond_t*));
	return condition;
}

int hoare_cond_dealloc(hoare_cond_t* cond){
	if (kthread_mutex_dealloc(cond->mutex_id) < 0){
		return -1;
	}
	free(cond);
	return 0;	
}

int hoare_cond_wait(hoare_cond_t* cond,int mutex_id){
	if (kthread_mutex_unlock(mutex_id) < 0){
		return -1;
	}
	kthread_mutex_lock(cond->mutex_id);
	return 0;
}

int hoare_cond_signal(hoare_cond_t* cond,int mutex_id){
	if ( kthread_mutex_yieldlock(cond->mutex_id,mutex_id) < 0){
		return -1;
	}
	return 0;
}

