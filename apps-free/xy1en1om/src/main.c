/**
 * @brief Red Pitaya xy1en1om main module.
 *
 * @author Ulrich Habel (DF4IAH) <espero7757@gmx.net>
 *
 * (c) Red Pitaya  http://www.redpitaya.com
 *
 * This part of code is written in C programming language.
 * Please visit http://en.wikipedia.org/wiki/C_(programming_language)
 * for more details on the language used herein.
 */

#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <fcntl.h>
//#include <math.h>
#include <errno.h>
#include <pthread.h>
//#include <sys/types.h>
#include <sys/mman.h>

#include "version.h"
#include "worker.h"
#include "fpga.h"
#include "cb_http.h"
#include "cb_ws.h"

#include "main.h"


#ifndef VERSION
# define VERSION "(not set)"
#endif
#ifndef REVISION
# define REVISION "(not set)"
#endif


/** @brief Holds last received transport frame index number and flag 0x80 for processing data */
unsigned char                   g_transport_pktIdx = 0;

/** @brief The system XADC memory file descriptor used to mmap() the FPGA space. */
int                             g_fpga_sys_xadc_mem_fd = -1;
/** @brief The system XADC memory layout of the FPGA registers. */
fpga_sys_xadc_reg_mem_t*        g_fpga_sys_xadc_reg_mem = NULL;

#if 0
/** @brief The system GPIO for LEDs memory file descriptor used to mmap() the FPGA space. */
int                             g_fpga_sys_gpio_leds_mem_fd = -1;
/** @brief The system GPIO for LEDs memory layout of the FPGA registers. */
fpga_sys_gpio_reg_mem_t*        g_fpga_sys_gpio_leds_reg_mem = NULL;
#endif

/** @brief HouseKeeping memory file descriptor used to mmap() the FPGA space */
int                             g_fpga_hk_mem_fd = -1;
/** @brief HouseKeeping memory layout of the FPGA registers */
fpga_hk_reg_mem_t*              g_fpga_hk_reg_mem = NULL;

/** @brief xy1en1om memory file descriptor used to mmap() the FPGA space */
int                             g_fpga_xy_mem_fd = -1;
/** @brief xy1en1om memory layout of the FPGA registers */
fpga_xy_reg_mem_t*              g_fpga_xy_reg_mem = NULL;

/** @brief Describes app. parameters with some info/limitations in high definition - compare initial values with: fpga_xy.fpga_xy_enable() */
const xy_app_params_t g_xy_default_params[XY_PARAMS_NUM + 1] = {

    { /* has to be last entry */
        NULL,                       0.0,  -1, -1, 0.0,      0.0  }
};

/** @brief CallBack copy of params to inform the worker */
rp_app_params_t*                g_rp_cb_in_params = NULL;
/** @brief Holds mutex to access on parameters from outside to the worker thread */
pthread_mutex_t                 g_rp_cb_in_params_mutex = PTHREAD_MUTEX_INITIALIZER;

/** @brief Current copy of params of the worker thread */
xy_app_params_t*                g_xy_info_worker_params = NULL;
/** @brief Holds mutex to access parameters from the worker thread to any other context */
pthread_mutex_t                 g_xy_info_worker_params_mutex = PTHREAD_MUTEX_INITIALIZER;


/** @brief params initialized */
int                             g_params_init_done = 0;  /* @see worker.c */


/** @brief name of the param element for the packet counter */
const char TRANSPORT_pktIdx[]      = "pktIdx";

const int  IEEE754_DOUBLE_EXP_BIAS = 1023;
const int  IEEE754_DOUBLE_EXP_BITS = 12;
const int  IEEE754_DOUBLE_MNT_BITS = 52;
const int  RB_CELL_MNT_BITS        = 20;

const char CAST_NAME_EXT_SE[]      = "SE_";
const char CAST_NAME_EXT_HI[]      = "HI_";
const char CAST_NAME_EXT_MI[]      = "MI_";
const char CAST_NAME_EXT_LO[]      = "LO_";
const int  CAST_NAME_EXT_LEN       = 3;


/*----------------------------------------------------------------------------------*/
int is_quad(const char* name)
{
    char* ptr = strrchr(name, '_');
    if (ptr && !strcmp("_f", ptr)) {
        return 1;
    }
    return 0;
}


/*----------------------------------------------------------------------------------*/
double cast_4xbf_to_1xdouble(float f_se, float f_hi, float f_mi, float f_lo)
{
    unsigned long long ull = 0ULL;
    double*            dp  = (void*) &ull;

    if (!f_se && !f_hi && !f_mi && !f_lo) {
        //fprintf(stderr, "INFO cast_4xbf_to_1xdouble (zero) - out(d=%lf) <-- in(f_se=%f, f_hi=%f, f_mi=%f, f_lo=%f)\n", 0.0, f_se, f_hi, f_mi, f_lo);
        return 0.0;
    }

    // avoid under-rounding when casting to integer
    uint64_t i_se = (uint64_t) (0.5f + f_se);
    uint64_t i_hi = (uint64_t) (0.5f + f_hi);
    uint64_t i_mi = (uint64_t) (0.5f + f_mi);
    uint64_t i_lo = (uint64_t) (0.5f + f_lo);

    /* unsigned long long interpretation */
    ull   = (i_hi & 0x00fffffULL);  // 20 bits

    ull <<= RB_CELL_MNT_BITS;
    ull  |= (i_mi & 0x00fffffULL);  // 20 bits

    ull <<= IEEE754_DOUBLE_MNT_BITS - (RB_CELL_MNT_BITS << 1);
    ull  |= (i_lo & 0x0000fffULL);  // 12 bits

    ull  |= (i_se & 0x0000fffULL) <<  IEEE754_DOUBLE_MNT_BITS;

    /* double interpretation */
    //fprintf(stderr, "INFO cast_4xbf_to_1xdouble (val)  - out(d=%lf) <-- in(f_se=%f, f_hi=%f, f_mi=%f, f_lo=%f)\n", *dp, f_se, f_hi, f_mi, f_lo);
    return *dp;
}

