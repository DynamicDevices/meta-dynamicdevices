# Universal PDF Generation Script

This directory contains a single, comprehensive PDF generation script for all documentation in meta-dynamicdevices.

## Usage

```bash
# Basic usage - auto-detects document type and generates PDF
./scripts/generate-pdf.sh -i input.md

# Security reports (auto-detected from filename)
./scripts/generate-pdf.sh -i docs/security/SECURITY_COMPLIANCE_REPORT_*.md

# Technical documentation
./scripts/generate-pdf.sh -i wiki/Technical-Architecture.md -t technical

# General documentation with custom headers
./scripts/generate-pdf.sh -i README.md -t general --header-left "Project Documentation"
```

## Features

- **Auto-detection**: Automatically detects document type from filename
- **Professional styling**: Consistent formatting with proper margins and typography
- **Flexible headers/footers**: Customizable headers and footers
- **Multiple document types**: Support for security, technical, and general documents
- **Template fallback**: Works with or without eisvogel template
- **Robust error handling**: Clear error messages and validation

## Document Types

- `security`: Security reports, compliance documents
- `technical`: Technical specifications, architecture docs  
- `general`: General documentation
- `auto`: Automatically detect based on filename (default)

## Replaced Scripts

This single script replaces:
- `generate-enhanced-pdf.sh` (removed to avoid confusion)
- Any other PDF generation approaches

Use only `./scripts/generate-pdf.sh` for all PDF generation needs.
