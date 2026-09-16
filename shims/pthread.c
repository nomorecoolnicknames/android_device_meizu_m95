/*
 * pthread_mutex_destroy interposer for /vendor/bin/mnld.
 *
 * The Nougat libmnl.so destroys its session mutex twice on every MNL stop,
 * and bionic FORTIFY aborts on destroying an already-destroyed mutex:
 *
 *   FORTIFY: pthread_mutex_destroy called on a destroyed mutex
 *
 * A no-op is safe: bionic's destroy frees no kernel resource, and a later
 * pthread_mutex_init() reinitialises the state word regardless.
 */
#include <pthread.h>

int pthread_mutex_destroy(pthread_mutex_t* mutex __attribute__((unused))) {
    return 0;
}
