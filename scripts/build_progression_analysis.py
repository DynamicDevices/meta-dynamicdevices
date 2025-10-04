#!/usr/bin/env python3
"""
E-Ink Board Power Analysis - Build Testing Progression
Shows current baseline and projected optimizations for 5-year battery life target
"""

import matplotlib.pyplot as plt
import numpy as np
from datetime import datetime
import pandas as pd

def create_build_progression_chart():
    """Create chart showing testing progression and optimization targets"""
    
    # Current measured data (Build 2097 baseline)
    baseline_current_mA = 269.8
    baseline_power_W = 1.349
    baseline_battery_years = 5000 / baseline_current_mA / 24 / 365  # 5Ah battery
    
    # Projected optimization builds with estimated power reductions
    builds_data = [
        {"name": "Build 2097\n(Baseline)", "current_mA": baseline_current_mA, "power_W": baseline_power_W, "status": "measured", "color": "#ff6b6b"},
        {"name": "Build 2100\n(IMX93_LPM)", "current_mA": baseline_current_mA * 0.85, "power_W": baseline_power_W * 0.85, "status": "building", "color": "#ffa726"},
        {"name": "Build 2101\n(Filesystem Opts)", "current_mA": baseline_current_mA * 0.75, "power_W": baseline_power_W * 0.75, "status": "projected", "color": "#66bb6a"},
        {"name": "Future Build\n(WiFi Power Mgmt)", "current_mA": baseline_current_mA * 0.60, "power_W": baseline_power_W * 0.60, "status": "projected", "color": "#42a5f5"},
        {"name": "Target Build\n(Full Optimization)", "current_mA": baseline_current_mA * 0.35, "power_W": baseline_power_W * 0.35, "status": "target", "color": "#26c6da"},
    ]
    
    # Calculate battery life for each build
    for build in builds_data:
        build["battery_years"] = 5000 / build["current_mA"] / 24 / 365
        build["power_reduction"] = (baseline_power_W - build["power_W"]) / baseline_power_W * 100
    
    # Create comprehensive chart
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(16, 12))
    fig.suptitle('E-Ink Board Power Optimization Journey\nTesting Progression for 5-Year Battery Life Target', 
                 fontsize=16, fontweight='bold')
    
    build_names = [b["name"] for b in builds_data]
    colors = [b["color"] for b in builds_data]
    
    # 1. Current Consumption Progression
    current_values = [b["current_mA"] for b in builds_data]
    bars1 = ax1.bar(build_names, current_values, color=colors, alpha=0.8)
    ax1.set_ylabel('Current Consumption (mA)')
    ax1.set_title('Current Consumption by Build')
    ax1.tick_params(axis='x', rotation=45)
    ax1.grid(True, alpha=0.3)
    
    # Add value labels and status indicators
    for i, (bar, build) in enumerate(zip(bars1, builds_data)):
        ax1.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 5, 
                f'{build["current_mA"]:.1f} mA', ha='center', va='bottom', fontweight='bold')
        # Add status indicator
        status_symbol = {"measured": "✅", "building": "🔨", "projected": "📊", "target": "🎯"}
        ax1.text(bar.get_x() + bar.get_width()/2, 10, 
                status_symbol[build["status"]], ha='center', va='bottom', fontsize=16)
    
    # 2. Power Consumption Progression
    power_values = [b["power_W"] for b in builds_data]
    bars2 = ax2.bar(build_names, power_values, color=colors, alpha=0.8)
    ax2.set_ylabel('Power Consumption (W)')
    ax2.set_title('Power Consumption by Build')
    ax2.tick_params(axis='x', rotation=45)
    ax2.grid(True, alpha=0.3)
    
    for bar, build in zip(bars2, builds_data):
        ax2.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.02, 
                f'{build["power_W"]:.2f} W', ha='center', va='bottom', fontweight='bold')
    
    # 3. Battery Life Progression
    battery_values = [min(b["battery_years"], 10) for b in builds_data]  # Cap at 10 years for chart
    bars3 = ax3.bar(build_names, battery_values, color=colors, alpha=0.8)
    ax3.set_ylabel('Battery Life (Years)')
    ax3.set_title('Projected Battery Life (5Ah Battery)')
    ax3.tick_params(axis='x', rotation=45)
    ax3.axhline(y=5, color='red', linestyle='--', linewidth=2, alpha=0.7, label='5-Year Target')
    ax3.grid(True, alpha=0.3)
    ax3.legend()
    
    for bar, build in zip(bars3, builds_data):
        years_text = f'{build["battery_years"]:.1f} yr' if build["battery_years"] < 10 else '>10 yr'
        ax3.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.1, 
                years_text, ha='center', va='bottom', fontweight='bold')
    
    # 4. Power Reduction Progression
    reduction_values = [b["power_reduction"] for b in builds_data]
    bars4 = ax4.bar(build_names, reduction_values, color=colors, alpha=0.8)
    ax4.set_ylabel('Power Reduction (%)')
    ax4.set_title('Power Reduction vs Baseline')
    ax4.tick_params(axis='x', rotation=45)
    ax4.axhline(y=50, color='green', linestyle='--', linewidth=2, alpha=0.7, label='50% Target (Min)')
    ax4.axhline(y=80, color='blue', linestyle='--', linewidth=2, alpha=0.7, label='80% Target (Max)')
    ax4.grid(True, alpha=0.3)
    ax4.legend()
    
    for bar, build in zip(bars4, builds_data):
        ax4.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 1, 
                f'{build["power_reduction"]:.1f}%', ha='center', va='bottom', fontweight='bold')
    
    plt.tight_layout()
    
    # Add legend for status symbols
    legend_text = "Status: ✅ Measured  🔨 Building  📊 Projected  🎯 Target"
    fig.text(0.5, 0.02, legend_text, ha='center', fontsize=12, style='italic')
    
    plt.savefig('eink_build_progression.png', dpi=300, bbox_inches='tight')
    print("Build progression chart saved to: eink_build_progression.png")
    
    return builds_data

