#!/bin/bash
# Enhanced PDF generation script for security compliance reports
# Provides better typography, styling, and professional appearance

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Default values
INPUT_FILE=""
OUTPUT_FILE=""
REPORT_TYPE="security"

# Function to show usage
show_usage() {
    echo "Usage: $0 -i INPUT_FILE [-o OUTPUT_FILE] [-t REPORT_TYPE]"
    echo ""
    echo "Options:"
    echo "  -i INPUT_FILE    Input Markdown file (required)"
    echo "  -o OUTPUT_FILE   Output PDF file (optional, defaults to INPUT_FILE.pdf)"
    echo "  -t REPORT_TYPE   Report type: security, technical, executive (default: security)"
    echo ""
    echo "Examples:"
    echo "  $0 -i docs/security/SECURITY_COMPLIANCE_REPORT_2025-10-07_dfdfe45.md"
    echo "  $0 -i report.md -o custom_output.pdf -t executive"
}

# Parse command line arguments
while getopts "i:o:t:h" opt; do
    case $opt in
        i)
            INPUT_FILE="$OPTARG"
            ;;
        o)
            OUTPUT_FILE="$OPTARG"
            ;;
        t)
            REPORT_TYPE="$OPTARG"
            ;;
        h)
            show_usage
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            show_usage
            exit 1
            ;;
    esac
done

# Validate required arguments
if [ -z "$INPUT_FILE" ]; then
    echo "Error: Input file is required"
    show_usage
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' does not exist"
    exit 1
fi

# Set default output file if not provided
if [ -z "$OUTPUT_FILE" ]; then
    OUTPUT_FILE="${INPUT_FILE%.*}.pdf"
fi

# Create temporary directory for processing
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Extract metadata from the markdown file
TITLE=$(grep "^# " "$INPUT_FILE" | head -1 | sed 's/^# //')
AUTHOR="Dynamic Devices Ltd"
DATE=$(date +"%B %d, %Y")

