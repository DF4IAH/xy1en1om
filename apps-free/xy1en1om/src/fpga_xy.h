/**
 * @brief xy1en1om FPGA Interface.
 *
 * @author Ulrich Habel (DF4IAH) <espero7757@gmx.net>
 *
 * This part of code is written in C programming language.
 * Please visit http://en.wikipedia.org/wiki/C_(programming_language)
 * for more details on the language used herein.
 */

#ifndef __FPGA_XY_H
#define __FPGA_XY_H

#include <stdint.h>

#include "main.h"


/** @defgroup fpga_xy_h FPGA xy1en1om sub-module access
 * @{
 */

/** @brief xy1en1om starting address of FPGA registers. */
#define FPGA_XY_BASE_ADDR       0x40100000

/** @brief xy1en1om memory map size of FPGA registers. */
#define FPGA_XY_BASE_SIZE       0x10000

/** @brief xy1en1om minimum FPGA version needed for this driver to work. */
#define FPGA_VERSION_MIN        0x16081001


/** @brief FPGA register offset addresses of the xy1en1om sub-system base address.
 */
enum {
    /* OMNI section */
    REG_RW_CTRL                           =  0x000,   // xy1en1om control register
    REG_RD_STATUS                         =  0x004,   // xy1en1om status  register
    REG_RD_VERSION                        =  0x00C,   // FPGA version information

    /* SHA256 section */
    REG_RW_SHA256_CTRL                    =  0x100,   // SHA256 submodule control register
    REG_RD_SHA256_STATUS                  =  0x104,   // SHA256 submodule status  register
    REG_RW_SHA256_BIT_LEN                 =  0x108,   // SHA256 submodule number of data bit to be hashed
    REG_WR_SHA256_DATA_PUSH               =  0x10C,   // SHA256 submodule data push in FIFO
    REG_RD_SHA256_HASH_H7                 =  0x110,   // SHA256 submodule hash out H7, LSB
    REG_RD_SHA256_HASH_H6                 =  0x114,   // SHA256 submodule hash out H6
    REG_RD_SHA256_HASH_H5                 =  0x118,   // SHA256 submodule hash out H5
    REG_RD_SHA256_HASH_H4                 =  0x11C,   // SHA256 submodule hash out H4
    REG_RD_SHA256_HASH_H3                 =  0x120,   // SHA256 submodule hash out H3
    REG_RD_SHA256_HASH_H2                 =  0x124,   // SHA256 submodule hash out H2
    REG_RD_SHA256_HASH_H1                 =  0x128,   // SHA256 submodule hash out H1
    REG_RD_SHA256_HASH_H0                 =  0x12C,   // SHA256 submodule hash out H0, MSB
    REG_RD_SHA256_FIFO_WR_COUNT           =  0x130,   // SHA256 FIFO stack count, at most this number of items are in the FIFO
    REG_RD_SHA256_FIFO_RD_COUNT           =  0x134,   // SHA256 FIFO stack count, at least this number of items can be pulled from the FIFO

    /* KECCAK512 section */
    REG_RW_KECCAK512_CTRL                 =  0x200,   // KECCAK512 submodule control register
    REG_RD_KECCAK512_STATUS               =  0x204    // KECCAK512 submodule status  register

} FPGA_XY_REG_ENUMS;

/** @brief FPGA registry structure for the xy1en1om sub-module.
 *
 * This structure is the direct image of the physical FPGA memory for the xy1en1om sub-module.
 * It assures direct read / write FPGA access when it is mapped to the appropriate memory address
 * through the /dev/mem device.
 */