/*----------------------------------------------------------------------------------*/
int cast_1xdouble_to_4xbf(float* f_se, float* f_hi, float* f_mi, float* f_lo, double d)
{
    unsigned long long ull = 0;
    double*            dp  = (void*) &ull;

    if (!f_se || !f_hi || !f_mi || !f_lo) {
        return -1;
    }

    if (d == 0.0) {
        /* use unnormalized zero instead */
        *f_se = 0.0f;
        *f_hi = 0.0f;
        *f_mi = 0.0f;
        *f_lo = 0.0f;
        //fprintf(stderr, "INFO cast_1xdouble_to_4xbf (zero) - out(f_se=%f, f_hi=%f, f_mi=%f, f_lo=%f) <-- in(d=%lf)\n", *f_se, *f_hi, *f_mi, *f_lo, d);
        return 0;
    }

    /* double interpretation */
    *dp = d;

    /* unsigned long long interpretation */
    uint64_t ui = ull;

    *f_lo   = ui & 0x00000fffULL;

    ui    >>= IEEE754_DOUBLE_MNT_BITS - (RB_CELL_MNT_BITS << 1);
    *f_mi   = ui & 0x000fffffULL;  // 12 bits

    ui    >>= RB_CELL_MNT_BITS;
    *f_hi   = ui & 0x000fffffULL;  // 20 bits

    ui    >>= RB_CELL_MNT_BITS;
    *f_se   = ui & 0x00000fffULL;  // 20 bits

    //fprintf(stderr, "INFO cast_1xdouble_to_4xbf (val)  - out(f_se=%f, f_hi=%f, f_mi=%f, f_lo=%f) <-- in(d=%lf)\n", *f_se, *f_hi, *f_mi, *f_lo, d);
    return 0;
}


/*----------------------------------------------------------------------------------*/
const char* rp_app_desc(void)
{
    return (const char *)"RedPitaya xy1en1om application by DF4IAH.\n";
}


/*----------------------------------------------------------------------------------*/
int rp_find_parms_index(const rp_app_params_t* src, const char* name)
{
    if (!src || !name) {
        fprintf(stderr, "ERROR find_parms_index - Bad function arguments received.\n");
        return -2;
    }

    int i = 0;
    while (src[i].name) {
        if (!strcmp(src[i].name, name)) {
            return i;
        }
        ++i;
    }
    return -1;
}

/*----------------------------------------------------------------------------------*/
int xy_find_parms_index(const xy_app_params_t* src, const char* name)
{
    if (!src || !name) {
        fprintf(stderr, "ERROR find_parms_index - Bad function arguments received.\n");
        return -2;
    }

    int i = 0;
    while (src[i].name) {
        if (!strcmp(src[i].name, name)) {
            return i;
        }
        ++i;
    }
    return -1;
}


/*----------------------------------------------------------------------------------*/
void xy_update_param(xy_app_params_t** dst, const char* param_name, double param_value)
{
    if (!dst || !param_name) {
        fprintf(stderr, "ERROR xy_update_param - Bad function arguments received.\n");
        return;
    }
    int l_num_params = 0;
    int param_name_len = strlen(param_name);

    //fprintf(stderr, "DEBUG xy_update_param - entry ...\n");
    //fprintf(stderr, "DEBUG xy_update_param - list before modify:\n");
    //print_xy_params(*dst);

    xy_app_params_t* p_dst = *dst;
    if (p_dst) {
        int idx = xy_find_parms_index(p_dst, param_name);
        if (idx >= 0) {
            /* update existing entry */
#if 0
            double param_value_cor = param_value;
            if (param_value_cor < p_dst[idx].min_val) {
                param_value_cor = p_dst[idx].min_val;
            } else if (param_value_cor > p_dst[idx].max_val) {
                param_value_cor = p_dst[idx].max_val;
            }
            p_dst[idx].value = param_value_cor;
            //fprintf(stderr, "DEBUG xy_update_param - updating %s with value = %f, bounds corrected value = %f\n", param_name, param_value, param_value_cor);
#else
            p_dst[idx].value = param_value;
            //fprintf(stderr, "DEBUG xy_update_param - updating %s with value = %f\n", param_name, param_value);
#endif

            //fprintf(stderr, "DEBUG xy_update_param - list after modify:\n");
            //print_xy_params(*dst);
            return;
        }

        /* count entries */
        while (p_dst[l_num_params].name)
            l_num_params++;

    } else {
        l_num_params++;
    }

    /* re-map to a bigger buffer */
    //fprintf(stderr, "DEBUG xy_update_param - realloc buffer for %d elements. Old ptr = %p\n", l_num_params + 1, p_dst);
    p_dst = *dst = realloc(p_dst, sizeof(xy_app_params_t) * (l_num_params + 1));
    //fprintf(stderr, "DEBUG xy_update_param - realloc buffer for %d elements. New ptr = %p\n", l_num_params + 1, p_dst);

    p_dst[l_num_params].name = malloc(param_name_len + 1);
    strncpy(p_dst[l_num_params].name, param_name, param_name_len + 1);
    p_dst[l_num_params].value       = param_value;
    p_dst[l_num_params].fpga_update = 1;
    p_dst[l_num_params].read_only   = 0;
    p_dst[l_num_params].min_val     = 0.0;
    p_dst[l_num_params].max_val     = 62.5e6;
    p_dst[l_num_params + 1].name = NULL;

    //fprintf(stderr, "DEBUG xy_update_param - list after modify:\n");
    //print_xy_params(*dst);
    //fprintf(stderr, "DEBUG xy_update_param - ... done.\n");
}

