/*
 * @Author: GitHub Copilot
 * @Date: 2025-04-05 10:00:00
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-04-04 18:55:18
 * @FilePath: /BUPT-EDA-Labs/lab1/src/BeidouB1I.cpp
 * @Description: Beidou B1I Signal Acquisition Implementation
 */
#include "BeidouB1I.h"
#include <algorithm>
#include <cstring>
#include <iostream>

// Generate Beidou B1I ranging code for a specific PRN
void GenerateBeidouB1ICode(ap_uint<11> prn,
                           ap_uint<1> code_array[B1I_CODE_LENGTH]) {
#pragma HLS INLINE off
  // Define G1 and G2 feedback polynomials for B1I ranging code
  // G1: X11 + X9 + X8 + X6 + X3 + X + 1
  // G2: X11 + X10 + X9 + X8 + X6 + X5 + X4 + X2 + 1
  ap_uint<11> g1_state = 0x01; // Initial state for G1 register
  ap_uint<11> g2_state = 0x01; // Initial state for G2 register

  // Phase selection for different PRNs (simplified - in a real implementation
  // this would use actual phases)
  ap_uint<11> phase_selector = prn;

  // Generate 2046 chips
  for (int i = 0; i < B1I_CODE_LENGTH; i++) {
    // G1 register output
    ap_uint<1> g1_out = g1_state[0];

    // G2 register output with phase selection (simplified)
    ap_uint<1> g2_out = g2_state[phase_selector % 11];

    // B1I code is G1 XOR G2
    code_array[i] = g1_out ^ g2_out;

    // Update G1 register
    ap_uint<1> g1_feedback = g1_state[10] ^ g1_state[8] ^ g1_state[7] ^
                             g1_state[5] ^ g1_state[2] ^ g1_state[0];
    g1_state = (g1_state >> 1) | (g1_feedback << 10);

    // Update G2 register
    ap_uint<1> g2_feedback = g2_state[10] ^ g2_state[9] ^ g2_state[8] ^
                             g2_state[7] ^ g2_state[5] ^ g2_state[4] ^
                             g2_state[3] ^ g2_state[1];
    g2_state = (g2_state >> 1) | (g2_feedback << 10);
  }
}

// Generate local carrier replicas for a specific Doppler frequency
void GenerateLocalCarrier(int doppler_freq,
                          complex_t carrier_buffer[B1I_SAMPLES_PER_CODE]) {
#pragma HLS INLINE off
  float_fixed_t phase_step =
      float_fixed_t(2.0 * M_PI * doppler_freq / B1I_SAMPLE_RATE);
  float_fixed_t phase = float_fixed_t(0.0);

  for (int i = 0; i < B1I_SAMPLES_PER_CODE; i++) {
    carrier_buffer[i].real(hls::cosf(phase));
    carrier_buffer[i].imag(hls::sinf(phase));
    phase += phase_step;
    // 保持相位在[0, 2π)范围内
    if (phase > float_fixed_t(2 * M_PI)) {
      phase -= float_fixed_t(2 * M_PI);
    }
  }
}

// Parallel code phase search for one Doppler bin
void ParallelCodePhaseSearch(sample_t *signal_samples, ap_uint<1> *code_samples,
                             complex_t *carrier_samples,
                             float *correlation_results, int doppler_bin) {
#pragma HLS INLINE off

  // Upsample the PRN code to match the sampling rate
  complex_t upsampled_code[B1I_SAMPLES_PER_CODE];
#pragma HLS ARRAY_PARTITION variable = upsampled_code cyclic factor = 8

  // Create upsampled code
  for (int i = 0; i < B1I_CODE_LENGTH; i++) {
    for (int j = 0; j < B1I_SAMPLES_PER_CHIP; j++) {
      int idx = i * B1I_SAMPLES_PER_CHIP + j;
      upsampled_code[idx].real(code_samples[i] ? float_fixed_t(1.0)
                                               : float_fixed_t(-1.0));
      upsampled_code[idx].imag(float_fixed_t(0.0));
    }
  }

  // Mix input signal with carrier and code for correlation
  complex_t mixed_signal[B1I_SAMPLES_PER_CODE];
#pragma HLS ARRAY_PARTITION variable = mixed_signal cyclic factor = 8

  for (int i = 0; i < B1I_SAMPLES_PER_CODE; i++) {
    // Convert ADC sample to float and mix with carrier
    float_fixed_t signal_float = static_cast<float_fixed_t>(signal_samples[i]) /
                                 float_fixed_t(8.0); // Normalize 4-bit samples
    complex_t carrier = carrier_samples[i];

    // Mix with carrier
    complex_t mixed;
    mixed.real(signal_float * carrier.real());
    mixed.imag(signal_float * carrier.imag());

    // Multiply by code
    mixed_signal[i].real(mixed.real() * upsampled_code[i].real());
    mixed_signal[i].imag(mixed.imag() * upsampled_code[i].real());
  }

  // Perform correlation for all possible code phases
  for (int phase = 0; phase < B1I_CODE_LENGTH; phase++) {
    complex_t correlation_sum(float_fixed_t(0.0), float_fixed_t(0.0));

    // Sum over one code period
    for (int i = 0; i < B1I_SAMPLES_PER_CODE; i++) {
      int idx = (i + phase * B1I_SAMPLES_PER_CHIP) % B1I_SAMPLES_PER_CODE;
      correlation_sum.real(correlation_sum.real() + mixed_signal[idx].real());
      correlation_sum.imag(correlation_sum.imag() + mixed_signal[idx].imag());
    }

    // Calculate power
    float power = correlation_sum.real() * correlation_sum.real() +
                  correlation_sum.imag() * correlation_sum.imag();

    // Store result
    correlation_results[phase] = power;
  }
}

