#!/usr/bin/env python3
"""
E-Ink Board Baseline Power Analysis - Build 2082
Establishes comprehensive power consumption baseline for optimization comparison
"""

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from datetime import datetime, timedelta
import numpy as np
import glob
import os

def parse_power_log(filepath):
    """Parse power monitoring log file"""
    data = []
    with open(filepath, 'r') as f:
        next(f)  # Skip header
        for line in f:
            parts = line.strip().split(',')
            if len(parts) >= 5:
                try:
                    timestamp = datetime.strptime(parts[0], '%Y-%m-%d %H:%M:%S')
                    
                    # Handle empty or invalid current values
                    if parts[1] and parts[1].strip():
                        current_A = float(parts[1])
                    else:
                        continue  # Skip lines with missing current data
                    
                    # Handle empty power values - calculate from current if missing
                    if parts[2] and parts[2].strip():
                        power_W = float(parts[2])
                    else:
                        power_W = current_A * 6.0  # 6V supply
                    
                    current_readable = parts[3] if parts[3] else f"{current_A*1000:.1f} mA"
                    power_readable = parts[4] if parts[4] else f"{power_W:.3f} W"
                    
                    data.append({
                        'timestamp': timestamp,
                        'current_A': current_A,
                        'power_W': power_W,
                        'current_mA': current_A * 1000,
                        'current_readable': current_readable,
                        'power_readable': power_readable
                    })
                except (ValueError, IndexError):
                    continue  # Skip malformed lines
    return pd.DataFrame(data)

def analyze_baseline_power(df, build_name="Build 2082"):
    """Comprehensive baseline power analysis"""
    if df.empty:
        return None
    
    # Calculate statistics
    stats = {
        'build': build_name,
        'start_time': df['timestamp'].min(),
        'end_time': df['timestamp'].max(),
        'duration_minutes': (df['timestamp'].max() - df['timestamp'].min()).total_seconds() / 60,
        'samples': len(df),
        'sampling_rate': len(df) / ((df['timestamp'].max() - df['timestamp'].min()).total_seconds() / 60),
        
        # Current statistics
        'avg_current_mA': df['current_mA'].mean(),
        'min_current_mA': df['current_mA'].min(),
        'max_current_mA': df['current_mA'].max(),
        'std_current_mA': df['current_mA'].std(),
        'median_current_mA': df['current_mA'].median(),
        
        # Power statistics
        'avg_power_W': df['power_W'].mean(),
        'min_power_W': df['power_W'].min(),
        'max_power_W': df['power_W'].max(),
        'std_power_W': df['power_W'].std(),
        'median_power_W': df['power_W'].median(),
        
        # Battery life projections (40Ah battery)
        'battery_life_hours_40Ah': 40000 / df['current_mA'].mean() if df['current_mA'].mean() > 0 else float('inf'),
        'battery_life_hours_80Ah': 80000 / df['current_mA'].mean() if df['current_mA'].mean() > 0 else float('inf'),
    }
    
    stats['battery_life_days'] = stats['battery_life_hours_40Ah'] / 24
    stats['battery_life_years'] = stats['battery_life_days'] / 365
    
    # Power stability analysis
    stats['current_cv'] = stats['std_current_mA'] / stats['avg_current_mA'] * 100  # Coefficient of variation
    stats['power_cv'] = stats['std_power_W'] / stats['avg_power_W'] * 100
    
    return stats

