# Datasheets Reference

## Available Documentation

### i.MX93 Applications Processor
- **Full Manual**: `IMX93RM.pdf` (5593 pages, Rev. 6, 2025-07-01)
- **Quick Reference**: `IMX93RM_Reference.txt` - Key sections for development
- **Key Chapters**: Memory Maps (Ch 2), LPUART (Ch 62), Interrupts (Ch 3)

### i.MX8MM Applications Processor  
- **Full Manual**: `IMX8MMRM.pdf`
- **Text Extract**: `IMX8MMRM_Official.txt` - Searchable text version

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

## Engineering Notes

- **i.MX93**: Focus on LPUART (Ch 62) and Memory Maps (Ch 2) for serial port work
- **i.MX8MM**: Audio development requires SAI and ASRC chapters
- **TAS2563**: I2C register configuration critical for audio functionality

---
*Keep datasheets accessible for quick hardware reference during development*
