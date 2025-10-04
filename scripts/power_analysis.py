#!/usr/bin/env python3
"""
E-Ink Board Power Analysis and Charting Tool
Analyzes power consumption data from different builds and creates comparison charts
"""

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from datetime import datetime
import numpy as np
import argparse
import os
import glob

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
                        power_W = current_A * 6.0  # Assume 6V supply
                    
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

def analyze_power_data(df, build_name="Unknown"):
    """Analyze power consumption data"""
    if df.empty:
        return None
    
    analysis = {
        'build': build_name,
        'duration_minutes': (df['timestamp'].max() - df['timestamp'].min()).total_seconds() / 60,
        'avg_current_mA': df['current_mA'].mean(),
        'avg_power_W': df['power_W'].mean(),
        'min_current_mA': df['current_mA'].min(),
        'max_current_mA': df['current_mA'].max(),
        'std_current_mA': df['current_mA'].std(),
        'battery_life_hours_5Ah': 5000 / df['current_mA'].mean() if df['current_mA'].mean() > 0 else float('inf'),
        'samples': len(df)
    }
    
    analysis['battery_life_days'] = analysis['battery_life_hours_5Ah'] / 24
    analysis['battery_life_years'] = analysis['battery_life_days'] / 365
    
    return analysis

def create_power_comparison_chart(analyses, output_file='power_comparison.png'):
    """Create comparison chart of different builds"""
    if not analyses:
        print("No data to chart")
        return
    
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 12))
    fig.suptitle('E-Ink Board Power Consumption Analysis\nBuild Comparison for 5-Year Battery Life Target', fontsize=16, fontweight='bold')
    
    builds = [a['build'] for a in analyses]
    avg_current = [a['avg_current_mA'] for a in analyses]
    avg_power = [a['avg_power_W'] for a in analyses]
    battery_years = [min(a['battery_life_years'], 10) for a in analyses]  # Cap at 10 years for chart
    
    # Colors for different builds
    colors = ['#ff6b6b', '#4ecdc4', '#45b7d1', '#96ceb4', '#feca57', '#ff9ff3']
    
    # Current consumption comparison
    bars1 = ax1.bar(builds, avg_current, color=colors[:len(builds)], alpha=0.8)
    ax1.set_ylabel('Average Current (mA)')
    ax1.set_title('Current Consumption by Build')
    ax1.tick_params(axis='x', rotation=45)
    
    # Add value labels on bars
    for bar, value in zip(bars1, avg_current):
        ax1.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 5, 
                f'{value:.1f} mA', ha='center', va='bottom', fontweight='bold')
    
    # Power consumption comparison  
    bars2 = ax2.bar(builds, avg_power, color=colors[:len(builds)], alpha=0.8)
    ax2.set_ylabel('Average Power (W)')
    ax2.set_title('Power Consumption by Build')
    ax2.tick_params(axis='x', rotation=45)
    
    # Add value labels on bars
    for bar, value in zip(bars2, avg_power):
        ax2.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.02, 
                f'{value:.2f} W', ha='center', va='bottom', fontweight='bold')
    
    # Battery life comparison
    bars3 = ax3.bar(builds, battery_years, color=colors[:len(builds)], alpha=0.8)
    ax3.set_ylabel('Battery Life (Years)')
    ax3.set_title('Projected Battery Life (5Ah Battery)')
    ax3.tick_params(axis='x', rotation=45)
    ax3.axhline(y=5, color='red', linestyle='--', alpha=0.7, label='5-Year Target')
    ax3.legend()
    
    # Add value labels on bars
    for bar, value in zip(bars3, battery_years):
        ax3.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.1, 
                f'{value:.1f} yr', ha='center', va='bottom', fontweight='bold')
    
    # Power reduction comparison (relative to first build)
    if len(analyses) > 1:
        baseline_power = analyses[0]['avg_power_W']
        power_reduction = [(baseline_power - a['avg_power_W']) / baseline_power * 100 for a in analyses]
        power_reduction[0] = 0  # Baseline is 0% reduction
        
        bars4 = ax4.bar(builds, power_reduction, color=colors[:len(builds)], alpha=0.8)
        ax4.set_ylabel('Power Reduction (%)')
        ax4.set_title('Power Reduction vs Baseline')
        ax4.tick_params(axis='x', rotation=45)
        ax4.axhline(y=50, color='green', linestyle='--', alpha=0.7, label='50% Target (Min)')
        ax4.axhline(y=80, color='blue', linestyle='--', alpha=0.7, label='80% Target (Max)')
        ax4.legend()
        
        # Add value labels on bars
        for bar, value in zip(bars4, power_reduction):
            ax4.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 1, 
                    f'{value:.1f}%', ha='center', va='bottom', fontweight='bold')
    else:
        ax4.text(0.5, 0.5, 'Need multiple builds\nfor comparison', 
                ha='center', va='center', transform=ax4.transAxes, fontsize=12)
        ax4.set_title('Power Reduction Analysis')
    
    plt.tight_layout()
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"Chart saved to: {output_file}")
    return output_file

