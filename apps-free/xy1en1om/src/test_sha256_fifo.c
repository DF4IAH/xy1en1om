/**
 * @brief Red Pitaya Validity tester for the SHA256 FIFO feature
 * of the xy1en1om sub-module.
 *
 * @author Ulrich Habel (DF4IAH) <espero7757@gmx.net>
 *
 * This part of code is written in C programming language.
 * Please visit http://en.wikipedia.org/wiki/C_(programming_language)
 * for more details on the language used herein.
 */

#include <stdio.h>
#include <pthread.h>
#include <sys/time.h>

#include "test_sha256_fifo.h"
#include "main.h"
#include "fpga_xy.h"


/** @brief CallBack copy of params from the worker when requested */
extern xy_app_params_t*     g_xy_info_worker_params;
/** @brief Holds mutex to access on parameters from the worker thread to any other context */
extern pthread_mutex_t      g_xy_info_worker_params_mutex;

/** @brief The xy1en1om memory layout of the FPGA registers. */
extern fpga_xy_reg_mem_t*   g_fpga_xy_reg_mem;

/* --- */

void test_sha256_fifo_INIT()
{

}

void test_sha256_fifo_TEST()
{

#if 0
    test_sha256_fifo_1x_A();
#elif 0
    test_sha256_fifo_2x_A();
#elif 0
    test_sha256_fifo_55x_A();
#elif 0
    test_sha256_fifo_56x_A();
#else
    test_sha256_fifo_119x_A();
#endif

}

void test_sha256_fifo_FINALIZE()
{

}

/* --- */

void test_sha256_fifo_1x_A()
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

void test_sha256_fifo_2x_A()
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

void test_sha256_fifo_55x_A()
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

void test_sha256_fifo_56x_A()
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

void test_sha256_fifo_119x_A()
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
