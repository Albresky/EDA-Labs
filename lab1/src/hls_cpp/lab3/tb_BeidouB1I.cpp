/*
 * @Author: GitHub Copilot
 * @Date: 2025-04-05 10:00:00
 * @LastEditors: Please set LastEditors
 * @LastEditTime: 2025-04-04 18:52:42
 * @FilePath: /BUPT-EDA-Labs/lab1/src/tb_BeidouB1I.cpp
 * @Description: Testbench for Beidou B1I Signal Acquisition
 */
#include "BeidouB1I.h"
#include <iostream>
#include <fstream>
#include <cmath>
#include <random>
#include <ctime>

// Function to generate simulated Beidou B1I signal
void generateBeidouB1ISignal(sample_t* signal_buffer, ap_uint<11> prn, int code_phase_offset, int doppler_shift) {
    // Generate the B1I code
    ap_uint<1> code_array[B1I_CODE_LENGTH];
    GenerateBeidouB1ICode(prn, code_array);
    
    // Initialize random number generator for noise
    std::default_random_engine generator(std::time(0));
    std::normal_distribution<float> distribution(0.0, 1.0); // Mean 0, std dev 1
    
    // Signal parameters
    float signal_power = 0.5; // Signal power
    float noise_power = 0.25; // Noise power for SNR control
    float snr = 10.0 * log10(signal_power / noise_power); // SNR in dB
    std::cout << "Generating signal with SNR: " << snr << " dB" << std::endl;
    
    // Generate carrier with Doppler shift
    float carrier_freq = B1I_CARRIER_FREQ + doppler_shift;
    float phase_step = 2.0 * M_PI * carrier_freq / B1I_SAMPLE_RATE;
    float phase = 0.0;
    
    // Generate the signal samples
    for (int i = 0; i < B1I_SAMPLES_PER_CODE; i++) {
        // Determine code value based on code phase offset
        int code_idx = ((i / B1I_SAMPLES_PER_CHIP) + code_phase_offset) % B1I_CODE_LENGTH;
        float code_value = code_array[code_idx] ? 1.0f : -1.0f;
        
        // Generate carrier
        float carrier = std::cos(phase);
        phase += phase_step;
        if (phase > 2 * M_PI) phase -= 2 * M_PI;
        
        // Create signal
        float signal = std::sqrt(signal_power) * code_value * carrier;
        
        // Add noise
        float noise = std::sqrt(noise_power) * distribution(generator);
        float sample = signal + noise;
        
        // Quantize to 4 bits
        int quant_value = std::round(sample * 7.0); // Scale to -7 to +7 range
        quant_value = std::min(std::max(quant_value, -7), 7); // Clamp to -7 to +7
        signal_buffer[i] = static_cast<sample_t>(quant_value);
    }
}

int main() {
    std::cout << "Beidou B1I Signal Acquisition Test" << std::endl;
    
    // Signal parameters
    ap_uint<11> prn = 1; // PRN number
    int true_code_phase = 1000; // True code phase in chips
    int true_doppler = 2500; // True Doppler in Hz
    
    // Generate simulated signal
    sample_t signal_buffer[B1I_SAMPLES_PER_CODE];
    generateBeidouB1ISignal(signal_buffer, prn, true_code_phase, true_doppler);
    
    // Get results
    AcquisitionResult result;
    
    // Run acquisition
    BeidouB1IAcquisition(signal_buffer, prn, result);
    
    // Print results
    std::cout << "Acquisition Results:" << std::endl;
    std::cout << "Signal detected: " << (result.signal_detected ? "YES" : "NO") << std::endl;
    std::cout << "Code phase: " << result.code_phase << " (true: " << true_code_phase << ")" << std::endl;
    std::cout << "Doppler bin: " << result.doppler_bin << std::endl;
    std::cout << "Doppler frequency: " << (-B1I_DOPPLER_RANGE + result.doppler_bin * B1I_DOPPLER_STEP) << " Hz (true: " << true_doppler << " Hz)" << std::endl;
    std::cout << "Peak metric: " << result.peak_metric << std::endl;
    std::cout << "SNR: " << result.SNR << " (" << 10*log10(result.SNR) << " dB)" << std::endl;
    
    // Calculate acquisition errors
    int code_phase_error = abs(result.code_phase - true_code_phase);
    int doppler_error = abs((-B1I_DOPPLER_RANGE + result.doppler_bin * B1I_DOPPLER_STEP) - true_doppler);
    
    std::cout << "Code phase error: " << code_phase_error << " chips" << std::endl;
    std::cout << "Doppler error: " << doppler_error << " Hz" << std::endl;
    
    // Success criteria
    bool success = result.signal_detected && 
                  code_phase_error < 5 && 
                  doppler_error < B1I_DOPPLER_STEP;
    
    std::cout << "Acquisition " << (success ? "SUCCESSFUL" : "FAILED") << std::endl;
    
    return success ? 0 : 1;
}
