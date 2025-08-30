# EL133UF1 E-Ink Driver Licensing Notes

## Current Status
- **Source**: E Ink Holdings Inc. sample code
- **Received Under**: NDA (Non-Disclosure Agreement)
- **Current License**: MIT (may be temporary/placeholder)

## Action Required
The license may need to be changed from MIT to one of the following:

### Option 1: COMMERCIAL License
```bitbake
LICENSE = "COMMERCIAL"
LIC_FILES_CHKSUM = "file://LICENSE;md5=<new_checksum>"
```

### Option 2: PROPRIETARY License  
```bitbake
LICENSE = "PROPRIETARY"
LIC_FILES_CHKSUM = "file://LICENSE;md5=<new_checksum>"
```

## Implications

### MIT License (Current)
- ✅ Open source compatible
- ✅ Can be used in commercial products
- ❌ May not reflect actual licensing terms from E Ink Holdings

### COMMERCIAL License
- ✅ Clearly indicates commercial/proprietary nature
- ✅ Prevents accidental open source distribution
- ❌ Requires proper license agreement with E Ink Holdings

### PROPRIETARY License
- ✅ Most restrictive, prevents redistribution
- ✅ Suitable for NDA-protected code
- ❌ May limit internal development flexibility

## Recommendations

1. **Immediate**: Add license warning to prevent accidental distribution
2. **Short-term**: Consult legal team about appropriate license terms
3. **Long-term**: Establish proper licensing agreement with E Ink Holdings

## Yocto Recipe Updates Needed

When license is finalized, update:
- `LICENSE = "PROPRIETARY"` (or appropriate license)
- `LIC_FILES_CHKSUM = "file://LICENSE;md5=<correct_checksum>"`
- Add `COMMERCIAL_LICENSE = "1"` if using commercial license

## Distribution Considerations

- **Internal Development**: Current setup OK for development/testing
- **Customer Delivery**: Must resolve licensing before shipping
- **Open Source**: Cannot be distributed as open source under NDA
- **Commercial Products**: Requires proper licensing agreement
