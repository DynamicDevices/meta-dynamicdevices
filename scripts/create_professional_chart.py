#!/usr/bin/env python3
"""
Professional Power Optimization Chart for E-Ink Board
Creates clean, presentation-ready charts for sharing with colleagues
"""

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from datetime import datetime
import numpy as np

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
                    if parts[1] and parts[1].strip():
                        current_A = float(parts[1])
                    else:
                        continue
                    if parts[2] and parts[2].strip():
                        power_W = float(parts[2])
                    else:
                        power_W = current_A * 6.0
                    data.append({
                        'timestamp': timestamp,
                        'current_A': current_A,
                        'power_W': power_W,
                        'current_mA': current_A * 1000,
                    })
                except (ValueError, IndexError):
                    continue
    return pd.DataFrame(data)

def create_professional_chart(df, output_file='power_optimization_summary.png'):
    """Create professional chart for colleague sharing"""
    
    # Calculate key statistics
    avg_current = df['current_mA'].mean()
    avg_power = df['power_W'].mean()
    std_current = df['current_mA'].std()
    cv_percent = (std_current / avg_current) * 100
    
    # Battery life calculations (40Ah battery)
    battery_40ah_years = 40000 / avg_current / 24 / 365
    target_current_5yr = 40000 / 5 / 365 / 24  # 913 mA for 5 years with 40Ah
    reduction_needed = (1 - target_current_5yr / avg_current) * 100
    
    # Create figure with clean layout
    plt.style.use('default')
    fig = plt.figure(figsize=(16, 10))
    
    # Create grid layout for better spacing
    gs = fig.add_gridspec(3, 3, height_ratios=[0.8, 1, 1], width_ratios=[1, 1, 1], 
                         hspace=0.3, wspace=0.3, top=0.90, bottom=0.08, left=0.08, right=0.95)
    
    # Main title
    fig.suptitle('E-Ink Board Power Analysis - Build 2082 Baseline\n' +
                 f'Normal Operation: {avg_current:.1f} mA avg, {avg_power:.2f} W avg (Sleep mode NOT implemented)',
                 fontsize=16, fontweight='bold')
    
    # 1. Current consumption over time (top, spans 2 columns)
    ax1 = fig.add_subplot(gs[0, :2])
    time_minutes = [(t - df['timestamp'].min()).total_seconds() / 60 for t in df['timestamp']]
    ax1.plot(time_minutes, df['current_mA'], color='#2E86AB', linewidth=2, alpha=0.8)
    ax1.axhline(y=avg_current, color='#A23B72', linestyle='--', linewidth=2, 
                label=f'Average: {avg_current:.1f} mA')
    ax1.fill_between(time_minutes, df['current_mA'], alpha=0.3, color='#2E86AB')
    ax1.set_xlabel('Time (minutes)', fontsize=11)
    ax1.set_ylabel('Current (mA)', fontsize=11)
    ax1.set_title('Current Consumption Over Time', fontsize=12, fontweight='bold')
    ax1.grid(True, alpha=0.3)
    ax1.legend(fontsize=10)
    
    # 2. Battery life by capacity (top right)
    ax2 = fig.add_subplot(gs[0, 2])
    battery_capacities = ['20Ah', '40Ah', '80Ah']
    capacities_mah = [20000, 40000, 80000]
    battery_years = [cap / avg_current / 24 / 365 for cap in capacities_mah]
    
    colors = ['#F18F01', '#2E86AB', '#A23B72']
    bars = ax2.bar(battery_capacities, battery_years, color=colors, alpha=0.8)
    
    # Set appropriate y-axis scale
    max_years = max(battery_years)
    if max_years < 0.1:
        ax2.set_ylim(0, 0.1)
        ax2.axhline(y=0.02, color='orange', linestyle='--', linewidth=1, alpha=0.7, label='1 Week')
        ax2.axhline(y=0.08, color='green', linestyle='--', linewidth=1, alpha=0.7, label='1 Month')
    
    ax2.set_ylabel('Battery Life (Years)', fontsize=11)
    ax2.set_title('Battery Life by Capacity', fontsize=12, fontweight='bold')
    ax2.grid(True, alpha=0.3, axis='y')
    
    # Add value labels
    for bar, years in zip(bars, battery_years):
        if years < 0.1:
            label = f'{years*365:.0f} days'
        else:
            label = f'{years:.1f}y'
        ax2.text(bar.get_x() + bar.get_width()/2, bar.get_height() + max_years*0.02, 
                label, ha='center', va='bottom', fontweight='bold', fontsize=10)
    
    # 3. Power reduction targets (middle left)
    ax3 = fig.add_subplot(gs[1, 0])
    scenarios = ['Current', '50% Cut', '80% Cut', '5-Year\nTarget']
    currents = [avg_current, avg_current * 0.5, avg_current * 0.2, target_current_5yr]
    scenario_colors = ['#C73E1D', '#F18F01', '#2E86AB', '#00A676']
    
    bars3 = ax3.bar(scenarios, currents, color=scenario_colors, alpha=0.8)
    ax3.set_ylabel('Current (mA)', fontsize=11)
    ax3.set_title('Optimization Targets', fontsize=12, fontweight='bold')
    ax3.grid(True, alpha=0.3, axis='y')
    ax3.tick_params(axis='x', labelsize=9)
    
    # Add value labels
    for bar, current in zip(bars3, currents):
        ax3.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 2, 
                f'{current:.1f}', ha='center', va='bottom', fontweight='bold', fontsize=9)
    
    # 4. Key metrics (middle center)
    ax4 = fig.add_subplot(gs[1, 1])
    ax4.axis('off')
    
    metrics_text = f"""CURRENT STATUS
    
Average Current: {avg_current:.1f} mA
Average Power: {avg_power:.2f} W
Stability: {cv_percent:.1f}% CV
    
Battery Life (40Ah): {battery_40ah_years*365:.0f} days
Target: 5 years (1,825 days)
Reduction Needed: {reduction_needed:.0f}%
    
Test Duration: {(df['timestamp'].max() - df['timestamp'].min()).total_seconds() / 60:.1f} min
Samples: {len(df)} measurements
Mode: Normal operation"""
    
    ax4.text(0.05, 0.95, metrics_text, transform=ax4.transAxes, fontsize=11,
             verticalalignment='top', fontfamily='monospace',
             bbox=dict(boxstyle='round,pad=0.5', facecolor='lightblue', alpha=0.3))
    
    # 5. Optimization roadmap (middle right)
    ax5 = fig.add_subplot(gs[1, 2])
    ax5.axis('off')
    
    roadmap_text = """OPTIMIZATION ROADMAP
    
Phase 1: Build 2097
• CPU frequency scaling
• Filesystem optimization
• VM tuning
    
Phase 2: Sleep Implementation
• Deep sleep states
• Wake-on-network
• Peripheral gating
    
Phase 3: Advanced
• Dynamic voltage scaling
• Application optimization"""
    
    ax5.text(0.05, 0.95, roadmap_text, transform=ax5.transAxes, fontsize=11,
             verticalalignment='top', fontfamily='monospace',
             bbox=dict(boxstyle='round,pad=0.5', facecolor='lightgreen', alpha=0.3))
    
    # 6. Power consumption distribution (bottom left)
    ax6 = fig.add_subplot(gs[2, 0])
    ax6.hist(df['current_mA'], bins=15, color='#2E86AB', alpha=0.7, edgecolor='black')
    ax6.axvline(x=avg_current, color='red', linestyle='--', linewidth=2, 
                label=f'Mean: {avg_current:.1f} mA')
    ax6.set_xlabel('Current (mA)', fontsize=11)
    ax6.set_ylabel('Frequency', fontsize=11)
    ax6.set_title('Current Distribution', fontsize=12, fontweight='bold')
    ax6.legend(fontsize=10)
    ax6.grid(True, alpha=0.3)
    
    # 7. Timeline comparison (bottom center)
    ax7 = fig.add_subplot(gs[2, 1])
    timeline_data = ['Current\n(7 days)', 'With Sleep\n(~6 months)', '5-Year\nTarget']
    timeline_values = [battery_40ah_years, 0.5, 5]  # Estimated sleep mode improvement
    timeline_colors = ['#C73E1D', '#F18F01', '#00A676']
    
    bars7 = ax7.bar(timeline_data, timeline_values, color=timeline_colors, alpha=0.8)
    ax7.set_ylabel('Battery Life (Years)', fontsize=11)
    ax7.set_title('Optimization Timeline', fontsize=12, fontweight='bold')
    ax7.grid(True, alpha=0.3, axis='y')
    ax7.tick_params(axis='x', labelsize=9)
    
    # Add value labels
    for bar, years in zip(bars7, timeline_values):
        if years < 0.1:
            label = f'{years*365:.0f}d'
        else:
            label = f'{years:.1f}y'
        ax7.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.1, 
                label, ha='center', va='bottom', fontweight='bold', fontsize=10)
    
    # 8. Next steps (bottom right)
    ax8 = fig.add_subplot(gs[2, 2])
    ax8.axis('off')
    
    next_steps_text = """IMMEDIATE NEXT STEPS
    
1. Deploy Build 2097
   Test initial optimizations
    
2. Implement Sleep Modes
   Major power reduction
    
3. Measure & Compare
   Validate improvements
    
4. Iterate & Optimize
   Reach 5-year target"""
    
    ax8.text(0.05, 0.95, next_steps_text, transform=ax8.transAxes, fontsize=11,
             verticalalignment='top', fontfamily='monospace',
             bbox=dict(boxstyle='round,pad=0.5', facecolor='lightyellow', alpha=0.3))
    
    # Add footer
    fig.text(0.5, 0.02, 'Dynamic Devices Ltd - E-Ink Board Power Optimization Project', 
             ha='center', fontsize=10, style='italic')
    
    plt.savefig(output_file, dpi=300, bbox_inches='tight', facecolor='white')
    print(f"Professional chart saved to: {output_file}")
    
    return output_file

def main():
    # Load the baseline data
    df = parse_power_log('power_optimization/eink_power_20251004_163700.log')
    if df.empty:
        print("No data found!")
        return
    
    # Create professional chart
    chart_file = create_professional_chart(df, 'power_optimization/E-Ink_Power_Baseline_Build2082.png')
    
    print(f"\nProfessional chart created for colleague sharing:")
    print(f"File: {chart_file}")
    print(f"Ready for presentations, emails, and reports!")

if __name__ == '__main__':
    main()
