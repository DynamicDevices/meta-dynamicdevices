#!/bin/bash
# Pre-commit hook for Yocto layer validation
# Validates layer structure and basic compliance before commits

set -e

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if file is staged for commit
is_staged() {
    git diff --cached --name-only | grep -q "^$1" 2>/dev/null
}

# Function to validate layer.conf files
validate_layer_conf() {
    local layer_conf="$1"
    local layer_name="$2"
    
    if [ ! -f "$layer_conf" ]; then
        log_error "layer.conf not found: $layer_conf"
        return 1
    fi
    
    log_info "Validating $layer_name layer.conf..."
    
    # Check required variables
    local required_vars=("BBFILE_COLLECTIONS" "BBFILE_PATTERN" "BBFILE_PRIORITY" "LAYERVERSION" "LAYERDEPENDS" "LAYERSERIES_COMPAT")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if ! grep -q "^$var" "$layer_conf"; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_error "Missing required variables in $layer_name layer.conf:"
        for var in "${missing_vars[@]}"; do
            log_error "  - $var"
        done
        return 1
    fi
    
    # Check for common issues
    if grep -q "BBFILE_PRIORITY.*=" "$layer_conf"; then
        local priority=$(grep "BBFILE_PRIORITY" "$layer_conf" | cut -d'=' -f2 | tr -d ' "')
        if [[ ! "$priority" =~ ^[0-9]+$ ]]; then
            log_error "Invalid BBFILE_PRIORITY in $layer_name: $priority"
            return 1
        fi
    fi
    
    log_success "$layer_name layer.conf validation passed"
    return 0
}

# Function to validate recipe files
validate_recipes() {
    local layer_path="$1"
    local layer_name="$2"
    
    log_info "Validating recipes in $layer_name..."
    
    local recipe_errors=0
    
    # Find all .bb and .bbappend files
    while IFS= read -r -d '' recipe_file; do
        # Skip if file is not staged
        local rel_path="${recipe_file#$PROJECT_ROOT/}"
        if ! is_staged "$rel_path"; then
            continue
        fi
        
        # Basic recipe validation
        if [ ! -s "$recipe_file" ]; then
            log_warning "Empty recipe file: $recipe_file"
            continue
        fi
        
        # Check for common recipe issues
        if grep -q "^DESCRIPTION.*=" "$recipe_file"; then
            if ! grep -q "^LICENSE.*=" "$recipe_file"; then
                log_error "Recipe missing LICENSE: $recipe_file"
                ((recipe_errors++))
            fi
        fi
        
        # Check for proper variable syntax
        if grep -q ".*=.*\${.*}" "$recipe_file"; then
            # Check for unescaped variables in strings
            if grep -q '".*\${.*}"' "$recipe_file"; then
                local unescaped=$(grep -n '".*\${.*}"' "$recipe_file" | head -3)
                if [ -n "$unescaped" ]; then
                    log_warning "Potential unescaped variables in $recipe_file:"
                    echo "$unescaped"
                fi
            fi
        fi
        
    done < <(find "$layer_path" -name "*.bb" -o -name "*.bbappend" -print0 2>/dev/null)
    
    if [ $recipe_errors -gt 0 ]; then
        log_error "$recipe_errors recipe validation errors in $layer_name"
        return 1
    fi
    
    log_success "Recipe validation passed for $layer_name"
    return 0
}

# Function to validate required files
validate_required_files() {
    local layer_path="$1"
    local layer_name="$2"
    
    log_info "Validating required files for $layer_name..."
    
    local required_files=("README.md" "SECURITY.md" "LICENSE" "conf/layer.conf")
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$layer_path/$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        log_error "Missing required files in $layer_name:"
        for file in "${missing_files[@]}"; do
            log_error "  - $file"
        done
        return 1
    fi
    
    # Validate README.md content
    if [ -f "$layer_path/README.md" ]; then
        if ! grep -q "maintainer\|contact\|email" "$layer_path/README.md" -i; then
            log_warning "README.md should include maintainer contact information"
        fi
        
        if ! grep -q "license" "$layer_path/README.md" -i; then
            log_warning "README.md should include license information"
        fi
    fi
    
    # Validate SECURITY.md content
    if [ -f "$layer_path/SECURITY.md" ]; then
        if ! grep -q "security@dynamicdevices.co.uk" "$layer_path/SECURITY.md"; then
            log_warning "SECURITY.md should include security contact email"
        fi
    fi
    
    log_success "Required files validation passed for $layer_name"
    return 0
}

