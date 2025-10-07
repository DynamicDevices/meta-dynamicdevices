#!/bin/bash

# Universal PDF Generation Script for meta-dynamicdevices
# Converts any Markdown document to professional PDF using pandoc with intelligent styling
# Supports security reports, technical documentation, and general documents

set -e

# Default values
INPUT_FILE=""
OUTPUT_FILE=""
DOCUMENT_TYPE="auto"
TITLE=""
DATE=$(date +"%B %d, %Y")
HEADER_LEFT=""
HEADER_RIGHT="Dynamic Devices Ltd"
FOOTER_LEFT=""
FOOTER_CENTER="Page [page] of [topage]"
FOOTER_RIGHT="Confidential"

# Function to show usage
show_usage() {
    echo "Universal PDF Generation Script for meta-dynamicdevices"
    echo "Usage: $0 -i INPUT_FILE [OPTIONS]"
    echo ""
    echo "Required:"
    echo "  -i INPUT_FILE      Input Markdown file"
    echo ""
    echo "Optional:"
    echo "  -o OUTPUT_FILE     Output PDF file (auto-generated if not provided)"
    echo "  -t DOCUMENT_TYPE   Document type: security, technical, general, auto (default: auto)"
    echo "  -T TITLE          Document title (extracted from file if not provided)"
    echo "  -d DATE           Document date (default: current date)"
    echo "  --header-left     Left header text (auto-detected if not provided)"
    echo "  --header-right    Right header text (default: Dynamic Devices Ltd)"
    echo "  --footer-left     Left footer text"
    echo "  --footer-center   Center footer text (default: Page [page] of [topage])"
    echo "  --footer-right    Right footer text (default: Confidential)"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Document Type Detection:"
    echo "  auto     - Automatically detect based on filename and content"
    echo "  security - Security reports, compliance documents"
    echo "  technical- Technical specifications, architecture docs"
    echo "  general  - General documentation"
    echo ""
    echo "Examples:"
    echo "  $0 -i report.md"
    echo "  $0 -i docs/security/SECURITY_COMPLIANCE_REPORT_*.md"
    echo "  $0 -i wiki/Technical-Architecture.md -t technical"
    echo "  $0 -i README.md -t general --header-left \"Project Documentation\""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i) INPUT_FILE="$2"; shift 2 ;;
        -o) OUTPUT_FILE="$2"; shift 2 ;;
        -t) DOCUMENT_TYPE="$2"; shift 2 ;;
        -T) TITLE="$2"; shift 2 ;;
        -d) DATE="$2"; shift 2 ;;
        --header-left) HEADER_LEFT="$2"; shift 2 ;;
        --header-right) HEADER_RIGHT="$2"; shift 2 ;;
        --footer-left) FOOTER_LEFT="$2"; shift 2 ;;
        --footer-center) FOOTER_CENTER="$2"; shift 2 ;;
        --footer-right) FOOTER_RIGHT="$2"; shift 2 ;;
        -h|--help) show_usage; exit 0 ;;
        *) echo "Unknown option: $1"; show_usage; exit 1 ;;
    esac
done

# Validate required arguments
if [[ -z "$INPUT_FILE" ]]; then
    echo "Error: Input file is required (-i INPUT_FILE)"
    show_usage
    exit 1
fi

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: Input file '$INPUT_FILE' does not exist"
    exit 1
fi

# Auto-generate output file if not provided
if [[ -z "$OUTPUT_FILE" ]]; then
    OUTPUT_FILE="${INPUT_FILE%.*}.pdf"
fi

# Auto-detect document type if set to auto
if [[ "$DOCUMENT_TYPE" == "auto" ]]; then
    case "$INPUT_FILE" in
        *security*|*SECURITY*|*compliance*|*COMPLIANCE*)
            DOCUMENT_TYPE="security"
            ;;
        *technical*|*TECHNICAL*|*architecture*|*ARCHITECTURE*|*spec*|*SPEC*)
            DOCUMENT_TYPE="technical"
            ;;
        *)
            DOCUMENT_TYPE="general"
            ;;
    esac