def create_baseline_charts(df, stats, output_prefix='build_2082_baseline'):
    """Create comprehensive baseline charts"""
    
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(16, 12))
    fig.suptitle(f'E-Ink Board Power Baseline - {stats["build"]}\n'
                 f'Duration: {stats["duration_minutes"]:.1f} minutes, '
                 f'Samples: {stats["samples"]}, '
                 f'Average: {stats["avg_current_mA"]:.1f} mA', 
                 fontsize=16, fontweight='bold')
    
    # 1. Time series plot
    ax1.plot(df['timestamp'], df['current_mA'], color='#1f77b4', linewidth=1, alpha=0.7)
    ax1.set_ylabel('Current (mA)')
    ax1.set_title('Current Consumption Over Time')
    ax1.grid(True, alpha=0.3)
    ax1.axhline(y=stats['avg_current_mA'], color='red', linestyle='--', alpha=0.8, 
                label=f'Average: {stats["avg_current_mA"]:.1f} mA')
    ax1.legend()
    
    # Format x-axis for time
    ax1.xaxis.set_major_formatter(mdates.DateFormatter('%H:%M'))
    ax1.xaxis.set_major_locator(mdates.MinuteLocator(interval=max(1, int(stats["duration_minutes"]/10))))
    plt.setp(ax1.xaxis.get_majorticklabels(), rotation=45)
    
    # 2. Current distribution histogram
    ax2.hist(df['current_mA'], bins=30, color='#ff7f0e', alpha=0.7, edgecolor='black')
    ax2.axvline(x=stats['avg_current_mA'], color='red', linestyle='--', linewidth=2, 
                label=f'Mean: {stats["avg_current_mA"]:.1f} mA')
    ax2.axvline(x=stats['median_current_mA'], color='green', linestyle='--', linewidth=2, 
                label=f'Median: {stats["median_current_mA"]:.1f} mA')
    ax2.set_xlabel('Current (mA)')
    ax2.set_ylabel('Frequency')
    ax2.set_title('Current Distribution')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    # 3. Power consumption over time
    ax3.plot(df['timestamp'], df['power_W'], color='#2ca02c', linewidth=1, alpha=0.7)
    ax3.set_ylabel('Power (W)')
    ax3.set_title('Power Consumption Over Time')
    ax3.grid(True, alpha=0.3)
    ax3.axhline(y=stats['avg_power_W'], color='red', linestyle='--', alpha=0.8, 
                label=f'Average: {stats["avg_power_W"]:.3f} W')
    ax3.legend()
    
    # Format x-axis for time
    ax3.xaxis.set_major_formatter(mdates.DateFormatter('%H:%M'))
    ax3.xaxis.set_major_locator(mdates.MinuteLocator(interval=max(1, int(stats["duration_minutes"]/10))))
    plt.setp(ax3.xaxis.get_majorticklabels(), rotation=45)
    
    # 4. Battery life projections
    battery_capacities = [20000, 40000, 60000, 80000, 100000]  # mAh
    battery_years = [cap / stats['avg_current_mA'] / 24 / 365 for cap in battery_capacities]
    
    bars = ax4.bar([f'{cap/1000:.0f}Ah' for cap in battery_capacities], battery_years, 
                   color=['#d62728', '#ff7f0e', '#2ca02c', '#1f77b4', '#9467bd'], alpha=0.8)
    ax4.set_ylabel('Battery Life (Years)')
    ax4.set_title('Projected Battery Life by Capacity')
    
    # Set appropriate y-axis scale based on actual data
    max_years = max(battery_years)
    if max_years < 0.1:  # Less than 36.5 days
        ax4.set_ylim(0, 0.1)
        ax4.axhline(y=0.02, color='orange', linestyle='--', alpha=0.7, label='1 Week')
        ax4.axhline(y=0.08, color='green', linestyle='--', alpha=0.7, label='1 Month')
        ax4.axhline(y=5, color='red', linestyle='--', alpha=0.3, label='5-Year Target (off-scale)')
    elif max_years < 1:  # Less than 1 year
        ax4.set_ylim(0, 1)
        ax4.axhline(y=0.08, color='green', linestyle='--', alpha=0.7, label='1 Month')
        ax4.axhline(y=5, color='red', linestyle='--', alpha=0.3, label='5-Year Target (off-scale)')
    else:
        ax4.axhline(y=5, color='red', linestyle='--', alpha=0.7, label='5-Year Target')
    
    ax4.grid(True, alpha=0.3)
    ax4.legend()
    
    # Add value labels with appropriate precision
    for bar, years in zip(bars, battery_years):
        if years < 0.01:  # Less than 3.65 days
            label = f'{years*365:.0f}d'
        elif years < 0.1:  # Less than 36.5 days  
            label = f'{years*365:.1f}d'
        elif years < 1:  # Less than 1 year
            label = f'{years*365:.0f}d'
        else:
            label = f'{years:.1f}y'
        ax4.text(bar.get_x() + bar.get_width()/2, bar.get_height() + max_years*0.01, 
                label, ha='center', va='bottom', fontweight='bold')
    
    plt.tight_layout()
    plt.savefig(f'{output_prefix}_analysis.png', dpi=300, bbox_inches='tight')
    print(f"Baseline analysis chart saved to: {output_prefix}_analysis.png")
    
    return f'{output_prefix}_analysis.png'

