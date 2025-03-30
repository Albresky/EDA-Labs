'''
Copyright (c) 2025 by Albresky, All Rights Reserved. 

Author: Albresky albre02@outlook.com
Date: 2025-03-18 19:46:57
LastEditTime: 2025-03-30 17:12:18
FilePath: /BUPT-EDA-Labs/lab1/src/visualize.py

Description: Signal visualization for spread spectrum synchronization
'''
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import glob
import os
import sys

base_dir = "./sync_prj/solution1/csim/build"

def find_waveform_file(case_num=None):
    if case_num is not None:
        pattern = os.path.join(base_dir, f"waveform_case_{case_num}.csv")
        if os.path.exists(pattern):
            case_id = str(case_num)
            return pattern, case_id
    
    pattern = os.path.join(base_dir, "waveform_case_*.csv")
    waveform_files = sorted(glob.glob(pattern))
    
    if not waveform_files:
        pattern = "waveform_case_*.csv"
        waveform_files = sorted(glob.glob(pattern))
        
    if waveform_files:
        waveform_file = waveform_files[0]
        case_id = os.path.splitext(os.path.basename(waveform_file))[0].split('_')[-1]
        print(f"Using waveform file: {waveform_file}")
        return waveform_file, case_id
    
    print("No waveform files found!")
    return None, None


def plot_waveforms(df, case_id):
    output_dir = "waveform"
    os.makedirs(output_dir, exist_ok=True)
    
    fig, axes = plt.subplots(6, 1, figsize=(14, 18), sharex=True)
    plt.subplots_adjust(hspace=0.3)
    
    # 1. 输入IF信号
    axes[0].plot(df["Time(n)"], df["IF_in"], 'b-', linewidth=1)
    axes[0].set_ylabel("IF_in")
    axes[0].set_title(f"Spread Spectrum Synchronization Signals - Test Case {case_id}")
    axes[0].grid(True)
    
    # 2. 码序列对比：发送端与接收端
    axes[1].plot(df["Time(n)"], df["M_Code_Out"], 'r-', linewidth=1, label="RX m-code")
    axes[1].plot(df["Time(n)"], df["Tx_Code"], 'b--', linewidth=1, alpha=0.7, label="TX m-code")
    axes[1].set_ylabel("Code Comparison")
    axes[1].set_ylim(-0.1, 1.1)
    axes[1].grid(True)
    axes[1].legend(loc='upper right')
    
    # 3. m 码状态
    axes[2].plot(df["Time(n)"], df["Rx_State"], 'g-', linewidth=1, label="RX state")
    axes[2].plot(df["Time(n)"], df["Tx_State"], 'b--', linewidth=1, alpha=0.6, label="TX state")
    axes[2].set_ylabel("m-Code States")
    axes[2].grid(True)
    axes[2].legend(loc='upper right')
    
    # 4. 相位估计和调整
    axes[3].plot(df["Time(n)"], df["Phase_Est"], 'm-', linewidth=1)
    axes[3].set_ylabel("Phase Estimate")
    axes[3].grid(True)
    
    # 5. I/Q积分值
    axes[4].plot(df["Time(n)"], df["I_Value"], 'r-', linewidth=1, label="I")
    axes[4].plot(df["Time(n)"], df["Q_Value"], 'b-', linewidth=1, label="Q")
    axes[4].set_ylabel("I/Q Values")
    axes[4].grid(True)
    axes[4].legend(loc='upper right')
    
    # 6. 同步标志
    axes[5].plot(df["Time(n)"], df["Sync_Flag"], 'k-', linewidth=1.5)
    axes[5].set_ylabel("Sync Flag")
    axes[5].set_ylim(-0.1, 1.1)
    axes[5].set_xlabel("Time (samples)")
    axes[5].grid(True)
    
    # 计算同步相关指标
    sync_achieved = 1 in df["Sync_Flag"].values
    adjustment_count = 0
    sync_time = None
    
    # 添加同步点的垂直线
    if sync_achieved:
        sync_time = df[df["Sync_Flag"] == 1]["Time(n)"].iloc[0]
        for ax in axes:
            ax.axvline(x=sync_time, color='red', linestyle='--', alpha=0.7, 
                      label=f"Sync at t={sync_time}")
        axes[0].legend(loc='upper right')
    
    # 标注码相位调整
    if len(df) > 1:
        # 检测接收端状态的变化，这表示码相位调整
        state_changes = df["Rx_State"].diff() != 0
        change_times = df["Time(n)"][state_changes]
        
        adjustment_count = len(change_times)
        
        if len(change_times) > 0:
            for i, t in enumerate(change_times):
                if i < 20:  # 限制标注数量
                    for ax in axes:
                        ax.axvline(x=t, color='green', linestyle=':', alpha=0.3)
                        if i % 5 == 0:  # 每5次调整显示一次计数
                            ax.text(t, ax.get_ylim()[1]*0.95, f"#{i+1}", 
                                    color='green', fontsize=8, ha='right')
    
    # 为多个相位区域添加背景色
    if sync_achieved:
        for ax in axes:
            ax.axvspan(0, sync_time, alpha=0.1, color='orange', label='Search Phase')
            ax.axvspan(sync_time, df["Time(n)"].max(), alpha=0.1, color='lightgreen', label='Lock Phase')
    
    # 添加能量计算说明文本框
    threshold_text = "25"  # 阈值固定为25
    energy_text = f"Energy threshold: {threshold_text}\n"
    if sync_achieved:
        energy_text += f"Sync achieved after {adjustment_count} code phase adjustments"
    else:
        energy_text += f"Sync not achieved after {adjustment_count} adjustments"
    
    axes[4].text(0.02, 0.95, energy_text, transform=axes[4].transAxes,
                bbox=dict(boxstyle='round', facecolor='white', alpha=0.7))
    
    if sync_achieved:
        window_size = 2000  # 样本点数
        xmin = max(0, sync_time - window_size)
        xmax = min(df["Time(n)"].max(), sync_time + window_size)
        plt.xlim(xmin, xmax)
    
    plt.tight_layout()
    output_file = os.path.join(output_dir, f"sync_visualization_case_{case_id}.png")
    plt.savefig(output_file, dpi=300)
    
    return output_file


if __name__ == "__main__":
    case_num = None
    if len(sys.argv) > 1:
        try:
            case_num = int(sys.argv[1])
            print(f"Looking for case in range [0, {case_num})...")
        except ValueError:
            print(f"Invalid argument: {sys.argv[1]}. Using any available case.")
    
    for i in range(case_num):
        waveform_file, case_id = find_waveform_file(i)
        if waveform_file is None:
            print(f"Could not find waveform file for case {i}: {waveform_file}")
            break

        print(f"Loading data from {waveform_file}...")
        df = pd.read_csv(waveform_file)
        
        output_file = plot_waveforms(df, case_id)
        print(f"Visualization saved to {output_file}")