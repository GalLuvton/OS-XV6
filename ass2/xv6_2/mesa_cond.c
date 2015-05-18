#include "mesa_cond.h"

mesa_cond_t* mesa_cond_alloc(){
	int mu_id1, mu_id2;
	mesa_cond_t* condition;
	
	mu_id1 = kthread_mutex_alloc();
	if (mu_id1 < 0 ){
		return 0;
	}
	mu_id2 = kthread_mutex_alloc();
	if (mu_id2 < 0 ){
		kthread_mutex_dealloc(mu_id1);
		return 0;
	}
	
	kthread_mutex_lock(mu_id1);
	
	condition = (mesa_cond_t*)malloc(sizeof(mesa_cond_t));
	condition->mutex_id = mu_id1;
	condition->internalLock = mu_id2;
	condition->numberOfSleepers = 0;
	return condition;
}

int mesa_cond_dealloc(mesa_cond_t* cond){
	kthread_mutex_unlock(cond->mutex_id);

	if (kthread_mutex_dealloc(cond->mutex_id) < 0){
		return -1;
	}
	if (kthread_mutex_dealloc(cond->internalLock) < 0){
		return -1;
	}
	free(cond);
	return 0;	
}

int mesa_cond_wait(mesa_cond_t* cond, int mutex_id){
	if (kthread_mutex_lock(cond->internalLock) < 0){
		return -1;
	}
	cond->numberOfSleepers++;
	kthread_mutex_unlock(cond->internalLock);
	if (kthread_mutex_unlock(mutex_id) < 0){
		return -1;
	}
	kthread_mutex_lock(cond->mutex_id);
	kthread_mutex_lock(mutex_id);
	return 0;
}

int mesa_cond_signal(mesa_cond_t* cond){
	if (kthread_mutex_lock(cond->internalLock) < 0){
		return -1;
	}
	while (cond->numberOfSleepers > 0 && (kthread_mutex_unlock(cond->mutex_id) < 0));
	if (cond->numberOfSleepers > 0){
		cond->numberOfSleepers--;
	}
	kthread_mutex_unlock(cond->internalLock);
	return 0;
}

