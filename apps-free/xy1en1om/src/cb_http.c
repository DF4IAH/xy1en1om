/*
 * @brief CallBack functions of the HTTP GET/POST parameter transfer system
 *
 * @author Ulrich Habel (DF4IAH) <espero7757@gmx.net>
 *
 *  Created on: 09.10.2015
 *      Author: espero
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <pthread.h>

#include "main.h"
#include "worker.h"
#include "fpga.h"

#include "cb_http.h"


/** @brief name of the param element for the packet counter */
extern const char TRANSPORT_pktIdx[];

/** @brief Describes app. parameters with some info/limitations */
extern rb_app_params_t      g_rb_default_params[];

/** @brief CallBack copy of params to inform the worker */
extern rp_app_params_t*     g_rp_cb_in_params;
/** @brief Holds mutex to access on parameters from outside to the worker thread */
extern pthread_mutex_t      g_rp_cb_in_params_mutex;

/** @brief Current copy of params of the worker thread */
extern rb_app_params_t*     g_rb_info_worker_params;
/** @brief Holds mutex to access parameters from the worker thread to any other context */
extern pthread_mutex_t      g_rb_info_worker_params_mutex;

/** @brief params initialized */
extern int                  g_params_init_done;

/** @brief Holds last received transport frame index number and flag 0x80 for processing data */
extern unsigned char        g_transport_pktIdx;



/*----------------------------------------------------------------------------*/
int rp_app_init(void)
{
    fprintf(stderr, "\n<=== Loading xy1en1om version %s-%s ===>\n\n", VERSION, REVISION);

    fpga_init();

    /* Set check pattern @ HK LEDs */
    //fprintf(stderr, "rp_app_init: setting pattern HK LEDs\n");
    fpga_hk_setLeds(0, 0xff, 0xaa);

#if 0
    // no worker at this point of development
    /* start-up worker thread */
    if (worker_init(g_rb_default_params, RB_PARAMS_NUM) < 0) {
        fprintf(stderr, "ERROR rp_app_init - failed to start worker_init.\n");
        return -1;
    }
#endif

    //fprintf(stderr, "rp_app_init: END\n");
    return 0;
}

/*----------------------------------------------------------------------------*/
int rp_app_exit(void)
{
    //fprintf(stderr, "rp_app_exit: BEGIN\n");
    fprintf(stderr, "\n<=== Unloading xy1en1om version %s-%s. ===>\n\n", VERSION, REVISION);

    /* turn off all LEDs */
    fpga_hk_setLeds(0, 0xff, 0x00);

    //fprintf(stderr, "rp_app_exit: calling fpga_exit()\n");
    fpga_exit();

#if 0
    //fprintf(stderr, "rp_app_exit: calling worker_exit()\n");
    /* shut-down worker thread */
    worker_exit();
#endif

    //fprintf(stderr, "rp_app_exit: END.\n");
    //fprintf(stderr, "xy1en1om unloaded\n\n");
    return 0;
}


/*----------------------------------------------------------------------------*/
int rp_set_params(rp_app_params_t* p, int len)
{
#if 0
	rp_app_params_t* p_copy = NULL;

    //fprintf(stderr, "!!! rp_set_params: BEGIN\n");

    if (!p || (len < 0)) {
        fprintf(stderr, "ERROR rp_set_params - non-valid parameter\n");
        return -1;

    } else if (!len) {                                                                                  // short-cut
        return 0;
    }

    /* create a local copy to release the caller */
    pthread_mutex_lock(&g_rp_cb_in_params_mutex);
    do {
        p_copy = g_rp_cb_in_params;
        if (!p_copy) {
            //fprintf(stderr, "DEBUG rp_set_params: g_rp_cb_in_params - rp_copy_params(&g_rp_cb_in_params, p, ) ...\n");
            rp_copy_params(&g_rp_cb_in_params, p, len, !g_params_init_done);                            // piping to the worker thread
            break;

        } else {
            pthread_mutex_unlock(&g_rp_cb_in_params_mutex);
            /* wait for the worker to process previous job */
            usleep(10000);
            pthread_mutex_lock(&g_rp_cb_in_params_mutex);
        }
    } while (1);
    pthread_mutex_unlock(&g_rp_cb_in_params_mutex);

    /* set current pktIdx */
    int idx = rp_find_parms_index(p, TRANSPORT_pktIdx);
    g_transport_pktIdx = (int) (p[idx].value) | 0x80;                                                   // 0x80 flag: processing changed data

    //fprintf(stderr, "!!! rp_set_params: END - pktIdx = %s = %lf\n", p[0].name, p[0].value);
#endif
    return 0;
}

/*----------------------------------------------------------------------------*/
int rp_get_params(rp_app_params_t** p)
{
    int count = 0;
#if 0
    rp_app_params_t* p_copy = NULL;

    //fprintf(stderr, "??? rp_get_params: BEGIN\n");

    /* wait until the worker has processed the input data */
    //fprintf(stderr, "?.. rp_get_params: waiting for worker has processed the input data - waiting ...\n");
    do {
        if (!(g_transport_pktIdx & 0x80)) {
            break;

        } else {
            /* wait for the worker to process previous job */
            usleep(1000);
        }
    } while (1);
    //fprintf(stderr, "?.. rp_get_params: waiting for worker has processed data - done.\n");

    //fprintf(stderr, "?.. rp_get_params: waiting for worker has exported the current params data - waiting ...\n");
    pthread_mutex_lock(&g_xy_info_worker_params_mutex);
    do {
        if (g_xy_info_worker_params) {
            /* get the memory - free() is called by the caller */
            count = rp_copy_params_rb2rp(&p_copy, g_xy_info_worker_params);
            break;

        } else {
            pthread_mutex_unlock(&g_xy_info_worker_params_mutex);
            /* wait for the worker to export its current params data */
            //pthread_yield();
            usleep(1000);
            pthread_mutex_lock(&g_xy_info_worker_params_mutex);
        }
    } while (1);
    pthread_mutex_unlock(&g_xy_info_worker_params_mutex);
    //fprintf(stderr, "?.. rp_get_params: waiting for worker has exported the current params data - done.\n");

    //fprintf(stderr, "?-> rp_get_params - having list with count = %d\n", count);
    *p = p_copy;

    //fprintf(stderr, "??? rp_get_params: END\n\n");
#endif
    return count;
}
