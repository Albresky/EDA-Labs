/*
 * @Author: GitHub Copilot
 * @Date: 2025-04-05 10:00:00
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-04-04 18:54:47
 * @FilePath: /BUPT-EDA-Labs/lab1/src/BeidouB1I.h
 * @Description: Beidou B1I Signal Acquisition Module
 */
#ifndef BEIDOU_B1I_H
#define BEIDOU_B1I_H

#include <ap_int.h>
#include <ap_fixed.h>
#include <hls_stream.h>
#include <hls_math.h>
#include <complex>

// Beidou B1I signal parameters
#define B1I_CARRIER_FREQ 1561098000        // 1561.098 MHz carrier frequency
#define B1I_CODE_LENGTH 2046              // B1I ranging code length
#define B1I_CODE_RATE 2046000             // 2.046 Mcps
#define B1I_SAMPLE_RATE 16368000          // 16.368 MHz (8x code rate)
#define B1I_SAMPLES_PER_CHIP 8            // Samples per chip
#define B1I_SAMPLES_PER_CODE (B1I_CODE_LENGTH * B1I_SAMPLES_PER_CHIP)  // Samples per code period
#define B1I_DOPPLER_RANGE 10000           // +/- 10kHz Doppler search range
#define B1I_DOPPLER_STEP 500              // 500Hz step for Doppler search
#define B1I_NUM_DOPPLER_BINS ((2 * B1I_DOPPLER_RANGE / B1I_DOPPLER_STEP) + 1)  // Number of Doppler bins
#define B1I_COHERENT_INTEGRATION_MS 1     // 1ms coherent integration
#define B1I_NON_COHERENT_INTEGRATIONS 10  // Non-coherent integrations
#define B1I_DETECTION_THRESHOLD 1.5       // Detection threshold

// Data types
typedef ap_int<4> sample_t;               // 4-bit ADC samples
typedef ap_fixed<32,16> float_fixed_t;     // Fixed point for calculations
typedef std::complex<float_fixed_t> complex_t;

// Structure for acquisition results
struct AcquisitionResult {
    bool signal_detected;
    int code_phase;
    int doppler_bin;
    float peak_metric;
    float SNR;
};

// Function declarations
void GenerateBeidouB1ICode(ap_uint<11> prn, ap_uint<1> code_array[B1I_CODE_LENGTH]);
void GenerateLocalCarrier(int doppler_freq, complex_t carrier_buffer[B1I_SAMPLES_PER_CODE]);
void ParallelCodePhaseSearch(sample_t* signal_samples, ap_uint<1>* code_samples, complex_t* carrier_samples,
                            float* correlation_results, int doppler_bin);
void AcquireBeidouB1I(sample_t signal_buffer[B1I_SAMPLES_PER_CODE], ap_uint<11> prn,
                      AcquisitionResult& result);

// Top-level function for HLS synthesis
void BeidouB1IAcquisition(sample_t signal_buffer[B1I_SAMPLES_PER_CODE],
    ap_uint<11> prn, AcquisitionResult &result_out);

#endif // BEIDOU_B1I_H
