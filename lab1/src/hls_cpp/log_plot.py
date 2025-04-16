'''
Copyright (c) 2025 by Albresky, All Rights Reserved. 

Author: Albresky albre02@outlook.com
Date: 2025-04-05 21:58:34
LastEditTime: 2025-04-05 22:03:15
FilePath: /BUPT-EDA-Labs/lab1/src/log_plot.py

Description: 
'''
import matplotlib.pyplot as plt
import numpy as np
import re

# Function to parse the log file
def parse_log_file(file_path):
    energy_values = []
    max_energy_values = []
    sync_values = []
    
    with open(file_path, 'r') as file:
        # filter = 3
        for line in file:
            # Extract Energy, max_energy, and Sync values using regex
            match = re.search(r'Energy: ([\d.]+), max_energy: ([\d.]+), Sync: (\d+)', line)
        
            if match:
                # if filter > 0:
                #     filter -= 1
                #     continue
                # filter = 3
                energy = float(match.group(1))
                max_energy = float(match.group(2))
                sync = int(match.group(3))
                
                energy_values.append(energy)
                max_energy_values.append(max_energy)
                sync_values.append(sync)
    
    return energy_values, max_energy_values, sync_values

# Parse the log file
energy_values, max_energy_values, sync_values = parse_log_file('./sync_prj/solution1/csim/build/log.txt')

# Create time values (1ms intervals)
time_ms = np.arange(len(energy_values))

# Create figure and subplots
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8), sharex=True)

# Plot Sync values on the top subplot
ax1.plot(time_ms, sync_values, 'r-', linewidth=1.5, label='Sync')
ax1.set_ylabel('Sync Value')
ax1.set_title('Sync Value over Time')
ax1.grid(True)
ax1.legend()

# Plot Energy values on the bottom subplot
ax2.plot(time_ms, energy_values, 'b-', linewidth=1.5, label='Energy')
ax2.plot(time_ms, max_energy_values, 'g--', linewidth=1, label='Max Energy')
ax2.set_xlabel('Time (ms)')
ax2.set_ylabel('Energy Value')
ax2.set_title('Energy Value over Time')
ax2.grid(True)
ax2.legend()

# Adjust layout
plt.tight_layout()
plt.subplots_adjust(hspace=0.3)

# Save the figure
plt.savefig('energy_sync_plot.png', dpi=300)

# Show the plot
plt.show()
