#!/usr/bin/env python3
"""
Simple TAS2563 RegBin JSON to Binary Converter
Converts the corrected JSON configuration to binary regbin format
"""

import json
import struct
import sys

def convert_json_to_regbin(json_file, output_file):
    """Convert JSON regbin configuration to binary format"""
    
    with open(json_file, 'r') as f:
        config = json.load(f)
    
    # Start building binary data
    binary_data = bytearray()
    
    # RegBin header (simplified)
    # Magic number for TAS2563 regbin
    binary_data.extend(b'TAS2563\x00')
    
    # Version info
    version = config.get('version', '1.3.8')
    binary_data.extend(version.encode('ascii')[:8].ljust(8, b'\x00'))
    
    # Configuration count
    config_list = config['settings']['configurationList']
    binary_data.extend(struct.pack('<I', len(config_list)))
    
    for config_item in config_list:
        # Configuration name
        config_name = config_item['configName']
        binary_data.extend(config_name.encode('ascii')[:64].ljust(64, b'\x00'))
        
        # Blocks count
        blocks = config_item['blocksList']
        binary_data.extend(struct.pack('<I', len(blocks)))
        
        for block in blocks:
            # Block type
            block_type = block['blockType']
            if block_type == 'PRE_POWER_UP':
                block_type_val = 0x04
            elif block_type == 'PRE_SHUTDOWN':
                block_type_val = 0x03
            else:
                block_type_val = 0x01
            
            binary_data.extend(struct.pack('<B', block_type_val))
            
            # Device value (THIS IS THE KEY FIX!)
            device_value = block['deviceValue']
            binary_data.extend(struct.pack('<B', device_value))
            
            # Commands count
            commands = block['commands']
            binary_data.extend(struct.pack('<I', len(commands)))
            
            for cmd in commands:
                # Book, Page, Register, Mask, Data
                book = int(cmd['book'], 16) if isinstance(cmd['book'], str) else cmd['book']
                page = int(cmd['page'], 16) if isinstance(cmd['page'], str) else cmd['page']
                register = int(cmd['register'], 16)
                mask = int(cmd['mask'], 16)
                data = int(cmd['data'], 16)
                
                binary_data.extend(struct.pack('<BBBBB', book, page, register, mask, data))
                
                # Delay (if present)
                delay = cmd.get('delay', '')
                if delay:
                    delay_val = int(delay)
                else:
                    delay_val = 0
                binary_data.extend(struct.pack('<H', delay_val))
    
    # Write to output file
    with open(output_file, 'wb') as f:
        f.write(binary_data)
    
    print(f"✅ Converted {json_file} to {output_file}")
    print(f"📊 Binary size: {len(binary_data)} bytes")
    
    # Show the key fix
    print(f"🔧 Key Fix Applied:")
    for config_item in config_list:
        for block in config_item['blocksList']:
            print(f"   {block['blockType']}: deviceValue = {block['deviceValue']}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 convert_regbin.py input.json output.bin")
        sys.exit(1)
    
    json_file = sys.argv[1]
    output_file = sys.argv[2]
    
    try:
        convert_json_to_regbin(json_file, output_file)
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)
