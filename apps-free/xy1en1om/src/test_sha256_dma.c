/**
 * @brief Red Pitaya Validity tester for the SHA256 DMA feature
 * of the xy1en1om sub-module.
 *
 * @author Ulrich Habel (DF4IAH) <espero7757@gmx.net>
 *
 * This part of code is written in C programming language.
 * Please visit http://en.wikipedia.org/wiki/C_(programming_language)
 * for more details on the language used herein.
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <pthread.h>
#include <sys/time.h>
//#include <asm/cachectl.h>

#include "test_sha256_dma.h"
#include "main.h"
#include "fpga_xy.h"


const uint64_t testmsg_rom[] = {
#if 1
            0x81cd02ab01000000,
            0xcd9317e27e569e8b,
            0x44d49ab2fe99f2de,
            0xa3080000b8851ba4,
            0xe320b6c200000000,
            0x0423db8bfffc8d75,
            0x710e951e1eb942ae,
            0xfc8892b0d797f7af,

            0xc7f5d74df1fc122b,
            0x42a14695f2b9441a,
            0x0000000080000000,
            0x0000000000000000,
            0x0000000000000000,
            0x0000000000000000,
            0x0000000000000000,
            0x0000028000000000
#else
            0x1020304050607080,
            0x1121314151617181,
            0x1222324252627282,
            0x1323334353637383,
            0x1424344454647484,
            0x1525354555657585,
            0x1626364656667686,
            0x1727374757677787,

            0x1828384858687888,
            0x1929394959697989,
            0x1a2a3a4a5a6a7a8a,
            0x1b2b3b4b5b6b7b8b,
            0x1c2c3c4c5c6c7c8c,
            0x1d2d3d4d5d6d7d8d,
            0x1e2e3e4e5e6e7e8e,
            0x1f2f3f4f5f6f7f8f
#endif
};

/** @brief CallBack copy of params from the worker when requested */
extern xy_app_params_t*     g_xy_info_worker_params;
/** @brief Holds mutex to access on parameters from the worker thread to any other context */
extern pthread_mutex_t      g_xy_info_worker_params_mutex;

/** @brief The xy1en1om memory layout of the FPGA registers. */
extern fpga_xy_reg_mem_t*   g_fpga_xy_reg_mem;

/* @brief DMA memory as virtual memory seen by the software module */
void* g_dma_buf = NULL;

/* @brief DMA memory as physical memory seen by the FPGA on the AMBA bus */
intptr_t g_dma_paddr = 0;


/* --- */

void test_sha256_dma_INIT()
{
#if 1
    // get DMA memory on a 4kB page - this allows axi_datamover_s_axi_hp0 to operate with the basic command mode
    g_dma_buf = valloc(1UL << 12);  // 4kB
#else
    // get DMA memory on an 64bit-alignment (at least)
    posix_memalign(&g_dma_buf, sizeof(uint64_t), 1UL << 20);
#endif
}

void test_sha256_dma_TEST()
{
    test_sha256_dma_blockchain_example();
}

void test_sha256_dma_FINALIZE()
{
    if (g_dma_buf) {
        g_dma_paddr = 0;
        free(g_dma_buf);
        g_dma_buf = NULL;
    }
}

/* --- */


