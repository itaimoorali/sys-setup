#!/bin/bash

# Script to copy Cursor settings from local file to Cursor installation
# Usage: ./clone-cursor-settings.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SOURCE_SETTINGS="settings/cursor-settings.json"
CURSOR_SETTINGS_DIR="$HOME/Library/Application Support/Cursor/User"
CURSOR_SETTINGS_FILE="$CURSOR_SETTINGS_DIR/settings.json"
BACKUP_DIR="$CURSOR_SETTINGS_DIR/backups"
LOG_FILE="logs/cursor-settings-clone.log"

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

# Function to create log file
setup_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "Cursor Settings Clone Log - $(date)" > "$LOG_FILE"
    echo "=====================================" >> "$LOG_FILE"
}

# Function to check if source settings file exists
check_source_file() {
    if [[ ! -f "$SOURCE_SETTINGS" ]]; then
        print_error "Source settings file not found: $SOURCE_SETTINGS"
        print_status "Please create the settings file first."
        echo "ERROR: Source file not found: $SOURCE_SETTINGS" >> "$LOG_FILE"
        exit 1
    fi
    
    # Validate JSON format
    if ! python3 -m json.tool "$SOURCE_SETTINGS" >/dev/null 2>&1; then
        print_error "Source settings file is not valid JSON: $SOURCE_SETTINGS"
        echo "ERROR: Invalid JSON in source file" >> "$LOG_FILE"
        exit 1
    fi
    
    print_success "Source settings file found and validated: $SOURCE_SETTINGS"
    echo "SUCCESS: Source file validated" >> "$LOG_FILE"
}

# Function to check if Cursor settings directory exists
check_cursor_installation() {
    if [[ ! -d "$CURSOR_SETTINGS_DIR" ]]; then
        print_warning "Cursor settings directory not found: $CURSOR_SETTINGS_DIR"
        print_status "Creating Cursor settings directory..."
        
        if mkdir -p "$CURSOR_SETTINGS_DIR" 2>&1 | tee -a "$LOG_FILE"; then
            print_success "Created Cursor settings directory"
            echo "SUCCESS: Created settings directory" >> "$LOG_FILE"
        else
            print_error "Failed to create Cursor settings directory"
            echo "ERROR: Failed to create settings directory" >> "$LOG_FILE"
            exit 1
        fi
    else
        print_success "Cursor settings directory found: $CURSOR_SETTINGS_DIR"
        echo "SUCCESS: Settings directory exists" >> "$LOG_FILE"
    fi
}

# Function to backup existing settings
backup_existing_settings() {
    if [[ -f "$CURSOR_SETTINGS_FILE" ]]; then
        print_status "Existing settings file found, creating backup..."
        
        # Create backup directory
        mkdir -p "$BACKUP_DIR"
        
        # Create backup with timestamp
        local backup_file="$BACKUP_DIR/settings_backup_$(date +%Y%m%d_%H%M%S).json"
        
        if cp "$CURSOR_SETTINGS_FILE" "$backup_file" 2>&1 | tee -a "$LOG_FILE"; then
            print_success "Backup created: $backup_file"
            echo "SUCCESS: Backup created at $backup_file" >> "$LOG_FILE"
        else
            print_error "Failed to create backup"
            echo "ERROR: Failed to create backup" >> "$LOG_FILE"
            exit 1
        fi
    else
        print_status "No existing settings file found, skipping backup"
        echo "INFO: No existing settings to backup" >> "$LOG_FILE"
    fi
}

# Function to copy settings
copy_settings() {
    print_status "Copying settings from $SOURCE_SETTINGS to $CURSOR_SETTINGS_FILE"
    
    if cp "$SOURCE_SETTINGS" "$CURSOR_SETTINGS_FILE" 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Settings copied successfully!"
        echo "SUCCESS: Settings copied" >> "$LOG_FILE"
        
        # Verify the copied file is valid JSON
        if python3 -m json.tool "$CURSOR_SETTINGS_FILE" >/dev/null 2>&1; then
            print_success "Copied settings file validated successfully"
            echo "SUCCESS: Copied file validated" >> "$LOG_FILE"
        else
            print_error "Copied settings file is not valid JSON"
            echo "ERROR: Copied file validation failed" >> "$LOG_FILE"
            exit 1
        fi
    else
        print_error "Failed to copy settings"
        echo "ERROR: Failed to copy settings" >> "$LOG_FILE"
        exit 1
    fi
}

# Function to show settings preview
show_settings_preview() {
    print_status "Settings Preview (first 10 lines):"
    echo "====================================="
    head -10 "$SOURCE_SETTINGS" | while IFS= read -r line; do
        echo "  $line"
    done
    echo "====================================="
}

# Function to list available backups
list_backups() {
    if [[ -d "$BACKUP_DIR" && "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        print_status "Available backups in $BACKUP_DIR:"
        ls -la "$BACKUP_DIR"/*.json 2>/dev/null | while IFS= read -r line; do
            echo "  $line"
        done
        echo ""
    fi
}

# Main function
main() {
    print_status "Starting Cursor settings clone process..."
    
    # Setup logging
    setup_logging
    
    # Check source file
    check_source_file
    
    # Show preview of settings
    show_settings_preview
    
    # Check Cursor installation
    check_cursor_installation
    
    # Backup existing settings
    backup_existing_settings
    
    # Copy settings
    copy_settings
    
    # List available backups
    list_backups
    
    # Final summary
    echo ""
    print_status "Settings Clone Summary:"
    print_status "======================"
    print_status "Source: $SOURCE_SETTINGS"
    print_status "Destination: $CURSOR_SETTINGS_FILE"
    print_success "Cursor settings have been successfully cloned!"
    print_status "Log file: $LOG_FILE"
    print_status ""
    print_status "Restart Cursor to apply the new settings."
}

# Run main function
main "$@" 