// Main acquisition function for Beidou B1I signal
void AcquireBeidouB1I(sample_t signal_buffer[B1I_SAMPLES_PER_CODE],
                      ap_uint<11> prn, AcquisitionResult &result) {
#pragma HLS INTERFACE mode = s_axilite port = return bundle = CONTROL_BUS
#pragma HLS INTERFACE mode = s_axilite port = signal_buffer bundle = CONTROL_BUS
#pragma HLS INTERFACE mode = s_axilite port = prn bundle = CONTROL_BUS
#pragma HLS INTERFACE mode = s_axilite port = result bundle = CONTROL_BUS

  // Generate PRN code
  ap_uint<1> code_array[B1I_CODE_LENGTH];
  GenerateBeidouB1ICode(prn, code_array);

  // Allocate space for correlation results
  float correlation_results[B1I_CODE_LENGTH];
  float max_correlation = 0.0;
  int max_doppler_bin = -1;
  int max_code_phase = -1;

  // Search through Doppler bins
  for (int doppler_bin = 0; doppler_bin < B1I_NUM_DOPPLER_BINS; doppler_bin++) {
    int doppler_freq = -B1I_DOPPLER_RANGE + doppler_bin * B1I_DOPPLER_STEP;

    // Generate carrier for this Doppler bin
    complex_t carrier_samples[B1I_SAMPLES_PER_CODE];
    GenerateLocalCarrier(doppler_freq, carrier_samples);

    // Perform parallel code phase search
    ParallelCodePhaseSearch(signal_buffer, code_array, carrier_samples,
                            correlation_results, doppler_bin);

    // Find maximum for this Doppler bin
    for (int phase = 0; phase < B1I_CODE_LENGTH; phase++) {
      if (correlation_results[phase] > max_correlation) {
        max_correlation = correlation_results[phase];
        max_doppler_bin = doppler_bin;
        max_code_phase = phase;
        std::cout << "Doppler bin: " << doppler_bin
                  << ", Code phase: " << phase
                  << ", Correlation: " << max_correlation << std::endl;
      }
    }
  }

  // Calculate noise floor (average of all correlation results excluding the
  // peak area)
  float noise_floor = 0.0;
  int count = 0;
  for (int phase = 0; phase < B1I_CODE_LENGTH; phase++) {
    if (abs(phase - max_code_phase) > 5) { // Exclude peak area
      noise_floor += correlation_results[phase];
      count++;
    }
  }
  noise_floor /= count;

  // Calculate SNR
  float snr = max_correlation / noise_floor;

  // Set acquisition result
  result.signal_detected = (snr > B1I_DETECTION_THRESHOLD);
  result.code_phase = max_code_phase;
  result.doppler_bin = max_doppler_bin;
  result.peak_metric = max_correlation;
  result.SNR = snr;
}

// Top-level function for HLS synthesis
void BeidouB1IAcquisition(sample_t signal_buffer[B1I_SAMPLES_PER_CODE],
    ap_uint<11> prn, AcquisitionResult &result_out) {
#pragma HLS INTERFACE mode = s_axilite port = return bundle = CONTROL_BUS
  // Perform acquisition
  AcquireBeidouB1I(signal_buffer, prn, result_out);
}