void test_sha256_dma_blockchain_example()
{
    uint32_t h7, h6, h5, h4, h3, h2, h1, h0;
    uint32_t status = 0;
    struct timeval t0 = { 0 };
    struct timeval t1 = { 0 };
    struct timeval t2 = { 0 };
    struct timeval t3 = { 0 };

    // ---
    // Prepare DMA memory
    {
        if (!g_dma_buf)
            return;

        // prepare the DMA data
        (void) memcpy(g_dma_buf, testmsg_rom, sizeof(testmsg_rom));

        // flush the D-cache
        {
            FILE *dropcaches;
            if ((dropcaches = fopen("/proc/sys/vm/drop_caches", "w"))) {
                fprintf(stderr, "dropping caches. Got filehandle = %p, filehandle ID = %d\n", dropcaches, fileno(dropcaches));
                fprintf(dropcaches, "1\n");
                fclose(dropcaches);
            }
        }

        {
            // https://www.kernel.org/doc/Documentation/vm/pagemap.txt
            FILE *pagemap;
            intptr_t paddr = 0;
            uint64_t e;
            int offset = (((uint32_t) g_dma_buf) / sysconf(_SC_PAGESIZE)) * sizeof(uint64_t);

            //fprintf(stderr, "INFO sysconf(_SC_PAGESIZE) = %ld, sizeof(uint64_t) = %d, offset = %d\n", sysconf(_SC_PAGESIZE), sizeof(uint64_t), offset);

            if ((pagemap = fopen("/proc/self/pagemap", "r"))) {
                if (lseek(fileno(pagemap), offset, SEEK_SET) == offset) {
                    if (fread(&e, sizeof(uint64_t), 1, pagemap)) {
                        if (e & (1ULL << 63)) { // page present ?
                            paddr  = e & ((1ULL << 55) - 1); // pfn mask
                            paddr *= sysconf(_SC_PAGESIZE);
                            // add offset within page
                            paddr |= (((uint32_t) g_dma_buf) & (sysconf(_SC_PAGESIZE) - 1));
                        }
                    }
                }
                fclose(pagemap);
            }
            g_dma_paddr = paddr;

            fprintf(stderr, "INFO g_dma_buf = %p\tg_dma_paddr = 0x%08x\n", g_dma_buf, g_dma_paddr);
        }
    }

    // ---

    fpga_xy_reset();

    (void) gettimeofday(&t0, NULL);
    g_fpga_xy_reg_mem->sha256_dma_base_addr = g_dma_paddr;    // SHA256 DMA - base address
    g_fpga_xy_reg_mem->sha256_dma_bit_len   = sizeof(testmsg_rom) << 3;  // SHA256 DMA - bit len
    g_fpga_xy_reg_mem->sha256_dma_nonce_ofs = 0x00000260;     // SHA256 DMA - nonce entry offset in bits
    g_fpga_xy_reg_mem->sha256_ctrl          = 0x00000033;     // SHA256 control: DMA_START | DBL_HASH | DMA_MODE | RESET trigger | ENABLE
    g_fpga_xy_reg_mem->sha256_ctrl          = 0x000000B1;     // SHA256 control: DMA_START | DBL_HASH | DMA_MODE | RESET trigger | ENABLE
    (void) gettimeofday(&t1, NULL);  // t1-t0 = x.xµs

    // wait until ready
    const int maxiter = 256;
    int iter = maxiter;
    status = g_fpga_xy_reg_mem->sha256_status;
    while (!(status & (1L << 1)) && iter) {
#if 0
        uint32_t fifo_wr_cnt          = g_fpga_xy_reg_mem->sha256_fifo_wr_count;
        uint32_t fifo_rd_cnt          = g_fpga_xy_reg_mem->sha256_fifo_rd_count;
        //uint32_t fifo_rd_last         = g_fpga_xy_reg_mem->sha256_data_push;
        uint32_t dma_state            = g_fpga_xy_reg_mem->sha256_dma_state;
        uint32_t dma_axi_r_state      = g_fpga_xy_reg_mem->sha256_dma_axi_r_state;
        uint32_t dma_axi_w_state      = g_fpga_xy_reg_mem->sha256_dma_axi_w_state;
        uint32_t sha256_dma_last_data = g_fpga_xy_reg_mem->sha256_dma_last_data;
        fprintf(stderr, "INFO waiting - status = %08x,  " \
                "fifo_wr_cnt = %03d, fifo_rd_cnt = %03d,  " \
                "fifo_rd_last = 0x%08x,  " \
                "dma_state = 0x%02x,  " \
                "dma_axi_r_state = 0x%08x, dma_axi_w_state = 0x%08x,  " \
                "sha256_dma_last_data = 0x%08x\n",
                status,
                fifo_wr_cnt, fifo_rd_cnt,
                0, //fifo_rd_last,
                dma_state,
                dma_axi_r_state, dma_axi_w_state,
                sha256_dma_last_data);
#endif
        status = g_fpga_xy_reg_mem->sha256_status;
       --iter;
    }
    (void) gettimeofday(&t2, NULL);  // t2-t0 = x.xµs

    h7 = g_fpga_xy_reg_mem->sha256_hash_h7;
    h6 = g_fpga_xy_reg_mem->sha256_hash_h6;
    h5 = g_fpga_xy_reg_mem->sha256_hash_h5;
    h4 = g_fpga_xy_reg_mem->sha256_hash_h4;
    h3 = g_fpga_xy_reg_mem->sha256_hash_h3;
    h2 = g_fpga_xy_reg_mem->sha256_hash_h2;
    h1 = g_fpga_xy_reg_mem->sha256_hash_h1;
    h0 = g_fpga_xy_reg_mem->sha256_hash_h0;
    (void) gettimeofday(&t3, NULL);  // t3-t0 = x.xµs

    uint32_t sha256_dma_clock_start    =  g_fpga_xy_reg_mem->sha256_dma_clock_start;
    uint32_t sha256_dma_clock_last     =  g_fpga_xy_reg_mem->sha256_dma_clock_last;
    uint32_t sha256_dma_clock_stop     =  g_fpga_xy_reg_mem->sha256_dma_clock_stop;
    uint32_t sha256_eng_clock_continue =  g_fpga_xy_reg_mem->sha256_eng_clock_continue;
    uint32_t sha256_eng_clock_dblhash  =  g_fpga_xy_reg_mem->sha256_eng_clock_dblhash;
    uint32_t sha256_eng_clock_complete =  g_fpga_xy_reg_mem->sha256_eng_clock_complete;
    uint32_t sha256_eng_clock_finish   =  g_fpga_xy_reg_mem->sha256_eng_clock_finish;
    uint32_t sha256_eng_state_loop     =  g_fpga_xy_reg_mem->sha256_eng_state_loop;

    fpga_xy_enable(0);

    fprintf(stderr, "INFO waiting iterations = %d\n", maxiter - iter);
    fprintf(stderr, "INFO DMA-FIFO    starting clock = %d last_dta clock = %d, time used = %05d clocks = %11.6lf µs\n",
            sha256_dma_clock_start, sha256_dma_clock_last,     sha256_dma_clock_last     - sha256_dma_clock_start, (sha256_dma_clock_last - sha256_dma_clock_start) / 125.0);
    fprintf(stderr, "INFO DMA-FIFO    starting clock = %d stopping clock = %d, time used = %05d clocks = %11.6lf µs\n",
            sha256_dma_clock_start, sha256_dma_clock_stop,     sha256_dma_clock_stop     - sha256_dma_clock_start, (sha256_dma_clock_stop - sha256_dma_clock_start) / 125.0);
    fprintf(stderr, "INFO SHA256-Eng. starting clock = %d continue clock = %d, time used = %05d clocks = %11.6lf µs\n",
            sha256_dma_clock_start, sha256_eng_clock_continue, sha256_eng_clock_continue - sha256_dma_clock_start, (sha256_eng_clock_continue - sha256_dma_clock_start) / 125.0);
    fprintf(stderr, "INFO SHA256-Eng. starting clock = %d dblhash  clock = %d, time used = %05d clocks = %11.6lf µs\n",
            sha256_dma_clock_start, sha256_eng_clock_dblhash,  sha256_eng_clock_dblhash  - sha256_dma_clock_start, (sha256_eng_clock_dblhash  - sha256_dma_clock_start) / 125.0);
    fprintf(stderr, "INFO SHA256-Eng. starting clock = %d complete clock = %d, time used = %05d clocks = %11.6lf µs\n",
            sha256_dma_clock_start, sha256_eng_clock_complete, sha256_eng_clock_complete - sha256_dma_clock_start, (sha256_eng_clock_complete - sha256_dma_clock_start) / 125.0);
    fprintf(stderr, "INFO SHA256-Eng. starting clock = %d finish.  clock = %d, time used = %05d clocks = %11.6lf µs\n",
            sha256_dma_clock_start, sha256_eng_clock_finish,   sha256_eng_clock_finish   - sha256_dma_clock_start, (sha256_eng_clock_finish   - sha256_dma_clock_start) / 125.0);
    fprintf(stderr, "INFO sha256_engine state_loop   = %08x\n", sha256_eng_state_loop);
    fprintf(stderr, "INFO HASH = 0x%s  (reference = should be this value)\n", "1dbd981fe6985776b644b173a4d0385ddc1aa2a829688d1e0000000000000000");
    fprintf(stderr, "INFO HASH = 0x%08x%08x%08x%08x%08x%08x%08x%08x  (calculated value)\n", h0, h1, h2, h3, h4, h5, h6, h7);
    fprintf(stderr, "INFO t0 = %ld.%06ld\n", t0.tv_sec, t0.tv_usec);
    fprintf(stderr, "INFO t1 = %ld.%06ld, t1-t0 = %ldµs\n", t1.tv_sec, t1.tv_usec, t1.tv_usec - t0.tv_usec);
    fprintf(stderr, "INFO t2 = %ld.%06ld, t2-t0 = %ldµs\n", t2.tv_sec, t2.tv_usec, t2.tv_usec - t0.tv_usec);
    fprintf(stderr, "INFO t3 = %ld.%06ld, t3-t0 = %ldµs\n", t3.tv_sec, t3.tv_usec, t3.tv_usec - t0.tv_usec);
}