/*----------------------------------------------------------------------------------*/
void rp2xy_params_value_copy(xy_app_params_t* dst_line, const rp_app_params_t src_line_se, const rp_app_params_t src_line_hi, const rp_app_params_t src_line_mi, const rp_app_params_t src_line_lo)
{
    dst_line->value          = cast_4xbf_to_1xdouble(src_line_se.value, src_line_hi.value, src_line_mi.value, src_line_lo.value);

    dst_line->fpga_update    = src_line_lo.fpga_update;
    dst_line->read_only      = src_line_lo.read_only;

//  dst_line->min_val        = cast_3xbf_to_1xdouble(src_line_se.min_val, src_line_hi.min_val, src_line_mi.min_val, src_line_lo.min_val);
//  dst_line->max_val        = cast_3xbf_to_1xdouble(src_line_se.max_val, src_line_hi.max_val, src_line_mi.max_val, src_line_lo.max_val);
}

/*----------------------------------------------------------------------------------*/
void xy2rp_params_value_copy(rp_app_params_t* dst_line_se, rp_app_params_t* dst_line_hi, rp_app_params_t* dst_line_mi, rp_app_params_t* dst_line_lo, const xy_app_params_t src_line)
{
    //fprintf(stderr, "DEBUG xy2rp_params_value_copy - before value: %lf\n", src_line.value);
    cast_1xdouble_to_4xbf(&(dst_line_se->value), &(dst_line_hi->value), &(dst_line_mi->value), &(dst_line_lo->value), src_line.value);

    dst_line_se->fpga_update = 0;
    dst_line_hi->fpga_update = 0;
    dst_line_mi->fpga_update = 0;
    dst_line_lo->fpga_update = src_line.fpga_update;

    dst_line_se->read_only = 0;
    dst_line_hi->read_only = 0;
    dst_line_mi->read_only = 0;
    dst_line_lo->read_only = src_line.read_only;

    //fprintf(stderr, "DEBUG xy2rp_params_value_copy - before min_val: %lf\n", src_line.min_val);
    cast_1xdouble_to_4xbf(&(dst_line_se->min_val), &(dst_line_hi->min_val), &(dst_line_mi->min_val), &(dst_line_lo->min_val), src_line.min_val);
    //fprintf(stderr, "DEBUG xy2rp_params_value_copy - before max_val: %lf\n", src_line.max_val);
    cast_1xdouble_to_4xbf(&(dst_line_se->max_val), &(dst_line_hi->max_val), &(dst_line_mi->max_val), &(dst_line_lo->max_val), src_line.max_val);
    //fprintf(stderr, "DEBUG xy2rp_params_value_copy - done.\n");
}


