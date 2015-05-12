#ifndef HOARE_COND_H
#define	HOARE_COND_H

#include "types.h"
#include "kthread.h"
#include "user.h"

typedef struct hoare_cond {
    int mutex_id;
} hoare_cond_t;

hoare_cond_t* hoare_cond_alloc();
int hoare_cond_dealloc(hoare_cond_t*);
int hoare_cond_wait(hoare_cond_t*, int);
int hoare_cond_signal(hoare_cond_t*, int);

#endif	/* HOARE_COND_H */

