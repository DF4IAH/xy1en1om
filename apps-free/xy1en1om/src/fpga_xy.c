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
#include <string.h>
#include <pthread.h>
#include <errno.h>
#include <unistd.h>

#include "main.h"
#include "fpga.h"
#include "cb_http.h"
#include "test_sha256_fifo.h"
#include "test_sha256_dma.h"


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
        fprintf(stderr, "INFO study section: INIT - BEGIN\n");
#if 0
        test_sha256_fifo_INIT();
#else
        test_sha256_dma_INIT();
#endif
        fprintf(stderr, "INFO study section: INIT - END\n");

        fprintf(stderr, "INFO study section: TEST - BEGIN\n");
#if 0
        test_sha256_fifo_TEST();
#else
        test_sha256_dma_TEST();
#endif
        fprintf(stderr, "INFO study section: TEST - END\n");
    }

    fprintf(stderr, "DEBUG fpga_xy_init: END\n");
    return 0;
}

/*----------------------------------------------------------------------------*/
int fpga_xy_exit(void)
{
    //fprintf(stderr, "fpga_xy_exit: BEGIN\n");

    fprintf(stderr, "INFO study section: FINALIZE - BEGIN\n");
#if 0
    test_sha256_fifo_FINALIZE();
#else
    test_sha256_dma_FINALIZE();
#endif
    fprintf(stderr, "INFO study section: FINALIZE - END\n");

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
