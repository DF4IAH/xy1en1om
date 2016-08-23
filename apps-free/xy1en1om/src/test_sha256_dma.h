/*
 * test_sha256_dma.h
 *
 *  Created on: 21.08.2016
 *      Author: espero
 */

#ifndef APPS_FREE_XY1EN1OM_SRC_TEST_SHA256_DMA_H_
#define APPS_FREE_XY1EN1OM_SRC_TEST_SHA256_DMA_H_


/**
 * @brief Initializing for validity check of SHA-256 DMA mode
 *
 */
void test_sha256_dma_INIT();

/**
 * @brief Testing and doing the validity check of SHA-256 DMA mode
 *
 */
void test_sha256_dma_TEST();

/**
 * @brief Finalizing for validity check of SHA-256 DMA mode
 *
 */
void test_sha256_dma_FINALIZE();


/**
 * @brief Check validity of SHA-256 sub-module with a valid blockchain data test
 *
 */
void test_sha256_dma_blockchain_example();


#endif /* APPS_FREE_XY1EN1OM_SRC_TEST_SHA256_DMA_H_ */
