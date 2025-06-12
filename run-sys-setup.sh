#!/bin/bash

# Main System Setup Script
# This script runs all the individual setup scripts in the correct order
# Usage: ./run-sys-setup.sh [--skip-brew] [--skip-cursor] [--skip-settings]

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPTS_DIR="scripts"
LOGS_DIR="logs"
SETUP_DATA_DIR="setup-data"
MAIN_LOG_FILE="$LOGS_DIR/system-setup.log"

# Script paths
BREW_SCRIPT="$SCRIPTS_DIR/install-brew-formulas.sh"
BREW_APPS_SCRIPT="$SCRIPTS_DIR/install-brew-apps.sh"
CURSOR_EXT_SCRIPT="$SCRIPTS_DIR/install-cursor-ext.sh"
CURSOR_SETTINGS_SCRIPT="$SCRIPTS_DIR/clone-cursor-settings.sh"
DOT_FILES_SCRIPT="$SCRIPTS_DIR/install-dot-files.sh"

# Flags for skipping components
SKIP_BREW=false
SKIP_BREW_APPS=false
SKIP_CURSOR=false
SKIP_SETTINGS=false
SKIP_DOT_FILES=false
INTERACTIVE_MODE=true

# Function to print colored output
print_header() {
    echo -e "${MAGENTA}================================${NC}"
    echo -e "${MAGENTA}$1${NC}"
    echo -e "${MAGENTA}================================${NC}"
}

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

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --skip-brew        Skip Homebrew formulas installation"
    echo "  --skip-brew-apps   Skip Homebrew cask applications installation"
    echo "  --skip-cursor      Skip Cursor extensions installation"
    echo "  --skip-settings    Skip Cursor settings cloning"
    echo "  --skip-dot-files   Skip dot-files installation"
    echo "  --non-interactive  Run without interactive prompts (uses skip flags)"
    echo "  --help, -h         Show this help message"
    echo ""
    echo "Interactive Mode (default):"
    echo "  The script will ask you to select which components to install"
    echo ""
    echo "Available components:"
    echo "  1. Install Homebrew formulas (from setup-data/brew-formulas.txt)"
    echo "  2. Install Homebrew cask applications (from setup-data/brew-apps.txt)"
    echo "  3. Install Cursor extensions (from setup-data/cursor-extensions.txt)"
    echo "  4. Clone Cursor settings (from settings/cursor-settings.json)"
    echo "  5. Install dot-files (from git@github.com:itaimoorali/dot-files.git)"
}

# Function to parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-brew)
                SKIP_BREW=true
                INTERACTIVE_MODE=false
                shift
                ;;
            --skip-brew-apps)
                SKIP_BREW_APPS=true
                INTERACTIVE_MODE=false
                shift
                ;;
            --skip-cursor)
                SKIP_CURSOR=true
                INTERACTIVE_MODE=false
                shift
                ;;
            --skip-settings)
                SKIP_SETTINGS=true
                INTERACTIVE_MODE=false
                shift
                ;;
            --skip-dot-files)
                SKIP_DOT_FILES=true
                INTERACTIVE_MODE=false
                shift
                ;;
            --non-interactive)
                INTERACTIVE_MODE=false
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Function to setup logging
setup_logging() {
    mkdir -p "$LOGS_DIR"
    mkdir -p "$SETUP_DATA_DIR"
    echo "System Setup Log - $(date)" > "$MAIN_LOG_FILE"
    echo "==============================" >> "$MAIN_LOG_FILE"
    print_status "Main log file: $MAIN_LOG_FILE"
}

# Function to check if script exists and is executable
check_script() {
    local script_path="$1"
    local script_name="$2"
    
    if [[ ! -f "$script_path" ]]; then
        print_error "Script not found: $script_path"
        return 1
    fi
    
    if [[ ! -x "$script_path" ]]; then
        print_warning "Script not executable: $script_path"
        print_status "Making script executable..."
        chmod +x "$script_path"
    fi
    
    print_success "$script_name script is ready"
    return 0
}

# Function to run a script with error handling
run_script() {
    local script_path="$1"
    local script_name="$2"
    local step_number="$3"
    
    print_step "Step $step_number: Running $script_name"
    echo "Step $step_number: Running $script_name - $(date)" >> "$MAIN_LOG_FILE"
    
    if ./"$script_path" 2>&1 | tee -a "$MAIN_LOG_FILE"; then
        print_success "$script_name completed successfully"
        echo "SUCCESS: $script_name completed - $(date)" >> "$MAIN_LOG_FILE"
        return 0
    else
        print_error "$script_name failed"
        echo "FAILED: $script_name failed - $(date)" >> "$MAIN_LOG_FILE"
        return 1
    fi
}