# Try to extract date from filename or content
if [[ "$INPUT_FILE" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
    REPORT_DATE="${BASH_REMATCH[1]}"
    DATE=$(date -d "$REPORT_DATE" +"%B %d, %Y" 2>/dev/null || echo "$DATE")
fi

echo "=== Enhanced PDF Generation ==="
echo "Input:  $INPUT_FILE"
echo "Output: $OUTPUT_FILE"
echo "Type:   $REPORT_TYPE"
echo "Title:  $TITLE"
echo "Date:   $DATE"
echo ""

# Create enhanced CSS for better styling
cat > "$TEMP_DIR/style.css" << 'EOF'
/* Enhanced CSS for Professional Security Reports */

@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap');

:root {
    --primary-color: #2563eb;
    --secondary-color: #64748b;
    --success-color: #059669;
    --warning-color: #d97706;
    --danger-color: #dc2626;
    --background-color: #ffffff;
    --text-color: #1e293b;
    --border-color: #e2e8f0;
    --code-background: #f8fafc;
}

* {
    box-sizing: border-box;
}

body {
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    font-size: 11pt;
    line-height: 1.6;
    color: var(--text-color);
    background-color: var(--background-color);
    margin: 0;
    padding: 0;
}

/* Page layout */
@page {
    size: A4;
    margin: 2cm 2cm 2.5cm 2cm;
    
    @top-left {
        content: "Security Compliance Report";
        font-size: 9pt;
        color: var(--secondary-color);
    }
    
    @top-right {
        content: "Dynamic Devices Ltd";
        font-size: 9pt;
        color: var(--secondary-color);
    }
    
    @bottom-center {
        content: "Page " counter(page) " of " counter(pages);
        font-size: 9pt;
        color: var(--secondary-color);
    }
    
    @bottom-right {
        content: "Confidential";
        font-size: 8pt;
        color: var(--danger-color);
        font-weight: 600;
    }
}

/* Typography */
h1, h2, h3, h4, h5, h6 {
    font-weight: 600;
    line-height: 1.3;
    margin-top: 1.5em;
    margin-bottom: 0.5em;
    page-break-after: avoid;
}

h1 {
    font-size: 24pt;
    color: var(--primary-color);
    border-bottom: 3px solid var(--primary-color);
    padding-bottom: 0.3em;
    margin-top: 0;
}

h2 {
    font-size: 18pt;
    color: var(--primary-color);
    border-bottom: 1px solid var(--border-color);
    padding-bottom: 0.2em;
}

h3 {
    font-size: 14pt;
    color: var(--text-color);
}

h4 {
    font-size: 12pt;
    color: var(--secondary-color);
}

/* Paragraphs and text */
p {
    margin: 0.8em 0;
    text-align: justify;
}

strong, b {
    font-weight: 600;
    color: var(--text-color);
}

em, i {
    font-style: italic;
    color: var(--secondary-color);
}

/* Lists */
ul, ol {
    margin: 0.8em 0;
    padding-left: 1.5em;
}

li {
    margin: 0.3em 0;
}

/* Code and preformatted text */
code {
    font-family: 'JetBrains Mono', 'Consolas', 'Monaco', monospace;
    font-size: 9pt;
    background-color: var(--code-background);
    padding: 0.2em 0.4em;
    border-radius: 3px;
    border: 1px solid var(--border-color);
}

pre {
    font-family: 'JetBrains Mono', 'Consolas', 'Monaco', monospace;
    font-size: 9pt;
    background-color: var(--code-background);
    border: 1px solid var(--border-color);
    border-radius: 5px;
    padding: 1em;
    margin: 1em 0;
    overflow-x: auto;
    page-break-inside: avoid;
}

pre code {
    background: none;
    border: none;
    padding: 0;
}

/* Tables */
table {
    width: 100%;
    border-collapse: collapse;
    margin: 1em 0;
    font-size: 10pt;
    page-break-inside: avoid;
}

th, td {
    border: 1px solid var(--border-color);
    padding: 0.6em;
    text-align: left;
    vertical-align: top;
}

th {
    background-color: var(--code-background);
    font-weight: 600;
    color: var(--text-color);
}

tr:nth-child(even) {
    background-color: #fafbfc;
}

/* Status indicators */
.status-compliant {
    color: var(--success-color);
    font-weight: 600;
}

.status-warning {
    color: var(--warning-color);
    font-weight: 600;
}

.status-danger {
    color: var(--danger-color);
    font-weight: 600;
}

/* Blockquotes */
blockquote {
    margin: 1em 0;
    padding: 0.8em 1.2em;
    border-left: 4px solid var(--primary-color);
    background-color: var(--code-background);
    font-style: italic;
    page-break-inside: avoid;
}

/* Links */
a {
    color: var(--primary-color);
    text-decoration: none;
}

a:hover {
    text-decoration: underline;
}

/* Page breaks */
.page-break {
    page-break-before: always;
}

.no-break {
    page-break-inside: avoid;
}

/* Special formatting for security reports */
.executive-summary {
    background-color: #f0f9ff;
    border: 1px solid #0ea5e9;
    border-radius: 5px;
    padding: 1em;
    margin: 1em 0;
    page-break-inside: avoid;
}

.security-section {
    margin: 1.5em 0;
    page-break-inside: avoid;
}

.compliance-matrix {
    font-size: 9pt;
}

.compliance-matrix th {
    background-color: var(--primary-color);
    color: white;
}

/* Print optimizations */
@media print {
    body {
        font-size: 10pt;
    }
    
    h1 {
        font-size: 20pt;
    }
    
    h2 {
        font-size: 16pt;
    }
    
    h3 {
        font-size: 13pt;
    }
    
    .no-print {
        display: none;
    }
}
EOF

# Generate PDF with enhanced styling
echo "Generating PDF with enhanced styling..."

pandoc "$INPUT_FILE" \
    -o "$OUTPUT_FILE" \
    --pdf-engine=wkhtmltopdf \
    --css="$TEMP_DIR/style.css" \
    --from markdown+smart \
    --to html5 \
    --standalone \
    --self-contained \
    --metadata title="$TITLE" \
    --metadata author="$AUTHOR" \
    --metadata date="$DATE" \
    --metadata subject="Security Compliance Report" \
    --metadata keywords="security,compliance,CE RED,CRA,imx93" \
    --toc \
    --toc-depth=3 \
    --number-sections \
    --highlight-style=github \
    --variable geometry:a4paper \
    --variable geometry:margin=1.5cm \
    --variable fontsize=11pt \
    --variable linestretch=1.2 \
    --variable colorlinks=true \
    --variable linkcolor=blue \
    --variable urlcolor=blue \
    --variable toccolor=black \
    --pdf-engine-opt=--enable-local-file-access \
    --pdf-engine-opt=--page-size \
    --pdf-engine-opt=A4 \
    --pdf-engine-opt=--margin-top \
    --pdf-engine-opt=15mm \
    --pdf-engine-opt=--margin-bottom \
    --pdf-engine-opt=20mm \
    --pdf-engine-opt=--margin-left \
    --pdf-engine-opt=15mm \
    --pdf-engine-opt=--margin-right \
    --pdf-engine-opt=15mm \
    --pdf-engine-opt=--header-left \
    --pdf-engine-opt="Security Compliance Report" \
    --pdf-engine-opt=--header-right \
    --pdf-engine-opt="Dynamic Devices Ltd" \
    --pdf-engine-opt=--header-font-size \
    --pdf-engine-opt=9 \
    --pdf-engine-opt=--footer-center \
    --pdf-engine-opt="Page [page] of [topage]" \
    --pdf-engine-opt=--footer-right \
    --pdf-engine-opt="Confidential" \
    --pdf-engine-opt=--footer-font-size \
    --pdf-engine-opt=9 \
    --pdf-engine-opt=--header-spacing \
    --pdf-engine-opt=5 \
    --pdf-engine-opt=--footer-spacing \
    --pdf-engine-opt=5

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ PDF generated successfully!"
    echo "📄 Output: $OUTPUT_FILE"
    echo "📊 Size: $(du -h "$OUTPUT_FILE" | cut -f1)"
    echo ""
    echo "Features included:"
    echo "  • Professional typography with Inter font family"
    echo "  • Syntax highlighting for code blocks"
    echo "  • Automatic table of contents with page numbers"
    echo "  • Headers and footers with company branding"
    echo "  • Responsive tables and proper page breaks"
    echo "  • Color-coded status indicators"
    echo "  • Print-optimized layout"
else
    echo ""
    echo "❌ PDF generation failed!"
    echo "Please check the input file and try again."
    exit 1
fi
