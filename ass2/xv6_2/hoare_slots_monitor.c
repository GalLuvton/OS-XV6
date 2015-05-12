#include "hoare_slots_monitor.h"

hoare_slots_monitor_t*
hoare_slots_monitor_alloc(){
	hoare_slots_monitor_t *monitor = (hoare_slots_monitor_t*)malloc(sizeof(hoare_slots_monitor_t));
	
	if ((monitor->mutex_id = kthread_mutex_alloc()) < 0){
		return 0;
	}
	if ((monitor->hasElements = hoare_cond_alloc()) <= 0){
		kthread_mutex_dealloc(monitor->mutex_id);
		return 0;
	}
	if ((monitor->empty = hoare_cond_alloc()) <= 0){
		kthread_mutex_dealloc(monitor->mutex_id);
		hoare_cond_dealloc(monitor->hasElements);
		return 0;
	}
	if ((kthread_mutex_lock(monitor->empty->mutex_id)) < 0){
		kthread_mutex_dealloc(monitor->mutex_id);
		hoare_cond_dealloc(monitor->hasElements);
		hoare_cond_dealloc(monitor->empty);
		return 0;
	}
	monitor->count = 0;
	monitor->doneAddingSlots= 0;
	return monitor;
}

int hoare_slots_monitor_dealloc(hoare_slots_monitor_t* monitor){
	int a,b,c;
	
	a = ((kthread_mutex_dealloc(monitor->mutex_id)) < 0);
	b = ((hoare_cond_dealloc(monitor->hasElements)) < 0);
	c = ((hoare_cond_dealloc(monitor->empty)) < 0);
	monitor->mutex_id = 0;
	monitor->hasElements = 0;
	monitor->empty = 0;
	free(monitor);
	if (a > 0 && b > 0 && c > 0){
		return 0;
	}
	return -1;
}

int hoare_slots_monitor_addslots(hoare_slots_monitor_t* monitor, int n){
	if (n <= 0 || monitor->doneAddingSlots || kthread_mutex_lock(monitor->mutex_id)){
		return -1;
	}

	if (hoare_cond_wait(monitor->empty, monitor->mutex_id) < 0){
		kthread_mutex_unlock(monitor->mutex_id);
		return -1;
	}
	
	if (monitor->doneAddingSlots){
		return -1;
	}
	
	monitor->count += n;
	
	if (hoare_cond_signal(monitor->hasElements, monitor->mutex_id) < 0){
		kthread_mutex_unlock(monitor->mutex_id);
		return -1;
	}

	return 0;
}

int hoare_slots_monitor_takeslot(hoare_slots_monitor_t* monitor){
	if (kthread_mutex_lock(monitor->mutex_id)){
		return -1;
	}
	
	if (hoare_cond_wait(monitor->hasElements, monitor->mutex_id) < 0){
		kthread_mutex_unlock(monitor->mutex_id);
		return -1;
	}
	
	monitor->count--;
	if (monitor->count == 0){
		if (hoare_cond_signal(monitor->empty, monitor->mutex_id) < 0){
			kthread_mutex_unlock(monitor->mutex_id);
			return -1;
		}
	}
	else {
		kthread_mutex_unlock(monitor->mutex_id);
	}
	return 0;
}

int hoare_slots_monitor_stopadding(hoare_slots_monitor_t* monitor){
	if (kthread_mutex_lock(monitor->mutex_id) < 0){
		return -1;
	}
	monitor->doneAddingSlots = 1;
	if (hoare_cond_signal(monitor->empty, monitor->mutex_id) < 0){
		kthread_mutex_unlock(monitor->mutex_id);
		return -1;
	}
	return 0;
}
