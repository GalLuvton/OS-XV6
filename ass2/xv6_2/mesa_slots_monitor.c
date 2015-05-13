#include "mesa_slots_monitor.h"

mesa_slots_monitor_t*
mesa_slots_monitor_alloc(){
	mesa_slots_monitor_t *monitor = (mesa_slots_monitor_t*)malloc(sizeof(mesa_slots_monitor_t));

	if ((monitor->mutex_id = kthread_mutex_alloc()) < 0){
		return 0;
	}

	if ((monitor->hasElements = mesa_cond_alloc()) <= 0){
		kthread_mutex_dealloc(monitor->mutex_id);
		return 0;
	}

	if ((monitor->empty = mesa_cond_alloc()) <= 0){
		kthread_mutex_dealloc(monitor->mutex_id);
		mesa_cond_dealloc(monitor->hasElements);
		return 0;
	}

	if ((kthread_mutex_lock(monitor->empty->mutex_id)) < 0){
		kthread_mutex_dealloc(monitor->mutex_id);
		mesa_cond_dealloc(monitor->hasElements);
		mesa_cond_dealloc(monitor->empty);
		return 0;
	}
	
	if ((kthread_mutex_lock(monitor->hasElements->mutex_id)) < 0){
		kthread_mutex_dealloc(monitor->mutex_id);
		kthread_mutex_unlock(monitor->empty->mutex_id);
		mesa_cond_dealloc(monitor->hasElements);
		mesa_cond_dealloc(monitor->empty);
		return 0;
	}
	
	monitor->count = 0;
	monitor->doneAddingSlots= 0;
	return monitor;
}

int
mesa_slots_monitor_dealloc(mesa_slots_monitor_t* monitor){
	int a,b,c;
	
	a = ((kthread_mutex_dealloc(monitor->mutex_id)) < 0);
	b = ((mesa_cond_dealloc(monitor->hasElements)) < 0);
	c = ((mesa_cond_dealloc(monitor->empty)) < 0);
	monitor->mutex_id = 0;
	monitor->hasElements = 0;
	monitor->empty = 0;
	free(monitor);
	if (a > 0 && b > 0 && c > 0){
		return 0;
	}
	return -1;
}

int
mesa_slots_monitor_addslots(mesa_slots_monitor_t* monitor, int n){
	if (n <= 0 || monitor->doneAddingSlots || kthread_mutex_lock(monitor->mutex_id) < 0){
		return -1;
	}

	while (monitor->count > 0 && !monitor->doneAddingSlots){
		if (mesa_cond_wait(monitor->empty, monitor->mutex_id) < 0){
			kthread_mutex_unlock(monitor->mutex_id);
			return -1;
		}
	}

	if (monitor->doneAddingSlots){
		return -1;
	}

	monitor->count += n;
	
	// if no one is waiting on the condition, it will return -1, but thats ok
	mesa_cond_signal(monitor->hasElements);
	
	if (kthread_mutex_unlock(monitor->mutex_id) < 0){
			return -1;
	}
	return 0;
}

int
mesa_slots_monitor_takeslot(mesa_slots_monitor_t* monitor){
	if (kthread_mutex_lock(monitor->mutex_id) < 0){
		return -1;
	}

	while (monitor->count == 0){
		if (mesa_cond_wait(monitor->hasElements, monitor->mutex_id) < 0){
			kthread_mutex_unlock(monitor->mutex_id);
			return -1;
		}
	}

	monitor->count--;
	if (monitor->count == 0){
		mesa_cond_signal(monitor->empty);
	}
	else {
		mesa_cond_signal(monitor->hasElements);
	}
	
	if (kthread_mutex_unlock(monitor->mutex_id) < 0){
		return -1;
	}
	return 0;
}

int
mesa_slots_monitor_stopadding(mesa_slots_monitor_t* monitor){
	if (kthread_mutex_lock(monitor->mutex_id) < 0){
		return -1;
	}
	monitor->doneAddingSlots = 1;
	mesa_cond_signal(monitor->empty);
	if (kthread_mutex_unlock(monitor->mutex_id) < 0){
		return -1;
	}
	return 0;
}
