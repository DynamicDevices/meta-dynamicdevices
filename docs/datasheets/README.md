# Datasheets Reference

## Available Documentation

### i.MX93 Applications Processor
- **Full Manual**: `IMX93RM.pdf` (5593 pages, Rev. 6, 2025-07-01)
- **Quick Reference**: `IMX93RM_Reference.txt` - Key sections for development
- **Key Chapters**: Memory Maps (Ch 2), LPUART (Ch 62), Interrupts (Ch 3)

### i.MX8MM Applications Processor  
- **Full Manual**: `IMX8MMRM.pdf`
- **Text Extract**: `IMX8MMRM_Official.txt` - Searchable text version

### MCXC Power Management Microcontroller
- **Board Manual**: `UM12120.pdf` - FRDM-MCXC444 Board User Manual
- **Reference Manual**: `MCXC44XP64M48RM.pdf` - MCX C44X Sub-Family Reference Manual
- **Key Features**: ARM Cortex-M0+, power management, battery monitoring

### Audio Codec
- **TAS2563 Datasheet**: `TAS2563_datasheet.pdf`
- **Text Extract**: `TAS2563_datasheet.txt` - Searchable text version

## Quick Access Commands

### Search i.MX93 Manual
```bash
# Search for specific topics
pdftotext IMX93RM.pdf - | grep -i "lpuart\|gpio\|i2c\|spi"

# Extract specific chapters
pdftotext -f 4857 -l 4925 IMX93RM.pdf -  # LPUART chapter
pdftotext -f 56 -l 90 IMX93RM.pdf -      # Memory maps
```

### Search i.MX8MM Manual
```bash
# Use pre-extracted text version
grep -i "audio\|sai\|i2s" IMX8MMRM_Official.txt
```

### Search TAS2563 Datasheet
```bash
# Use pre-extracted text version  
grep -i "i2c\|register\|power" TAS2563_datasheet.txt
```

### Search MCXC Power Management MCU
```bash
# Search board manual
pdftotext UM12120.pdf - | grep -i "power\|battery\|management"

# Search reference manual
pdftotext MCXC44XP64M48RM.pdf - | grep -i "gpio\|uart\|power\|register"
```

## Engineering Notes

- **i.MX93**: Focus on LPUART (Ch 62) and Memory Maps (Ch 2) for serial port work
- **i.MX8MM**: Audio development requires SAI and ASRC chapters
- **TAS2563**: I2C register configuration critical for audio functionality

---
*Keep datasheets accessible for quick hardware reference during development*
