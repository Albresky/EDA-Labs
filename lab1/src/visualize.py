'''
Copyright (c) 2025 by Albresky, All Rights Reserved. 

Author: Albresky albre02@outlook.com
Date: 2025-03-18 19:46:57
LastEditTime: 2025-03-18 19:47:00
FilePath: /BUPT-EDA-Labs/lab1/src/visualize.py

Description: 
'''
import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("./sync_prj/solution1/csim/build/waveform.csv")
plt.plot(df["Time(n)"], df["Sync_Flag"], label="Sync Flag")
plt.plot(df["Time(n)"], df["IF_in"], label="IF Input (scaled)")
plt.legend()
plt.show()
plt.savefig(fname='waveform.png')