# Function to check for layer separation compliance
validate_layer_separation() {
    local layer_path="$1"
    local layer_name="$2"
    local layer_type="$3"
    
    log_info "Validating layer separation for $layer_name ($layer_type)..."
    
    case $layer_type in
        "bsp")
            # BSP layer should not contain distro configs
            if [ -d "$layer_path/conf/distro" ]; then
                log_error "BSP layer contains distro configurations: $layer_path/conf/distro"
                return 1
            fi
            
            # BSP layer should have machine configs
            if [ ! -d "$layer_path/conf/machine" ]; then
                log_warning "BSP layer missing machine configurations"
            fi
            ;;
        "distro")
            # Distro layer should not contain machine configs
            if [ -d "$layer_path/conf/machine" ]; then
                log_error "Distro layer contains machine configurations: $layer_path/conf/machine"
                return 1
            fi
            
            # Distro layer should have distro configs
            if [ ! -d "$layer_path/conf/distro" ]; then
                log_warning "Distro layer missing distro configurations"
            fi
            
            # Distro layer should not contain BSP recipes
            if [ -d "$layer_path/recipes-bsp" ]; then
                log_error "Distro layer contains BSP recipes: $layer_path/recipes-bsp"
                return 1
            fi
            ;;
    esac
    
    log_success "Layer separation validation passed for $layer_name"
    return 0
}

# Function to validate a single layer
validate_layer() {
    local layer_path="$1"
    local layer_name="$2"
    local layer_type="$3"
    
    if [ ! -d "$layer_path" ]; then
        log_error "Layer directory not found: $layer_path"
        return 1
    fi
    
    log_info "=== Validating $layer_name ($layer_type) ==="
    
    local validation_failed=false
    
    # Validate required files
    if ! validate_required_files "$layer_path" "$layer_name"; then
        validation_failed=true
    fi
    
    # Validate layer.conf
    if ! validate_layer_conf "$layer_path/conf/layer.conf" "$layer_name"; then
        validation_failed=true
    fi
    
    # Validate recipes
    if ! validate_recipes "$layer_path" "$layer_name"; then
        validation_failed=true
    fi
    
    # Validate layer separation
    if ! validate_layer_separation "$layer_path" "$layer_name" "$layer_type"; then
        validation_failed=true
    fi
    
    if [ "$validation_failed" = true ]; then
        log_error "$layer_name validation failed"
        return 1
    else
        log_success "$layer_name validation passed"
        return 0
    fi
}

# Main execution
main() {
    log_info "Running Yocto layer pre-commit validation..."
    
    local validation_failed=false
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository"
        exit 1
    fi
    
    # Check if there are staged changes
    if ! git diff --cached --quiet; then
        log_info "Staged changes detected, running validation..."
    else
        log_info "No staged changes, skipping validation"
        exit 0
    fi
    
    # Validate BSP layer if it exists and has changes
    if [ -d "$PROJECT_ROOT/meta-dynamicdevices-bsp" ]; then
        if git diff --cached --name-only | grep -q "^meta-dynamicdevices-bsp/"; then
            if ! validate_layer "$PROJECT_ROOT/meta-dynamicdevices-bsp" "meta-dynamicdevices-bsp" "bsp"; then
                validation_failed=true
            fi
        fi
    fi
    
    # Validate distro layer if it exists and has changes
    if [ -d "$PROJECT_ROOT/meta-dynamicdevices-distro" ]; then
        if git diff --cached --name-only | grep -q "^meta-dynamicdevices-distro/"; then
            if ! validate_layer "$PROJECT_ROOT/meta-dynamicdevices-distro" "meta-dynamicdevices-distro" "distro"; then
                validation_failed=true
            fi
        fi
    fi
    
    # Check main layer changes
    if git diff --cached --name-only | grep -q "^conf/\|^recipes-"; then
        log_info "Main layer changes detected, validating..."
        
        # Validate main layer.conf if changed
        if git diff --cached --name-only | grep -q "^conf/layer.conf"; then
            if ! validate_layer_conf "$PROJECT_ROOT/conf/layer.conf" "meta-dynamicdevices"; then
                validation_failed=true
            fi
        fi
        
        # Validate main layer recipes if changed
        if git diff --cached --name-only | grep -q "^recipes-"; then
            if ! validate_recipes "$PROJECT_ROOT" "meta-dynamicdevices"; then
                validation_failed=true
            fi
        fi
    fi
    
    # Final result
    if [ "$validation_failed" = true ]; then
        log_error "Pre-commit validation failed!"
        log_info "Fix the issues above and try committing again"
        exit 1
    else
        log_success "Pre-commit validation passed!"
        exit 0
    fi
}

# Run main function
main "$@"
