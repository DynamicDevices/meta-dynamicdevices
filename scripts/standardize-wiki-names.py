#!/usr/bin/env python3
"""
Wiki File Naming Standardizer
Standardizes wiki file names to follow consistent naming convention
"""

import os
import re
import sys

def get_standard_name(filename):
    """Convert filename to standard naming convention"""
    # Remove .md extension
    name = filename.replace('.md', '')
    
    # Standard naming patterns we want to follow:
    # - Use Title-Case-With-Hyphens
    # - Group related files with prefixes (e.g., Quick-Start-, Development-Workflows-, etc.)
    # - No underscores, use hyphens instead
    # - No spaces
    
    # Replace underscores with hyphens
    name = name.replace('_', '-')
    
    # Handle special cases and ensure consistent naming
    replacements = {
        # Fix inconsistent casing
        'EINK-BOARD-TESTING-PLAN-v1.0.0-rc1': 'Development-Workflows-EInk-Board-Testing-Plan',
        'POWER-MONITORING-GUIDE': 'Development-Workflows-Power-Monitoring-Guide',
        'RTC-POWER-OPTIMIZATION-STRATEGY': 'Development-Workflows-RTC-Power-Optimization-Strategy', 
        'TWT-USERSPACE-TOOLS-UPDATE-STRATEGY': 'Development-Workflows-TWT-Userspace-Tools-Update-Strategy',
        
        # Ensure consistent prefixing
        'E-Ink-Display-Testing': 'Hardware-Testing-EInk-Display-Testing',
        'USB-Audio-Integration': 'Feature-Guides-USB-Audio-Integration',
        'IW612-Power-Management-Fix': 'Hardware-Fixes-IW612-Power-Management-Fix',
        'MCUmgr-Bootloader-Management': 'Development-Tools-MCUmgr-Bootloader-Management',
        'Serial-Port-Configuration': 'Development-Setup-Serial-Port-Configuration',
        'Hardware-Troubleshooting': 'Hardware-Reference-Troubleshooting',
        
        # Fix specific naming issues
        'Moving-between-Production-and-Development-builds': 'Development-Workflows-Production-Development-Builds',
        'Onboarding-to-WiFi-with-BLE-Serial-using-Improv': 'Feature-Guides-WiFi-BLE-Onboarding-Improv',
        'Flashing-an-Edge-board-with-a-Yocto-Embedded-Linux-image': 'Development-Workflows-Board-Flashing-Guide',
        'Yocto-SDK-Installation': 'Development-Setup-Yocto-SDK-Installation',
        'Troubleshooting:-(Re‐)registering-with-Foundries.io': 'Troubleshooting-Foundries-Registration',
        'Securing-Edge-Boards': 'Security-Edge-Board-Security-Guide',
    }
    
    # Apply specific replacements
    if name in replacements:
        return replacements[name]
    
    # Ensure proper title case for remaining files
    # Split on hyphens, capitalize each word, rejoin
    parts = name.split('-')
    standardized_parts = []
    
    for part in parts:
        # Handle acronyms and special cases
        if part.upper() in ['AI', 'EV', 'GW', 'USB', 'SDK', 'API', 'GPIO', 'I2C', 'SPI', 'UART', 'PWM', 'ADC', 'DAC']:
            standardized_parts.append(part.upper())
        elif part.lower() in ['eink', 'e-ink']:
            standardized_parts.append('EInk')
        elif part.lower() == 'wifi':
            standardized_parts.append('WiFi')
        elif part.lower() == 'bluetooth':
            standardized_parts.append('Bluetooth')
        else:
            # Standard title case
            standardized_parts.append(part.capitalize())
    
    return '-'.join(standardized_parts)

def find_wiki_files():
    """Find all markdown files in wiki directory"""
    wiki_files = []
    for root, dirs, files in os.walk('wiki'):
        for file in files:
            if file.endswith('.md'):
                wiki_files.append(os.path.join(root, file))
    return wiki_files

def update_links_in_file(file_path, old_to_new_mapping):
    """Update wiki links in a file based on name changes"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Update wiki-style links [[Page-Name|Display Text]] and [[Page-Name]]
        def replace_wiki_link(match):
            full_match = match.group(0)
            page_ref = match.group(1)
            display_text = match.group(2) if match.group(2) else None
            
            # Check if this page reference needs updating
            if page_ref in old_to_new_mapping:
                new_page_ref = old_to_new_mapping[page_ref]
                if display_text:
                    return f'[[{new_page_ref}|{display_text}]]'
                else:
                    return f'[[{new_page_ref}]]'
            
            return full_match
        
        # Pattern for [[Page-Name|Display Text]] or [[Page-Name]]
        content = re.sub(r'\[\[([^|\]]+)(?:\|([^\]]+))?\]\]', replace_wiki_link, content)
        
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        
        return False
        
    except Exception as e:
        print(f"Error updating links in {file_path}: {e}")
        return False

def main():
    if not os.path.exists('wiki'):
        print("Error: wiki directory not found")
        sys.exit(1)
    
    wiki_files = find_wiki_files()
    
    # Build mapping of old names to new names
    renames = []
    old_to_new_mapping = {}
    
    for file_path in wiki_files:
        filename = os.path.basename(file_path)
        directory = os.path.dirname(file_path)
        
        standard_name = get_standard_name(filename)
        
        if standard_name + '.md' != filename:
            old_name = filename.replace('.md', '')
            new_name = standard_name
            
            old_path = file_path
            new_path = os.path.join(directory, standard_name + '.md')
            
            renames.append((old_path, new_path, old_name, new_name))
            old_to_new_mapping[old_name] = new_name
    
    if not renames:
        print("✅ All wiki files already follow standard naming convention!")
        return
    
    print(f"Found {len(renames)} files to rename:")
    for old_path, new_path, old_name, new_name in renames:
        print(f"  {old_name} → {new_name}")
    
    # Perform renames
    print("\n📝 Renaming files...")
    for old_path, new_path, old_name, new_name in renames:
        try:
            os.rename(old_path, new_path)
            print(f"✅ Renamed: {old_name} → {new_name}")
        except Exception as e:
            print(f"❌ Failed to rename {old_name}: {e}")
    
    # Update all links in all wiki files
    print("\n🔗 Updating links in all wiki files...")
    updated_files = 0
    
    # Get updated file list after renames
    wiki_files = find_wiki_files()
    
    for file_path in wiki_files:
        if update_links_in_file(file_path, old_to_new_mapping):
            updated_files += 1
            print(f"✅ Updated links in {os.path.basename(file_path)}")
    
    print(f"\n🎉 Standardization complete!")
    print(f"Files renamed: {len(renames)}")
    print(f"Files with updated links: {updated_files}")
    print(f"Total wiki files: {len(wiki_files)}")

if __name__ == '__main__':
    main()