/*----------------------------------------------------------------------------------*/
int rp_copy_params(rp_app_params_t** dst, const rp_app_params_t src[], int len, int do_copy_all_attr)
{
    const rp_app_params_t* s = src;
    int l_num_params = 0;

    /* check arguments */
    if (!s || !dst) {
        fprintf(stderr, "ERROR rp_copy_params - Internal error, the destination Application parameters variable is not set.\n");
        return -1;
    }

    /* check if destination buffer is allocated already */
    rp_app_params_t* p_dst = *dst;
    if (p_dst) {
        //fprintf(stderr, "DEBUG rp_copy_params - dst exists - updating into dst vector.\n");
        /* destination buffer exists */
        int i;
        for (i = 0; s[i].name; i++) {
            l_num_params++;
            //fprintf(stderr, "DEBUG rp_copy_params - processing name = %s\n", s[i].name);
            /* process each parameter entry of the list */

            if (!strcmp(p_dst[i].name, s[i].name)) {  // direct mapping found - just copy the value
                //fprintf(stderr, "DEBUG rp_copy_params - direct mapping used\n");
                p_dst[i].value = s[i].value;
                if (s[i].fpga_update & 0x80) {
                    p_dst[i].fpga_update |=  0x80;  // transfer FPGA update marker in case it is present
                } else {
                    p_dst[i].fpga_update &= ~0x80;  // or remove it when it is not set
                }

                if (do_copy_all_attr) {  // if default parameters are taken, use all attributes
                    p_dst[i].fpga_update    = s[i].fpga_update;
                    p_dst[i].read_only      = s[i].read_only;
                    p_dst[i].min_val        = s[i].min_val;
                    p_dst[i].max_val        = s[i].max_val;
                }

            } else {
                //fprintf(stderr, "DEBUG rp_copy_params - iterative searching ...\n");
                int j;
                for (j = 0; p_dst[j].name; j++) {  // scanning the complete list
                    if (j == i) {  // do a short-cut here
                        continue;
                    }

                    if (!strcmp(p_dst[j].name, s[i].name)) {
                        p_dst[j].value = s[i].value;
                        if (s[i].fpga_update & 0x80) {
                            p_dst[j].fpga_update |=  0x80;  // transfer FPGA update marker in case it is present
                        } else {
                            p_dst[j].fpga_update &= ~0x80;  // or remove it when it is not set
                        }

                        if (do_copy_all_attr) {  // if default parameters are taken, use all attributes
                            p_dst[j].fpga_update    = s[i].fpga_update;  // copy FPGA update marker in case it is present
                            p_dst[j].read_only      = s[i].read_only;
                            p_dst[j].min_val        = s[i].min_val;
                            p_dst[j].max_val        = s[i].max_val;
                        }
                        break;
                    }
                }  // for (; p_dst[j].name ;)
            }  // if () else
        }  // for ()

    } else {
        /* destination buffer has to be allocated, create a new parameter list */

        if (len >= 0) {
            l_num_params = len;

        } else {
            /* retrieve the number of source parameters */
            for (l_num_params = 0; s[l_num_params].name; l_num_params++) { }
        }

        /* allocate array of parameter entries, parameter names must be allocated separately */
        p_dst = (rp_app_params_t*) malloc(sizeof(rp_app_params_t) * (l_num_params + 1));
        if (!p_dst) {
            fprintf(stderr, "ERROR rp_copy_params - memory problem, the destination buffer could not be allocated (1).\n");
            return -3;
        }
        /* prepare a copy for built-in attributes. Strings have to be handled on their own way */
        memcpy(p_dst, s, (l_num_params + 1) * sizeof(rp_app_params_t));

        /* allocate memory and copy character strings for params names */
        int i;
        for (i = 0; s[i].name; i++) {
            int slen = strlen(s[i].name);
            p_dst[i].name = (char*) malloc(slen + 1);  // old pointer to name does not belong to us and has to be discarded
            if (!(p_dst[i].name)) {
                fprintf(stderr, "ERROR rp_copy_params - memory problem, the destination buffer could not be allocated (2).\n");
                return -4;
            }
            strncpy(p_dst[i].name, s[i].name, slen);
            p_dst[i].name[slen] = '\0';
        }

        /* mark last one as final entry */
        p_dst[l_num_params].name = NULL;
        p_dst[l_num_params].value = -1;
    }
    *dst = p_dst;

    return l_num_params;
}

/*----------------------------------------------------------------------------------*/
int xy_copy_params(xy_app_params_t** dst, const xy_app_params_t src[], int len, int do_copy_all_attr)
{
    const xy_app_params_t* s = src;
    int l_num_params = 0;

    /* check arguments */
    if (!dst) {
        fprintf(stderr, "ERROR xy_copy_params - Internal error, the destination Application parameters variable is not set.\n");
        return -1;
    }
    if (!s) {
        //fprintf(stderr, "INFO xy_copy_params - no source parameter list given, taking default parameters instead.\n");
        s = g_xy_default_params;
    }

    /* check if destination buffer is allocated already */
    xy_app_params_t* p_dst = *dst;
    if (p_dst) {
        //fprintf(stderr, "DEBUG xy_copy_params - dst exists - updating into dst vector.\n");
        /* destination buffer exists */
        int i, j;
        for (i = 0, j = 0; s[i].name; i++) {
            l_num_params++;
            //fprintf(stderr, "DEBUG xy_copy_params - processing name = %s\n", s[i].name);
            /* process each parameter entry of the list */

            j = xy_find_parms_index(p_dst, s[i].name);
            if (j >= 0) {
                //fprintf(stderr, "DEBUG xy_copy_params - fill in\n");
                p_dst[j].value = s[i].value;
                if (s[i].fpga_update & 0x80) {
                    p_dst[j].fpga_update |=  0x80;  // transfer FPGA update marker in case it is present
                } else {
                    p_dst[j].fpga_update &= ~0x80;  // or remove it when it is not set
                }

                if (do_copy_all_attr) {  // if default parameters are taken, use all attributes
                    p_dst[j].fpga_update    = s[i].fpga_update;
                    p_dst[j].read_only      = s[i].read_only;
                    p_dst[j].min_val        = s[i].min_val;
                    p_dst[j].max_val        = s[i].max_val;
                }
            }  // if (j >= 0)
        }  // for ()

    } else {
        /* destination buffer has to be allocated, create a new parameter list */

        if (len >= 0) {
            l_num_params = len;

        } else {
            /* retrieve the number of source parameters */
            for (l_num_params = 0; s[l_num_params].name; l_num_params++) { }
        }

        /* allocate array of parameter entries, parameter names must be allocated separately */
        p_dst = (xy_app_params_t*) malloc(sizeof(xy_app_params_t) * (l_num_params + 1));
        if (!p_dst) {
            fprintf(stderr, "ERROR xy_copy_params - memory problem, the destination buffer could not be allocated (1).\n");
            return -3;
        }

        /* allocate memory and copy character strings for params names */
        int i;
        for (i = 0; s[i].name; i++) {
            const int slen = strlen(s[i].name);

            p_dst[i].name = (char*) malloc(slen + 1);  // old pointer to name does not belong to us and has to be discarded
            if (!(p_dst[i].name)) {
                fprintf(stderr, "ERROR xy_copy_params - memory problem, the destination buffer could not be allocated (2).\n");
                return -4;
            }
            strncpy(p_dst[i].name, s[i].name, slen);
            p_dst[i].name[slen] = '\0';

            p_dst[i].value          = s[i].value;
            p_dst[i].fpga_update    = s[i].fpga_update;
            if (do_copy_all_attr) {                                                                     // if default parameters are taken, use all attributes
                p_dst[i].fpga_update    = s[i].fpga_update;
                p_dst[i].read_only      = s[i].read_only;
                p_dst[i].min_val        = s[i].min_val;
                p_dst[i].max_val        = s[i].max_val;
            }
        }

        /* mark last one as final entry */
        p_dst[l_num_params].name = NULL;
        p_dst[l_num_params].value = -1;
    }
    *dst = p_dst;

    return l_num_params;
}