# Function to show system info
show_system_info() {
    print_header "System Information"
    echo "OS: $(uname -s) $(uname -r)"
    echo "User: $(whoami)"
    echo "Home: $HOME"
    echo "Working Directory: $(pwd)"
    echo "Date: $(date)"
    echo ""
}

# Function to check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local all_good=true
    
    # Check scripts
    if ! check_script "$BREW_SCRIPT" "Homebrew formulas installer"; then
        all_good=false
    fi
    
    if ! check_script "$CURSOR_EXT_SCRIPT" "Cursor extensions installer"; then
        all_good=false
    fi
    
    if ! check_script "$CURSOR_SETTINGS_SCRIPT" "Cursor settings cloner"; then
        all_good=false
    fi
    
    if ! check_script "$BREW_APPS_SCRIPT" "Homebrew cask applications installer"; then
        all_good=false
    fi
    
    if ! check_script "$DOT_FILES_SCRIPT" "Dot-files installer"; then
        all_good=false
    fi
    
    if [[ "$all_good" == false ]]; then
        print_error "Prerequisites check failed"
        exit 1
    fi
    
    print_success "All prerequisites checked"
    echo ""
}

# Function to show interactive menu
show_interactive_menu() {
    print_header "System Setup - Component Selection"
    
    echo "Welcome to the System Setup Script!"
    echo "Please select which components you want to install:"
    echo ""
    echo "1. Install Homebrew formulas (from setup-data/brew-formulas.txt)"
    echo "2. Install Homebrew cask applications (from setup-data/brew-apps.txt)"
    echo "3. Install Cursor extensions (from setup-data/cursor-extensions.txt)"
    echo "4. Clone Cursor settings (from settings/cursor-settings.json)"
    echo "5. Install dot-files (from git@github.com:itaimoorali/dot-files.git)"
    echo "6. Install all components"
    echo "7. Exit without installing anything"
    echo ""
    
    while true; do
        echo -n -e "${BLUE}[SELECT]${NC} Enter your choice(s) [1-7, or multiple like '1,2,3']: "
        read -r choice
        
        if [[ "$choice" == "7" ]]; then
            print_status "Exiting without installing anything. Goodbye!"
            exit 0
        elif [[ "$choice" == "6" ]]; then
            SKIP_BREW=false
            SKIP_BREW_APPS=false
            SKIP_CURSOR=false
            SKIP_SETTINGS=false
            SKIP_DOT_FILES=false
            print_success "Selected: All components will be installed"
            echo ""
            print_status "The script will now install:"
            echo "  ✓ Homebrew formulas"
            echo "  ✓ Homebrew cask applications"
            echo "  ✓ Cursor extensions"
            echo "  ✓ Cursor settings"
            echo "  ✓ Dot-files"
            break
        else
            # Reset all to true (skip all)
            SKIP_BREW=true
            SKIP_BREW_APPS=true
            SKIP_CURSOR=true
            SKIP_SETTINGS=true
            SKIP_DOT_FILES=true
            
            # Parse comma-separated choices
            IFS=',' read -ra CHOICES <<< "$choice"
            local valid_choice=false
            local selected_components=()
            
            for c in "${CHOICES[@]}"; do
                c=$(echo "$c" | xargs)  # Trim whitespace
                case "$c" in
                    1)
                        SKIP_BREW=false
                        selected_components+=("Homebrew formulas")
                        valid_choice=true
                        ;;
                    2)
                        SKIP_BREW_APPS=false
                        selected_components+=("Homebrew cask applications")
                        valid_choice=true
                        ;;
                    3)
                        SKIP_CURSOR=false
                        selected_components+=("Cursor extensions")
                        valid_choice=true
                        ;;
                    4)
                        SKIP_SETTINGS=false
                        selected_components+=("Cursor settings")
                        valid_choice=true
                        ;;
                    5)
                        SKIP_DOT_FILES=false
                        selected_components+=("Dot-files")
                        valid_choice=true
                        ;;
                    *)
                        print_error "Invalid choice: $c"
                        ;;
                esac
            done
            
            if [[ "$valid_choice" == true ]]; then
                print_success "Selected components: ${selected_components[*]}"
                echo ""
                print_status "The script will now install:"
                if [[ "$SKIP_BREW" == false ]]; then
                    echo "  ✓ Homebrew formulas"
                fi
                if [[ "$SKIP_BREW_APPS" == false ]]; then
                    echo "  ✓ Homebrew cask applications"
                fi
                if [[ "$SKIP_CURSOR" == false ]]; then
                    echo "  ✓ Cursor extensions"
                fi
                if [[ "$SKIP_SETTINGS" == false ]]; then
                    echo "  ✓ Cursor settings"
                fi
                if [[ "$SKIP_DOT_FILES" == false ]]; then
                    echo "  ✓ Dot-files"
                fi
                break
            else
                print_error "Please enter valid choices (1-7)"
            fi
        fi
    done
    
    # Confirmation prompt
    echo ""
    echo -n -e "${YELLOW}[CONFIRM]${NC} Proceed with installation? (y/N): "
    read -r confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled by user. Goodbye!"
        exit 0
    fi
    
    print_success "Starting installation process..."
    echo ""
}

