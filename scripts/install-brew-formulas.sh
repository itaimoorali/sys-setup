#!/bin/bash

# Script to install Homebrew formulas from a text file
# Usage: ./install-brew-formulas.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FORMULAS_FILE="setup-data/brew-formulas.txt"
LOG_FILE="logs/brew-formulas-install.log"

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

# Function to check if brew command exists
check_brew_command() {
    if ! command -v brew &> /dev/null; then
        print_error "Homebrew not found. Please install Homebrew first."
        print_status "Visit: https://brew.sh"
        exit 1
    fi
}

# Function to create log file
setup_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "Homebrew Formulas Installation Log - $(date)" > "$LOG_FILE"
    echo "=============================================" >> "$LOG_FILE"
}

# Function to check if formula is already installed
is_formula_installed() {
    local formula="$1"
    brew list --formula | grep -q "^${formula}$" 2>/dev/null
}

# Function to install a single formula
install_formula() {
    local formula="$1"
    
    # Check if already installed
    if is_formula_installed "$formula"; then
        print_warning "Already installed: $formula"
        echo "ALREADY_INSTALLED: $formula" >> "$LOG_FILE"
        return 0
    fi
    
    print_status "Installing formula: $formula"
    
    if brew install "$formula" 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Successfully installed: $formula"
        echo "SUCCESS: $formula" >> "$LOG_FILE"
        return 0
    else
        print_error "Failed to install: $formula"
        echo "FAILED: $formula" >> "$LOG_FILE"
        return 1
    fi
}

# Function to update Homebrew
update_brew() {
    print_status "Updating Homebrew..."
    if brew update 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Homebrew updated successfully"
        echo "SUCCESS: brew update" >> "$LOG_FILE"
    else
        print_warning "Failed to update Homebrew, continuing anyway..."
        echo "WARNING: brew update failed" >> "$LOG_FILE"
    fi
}

# Main function
main() {
    print_status "Starting Homebrew formulas installation..."
    
    # Check if brew command exists
    check_brew_command
    
    # Setup logging
    setup_logging
    
    # Check if formulas file exists
    if [[ ! -f "$FORMULAS_FILE" ]]; then
        print_error "Formulas file not found: $FORMULAS_FILE"
        print_status "Please create the file with one formula name per line."
        exit 1
    fi
    
    # Check if file is empty
    if [[ ! -s "$FORMULAS_FILE" ]]; then
        print_warning "Formulas file is empty: $FORMULAS_FILE"
        exit 0
    fi
    
    # Update Homebrew first
    update_brew
    
    print_status "Reading formulas from: $FORMULAS_FILE"
    
    # Initialize counters
    local total_count=0
    local success_count=0
    local already_installed_count=0
    local failed_count=0
    
    # Read file line by line and install formulas
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments (lines starting with #)
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Trim whitespace
        formula=$(echo "$line" | xargs)
        
        if [[ -n "$formula" ]]; then
            ((total_count++))
            
            if is_formula_installed "$formula"; then
                print_warning "Already installed: $formula"
                echo "ALREADY_INSTALLED: $formula" >> "$LOG_FILE"
                ((already_installed_count++))
            elif install_formula "$formula"; then
                ((success_count++))
            else
                ((failed_count++))
            fi
            
            # Add a small delay between installations
            sleep 1
        fi
    done < "$FORMULAS_FILE"
    
    # Print summary
    echo ""
    print_status "Installation Summary:"
    print_status "===================="
    print_status "Total formulas processed: $total_count"
    print_success "Successfully installed: $success_count"
    print_warning "Already installed: $already_installed_count"
    
    if [[ $failed_count -gt 0 ]]; then
        print_error "Failed installations: $failed_count"
        print_status "Check the log file for details: $LOG_FILE"
        exit 1
    else
        print_success "All formulas processed successfully!"
        print_status "Log file: $LOG_FILE"
    fi
}

# Run main function
main "$@" 