def create_summary_report(builds_data):
    """Create detailed testing progression report"""
    with open('eink_build_progression_report.txt', 'w') as f:
        f.write("E-INK BOARD POWER OPTIMIZATION TESTING PROGRESSION\n")
        f.write("=" * 60 + "\n\n")
        f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"Target: 5-year battery life (50-80% power reduction)\n")
        f.write(f"Battery Capacity: 5Ah\n")
        f.write(f"Supply Voltage: 6V\n\n")
        
        f.write("BUILD PROGRESSION ANALYSIS\n")
        f.write("-" * 40 + "\n\n")
        
        for i, build in enumerate(builds_data):
            f.write(f"{i+1}. {build['name'].replace(chr(10), ' ')}\n")
            f.write(f"   Status: {build['status'].upper()}\n")
            f.write(f"   Current: {build['current_mA']:.1f} mA\n")
            f.write(f"   Power: {build['power_W']:.3f} W\n")
            f.write(f"   Battery Life: {build['battery_years']:.2f} years\n")
            f.write(f"   Power Reduction: {build['power_reduction']:.1f}%\n")
            
            if build['battery_years'] >= 5:
                f.write("   ✅ MEETS 5-YEAR TARGET\n")
            else:
                f.write("   ❌ Below 5-year target\n")
            f.write("\n")
        
        f.write("OPTIMIZATION STRATEGY\n")
        f.write("-" * 40 + "\n")
        f.write("1. Build 2097 (Baseline): Current measured consumption\n")
        f.write("2. Build 2100 (IMX93_LPM): Enable i.MX93 Low Power Management\n")
        f.write("3. Build 2101 (Filesystem): Optimize filesystem operations\n")
        f.write("4. Future Builds: WiFi power management, service optimization\n")
        f.write("5. Target: 65% power reduction for 5+ year battery life\n\n")
        
        f.write("CURRENT STATUS\n")
        f.write("-" * 40 + "\n")
        baseline = builds_data[0]
        target = builds_data[-1]
        f.write(f"Current Consumption: {baseline['current_mA']:.1f} mA\n")
        f.write(f"Target Consumption: {target['current_mA']:.1f} mA\n")
        f.write(f"Required Reduction: {target['power_reduction']:.1f}%\n")
        f.write(f"Current Battery Life: {baseline['battery_years']:.2f} years\n")
        f.write(f"Target Battery Life: {target['battery_years']:.2f} years\n")
    
    print("Build progression report saved to: eink_build_progression_report.txt")

if __name__ == '__main__':
    builds_data = create_build_progression_chart()
    create_summary_report(builds_data)