def create_baseline_report(stats, output_file='build_2082_baseline_report.txt'):
    """Create detailed baseline report"""
    with open(output_file, 'w') as f:
        f.write("E-INK BOARD POWER BASELINE REPORT\n")
        f.write("=" * 50 + "\n\n")
        f.write(f"Build: {stats['build']}\n")
        f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"Measurement Period: {stats['start_time'].strftime('%Y-%m-%d %H:%M:%S')} to {stats['end_time'].strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"Duration: {stats['duration_minutes']:.1f} minutes\n")
        f.write(f"Samples: {stats['samples']} (Rate: {stats['sampling_rate']:.1f} samples/min)\n\n")
        
        f.write("CURRENT CONSUMPTION ANALYSIS\n")
        f.write("-" * 40 + "\n")
        f.write(f"Average Current: {stats['avg_current_mA']:.2f} mA\n")
        f.write(f"Median Current: {stats['median_current_mA']:.2f} mA\n")
        f.write(f"Minimum Current: {stats['min_current_mA']:.2f} mA\n")
        f.write(f"Maximum Current: {stats['max_current_mA']:.2f} mA\n")
        f.write(f"Standard Deviation: {stats['std_current_mA']:.2f} mA\n")
        f.write(f"Coefficient of Variation: {stats['current_cv']:.1f}%\n\n")
        
        f.write("POWER CONSUMPTION ANALYSIS\n")
        f.write("-" * 40 + "\n")
        f.write(f"Average Power: {stats['avg_power_W']:.3f} W\n")
        f.write(f"Median Power: {stats['median_power_W']:.3f} W\n")
        f.write(f"Minimum Power: {stats['min_power_W']:.3f} W\n")
        f.write(f"Maximum Power: {stats['max_power_W']:.3f} W\n")
        f.write(f"Standard Deviation: {stats['std_power_W']:.3f} W\n")
        f.write(f"Coefficient of Variation: {stats['power_cv']:.1f}%\n\n")
        
        f.write("BATTERY LIFE PROJECTIONS\n")
        f.write("-" * 40 + "\n")
        f.write(f"40Ah Battery: {stats['battery_life_years']:.2f} years\n")
        f.write(f"80Ah Battery: {stats['battery_life_hours_80Ah']/24/365:.2f} years\n")
        f.write(f"Daily Energy: {stats['avg_power_W'] * 24:.1f} Wh\n")
        f.write(f"Annual Energy: {stats['avg_power_W'] * 24 * 365:.1f} Wh\n\n")
        
        f.write("OPTIMIZATION TARGETS\n")
        f.write("-" * 40 + "\n")
        target_current_50 = stats['avg_current_mA'] * 0.5
        target_current_35 = stats['avg_current_mA'] * 0.35
        f.write(f"50% Reduction Target: {target_current_50:.1f} mA ({target_current_50 * 6 / 1000:.3f} W)\n")
        f.write(f"65% Reduction Target: {target_current_35:.1f} mA ({target_current_35 * 6 / 1000:.3f} W)\n")
        target_5yr_mA = 40000/5/365/24
        f.write(f"5-Year Battery Life Requires: ≤{target_5yr_mA:.1f} mA average\n\n")
        
        if stats['battery_life_years'] >= 5:
            f.write("✅ CURRENT BUILD MEETS 5-YEAR TARGET\n")
        else:
            target_5yr_mA = 40000/5/365/24
            reduction_needed = (1 - target_5yr_mA / stats['avg_current_mA']) * 100
            f.write(f"❌ OPTIMIZATION REQUIRED: {reduction_needed:.1f}% power reduction needed\n")
    
    print(f"Baseline report saved to: {output_file}")
    return output_file

def main():
    # Find the most recent power log
    log_files = glob.glob('eink_power_*.log')
    if not log_files:
        print("No power log files found! Please run power monitoring first.")
        return
    
    # Use the most recent log file
    latest_log = max(log_files, key=os.path.getctime)
    print(f"Analyzing baseline from: {latest_log}")
    
    # Parse and analyze
    df = parse_power_log(latest_log)
    if df.empty:
        print("No valid data found in log file!")
        return
    
    stats = analyze_baseline_power(df, "Build 2082 (Current Baseline)")
    if not stats:
        print("Failed to analyze power data!")
        return
    
    # Create charts and report
    chart_file = create_baseline_charts(df, stats)
    report_file = create_baseline_report(stats)
    
    print(f"\n=== BASELINE ANALYSIS COMPLETE ===")
    print(f"Build: {stats['build']}")
    print(f"Average Current: {stats['avg_current_mA']:.1f} mA")
    print(f"Average Power: {stats['avg_power_W']:.3f} W")
    print(f"Battery Life (5Ah): {stats['battery_life_years']:.2f} years")
    print(f"Stability (CV): {stats['current_cv']:.1f}%")
    print(f"Charts: {chart_file}")
    print(f"Report: {report_file}")

if __name__ == '__main__':
    main()