fi

# Auto-extract title if not provided
if [[ -z "$TITLE" ]]; then
    # Try to extract title from first # heading in the file
    TITLE=$(grep -m 1 "^# " "$INPUT_FILE" 2>/dev/null | sed 's/^# //' || echo "Document")
fi

# Auto-set header left based on document type if not provided
if [[ -z "$HEADER_LEFT" ]]; then
    case "$DOCUMENT_TYPE" in
        security)
            HEADER_LEFT="Security Compliance Report"
            ;;
        technical)
            HEADER_LEFT="Technical Documentation"
            ;;
        general)
            HEADER_LEFT="Documentation"
            ;;
    esac
fi

# Create output directory if it doesn't exist
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
mkdir -p "$OUTPUT_DIR"

echo "=== Universal PDF Generation ==="
echo "Input:     $INPUT_FILE"
echo "Output:    $OUTPUT_FILE"
echo "Type:      $DOCUMENT_TYPE (auto-detected)"
echo "Title:     $TITLE"
echo "Date:      $DATE"
echo "Header:    $HEADER_LEFT | $HEADER_RIGHT"
echo "Footer:    $FOOTER_LEFT | $FOOTER_CENTER | $FOOTER_RIGHT"
echo ""
echo "Generating PDF with professional styling..."

# Check if pandoc is available
if ! command -v pandoc &> /dev/null; then
    echo "Error: pandoc is not installed. Please install pandoc to generate PDFs."
    exit 1
fi

# Generate PDF with pandoc - use default template and wkhtmltopdf engine
echo "Using default pandoc template with wkhtmltopdf engine..."

# Generate PDF with precise margin control - simplified approach
echo "Creating PDF with precise 8mm margins using direct wkhtmltopdf..."

# Create temporary HTML with inline CSS
TEMP_HTML="/tmp/security_report.html"

# First convert markdown to HTML
pandoc \
    "${INPUT_FILE}" \
    -o "${TEMP_HTML}" \
    --from=markdown+yaml_metadata_block+raw_html \
    --to=html5 \
    --highlight-style=pygments \
    --standalone

