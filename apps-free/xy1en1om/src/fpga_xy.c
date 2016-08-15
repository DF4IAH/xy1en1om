/**
 * @brief Red Pitaya FPGA Interface for the xy1en1om sub-module.
 *
 * @author Ulrich Habel (DF4IAH) <espero7757@gmx.net>
 *
 * This part of code is written in C programming language.
 * Please visit http://en.wikipedia.org/wiki/C_(programming_language)
 * for more details on the language used herein.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <pthread.h>
#include <errno.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <unistd.h>
#include <fcntl.h>

#include "main.h"
#include "fpga.h"
#include "cb_http.h"


/** @brief CallBack copy of params from the worker when requested */
extern xy_app_params_t*     g_xy_info_worker_params;
/** @brief Holds mutex to access on parameters from the worker thread to any other context */
extern pthread_mutex_t      g_xy_info_worker_params_mutex;

/** @brief The xy1en1om memory file descriptor used to mmap() the FPGA space. */
extern int                  g_fpga_xy_mem_fd;
/** @brief The xy1en1om memory layout of the FPGA registers. */
extern fpga_xy_reg_mem_t*   g_fpga_xy_reg_mem;


/** @brief Filename of the default FPGA configuration. */
const char fn_bit[]       = "/opt/redpitaya/fpga/fpga.bit";

/** @brief Filename of the safed FPGA configuration. */
const char fn_bit_orig[]  = "/opt/redpitaya/fpga/fpga.bit_orig";

/** @brief Filename of a fresh xy1en1om FPGA configuration. */
const char fn_bit_fresh[] = "/opt/redpitaya/www/apps/xy1en1om/fpga.bit";


/*----------------------------------------------------------------------------*/
int fpga_xy_init(void)
{
    //fprintf(stderr, "DEBUG fpga_xy_init: BEGIN\n");

    /* make sure all previous data is vanished */
    fpga_xy_exit();

    /* init the xy1en1om FPGA sub-module access */
    if (fpga_mmap_area(&g_fpga_xy_mem_fd, (void**) &g_fpga_xy_reg_mem, FPGA_XY_BASE_ADDR, FPGA_XY_BASE_SIZE)) {
        fprintf(stderr, "ERROR - fpga_xy_init: g_fpga_xy_reg_mem - mmap() failed: %s\n", strerror(errno));
        fpga_exit();
        return -1;
    }
    //fprintf(stderr, "DEBUG fpga_xy_init: g_fpga_xy_reg_mem - having access pointer.\n");

    // Check for valid FPGA
    uint32_t ver = fpga_get_version();
    if ((ver < FPGA_VERSION_MIN) || (ver & 0x80000000)) {  // xy1en1om to old or contains no xy1en1om sub-module at all
        fprintf(stderr, "ERROR - fpga_xy_init: xy1en1om to old or contains no xy1en1om sub-module at all - version found: 20%08x\n", ver);
        fpga_exit();
        return -1;
    }

    // enable xy1en1om sub-module
    fpga_xy_enable(1);

    // studying section as quick hack
    {
        fprintf(stderr, "INFO study section: BEGIN\n");

#if 0
        sha256_test_1x_A();
#elif 0
        sha256_test_2x_A();
#elif 0
        sha256_test_55x_A();
#elif 0
        sha256_test_56x_A();
#else
        sha256_test_119x_A();
#endif

        fprintf(stderr, "INFO study section: END\n");
    }

    fprintf(stderr, "DEBUG fpga_xy_init: END\n");
    return 0;
}

/*----------------------------------------------------------------------------*/
int fpga_xy_exit(void)
{
    //fprintf(stderr, "fpga_xy_exit: BEGIN\n");

    /* disable xy1en1om sub-module */
    fpga_xy_enable(0);

    /* unmap the xy1en1om sub-module */
    if (fpga_munmap_area(&g_fpga_xy_mem_fd, (void**) &g_fpga_xy_reg_mem, FPGA_XY_BASE_ADDR, FPGA_XY_BASE_SIZE)) {
        fprintf(stderr, "ERROR - fpga_xy_exit: g_fpga_xy_reg_mem - munmap() failed: %s\n", strerror(errno));
    }

    //fprintf(stderr, "fpga_xy_exit: END\n");
    return 0;
}