/*----------------------------------------------------------------------------------*/
int rp_copy_params_xy2rp(rp_app_params_t** dst, const xy_app_params_t src[])
{
    int l_num_single_params = 0;
    int l_num_quad_params = 0;

    /* check arguments */
    if (!dst) {
        fprintf(stderr, "ERROR rp_copy_params_xy2rp - Internal error, the destination Application parameters vector variable is not set.\n");
        return -1;
    }
    if (!src) {
        fprintf(stderr, "ERROR rp_copy_params_xy2rp - Internal error, the source Application parameters vector variable is not set.\n");
        return -2;
    }

    /* check if destination buffer is allocated already */
    rp_app_params_t* p_dst = *dst;
    if (p_dst) {
        //fprintf(stderr, "DEBUG rp_copy_params_xy2rp: freeing ...\n");
        rp_free_params(dst);
    }

    /* destination buffer has to be allocated, create a new parameter list */
    {
        /* get the number entries */
        {
            int i;
            for (i = 0; src[i].name; i++) {
                //fprintf(stderr, "DEBUG rp_copy_params_xy2rp - get_the_number_entries - name=%s\n", src[i].name);
                if (is_quad(src[i].name)) {
                    l_num_quad_params++;
                } else {
                    l_num_single_params++;
                }
            }
            //fprintf(stderr, "DEBUG rp_copy_params_xy2rp - num_single_params=%d, num_quad_params=%d\n", l_num_single_params, l_num_quad_params);
        }

        /* allocate array of parameter entries, parameter names must be allocated separately */
        p_dst = (rp_app_params_t*) malloc(sizeof(rp_app_params_t) * (1 + l_num_single_params + (l_num_quad_params << 2)));
        if (!p_dst) {
            fprintf(stderr, "ERROR rp_copy_params_xy2rp - memory problem, the destination buffer failed to be allocated (1).\n");
            return -3;
        }

        /* allocate memory and copy character strings for params names */
        int i, j;
        for (i = 0, j = 0; src[i].name; i++) {
            const int slen = strlen(src[i].name);
            char found = 0;

            /* limit transfer volume to a part of all param entries, @see main.g_xy_default_params (abt. line 70) for a full list */
            switch (g_transport_pktIdx & 0x7f) {
            case 1:
                if (!strcmp("xy_run",              src[i].name)) {
                    found = 1;
                }
                break;

            default:
                /* no limitation of output data */
                    found = 1;
                break;
            }

            if (!found) {
                if (is_quad(src[i].name)) {
                    l_num_quad_params--;
                } else {
                    l_num_single_params--;
                }
                //fprintf(stderr, "DEBUG rp_copy_params_xy2rp - Limit transfer - for pktIdx = %d  no  name = %s - num_single_params = %d, num_quad_params = %d - continue\n", g_transport_pktIdx, src[i].name, l_num_single_params, l_num_quad_params);
                continue;
            }

            if (is_quad(src[i].name)) {                                                                 // float parameter --> QUAD encoder
                int j_se = j++;
                int j_hi = j++;
                int j_mi = j++;
                int j_lo = j++;

                p_dst[j_se].name = (char*) malloc(CAST_NAME_EXT_LEN + slen + 1);
                p_dst[j_hi].name = (char*) malloc(CAST_NAME_EXT_LEN + slen + 1);
                p_dst[j_mi].name = (char*) malloc(CAST_NAME_EXT_LEN + slen + 1);
                p_dst[j_lo].name = (char*) malloc(CAST_NAME_EXT_LEN + slen + 1);
                if (!(p_dst[j_se].name) || !(p_dst[j_hi].name) || !(p_dst[j_mi].name) || !(p_dst[j_lo].name)) {
                    fprintf(stderr, "ERROR rp_copy_params_xy2rp - memory problem, the destination buffers failed to be allocated (2).\n");
                    return -3;
                }

                strncpy( p_dst[j_se].name,   CAST_NAME_EXT_SE, CAST_NAME_EXT_LEN);
                strncpy((p_dst[j_se].name) + CAST_NAME_EXT_LEN, src[i].name, slen);
                p_dst[j_se].name[CAST_NAME_EXT_LEN + slen] = '\0';

                strncpy( p_dst[j_hi].name,   CAST_NAME_EXT_HI, CAST_NAME_EXT_LEN);
                strncpy((p_dst[j_hi].name) + CAST_NAME_EXT_LEN, src[i].name, slen);
                p_dst[j_hi].name[CAST_NAME_EXT_LEN + slen] = '\0';

                strncpy( p_dst[j_mi].name,   CAST_NAME_EXT_MI, CAST_NAME_EXT_LEN);
                strncpy((p_dst[j_mi].name) + CAST_NAME_EXT_LEN, src[i].name, slen);
                p_dst[j_mi].name[CAST_NAME_EXT_LEN + slen] = '\0';

                strncpy( p_dst[j_lo].name,   CAST_NAME_EXT_LO, CAST_NAME_EXT_LEN);
                strncpy((p_dst[j_lo].name) + CAST_NAME_EXT_LEN, src[i].name, slen);
                p_dst[j_lo].name[CAST_NAME_EXT_LEN + slen] = '\0';

                xy2rp_params_value_copy(&(p_dst[j_se]), &(p_dst[j_hi]), &(p_dst[j_mi]), &(p_dst[j_lo]), src[i]);
                //fprintf(stderr, "INFO rp_copy_params_xy2rp - out[%d, %d, %d, %d] copied from in[%d] - name = %s, val = %lf\n", j_se, j_hi, j_mi, j_lo, i, src[i].name, src[i].value);

            } else {                                                                                    // SINGLE parameter
                p_dst[j].name = (char*) malloc(slen + 1);
                if (!(p_dst[j].name)) {
                    fprintf(stderr, "ERROR rp_copy_params_xy2rp - memory problem, the destination buffers failed to be allocated (3).\n");
                    return -3;
                }

                strncpy((p_dst[j].name), src[i].name, slen);
                p_dst[j].name[slen] = '\0';

                p_dst[j].value       = src[i].value;
                p_dst[j].fpga_update = src[i].fpga_update;
                p_dst[j].read_only   = src[i].read_only;
                p_dst[j].min_val     = src[i].min_val;
                p_dst[j].max_val     = src[i].max_val;
                //fprintf(stderr, "INFO rp_copy_params_xy2rp - out[%d] copied from in[%d] - name = %s, val = %lf\n", j, i, src[i].name, src[i].value);

                j++;
            }  // else SINGLE
        }  // for ()

        /* mark last one as final entry */
        p_dst[l_num_single_params + (l_num_quad_params << 2)].name = NULL;
        p_dst[l_num_single_params + (l_num_quad_params << 2)].value = -1;
    }
    *dst = p_dst;

    return l_num_single_params + (l_num_quad_params << 2);
}