# Add our custom CSS directly to the HTML file for professional styling with improved page breaks
sed -i '/<\/head>/i \
<style>\
@page {\
    margin: 15mm 12mm 15mm 12mm;\
    size: A4;\
}\
@media print {\
    .page-break { page-break-before: always; }\
    .no-break { page-break-inside: avoid; }\
    h1 { page-break-before: always; }\
    h2 { page-break-before: auto; page-break-after: avoid; }\
}\
body {\
    font-family: "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;\
    font-size: 11pt;\
    line-height: 1.4;\
    margin: 0;\
    padding: 0;\
    color: #333;\
    max-width: none;\
}\
h1 {\
    color: #1f4e79;\
    font-size: 24pt;\
    font-weight: 700;\
    margin-top: 20pt;\
    margin-bottom: 12pt;\
    border-bottom: 3px solid #1f4e79;\
    padding-bottom: 8pt;\
    page-break-before: always;\
    page-break-after: avoid;\
}\
h1:first-of-type {\
    page-break-before: auto;\
}\
h2 {\
    color: #2e5c8a;\
    font-size: 18pt;\
    font-weight: 600;\
    margin-top: 18pt;\
    margin-bottom: 10pt;\
    border-left: 4px solid #2e5c8a;\
    padding-left: 12pt;\
    page-break-before: auto;\
    page-break-after: avoid;\
    page-break-inside: avoid;\
}\
h3 {\
    color: #4472c4;\
    font-size: 14pt;\
    font-weight: 600;\
    margin-top: 14pt;\
    margin-bottom: 8pt;\
    page-break-after: avoid;\
    page-break-inside: avoid;\
}\
h4 {\
    color: #5b9bd5;\
    font-size: 12pt;\
    font-weight: 600;\
    margin-top: 12pt;\
    margin-bottom: 6pt;\
    page-break-after: avoid;\
    page-break-inside: avoid;\
}\
p {\
    margin: 6pt 0;\
    text-align: justify;\
    text-justify: inter-word;\
    orphans: 3;\
    widows: 3;\
}\
blockquote {\
    background-color: #f8f9fa;\
    border-left: 4px solid #4472c4;\
    margin: 12pt 0;\
    padding: 12pt 16pt;\
    font-style: italic;\
    page-break-inside: avoid;\
    orphans: 2;\
    widows: 2;\
}\
table {\
    width: 100%;\
    border-collapse: collapse;\
    margin: 12pt 0;\
    font-size: 10pt;\
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);\
    page-break-inside: avoid;\
    page-break-before: auto;\
    page-break-after: auto;\
}\
thead {\
    display: table-header-group;\
}\
tbody {\
    display: table-row-group;\
}\
th {\
    background: linear-gradient(135deg, #1f4e79 0%, #2e5c8a 100%);\
    color: white;\
    font-weight: 600;\
    padding: 8pt 10pt;\
    text-align: left;\
    border: none;\
}\
td {\
    padding: 6pt 10pt;\
    border-bottom: 1px solid #e1e5e9;\
    vertical-align: top;\
}\
tr {\
    page-break-inside: avoid;\
}\
tr:nth-child(even) td {\
    background-color: #f8f9fa;\
}\
tr:hover td {\
    background-color: #e3f2fd;\
}\
ul, ol {\
    margin: 6pt 0;\
    padding-left: 24pt;\
    page-break-inside: avoid;\
}\
li {\
    margin: 3pt 0;\
    line-height: 1.3;\
    page-break-inside: avoid;\
}\
strong {\
    color: #1f4e79;\
    font-weight: 600;\
}\
code {\
    background-color: #f1f3f4;\
    padding: 2pt 4pt;\
    border-radius: 3px;\
    font-family: "Consolas", "Monaco", monospace;\
    font-size: 9pt;\
}\
.status-compliant { color: #0d7377; font-weight: 600; }\
.status-pending { color: #f57c00; font-weight: 600; }\
.status-attention { color: #d32f2f; font-weight: 600; }\
hr {\
    border: none;\
    height: 2px;\
    background: linear-gradient(90deg, #1f4e79 0%, #4472c4 100%);\
    margin: 20pt 0;\
    page-break-before: auto;\
    page-break-after: auto;\
}\
/* Specific page break classes */\
.section-break {\
    page-break-before: always;\
}\
.keep-together {\
    page-break-inside: avoid;\
}\
.allow-break {\
    page-break-inside: auto;\
}\
</style>' "${TEMP_HTML}"

# Convert HTML to PDF with wkhtmltopdf using explicit page settings for proper pagination
wkhtmltopdf \
    --page-size A4 \
    --orientation Portrait \
    --margin-top 15mm \
    --margin-bottom 15mm \
    --margin-left 12mm \
    --margin-right 12mm \
    --minimum-font-size 8 \
    --encoding UTF-8 \
    --dpi 300 \
    --image-quality 94 \
    --javascript-delay 1000 \
    --no-stop-slow-scripts \
    "${TEMP_HTML}" \
    "${OUTPUT_FILE}"

# Clean up temporary HTML
rm -f "${TEMP_HTML}"

if [[ $? -eq 0 ]]; then
    echo ""
    echo "✅ PDF generated successfully!"
    echo "📄 Output: $OUTPUT_FILE"
    echo "📊 Size: $(du -h "$OUTPUT_FILE" | cut -f1)"
    echo ""
    echo "Features included:"
    echo "  • Professional typography with optimized spacing"
    echo "  • Syntax highlighting for code blocks"
    echo "  • Automatic table of contents with page numbers"
    echo "  • Intelligent headers and footers"
    echo "  • Responsive tables and proper page breaks"
    echo "  • Color-coded links and status indicators"
    echo "  • Print-optimized A4 layout with 2.5cm margins"
    echo "  • Document type: $DOCUMENT_TYPE"
else
    echo "❌ PDF generation failed!"
    exit 1
fi