typedef struct fpga_xy_reg_mem_s {

    /* OMNI section */

    /** @brief  R/W XY_CTRL - Control register (addr: 0x40100000)
     *
     * bit h00: ENABLE - '1' enables the xy1en1om sub-module of the FPGA.
     *
     * bit h1F..h01: n/a
     *
     */
    uint32_t ctrl;

    /** @brief  R/O XY_STATUS - Status register (addr: 0x40100004)
     *
     * bit h00: STAT_X11_EN - '1' X11 sub-module enabled.
     *
     * bit h03..h01: n/a
     *
     * bit h04: STAT_SHA256_EN - '1' SHA-256 part of the X11 sub-module enabled.
     *
     * bit h07..h05: n/a
     *
     * bit h08: STAT_KEK512_EN - '1' KECCAK-512 part of the X11 sub-module enabled.
     *
     * bit h1F..h09: n/a
     *
     */
    uint32_t status;

    /** @brief  Placeholder for addr: 0x40100008
     *
     * n/a
     *
     */
    uint32_t reserved_008;

    /** @brief  R/W RB_ICR - Interrupt control register (addr: 0x4010000C)
     *
     * n/a
     *
     */
    uint32_t version;


    /** @brief  Placeholder for addr: 0x40100010 .. 0x406000FC
     *
     * n/a
     *
     */
    uint32_t reserved_010To0fc[((0x0fc - 0x010) >> 2) + 1];


    /** @brief  R/W XY_SHA256_CTRL - Control register (addr: 0x40100100)
     *
     * bit h00: ENABLE - '1' enables the SHA-256 part of the xy1en1om sub-module of the FPGA.
     *
     * bit h1F..h01: n/a
     *
     */
    uint32_t sha256_ctrl;

    /** @brief  R/O XY_SHA256_STATUS - Status register (addr: 0x40100104)
     *
     * bit h00: STAT_SHA256_RDY - '1' SHA-256 part is ready to start.
     *
     * bit h01: STAT_SHA256_HASH_VALID - '1' SHA-256 part presents valid hash ID.
     *
     * bit h03..h02: n/a
     *
     * bit h04: STAT_SHA256_FIFO_EMPTY - '1' SHA-256 FIFO is empty.
     *
     * bit h05: STAT_SHA256_FIFO_ALMOST_FULL - '1' SHA-256 FIFO is almost full.
     *
     * bit h06: STAT_SHA256_FIFO_FULL - '1' SHA-256 FIFO is full.
     *
     * bit h1F..h07: n/a
     *
     */
    uint32_t sha256_status;

    /** @brief  R/W XY_SHA256_BIT_LEN - Status register (addr: 0x40100108)
     *
     * bit h1F..h01: number of bit to hash (not yet enabled)
     *
     */
    uint32_t sha256_bit_len;

    /** @brief  W/O XY_SHA256_DATA_PUSH - Data push register (addr: 0x4010010C)
     *
     * bit h1F..h00: bits to be hashed. Starting with the MSB bit h1F.
     *
     */
    uint32_t sha256_data_push;

    /** @brief  R/O XY_SHA256_HASH_H7 - Returned hash value register (addr: 0x40100110)
     *
     * bit h1F..h00: H7-part of the hash value (LSB).
     *
     */
    uint32_t sha256_hash_h7;

    /** @brief  R/O XY_SHA256_HASH_H6 - Returned hash value register (addr: 0x40100114)
     *
     * bit h1F..h00: H6-part of the hash value.
     *
     */
    uint32_t sha256_hash_h6;

    /** @brief  R/O XY_SHA256_HASH_H5 - Returned hash value register (addr: 0x40100118)
     *
     * bit h1F..h00: H5-part of the hash value.
     *
     */
    uint32_t sha256_hash_h5;

    /** @brief  R/O XY_SHA256_HASH_H4 - Returned hash value register (addr: 0x4010011C)
     *
     * bit h1F..h00: H4-part of the hash value.
     *
     */
    uint32_t sha256_hash_h4;

    /** @brief  R/O XY_SHA256_HASH_H3 - Returned hash value register (addr: 0x40100120)
     *
     * bit h1F..h00: H3-part of the hash value.
     *
     */
    uint32_t sha256_hash_h3;

    /** @brief  R/O XY_SHA256_HASH_H2 - Returned hash value register (addr: 0x40100124)
     *
     * bit h1F..h00: H2-part of the hash value.
     *
     */
    uint32_t sha256_hash_h2;

    /** @brief  R/O XY_SHA256_HASH_H1 - Returned hash value register (addr: 0x40100128)
     *
     * bit h1F..h00: H1-part of the hash value.
     *
     */
    uint32_t sha256_hash_h1;

    /** @brief  R/O XY_SHA256_HASH_H0 - Returned hash value register (addr: 0x4010012C)
     *
     * bit h1F..h00: H0-part of the hash value (MSB).
     *
     */
    uint32_t sha256_hash_h0;

    /** @brief  R/O XY_SHA256_FIFO_WR_COUNT - SHA256 FIFO write stack count register (addr: 0x40100130)
     *
     * bit h1F..h00: at most this number of items are in the FIFO.
     *
     */
    uint32_t sha256_fifo_wr_count;

    /** @brief  R/O XY_SHA256_FIFO_RD_COUNT - SHA256 FIFO read stack count register (addr: 0x40100134)
     *
     * bit h1F..h00: at least this number of items can be pulled from the FIFO.
     *
     */
    uint32_t sha256_fifo_rd_count;


    /** @brief  Placeholder for addr: 0x40100138 .. 0x406001FC
     *
     * n/a
     *
     */
    uint32_t reserved_138To1fc[((0x1fc - 0x138) >> 2) + 1];


    /** @brief  R/W XY_KEK512_CTRL - Control register (addr: 0x40100200)
     *
     * bit h00: ENABLE - '1' enables the KEK-512 part of the xy1en1om sub-module of the FPGA.
     *
     * bit h1F..h01: n/a
     *
     */
    uint32_t kek512_ctrl;

    /** @brief  R/O XY_KEK512_STATUS - Status register (addr: 0x40100204)
     *
     * bit h1f..h00: n/a
     *
     */
    uint32_t kek512_status;

} fpga_xy_reg_mem_t;


