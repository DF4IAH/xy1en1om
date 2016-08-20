/*
 * test_sha256_fifo.h
 *
 *  Created on: 20.08.2016
 *      Author: espero
 */

#ifndef APPS_FREE_XY1EN1OM_SRC_TEST_SHA256_FIFO_H_
#define APPS_FREE_XY1EN1OM_SRC_TEST_SHA256_FIFO_H_


/**
 * @brief Initializing for validity check of SHA-256 FIFO mode
 *
 */
void test_sha256_fifo_INIT();

/**
 * @brief Testing and doing the validity check of SHA-256 FIFO mode
 *
 */
void test_sha256_fifo_TEST();

/**
 * @brief Finalizing for validity check of SHA-256 FIFO mode
 *
 */
void test_sha256_fifo_FINALIZE();


/**
 * @brief Check validity of SHA-256 sub-module with single letter 'A'
 *
 */
void test_sha256_fifo_1x_A();

/**
 * @brief Check validity of SHA-256 sub-module with double letter 'A'
 *
 */
void test_sha256_fifo_2x_A();

/**
 * @brief Check validity of SHA-256 sub-module with 55x letter 'A'
 *
 */
void test_sha256_fifo_55x_A();

/**
 * @brief Check validity of SHA-256 sub-module with 56x letter 'A'
 *
 */
void test_sha256_fifo_56x_A();

/**
 * @brief Check validity of SHA-256 sub-module with 119x letter 'A' that results to 512 bytes full of data
 *
 */
void test_sha256_fifo_119x_A();


#endif /* APPS_FREE_XY1EN1OM_SRC_TEST_SHA256_FIFO_H_ */