# Function to show setup plan
show_setup_plan() {
    print_header "Setup Plan"
    
    local step=1
    
    if [[ "$SKIP_BREW" == false ]]; then
        echo "Step $step: Install Homebrew formulas"
        ((step++))
    else
        print_warning "Skipping Homebrew formulas installation"
    fi
    
    if [[ "$SKIP_BREW_APPS" == false ]]; then
        echo "Step $step: Install Homebrew cask applications"
        ((step++))
    else
        print_warning "Skipping Homebrew cask applications installation"
    fi
    
    if [[ "$SKIP_CURSOR" == false ]]; then
        echo "Step $step: Install Cursor extensions"
        ((step++))
    else
        print_warning "Skipping Cursor extensions installation"
    fi
    
    if [[ "$SKIP_SETTINGS" == false ]]; then
        echo "Step $step: Clone Cursor settings"
        ((step++))
    else
        print_warning "Skipping Cursor settings cloning"
    fi
    
    if [[ "$SKIP_DOT_FILES" == false ]]; then
        echo "Step $step: Install dot-files"
        ((step++))
    else
        print_warning "Skipping dot-files installation"
    fi
    
    if [[ "$SKIP_BREW" == true && "$SKIP_BREW_APPS" == true && "$SKIP_CURSOR" == true && "$SKIP_SETTINGS" == true && "$SKIP_DOT_FILES" == true ]]; then
        print_warning "All components are being skipped. Nothing to do!"
        exit 0
    fi
    
    echo ""
}

# Main function
main() {
    # Parse command line arguments
    parse_arguments "$@"
    
    # Show interactive menu if in interactive mode (before anything else)
    if [[ "$INTERACTIVE_MODE" == true ]]; then
        show_interactive_menu
    fi
    
    # Show system info
    show_system_info
    
    # Setup logging
    setup_logging
    
    # Check prerequisites
    check_prerequisites
    
    # Show setup plan (non-interactive mode only)
    if [[ "$INTERACTIVE_MODE" == false ]]; then
        show_setup_plan
    fi
    
    print_header "Executing System Setup"
    
    local step=1
    local failed_components=()
    
    # Step 1: Install Homebrew formulas
    if [[ "$SKIP_BREW" == false ]]; then
        if ! run_script "$BREW_SCRIPT" "Homebrew formulas installer" "$step"; then
            failed_components+=("Homebrew formulas")
        fi
        ((step++))
        echo ""
    fi
    
    # Step 2: Install Homebrew cask applications
    if [[ "$SKIP_BREW_APPS" == false ]]; then
        if ! run_script "$BREW_APPS_SCRIPT" "Homebrew cask applications installer" "$step"; then
            failed_components+=("Homebrew cask applications")
        fi
        ((step++))
        echo ""
    fi
    
    # Step 3: Install Cursor extensions
    if [[ "$SKIP_CURSOR" == false ]]; then
        if ! run_script "$CURSOR_EXT_SCRIPT" "Cursor extensions installer" "$step"; then
            failed_components+=("Cursor extensions")
        fi
        ((step++))
        echo ""
    fi
    
    # Step 4: Clone Cursor settings
    if [[ "$SKIP_SETTINGS" == false ]]; then
        if ! run_script "$CURSOR_SETTINGS_SCRIPT" "Cursor settings cloner" "$step"; then
            failed_components+=("Cursor settings")
        fi
        ((step++))
        echo ""
    fi
    
    # Step 5: Install dot-files
    if [[ "$SKIP_DOT_FILES" == false ]]; then
        if ! run_script "$DOT_FILES_SCRIPT" "Dot-files installer" "$step"; then
            failed_components+=("Dot-files")
        fi
        ((step++))
        echo ""
    fi
    
    # Final summary
    print_header "Setup Complete"
    
    if [[ ${#failed_components[@]} -eq 0 ]]; then
        print_success "All components installed successfully!"
        echo "SUCCESS: Complete system setup - $(date)" >> "$MAIN_LOG_FILE"
    else
        print_error "Some components failed:"
        for component in "${failed_components[@]}"; do
            echo "  - $component"
        done
        echo "PARTIAL_SUCCESS: Setup completed with failures - $(date)" >> "$MAIN_LOG_FILE"
        print_status "Check individual log files for details."
    fi
    
    print_status "Main log file: $MAIN_LOG_FILE"
    print_status "Individual log files in: $LOGS_DIR/"
    
    if [[ ${#failed_components[@]} -gt 0 ]]; then
        exit 1
    fi
}

# Run main function with all arguments
main "$@" 