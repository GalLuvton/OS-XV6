#include "mesa_cond.h"

mesa_cond_t* mesa_cond_alloc(){
	int mutex_id;
	mesa_cond_t* condition;
	
	mutex_id = kthread_mutex_alloc();
	if (mutex_id < 0 ){
		return 0;
	}
	condition = (mesa_cond_t*)malloc(sizeof(mesa_cond_t*));
	return condition;
}

int mesa_cond_dealloc(mesa_cond_t* cond){
	if (kthread_mutex_dealloc(cond->mutex_id) < 0){
		return -1;
	}
	free(cond);
	return 0;	
}

int mesa_cond_wait(mesa_cond_t* cond,int mutex_id){
	if (kthread_mutex_unlock(mutex_id) < 0){
		return -1;
	}
	kthread_mutex_lock(cond->mutex_id);
	kthread_mutex_lock(mutex_id);
	return 0;
}

int mesa_cond_signal(mesa_cond_t* cond){
	if (kthread_mutex_unlock(cond->mutex_id) < 0){
		return -1;
	}
	return 0;
}