/*----------------------------------------------------------------------------*/
void fpga_xy_enable(int enable)
{
    if (!g_fpga_xy_reg_mem) {
        return;
    }

    //fprintf(stderr, "DEBUG - fpga_xy_enable(%d): BEGIN\n", enable);

    if (enable) {
        // enable xy1en1om
        g_fpga_xy_reg_mem->ctrl           = 0x00000001;    // enable xy1en1om sub-module

        //fprintf(stderr, "fpga_xy_enable(1): enabling SHA-256 part\n");
        g_fpga_xy_reg_mem->sha256_ctrl    = 0x00000001;    // enable SHA-256 part of the xy1en1om sub-module

    } else {
        // disable xy1en1om
        //fprintf(stderr, "fpga_xy_enable(0): disabling SHA-256 part\n");
        g_fpga_xy_reg_mem->sha256_ctrl    = 0x00000000;    // disable SHA-256 part of the xy1en1om sub-module

        //fprintf(stderr, "fpga_xy_enable(0): disabling KEK-512 part\n");
        g_fpga_xy_reg_mem->kek512_ctrl    = 0x00000000;    // disable KEK-512 part of the xy1en1om sub-module

        //fprintf(stderr, "fpga_xy_enable(0): disabling xy1en1om sub-module\n");
        g_fpga_xy_reg_mem->ctrl           = 0x00000000;    // disable xy1en1om sub-module
    }

    //fprintf(stderr, "DEBUG - fpga_xy_enable(%d): END\n", enable);
}

/*----------------------------------------------------------------------------*/
void fpga_xy_reset(void)
{
    if (!g_fpga_xy_reg_mem) {
        return;
    }

    //fprintf(stderr, "INFO - fpga_xy_reset\n");

    /* set reset flag of the SHA-256 part which falls back by its own */
    g_fpga_xy_reg_mem->sha256_ctrl = 0x00000003;
    usleep(1);
}

/*----------------------------------------------------------------------------*/
uint32_t fpga_get_version()
{
    if (!g_fpga_xy_reg_mem) {
        return -1;
    }

    uint32_t version = g_fpga_xy_reg_mem->version;
    fprintf(stderr, "INFO - fpga_get_version: current FPGA xy1en1om version: %08x\n", version);

    if (version < 0x12010101 || version > 0x29123299) {
        //fprintf(stderr, "DEBUG - fpga_get_version: error -2\n");
        return -2;
    }

    int pos;
    for (pos = 28; pos >= 0; pos -= 4) {
        if (((version >> pos) & 0xf) > 0x9) {  // no HEX entries allowed as date and serial number
            //fprintf(stderr, "DEBUG - fpga_get_version: error -3\n");
            return -3;
        }
    }

    return version;  // valid date found
}

