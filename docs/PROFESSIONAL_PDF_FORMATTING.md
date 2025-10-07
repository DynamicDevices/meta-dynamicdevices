# Professional PDF Formatting Documentation

This document explains how the professional formatting is achieved for security reports and ensures it's preserved for future use.

## Format Definition Layers

### 1. Document Structure (Markdown Level)
The professional format starts with proper Markdown structure in the report file:

```markdown
---
title: "Security Compliance Report"
subtitle: "imx93-jaguar-eink Board"
author: "Dynamic Devices Ltd"
date: "October 7, 2025"
version: "2025-10-07"
classification: "Confidential"
---

\newpage

# Security Compliance Report
## imx93-jaguar-eink Board

**Document Control**
| Field | Value |
|-------|-------|
| **Document Title** | Security Compliance Report: imx93-jaguar-eink Board |
```

### 2. CSS Styling (Embedded in PDF Generator)
The professional appearance is defined in `scripts/generate-pdf.sh` with embedded CSS:

**Location**: Lines 165-278 in `scripts/generate-pdf.sh`

**Key Style Elements**:
- Corporate color scheme: `#1f4e79` (dark blue), `#2e5c8a` (medium blue), `#4472c4` (light blue)
- Professional typography: Segoe UI font family
- Gradient table headers: `linear-gradient(135deg, #1f4e79 0%, #2e5c8a 100%)`
- Page margins: `15mm 12mm 15mm 12mm` (top, right, bottom, left)
- Justified text alignment for professional appearance

### 3. PDF Generation Process
**Two-step process in `scripts/generate-pdf.sh`**:

1. **Markdown → HTML**: `pandoc` converts with syntax highlighting
2. **CSS Injection**: `sed` injects professional CSS into HTML `<head>`
3. **HTML → PDF**: `wkhtmltopdf` with professional margins

## Critical Files to Preserve

### Primary Files:
1. **`scripts/generate-pdf.sh`** - Contains all CSS styling and generation logic
2. **`scripts/PDF_GENERATION.md`** - Usage documentation
3. **Document template structure** in security reports

### Backup Strategy:
1. CSS styles are embedded in the generation script (self-contained)
2. No external CSS files that could be lost
3. All formatting logic in version control

## CSS Style Breakdown

### Color Scheme:
```css
/* Corporate Blues */
--primary-blue: #1f4e79;    /* Headers, borders */
--medium-blue: #2e5c8a;     /* Section headers */
--light-blue: #4472c4;      /* Subsections, accents */
--text-color: #333;         /* Body text */
```

### Typography Hierarchy:
```css
h1: 24pt, #1f4e79, bottom border
h2: 18pt, #2e5c8a, left border
h3: 14pt, #4472c4
h4: 12pt, #5b9bd5
```

### Table Styling:
```css
/* Professional gradient headers */
th: linear-gradient(135deg, #1f4e79 0%, #2e5c8a 100%)
/* Zebra striping */
tr:nth-child(even): #f8f9fa background
/* Hover effects */
tr:hover: #e3f2fd background
```

## Usage for Future Reports

### For Security Reports:
```bash
./scripts/generate-pdf.sh -i docs/security/REPORT_NAME.md
```

### For Technical Documentation:
```bash
./scripts/generate-pdf.sh -i wiki/Technical-Doc.md -t technical
```

### For General Documents:
```bash
./scripts/generate-pdf.sh -i README.md -t general
```

## Customization Points

### Document-Specific Styling:
- Modify YAML frontmatter for different document types
- Adjust color scheme in CSS section (lines 180-278)
- Change margins in wkhtmltopdf command (lines 283-286)

### Corporate Branding:
- Colors defined in CSS variables
- Logo can be added to header/footer
- Company name in YAML frontmatter

## Preservation Checklist

- ✅ CSS embedded in generation script (no external dependencies)
- ✅ All formatting logic version controlled
- ✅ Documentation of style elements
- ✅ Example usage documented
- ✅ Backup of working configuration

## Recovery Instructions

If formatting is lost, restore from:
1. Git history of `scripts/generate-pdf.sh`
2. This documentation file
3. Working PDF example for reference

The key is that ALL formatting is self-contained in the `generate-pdf.sh` script - no external files needed!