/* function declarations, detailed descriptions is in apparent implementation file  */


// xy1en1om FPGA accessors

/**
 * @brief Initialize interface to xy1en1om FPGA sub-module
 *
 * Set-up for FPGA access to the xy1en1om sub-module.
 *
 * @retval  0 Success
 * @retval -1 Failure, error message is printed on standard error device
 *
 */
int fpga_xy_init(void);

/**
 * @brief Finalize and release allocated resources of the xy1en1om sub-module
 *
 * @retval 0 Success, never fails
 */
int fpga_xy_exit(void);

/**
 * @brief Enables or disables xy1en1om FPGA sub-module
 *
 * @param[in] enable  nonzero enables the xy1en1om sub-module, zero disables it.
 *
 */
void fpga_xy_enable(int enable);

/**
 * @brief Resets xy1en1om FPGA sub-module
 *
 */
void fpga_xy_reset(void);

/**
 * @brief Get the version number of the xy1en1om FPGA sub-module
 *
 * @retval        version   Date and serial number stamp, < 0: error
 * @retval        -1        FPGA not initialized
 * @retval        -2        Date out of valid span
 * @retval        -3        Hex numbers found within date/serial version format
 */
uint32_t fpga_get_version();


#if 0
/**
 * @brief Move current fpga.bit file out of the way and copy local file to the central directory
 *
 * @retval        0         success
 * @retval        -1        error
 */
int fpga_xy_prepare_file();

/**
 * @brief Reload new configuration to the FPGA
 *
 */
void fpga_xy_reload_fpga();


/**
 * @brief Updates all modified data attributes to the xy1en1om FPGA sub-module
 *
 * Being called out of the worker context.
 *
 * @param[inout]  pb     List of base parameters with complete set of data entries.
 * @param[in]     p_pn   List of parameters to be scanned for marked entries, removes MARKER.
 *
 * @retval        0      Success
 * @retval        -1     Failure, parameter list or RB accessor not valid
 * @retval        -2     Failure, parameter list or RB accessor not valid
 */
int fpga_xy_update_all_params(xy_app_params_t* pb, xy_app_params_t** p_pn);

/**
 * @brief Read back automatic register values from the xy1en1om FPGA sub-module
 *
 * Being called out of the worker context.
 *
 * @param[inout]  pb     List of base parameters with complete set of data entries.
 * @param[in]     p_pn   List of returned FPGA parameters added to that list.
 *
 * @retval        1      Success, new data available
 * @retval        0      Success, no change of data
 * @retval        -1     Failure, parameter list or RB accessor not valid
 * @retval        -2     Failure, parameter list or RB accessor not valid
 */
int fpga_xy_get_fpga_params(xy_app_params_t* pb, xy_app_params_t** p_pn);


/**
 * @brief Calculates and programs the FPGA xy1en1om ctrl and misc registers
 *
 * @param[in]  xy_run           xy1en1om application  0: disabled, else: enabled.
 */
void fpga_xy_set_ctrl(int xy_run);
#endif

#if 0
/**
 * @brief Reads FPGA xy1en1om automatic registers
 *
 * @param[in]  tx_modtyp               2==USB, 3==LSB, 4==AM, 7==FM, 8==PM - else ignored.
 * @param[in]  rx_modtyp               2==USB, 3==LSB, 4==AMenv, 5==AMsync_USB, 6==AMsync_LSB, 7==FM, 8==PM - else ignored.
 * @param[out] loc_RD_ovrdrv           Current overdrive flags.
 */
void fpga_xy_get_ctrl(int tx_modtyp, int rx_modtyp,
        uint16_t* loc_RD_ovrdrv);
#endif


#if 0
uint32_t fpga_xy_read_register(unsigned int xy_reg_ofs);
int fpga_xy_write_register(unsigned int xy_reg_ofs, uint32_t value);
#endif

/** @} */


#endif /* __FPGA_XY_H */