void sha256_test_1x_A()
{
    uint32_t h7, h6, h5, h4, h3, h2, h1, h0;
    uint32_t state = 0;
    struct timeval t0 = { 0 };
    struct timeval t1 = { 0 };
    struct timeval t2 = { 0 };
    struct timeval t3 = { 0 };

    fpga_xy_reset();

    // write data to the FIFO - MSB first
    // variant 1: have a single letter 'A'
    (void) gettimeofday(&t0, NULL);
    g_fpga_xy_reg_mem->sha256_data_push = 0x41800000;         // SHA256 FIFO MSB - #0 - one bit after the last data message is set
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO LSB - #0
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #1
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO LSB - #1
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #2
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO LSB - #2
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #3
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO LSB - #3
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #4
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO LSB - #4
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #5
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO LSB - #5
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #6
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO LSB - #6
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #7
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000008;         // SHA256 FIFO LSB - #7
    (void) gettimeofday(&t1, NULL);  // t1-t0 = 3.5µs

    // wait until ready
    state = g_fpga_xy_reg_mem->sha256_status;
    while (!(state & (1L << 1)))
        state = g_fpga_xy_reg_mem->sha256_status;
    (void) gettimeofday(&t2, NULL);  // t2-t0 = 5.9µs

    h7 = g_fpga_xy_reg_mem->sha256_hash_h7;
    h6 = g_fpga_xy_reg_mem->sha256_hash_h6;
    h5 = g_fpga_xy_reg_mem->sha256_hash_h5;
    h4 = g_fpga_xy_reg_mem->sha256_hash_h4;
    h3 = g_fpga_xy_reg_mem->sha256_hash_h3;
    h2 = g_fpga_xy_reg_mem->sha256_hash_h2;
    h1 = g_fpga_xy_reg_mem->sha256_hash_h1;
    h0 = g_fpga_xy_reg_mem->sha256_hash_h0;
    (void) gettimeofday(&t3, NULL);  // t3-t0 = 7.8µs

    fpga_xy_enable(0);

    fprintf(stderr, "INFO HASH = 0x%s  (reference = should be this value)\n", "559aead08264d5795d3909718cdd05abd49572e84fe55590eef31a88a08fdffd");
    fprintf(stderr, "INFO HASH = 0x%08x%08x%08x%08x%08x%08x%08x%08x  (calculated value)\n", h0, h1, h2, h3, h4, h5, h6, h7);
    fprintf(stderr, "INFO t0 = %ld.%06ld\n", t0.tv_sec, t0.tv_usec);
    fprintf(stderr, "INFO t1 = %ld.%06ld\n", t1.tv_sec, t1.tv_usec);
    fprintf(stderr, "INFO t2 = %ld.%06ld\n", t2.tv_sec, t2.tv_usec);
    fprintf(stderr, "INFO t3 = %ld.%06ld\n", t3.tv_sec, t3.tv_usec);
}

void sha256_test_2x_A()
{
    uint32_t h7, h6, h5, h4, h3, h2, h1, h0;
    uint32_t state = 0;
    struct timeval t0 = { 0 };
    struct timeval t1 = { 0 };
    struct timeval t2 = { 0 };
    struct timeval t3 = { 0 };

    fpga_xy_reset();

    // write data to the FIFO - MSB first
    // variant 2: have a double letter 'A'
    (void) gettimeofday(&t0, NULL);
    g_fpga_xy_reg_mem->sha256_data_push = 0x41418000;         // SHA256 FIFO MSB - #0 - one bit after the last data message is set
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO LSB - #0
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #1
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO LSB - #1
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #2
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO LSB - #2
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #3
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO LSB - #3
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #4
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO LSB - #4
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #5
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO LSB - #5
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #6
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO LSB - #6
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #7
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000010;         // SHA256 FIFO LSB - #7
    (void) gettimeofday(&t1, NULL);  // t1-t0 = 4µs

    // wait until ready
    state = g_fpga_xy_reg_mem->sha256_status;
    while (!(state & (1L << 1)))
        state = g_fpga_xy_reg_mem->sha256_status;
    (void) gettimeofday(&t2, NULL);  // t2-t0 = 6.5µs

    h7 = g_fpga_xy_reg_mem->sha256_hash_h7;
    h6 = g_fpga_xy_reg_mem->sha256_hash_h6;
    h5 = g_fpga_xy_reg_mem->sha256_hash_h5;
    h4 = g_fpga_xy_reg_mem->sha256_hash_h4;
    h3 = g_fpga_xy_reg_mem->sha256_hash_h3;
    h2 = g_fpga_xy_reg_mem->sha256_hash_h2;
    h1 = g_fpga_xy_reg_mem->sha256_hash_h1;
    h0 = g_fpga_xy_reg_mem->sha256_hash_h0;
    (void) gettimeofday(&t3, NULL);  // t3-t0 = 8.2µs

    fpga_xy_enable(0);

    fprintf(stderr, "INFO HASH = 0x%s  (reference = should be this value)\n", "58bb119c35513a451d24dc20ef0e9031ec85b35bfc919d263e7e5d9868909cb5");
    fprintf(stderr, "INFO HASH = 0x%08x%08x%08x%08x%08x%08x%08x%08x  (calculated value)\n", h0, h1, h2, h3, h4, h5, h6, h7);
    fprintf(stderr, "INFO t0 = %ld.%06ld\n", t0.tv_sec, t0.tv_usec);
    fprintf(stderr, "INFO t1 = %ld.%06ld\n", t1.tv_sec, t1.tv_usec);
    fprintf(stderr, "INFO t2 = %ld.%06ld\n", t2.tv_sec, t2.tv_usec);
    fprintf(stderr, "INFO t3 = %ld.%06ld\n", t3.tv_sec, t3.tv_usec);
}

