#!/bin/bash

# Script to install Homebrew cask applications from a text file
# Usage: ./install-brew-apps.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APPS_FILE="setup-data/brew-apps.txt"
LOG_FILE="logs/brew-apps-install.log"

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
    echo "Homebrew Cask Applications Installation Log - $(date)" > "$LOG_FILE"
    echo "====================================================" >> "$LOG_FILE"
}

# Function to check if cask app is already installed
is_cask_installed() {
    local app="$1"
    brew list --cask | grep -q "^${app}$" 2>/dev/null
}

# Function to install a single cask application
install_cask_app() {
    local app="$1"
    
    # Check if already installed
    if is_cask_installed "$app"; then
        print_warning "Already installed: $app"
        echo "ALREADY_INSTALLED: $app" >> "$LOG_FILE"
        return 0
    fi
    
    print_status "Installing cask application: $app"
    
    if brew install --cask "$app" 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Successfully installed: $app"
        echo "SUCCESS: $app" >> "$LOG_FILE"
        return 0
    else
        print_error "Failed to install: $app"
        echo "FAILED: $app" >> "$LOG_FILE"
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

# Function to check if Xcode Command Line Tools are installed
check_xcode_tools() {
    print_status "Checking Xcode Command Line Tools..."
    
    if xcode-select -p &>/dev/null; then
        print_success "Xcode Command Line Tools are installed"
        echo "SUCCESS: Xcode Command Line Tools found" >> "$LOG_FILE"
    else
        print_warning "Xcode Command Line Tools not found"
        print_status "Some applications may require Xcode Command Line Tools"
        print_status "Install with: xcode-select --install"
        echo "WARNING: Xcode Command Line Tools not found" >> "$LOG_FILE"
    fi
}

# Function to show app preview
show_apps_preview() {
    if [[ -f "$APPS_FILE" ]]; then
        local app_count=$(wc -l < "$APPS_FILE" | xargs)
        print_status "Applications to install ($app_count total):"
        echo "========================================"
        head -10 "$APPS_FILE" | while IFS= read -r line; do
            if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
                echo "  • $line"
            fi
        done
        
        if [[ $app_count -gt 10 ]]; then
            echo "  ... and $((app_count - 10)) more"
        fi
        echo "========================================"
        echo ""
    fi
}

# Main function
main() {
    print_status "Starting Homebrew cask applications installation..."
    
    # Setup logging
    setup_logging
    
    # Check if brew command exists
    check_brew_command
    
    # Check if apps file exists
    if [[ ! -f "$APPS_FILE" ]]; then
        print_error "Applications file not found: $APPS_FILE"
        print_status "Please create the file with one application name per line."
        exit 1
    fi
    
    # Check if file is empty
    if [[ ! -s "$APPS_FILE" ]]; then
        print_warning "Applications file is empty: $APPS_FILE"
        exit 0
    fi
    
    # Show preview of apps to install
    show_apps_preview
    
    # Check Xcode Command Line Tools
    check_xcode_tools
    
    # Update Homebrew first
    update_brew
    
    print_status "Reading applications from: $APPS_FILE"
    
    # Initialize counters
    local total_count=0
    local success_count=0
    local already_installed_count=0
    local failed_count=0
    
    # Read file line by line and install applications
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments (lines starting with #)
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Trim whitespace
        app=$(echo "$line" | xargs)
        
        if [[ -n "$app" ]]; then
            ((total_count++))
            
            if is_cask_installed "$app"; then
                print_warning "Already installed: $app"
                echo "ALREADY_INSTALLED: $app" >> "$LOG_FILE"
                ((already_installed_count++))
            elif install_cask_app "$app"; then
                ((success_count++))
            else
                ((failed_count++))
            fi
            
            # Add a small delay between installations
            sleep 2
        fi
    done < "$APPS_FILE"
    
    # Print summary
    echo ""
    print_status "Installation Summary:"
    print_status "===================="
    print_status "Total applications processed: $total_count"
    print_success "Successfully installed: $success_count"
    print_warning "Already installed: $already_installed_count"
    
    if [[ $failed_count -gt 0 ]]; then
        print_error "Failed installations: $failed_count"
        print_status "Check the log file for details: $LOG_FILE"
        exit 1
    else
        print_success "All applications processed successfully!"
        print_status "Log file: $LOG_FILE"
        print_status ""
        print_status "Note: Some applications may require additional setup"
        print_status "Check Applications folder or Launchpad for installed apps"
    fi
}

# Run main function
main "$@" 