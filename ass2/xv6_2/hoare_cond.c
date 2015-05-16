#include "hoare_cond.h"

hoare_cond_t* hoare_cond_alloc(){
	int mu_id1, mu_id2;
	hoare_cond_t* condition;
	
	mu_id1 = kthread_mutex_alloc();
	if (mu_id1 < 0){
		return 0;
	}
	
	mu_id2 = kthread_mutex_alloc();
	if (mu_id2 < 0){
		return 0;
	}
	
	condition = (hoare_cond_t*)malloc(sizeof(hoare_cond_t));
	condition->mutex_id = mu_id1;
	condition->internalLock = mu_id2;
	condition->numberOfSleepers = 0;
	return condition;
}

int hoare_cond_dealloc(hoare_cond_t* cond){
	if (kthread_mutex_dealloc(cond->mutex_id) < 0){
		return -1;
	}
	if (kthread_mutex_dealloc(cond->internalLock) < 0){
		return -1;
	}
	free(cond);
	return 0;	
}

int hoare_cond_wait(hoare_cond_t* cond, int mu_id){
	if (kthread_mutex_lock(cond->internalLock) < 0){
		return -1;
	}
	cond->numberOfSleepers++;
	kthread_mutex_unlock(cond->internalLock);
	if (kthread_mutex_unlock(mu_id) < 0){
		return -1;
	}
	kthread_mutex_lock(cond->mutex_id);
	return 0;
}

int hoare_cond_signal(hoare_cond_t* cond, int mu_id){
	int retval;
	if (kthread_mutex_lock(cond->internalLock) < 0){
		return -1;
	}
	while(1){
		if (cond->numberOfSleepers == 0){
			kthread_mutex_unlock(mu_id);
			break;
		}
		retval = kthread_mutex_yieldlock(mu_id, cond->mutex_id);
		if (retval == 0){
			break;
		}
	}
	if (cond->numberOfSleepers > 0){
		cond->numberOfSleepers--;
	}
	kthread_mutex_unlock(cond->internalLock);
	return 0;
}