/*----------------------------------------------------------------------------------*/
 int rp_copy_params_rp2xy(xy_app_params_t** dst, const rp_app_params_t src[])
{
    int l_num_single_params = 0;
    int l_num_quad_params = 0;

    /* check arguments */

    if (!dst) {
        fprintf(stderr, "ERROR rp_copy_params_rp2xy - Internal error, the destination Application parameters vector variable is not set.\n");
        return -1;
    }
    if (!src) {
        fprintf(stderr, "ERROR rp_copy_params_rp2xy - Internal error, the source Application parameters vector variable is not set.\n");
        return -2;
    }

    /* get the number entries */
    {
        int i;
        for (i = 0; src[i].name; i++) {
            //fprintf(stderr, "DEBUG rp_copy_params_rp2xy - get_the_number_entries - name=%s\n", src[i].name);
            if (is_quad(src[i].name)) {
                /* count LO_yyy entries */
                if (!strncmp(CAST_NAME_EXT_LO, src[i].name, CAST_NAME_EXT_LEN)) {
                    l_num_quad_params++;
                }
            } else {
                l_num_single_params++;
            }
        }  // for ()
        //fprintf(stderr, "DEBUG rp_copy_params_rp2xy - num_single_params=%d, num_quad_params=%d\n", l_num_single_params, l_num_quad_params);
    }

    /* check if destination buffer is allocated already */
    xy_app_params_t* p_dst = *dst;
    if (p_dst) {
        //fprintf(stderr, "DEBUG rp_copy_params_rp2xy = dst vector is valid\n");

        int i, j;
        for (i = 0, j = 0; src[i].name; i++) {
            const int slen = strlen(src[i].name);

            if (!strncmp(CAST_NAME_EXT_SE, src[i].name, CAST_NAME_EXT_LEN) ||
                !strncmp(CAST_NAME_EXT_HI, src[i].name, CAST_NAME_EXT_LEN) ||
                !strncmp(CAST_NAME_EXT_MI, src[i].name, CAST_NAME_EXT_LEN)) {
                continue;  // skip all SE_, HI_ and MI_ params
            }

            if (!strcmp(TRANSPORT_pktIdx, src[i].name)) {
                l_num_single_params--;
                //fprintf(stderr, "DEBUG rp_copy_params_rp2xy - disregard this entry (1) - name = %s - num_single_params = %d, num_quad_params = %d\n", src[i].name, l_num_single_params, l_num_quad_params);
                continue;
            }

            if (!strncmp(CAST_NAME_EXT_LO, src[i].name, CAST_NAME_EXT_LEN)) {                           // QUAD elements - since here: LO_xxx
                char name_se[256];
                char name_hi[256];
                char name_mi[256];

                /* prepare name variants */
                {
                    strncpy(name_se, CAST_NAME_EXT_SE, CAST_NAME_EXT_LEN);
                    strncpy(name_se + CAST_NAME_EXT_LEN, CAST_NAME_EXT_LEN + src[i].name, slen);
                    name_se[CAST_NAME_EXT_LEN + slen] = '\0';

                    strncpy(name_hi, CAST_NAME_EXT_HI, CAST_NAME_EXT_LEN);
                    strncpy(name_hi + CAST_NAME_EXT_LEN, CAST_NAME_EXT_LEN + src[i].name, slen);
                    name_hi[CAST_NAME_EXT_LEN + slen] = '\0';

                    strncpy(name_mi, CAST_NAME_EXT_MI, CAST_NAME_EXT_LEN);
                    strncpy(name_mi + CAST_NAME_EXT_LEN, CAST_NAME_EXT_LEN + src[i].name, slen);
                    name_mi[CAST_NAME_EXT_LEN + slen] = '\0';
                }

                /* find all quad elements */
                int i_se = rp_find_parms_index(src, name_se);
                int i_hi = rp_find_parms_index(src, name_hi);
                int i_mi = rp_find_parms_index(src, name_mi);
                int i_lo = i;
                if (i_se < 0 || i_hi < 0 || i_mi < 0) {
                    continue;  // no quad found, ignore uncomplete entries
                }

                j = xy_find_parms_index(p_dst, src[i].name + CAST_NAME_EXT_LEN);  // the extension is stripped away before the compare
                if (j < 0) {
                    // discard new entry if not already known in target vector
                    fprintf(stderr, "WARNING rp_copy_params_rp2xy (1) - input element of vector is unknown - name = %s\n", src[i].name);
                    continue;
                }

                rp2xy_params_value_copy(&(p_dst[j]), src[i_se], src[i_hi], src[i_mi], src[i_lo]);
                //fprintf(stderr, "INFO rp_copy_params_rp2xy - out[%d] copied from in[%d, %d, %d, %d] - name = %s, val = %lf\n", j, i_se, i_hi, i_mi, i_lo, src[i_lo].name + CAST_NAME_EXT_LEN, p_dst[j].value);

            } else {                                                                                    // SINGLE element
                j = xy_find_parms_index(p_dst, src[i].name);
                if (j < 0) {
                    // discard new entry if not already known in target vector
                    fprintf(stderr, "WARNING rp_copy_params_rp2xy (2) - input element of vector is unknown - name = %s\n", src[i].name);
                    continue;
                }

                p_dst[j].value       = src[i].value;
                p_dst[j].fpga_update = src[i].fpga_update;
                p_dst[j].read_only   = src[i].read_only;
                p_dst[j].min_val     = src[i].min_val;
                p_dst[j].max_val     = src[i].max_val;
                //fprintf(stderr, "INFO rp_copy_params_rp2xy - out[%d] copied from in[%d] - name = %s, val = %lf\n", j, i, src[i].name, src[i].value);
            }
        }  // for ()

    } else {
        //fprintf(stderr, "DEBUG rp_copy_params_rp2xy = creating new dst vector\n");
        /* destination buffer has to be allocated, create a new parameter list */

        /* allocate array of parameter entries, parameter names must be allocated separately */
        p_dst = (xy_app_params_t*) malloc(sizeof(xy_app_params_t) * (1 + l_num_single_params + (l_num_quad_params << 2)));
        if (!p_dst) {
            fprintf(stderr, "ERROR rp_copy_params_rp2xy - memory problem, the destination buffer failed to be allocated (1).\n");
            return -3;
        }

        /* allocate memory and copy character strings for params names */
        int i, j;
        for (i = 0, j = 0; src[i].name; i++) {
            if (!strncmp(CAST_NAME_EXT_SE, src[i].name, CAST_NAME_EXT_LEN) ||
                !strncmp(CAST_NAME_EXT_HI, src[i].name, CAST_NAME_EXT_LEN) ||
                !strncmp(CAST_NAME_EXT_MI, src[i].name, CAST_NAME_EXT_LEN)) {
                //fprintf(stderr, "DEBUG rp_copy_params_rp2xy - skip this name=%s\n", src[i].name);
                continue;  // skip all SE_, HI_ and MI_ params
            }

            if (!strncmp(CAST_NAME_EXT_LO, src[i].name, CAST_NAME_EXT_LEN)) {                           // QUAD elements - since here: LO_xxx
                const int slen = strlen(src[i].name) - CAST_NAME_EXT_LEN;
                char name_se[256];
                char name_hi[256];
                char name_mi[256];

                //fprintf(stderr, "DEBUG rp_copy_params_rp2xy - QUAD - name=%s\n", src[i].name);
                /* prepare name variants */
                {
                    strncpy(name_se, CAST_NAME_EXT_SE, CAST_NAME_EXT_LEN);
                    strncpy(name_se + CAST_NAME_EXT_LEN, src[i].name + CAST_NAME_EXT_LEN, slen);
                    name_se[CAST_NAME_EXT_LEN + slen] = '\0';

                    strncpy(name_hi, CAST_NAME_EXT_HI, CAST_NAME_EXT_LEN);
                    strncpy(name_hi + CAST_NAME_EXT_LEN, src[i].name + CAST_NAME_EXT_LEN, slen);
                    name_hi[CAST_NAME_EXT_LEN + slen] = '\0';

                    strncpy(name_mi, CAST_NAME_EXT_MI, CAST_NAME_EXT_LEN);
                    strncpy(name_mi + CAST_NAME_EXT_LEN, src[i].name + CAST_NAME_EXT_LEN, slen);
                    name_mi[CAST_NAME_EXT_LEN + slen] = '\0';
                }

                /* find all quad elements */
                int i_se = rp_find_parms_index(src, name_se);
                int i_hi = rp_find_parms_index(src, name_hi);
                int i_mi = rp_find_parms_index(src, name_mi);
                int i_lo = i;
                if (i_se < 0 || i_hi < 0 || i_mi < 0) {
                    continue;
                }

                /* create for each valid "rp" input vector tuple a "xy" output vector entry */
                p_dst[j].name = (char*) malloc(slen + 1);
                if (!p_dst[j].name) {
                    fprintf(stderr, "ERROR rp_copy_params_rp2xy - memory problem, the destination buffers failed to be allocated (2).\n");
                    return -3;
                }

                strncpy(p_dst[j].name, src[i_lo].name + CAST_NAME_EXT_LEN, slen);                       // yyy <-- LO_yyy
                p_dst[j].name[slen] = '\0';

                rp2xy_params_value_copy(&(p_dst[j]), src[i_se], src[i_hi], src[i_mi], src[i_lo]);
                //fprintf(stderr, "INFO rp_copy_params_rp2xy - out[%d] copied from in[%d,%d,%d,%d] - name = %s, val = %lf\n", j, i_se, i_hi, i_mi, i_lo, src[i_lo].name + CAST_NAME_EXT_LEN, p_dst[j].value);

                j++;

            } else {                                                                                    // SINGLE element
                const int slen = strlen(src[i].name);

                //fprintf(stderr, "DEBUG rp_copy_params_rp2xy - SINGLE - name=%s\n", src[i].name);

                if (!strcmp(TRANSPORT_pktIdx, src[i].name)) {
                    l_num_single_params--;
                    //fprintf(stderr, "DEBUG rp_copy_params_rp2xy - disregard this entry (1) - name = %s - num_single_params = %d, num_quad_params = %d\n", src[i].name, l_num_single_params, l_num_quad_params);
                    continue;
                }

                p_dst[j].name = (char*) malloc(slen + 1);
                if (!(p_dst[j].name)) {
                    fprintf(stderr, "ERROR rp_copy_params_rp2xy - memory problem, the destination buffer could not be allocated (2).\n");
                    return -3;
                }
                strncpy(p_dst[j].name, src[i].name, slen);
                p_dst[j].name[slen] = '\0';

                p_dst[j].value       = src[i].value;
                p_dst[j].fpga_update = src[i].fpga_update;
                p_dst[j].read_only   = src[i].read_only;
                p_dst[j].min_val     = src[i].min_val;
                p_dst[j].max_val     = src[i].max_val;
                //fprintf(stderr, "INFO rp_copy_params_rp2xy - out[%d] copied from in[%d] - name = %s, val = %lf\n", j, i, src[i].name, src[i].value);

                j++;
            }
        }  // for ()
    }  // if () else

    /* mark last one as final entry */
    p_dst[l_num_single_params + l_num_quad_params].name  = NULL;
    p_dst[l_num_single_params + l_num_quad_params].value = -1;

    *dst = p_dst;

    return l_num_single_params + l_num_quad_params;
}


/*----------------------------------------------------------------------------------*/
int print_xy_params(xy_app_params_t* params)
{
    if (!params) {
        return -1;
    }

    int i;
    for (i = 0; params[i].name; i++) {
        fprintf(stderr, "INFO print_xy_params: params[%d].name = %s - value = %lf\n", i, params[i].name, params[i].value);
    }

    return 0;
}


/*----------------------------------------------------------------------------------*/
int rp_free_params(rp_app_params_t** params)
{
    if (!params) {
        return -1;
    }

    /* free params structure */
    if (*params) {
        rp_app_params_t* p = *params;

        int i;
        for (i = 0; p[i].name; i++) {
            free(p[i].name);
            p[i].name = NULL;
        }

        free(*params);
        *params = NULL;
    }
    return 0;
}

/*----------------------------------------------------------------------------------*/
int xy_free_params(xy_app_params_t** params)
{
    if (!params) {
        return -1;
    }

    /* free params structure */
    if (*params) {
        xy_app_params_t* p = *params;

        int i;
        for (i = 0; p[i].name; i++) {
            free(p[i].name);
            p[i].name = NULL;
        }

        free(p);
        *params = NULL;
    }
    return 0;
}