def create_summary_report(analyses, output_file='power_analysis_report.txt'):
    """Create detailed text report"""
    with open(output_file, 'w') as f:
        f.write("E-INK BOARD POWER ANALYSIS REPORT\n")
        f.write("=" * 50 + "\n\n")
        f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"Target: 5-year battery life (50-80% power reduction)\n\n")
        
        for i, analysis in enumerate(analyses):
            f.write(f"BUILD: {analysis['build']}\n")
            f.write("-" * 30 + "\n")
            f.write(f"Duration: {analysis['duration_minutes']:.1f} minutes\n")
            f.write(f"Samples: {analysis['samples']}\n")
            f.write(f"Average Current: {analysis['avg_current_mA']:.1f} mA\n")
            f.write(f"Average Power: {analysis['avg_power_W']:.3f} W\n")
            f.write(f"Current Range: {analysis['min_current_mA']:.1f} - {analysis['max_current_mA']:.1f} mA\n")
            f.write(f"Current Std Dev: {analysis['std_current_mA']:.1f} mA\n")
            f.write(f"Battery Life: {analysis['battery_life_years']:.2f} years\n")
            
            if i > 0:
                baseline = analyses[0]
                reduction = (baseline['avg_power_W'] - analysis['avg_power_W']) / baseline['avg_power_W'] * 100
                f.write(f"Power Reduction: {reduction:.1f}% vs {baseline['build']}\n")
                
                if analysis['battery_life_years'] >= 5:
                    f.write("✅ MEETS 5-YEAR TARGET\n")
                else:
                    f.write("❌ Below 5-year target\n")
            
            f.write("\n")
        
        # Summary
        if len(analyses) > 1:
            f.write("SUMMARY\n")
            f.write("-" * 30 + "\n")
            best_build = min(analyses, key=lambda x: x['avg_power_W'])
            baseline = analyses[0]
            total_reduction = (baseline['avg_power_W'] - best_build['avg_power_W']) / baseline['avg_power_W'] * 100
            
            f.write(f"Best Build: {best_build['build']}\n")
            f.write(f"Total Power Reduction: {total_reduction:.1f}%\n")
            f.write(f"Best Battery Life: {best_build['battery_life_years']:.2f} years\n")
            
            if total_reduction >= 50:
                f.write("✅ POWER REDUCTION TARGET MET\n")
            else:
                f.write(f"❌ Need {50 - total_reduction:.1f}% more reduction\n")
    
    print(f"Report saved to: {output_file}")
    return output_file

def main():
    parser = argparse.ArgumentParser(description='Analyze E-Ink board power consumption')
    parser.add_argument('--log-dir', default='.', help='Directory containing log files')
    parser.add_argument('--output-dir', default='.', help='Output directory for charts and reports')
    parser.add_argument('--build-mapping', help='JSON file mapping log files to build names')
    
    args = parser.parse_args()
    
    # Find all power log files
    log_files = glob.glob(os.path.join(args.log_dir, 'eink_power_*.log'))
    
    if not log_files:
        print("No power log files found!")
        return
    
    analyses = []
    
    # Load build mapping from JSON if provided
    build_mapping = {}
    if args.build_mapping and os.path.exists(args.build_mapping):
        import json
        with open(args.build_mapping, 'r') as f:
            build_mapping = json.load(f)
    else:
        # Default build mapping based on timestamp/filename
        build_mapping = {
            '20251004_154606': 'Build 2097 (Pre-Optimization)',
            '20251004_154830': 'Build 2097 (Initial Test)', 
            '20251004_162918': 'Build 2097 (Baseline)'
        }
    
    for log_file in sorted(log_files):
        print(f"Processing: {log_file}")
        df = parse_power_log(log_file)
        
        if df.empty:
            print(f"  No valid data found in {log_file}")
            continue
            
        # Extract timestamp from filename for build identification
        filename = os.path.basename(log_file)
        timestamp = filename.replace('eink_power_', '').replace('.log', '')
        build_name = build_mapping.get(timestamp, f"Build {timestamp}")
        
        analysis = analyze_power_data(df, build_name)
        if analysis:
            analyses.append(analysis)
            print(f"  {build_name}: {analysis['avg_current_mA']:.1f} mA, {analysis['avg_power_W']:.3f} W, {analysis['battery_life_years']:.2f} years")
    
    if analyses:
        # Create charts and reports
        chart_file = os.path.join(args.output_dir, 'eink_power_comparison.png')
        report_file = os.path.join(args.output_dir, 'eink_power_analysis.txt')
        
        create_power_comparison_chart(analyses, chart_file)
        create_summary_report(analyses, report_file)
        
        print(f"\nAnalysis complete!")
        print(f"Charts: {chart_file}")
        print(f"Report: {report_file}")
    else:
        print("No valid data found to analyze")

if __name__ == '__main__':
    main()
