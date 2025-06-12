#!/bin/bash

# Script to install Cursor extensions from a text file
# Usage: ./install-cursor-ext.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
EXTENSIONS_FILE="setup-data/cursor-extensions.txt"
LOG_FILE="logs/cursor-extension-install.log"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if cursor command exists
check_cursor_command() {
    if ! command -v cursor &> /dev/null; then
        print_error "Cursor command not found. Please make sure Cursor is installed and added to PATH."
        exit 1
    fi
}

# Function to create log file
setup_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "Cursor Extension Installation Log - $(date)" > "$LOG_FILE"
    echo "==========================================" >> "$LOG_FILE"
}

# Function to install a single extension
install_extension() {
    local extension_id="$1"
    
    print_status "Installing extension: $extension_id"
    
    if cursor --install-extension "$extension_id" 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Successfully installed: $extension_id"
        echo "SUCCESS: $extension_id" >> "$LOG_FILE"
        return 0
    else
        print_error "Failed to install: $extension_id"
        echo "FAILED: $extension_id" >> "$LOG_FILE"
        return 1
    fi
}

# Main function
main() {
    print_status "Starting Cursor extension installation..."
    
    # Check if cursor command exists
    check_cursor_command
    
    # Setup logging
    setup_logging
    
    # Check if extensions file exists
    if [[ ! -f "$EXTENSIONS_FILE" ]]; then
        print_error "Extensions file not found: $EXTENSIONS_FILE"
        print_status "Please create the file with one extension ID per line."
        exit 1
    fi
    
    # Check if file is empty
    if [[ ! -s "$EXTENSIONS_FILE" ]]; then
        print_warning "Extensions file is empty: $EXTENSIONS_FILE"
        exit 0
    fi
    
    print_status "Reading extensions from: $EXTENSIONS_FILE"
    
    # Initialize counters
    local total_count=0
    local success_count=0
    local failed_count=0
    
    # Read file line by line and install extensions
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments (lines starting with #)
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Trim whitespace
        extension_id=$(echo "$line" | xargs)
        
        if [[ -n "$extension_id" ]]; then
            ((total_count++))
            
            if install_extension "$extension_id"; then
                ((success_count++))
            else
                ((failed_count++))
            fi
            
            # Add a small delay between installations
            sleep 1
        fi
    done < "$EXTENSIONS_FILE"
    
    # Print summary
    echo ""
    print_status "Installation Summary:"
    print_status "===================="
    print_status "Total extensions processed: $total_count"
    print_success "Successfully installed: $success_count"
    
    if [[ $failed_count -gt 0 ]]; then
        print_error "Failed installations: $failed_count"
        print_status "Check the log file for details: $LOG_FILE"
        exit 1
    else
        print_success "All extensions installed successfully!"
        print_status "Log file: $LOG_FILE"
    fi
}

# Run main function
main "$@"