void sha256_test_55x_A()
{
    uint32_t h7, h6, h5, h4, h3, h2, h1, h0;
    uint32_t state = 0;
    struct timeval t0 = { 0 };
    struct timeval t1 = { 0 };
    struct timeval t2 = { 0 };
    struct timeval t3 = { 0 };

    fpga_xy_reset();

    // write data to the FIFO - MSB first
    // variant 2: have a double letter 'A'
    (void) gettimeofday(&t0, NULL);
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #0
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #0
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #1
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #1
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #2
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #2
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #3
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #3
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #4
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #4
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #5
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #5
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #6
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414180;         // SHA256 FIFO LSB - #6 - one bit after the last data message is set
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #7
    g_fpga_xy_reg_mem->sha256_data_push = 0x000001B8;         // SHA256 FIFO LSB - #7
    (void) gettimeofday(&t1, NULL);  // t1-t0 = 4µs

    // wait until ready
    state = g_fpga_xy_reg_mem->sha256_status;
    while (!(state & (1L << 1)))
        state = g_fpga_xy_reg_mem->sha256_status;
    (void) gettimeofday(&t2, NULL);  // t2-t0 = 6µs

    h7 = g_fpga_xy_reg_mem->sha256_hash_h7;
    h6 = g_fpga_xy_reg_mem->sha256_hash_h6;
    h5 = g_fpga_xy_reg_mem->sha256_hash_h5;
    h4 = g_fpga_xy_reg_mem->sha256_hash_h4;
    h3 = g_fpga_xy_reg_mem->sha256_hash_h3;
    h2 = g_fpga_xy_reg_mem->sha256_hash_h2;
    h1 = g_fpga_xy_reg_mem->sha256_hash_h1;
    h0 = g_fpga_xy_reg_mem->sha256_hash_h0;
    (void) gettimeofday(&t3, NULL);  // t3-t0 = 8µs

    fpga_xy_enable(0);

    fprintf(stderr, "INFO HASH = 0x%s  (reference = should be this value)\n", "8963cc0afd622cc7574ac2011f93a3059b3d65548a77542a1559e3d202e6ab00");
    fprintf(stderr, "INFO HASH = 0x%08x%08x%08x%08x%08x%08x%08x%08x  (calculated value)\n", h0, h1, h2, h3, h4, h5, h6, h7);
    fprintf(stderr, "INFO t0 = %ld.%06ld\n", t0.tv_sec, t0.tv_usec);
    fprintf(stderr, "INFO t1 = %ld.%06ld\n", t1.tv_sec, t1.tv_usec);
    fprintf(stderr, "INFO t2 = %ld.%06ld\n", t2.tv_sec, t2.tv_usec);
    fprintf(stderr, "INFO t3 = %ld.%06ld\n", t3.tv_sec, t3.tv_usec);
}

void sha256_test_56x_A()
{
    uint32_t h7, h6, h5, h4, h3, h2, h1, h0;
    uint32_t state = 0;
    struct timeval t0 = { 0 };
    struct timeval t1 = { 0 };
    struct timeval t2 = { 0 };
    struct timeval t3 = { 0 };

    fpga_xy_reset();

    // write data to the FIFO - MSB first
    // variant 2: have a double letter 'A'
    (void) gettimeofday(&t0, NULL);
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #0
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #0
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #1
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #1
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #2
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #2
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #3
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #3
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #4
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #4
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #5
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #5
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #6
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #6
    g_fpga_xy_reg_mem->sha256_data_push = 0x80000000;         // SHA256 FIFO MSB - #7 - one bit after the last data message is set
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO LSB - #7

    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #8
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO LSB - #8
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #9
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO LSB - #9
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #10
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO LSB - #10
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #11
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO LSB - #11
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #12
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO LSB - #12
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #13
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO LSB - #13
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #14
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO LSB - #14
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #15
    g_fpga_xy_reg_mem->sha256_data_push = 0x000001C0;         // SHA256 FIFO LSB - #15
    (void) gettimeofday(&t1, NULL);  // t1-t0 = 6µs

    // wait until ready
    state = g_fpga_xy_reg_mem->sha256_status;
    while (!(state & (1L << 1)))
        state = g_fpga_xy_reg_mem->sha256_status;
    (void) gettimeofday(&t2, NULL);  // t2-t0 = 8.7µs

    h7 = g_fpga_xy_reg_mem->sha256_hash_h7;
    h6 = g_fpga_xy_reg_mem->sha256_hash_h6;
    h5 = g_fpga_xy_reg_mem->sha256_hash_h5;
    h4 = g_fpga_xy_reg_mem->sha256_hash_h4;
    h3 = g_fpga_xy_reg_mem->sha256_hash_h3;
    h2 = g_fpga_xy_reg_mem->sha256_hash_h2;
    h1 = g_fpga_xy_reg_mem->sha256_hash_h1;
    h0 = g_fpga_xy_reg_mem->sha256_hash_h0;
    (void) gettimeofday(&t3, NULL);  // t3-t0 = 10.7µs

    fpga_xy_enable(0);

    fprintf(stderr, "INFO HASH = 0x%s  (reference = should be this value)\n", "6ea719cefa4b31862035a7fa606b7cc3602f46231117d135cc7119b3c1412314");
    fprintf(stderr, "INFO HASH = 0x%08x%08x%08x%08x%08x%08x%08x%08x  (calculated value)\n", h0, h1, h2, h3, h4, h5, h6, h7);
    fprintf(stderr, "INFO t0 = %ld.%06ld\n", t0.tv_sec, t0.tv_usec);
    fprintf(stderr, "INFO t1 = %ld.%06ld\n", t1.tv_sec, t1.tv_usec);
    fprintf(stderr, "INFO t2 = %ld.%06ld\n", t2.tv_sec, t2.tv_usec);
    fprintf(stderr, "INFO t3 = %ld.%06ld\n", t3.tv_sec, t3.tv_usec);
}

void sha256_test_119x_A()
{
    uint32_t h7, h6, h5, h4, h3, h2, h1, h0;
    uint32_t state = 0;
    struct timeval t0 = { 0 };
    struct timeval t1 = { 0 };
    struct timeval t2 = { 0 };
    struct timeval t3 = { 0 };

    fpga_xy_reset();

    // write data to the FIFO - MSB first
    // variant 2: have a double letter 'A'
    (void) gettimeofday(&t0, NULL);
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #0
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #0
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #1
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #1
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #2
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #2
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #3
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #3
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #4
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #4
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #5
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #5
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #6
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #6
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #7
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #7

    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #8
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #8
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #9
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #9
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #10
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #10
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #11
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #11
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #12
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #12
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #13
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO LSB - #13
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414141;         // SHA256 FIFO MSB - #14
    g_fpga_xy_reg_mem->sha256_data_push = 0x41414180;         // SHA256 FIFO LSB - #14 - one bit after the last data message is set
    g_fpga_xy_reg_mem->sha256_data_push = 0x00000000;         // SHA256 FIFO MSB - #15
    g_fpga_xy_reg_mem->sha256_data_push = 0x000003B8;         // SHA256 FIFO LSB - #15
    (void) gettimeofday(&t1, NULL);  // t1-t0 = 6.2µs

    // wait until ready
    state = g_fpga_xy_reg_mem->sha256_status;
    while (!(state & (1L << 1)))
        state = g_fpga_xy_reg_mem->sha256_status;
    (void) gettimeofday(&t2, NULL);  // t2-t0 = 9.2µs

    h7 = g_fpga_xy_reg_mem->sha256_hash_h7;
    h6 = g_fpga_xy_reg_mem->sha256_hash_h6;
    h5 = g_fpga_xy_reg_mem->sha256_hash_h5;
    h4 = g_fpga_xy_reg_mem->sha256_hash_h4;
    h3 = g_fpga_xy_reg_mem->sha256_hash_h3;
    h2 = g_fpga_xy_reg_mem->sha256_hash_h2;
    h1 = g_fpga_xy_reg_mem->sha256_hash_h1;
    h0 = g_fpga_xy_reg_mem->sha256_hash_h0;
    (void) gettimeofday(&t3, NULL);  // t3-t0 = 10.5µs

    fpga_xy_enable(0);

    fprintf(stderr, "INFO HASH = 0x%s  (reference = should be this value)\n", "17d2f0f7197a6612e311d141781f2b9539c4aef7affd729246c401890e000dde");
    fprintf(stderr, "INFO HASH = 0x%08x%08x%08x%08x%08x%08x%08x%08x  (calculated value)\n", h0, h1, h2, h3, h4, h5, h6, h7);
    fprintf(stderr, "INFO t0 = %ld.%06ld\n", t0.tv_sec, t0.tv_usec);
    fprintf(stderr, "INFO t1 = %ld.%06ld\n", t1.tv_sec, t1.tv_usec);
    fprintf(stderr, "INFO t2 = %ld.%06ld\n", t2.tv_sec, t2.tv_usec);
    fprintf(stderr, "INFO t3 = %ld.%06ld\n", t3.tv_sec, t3.tv_usec);
}


#if 0
/* --------------------------------------------------------------------------- *
 * FPGA SECOND ACCESS METHOD
 * --------------------------------------------------------------------------- */

/*----------------------------------------------------------------------------*/
/**
 * @brief Reads value from the specific xy1en1om sub-module register
 *
 * @param[in] xy_reg_ofs  offset value for the xy1en1om base address to be written to.
 *
 * @retval  value of the specified register.
 */
uint32_t fpga_xy_read_register(unsigned int xy_reg_ofs)
{
    //fprintf(stderr, "fpga_xy_read_register: BEGIN\n");
    if (!g_fpga_xy_reg_mem) {
        return -1;
    }

    uint32_t value = *((uint32_t*) ((void*) g_fpga_xy_reg_mem) + rb_reg_ofs);
    fprintf(stderr, "fpga_xy_read_register: ofs=0x%06x --> read=0x%08x\n", xy_reg_ofs, value);
    fprintf(stderr, "fpga_xy_read_register: END\n");
    return value;
}

/*----------------------------------------------------------------------------*/
/**
 * @brief Writes value to the specific xy1en1om sub-module register
 *
 * @param[in] xy_reg_ofs  offset value for the xy1en1om base address to be written to.
 * @param[in] value  value that is written to the specified register.
 *
 * @retval  0 Success
 * @retval -1 Failure, error message is output on standard error device
 */
int fpga_xy_write_register(unsigned int xy_reg_ofs, uint32_t value)
{
    //fprintf(stderr, "fpga_xy_write_register: BEGIN\n");

    if (!g_fpga_xy_reg_mem) {
        return -1;
    }

    fprintf(stderr, "fpga_xy_write_register: ofs=0x%06x <-- write=0x%08x\n", xy_reg_ofs, value);
    *((uint32_t*) ((void*) g_fpga_xy_reg_mem) + rb_reg_ofs) = value;

    //fprintf(stderr, "fpga_xy_write_register: END\n");
    return 0;
}
#endif
