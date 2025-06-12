#!/bin/bash

# Script to install dot-files from GitHub repository
# Usage: ./install-dot-files.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="git@github.com:itaimoorali/dot-files.git"
DOT_FILES_DIR="$HOME/dot-files"
BASH_PROFILE="$HOME/.bash_profile"
BACKUP_DIR="$HOME/.bash_profile_backups"
DOTFILES_BACKUP_DIR="$HOME/.dotfiles_backups"
LOG_FILE="logs/dot-files-install.log"
SOURCE_LINE="source ~/dot-files/index.sh;"

# Files to be symlinked (Bash 3.2 compatible)
SYMLINK_SOURCES=(
    "$DOT_FILES_DIR/.gitconfig"
    "$DOT_FILES_DIR/.gitignore"
)

SYMLINK_TARGETS=(
    "$HOME/.gitconfig"
    "$HOME/.gitignore"
)

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
    echo "Dot-files Installation Log - $(date)" > "$LOG_FILE"
    echo "======================================" >> "$LOG_FILE"
}

# Function to check if git is installed
check_git_installation() {
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed. Please install Git first."
        print_status "You can install Git by running: xcode-select --install"
        print_status "Or install via Homebrew: brew install git"
        echo "ERROR: Git not found" >> "$LOG_FILE"
        exit 1
    fi
    
    print_success "Git is installed"
    echo "SUCCESS: Git found" >> "$LOG_FILE"
}

# Function to check bash version compatibility
check_bash_version() {
    print_status "Running on Bash version: $BASH_VERSION"
    echo "INFO: Running on Bash version: $BASH_VERSION" >> "$LOG_FILE"
    
    # Script is now compatible with Bash 3.2+ (default macOS version)
    local bash_version="${BASH_VERSION%%.*}"
    if [[ "$bash_version" -lt 3 ]]; then
        print_error "This script requires Bash 3.0+."
        print_error "Current Bash version: $BASH_VERSION"
        echo "ERROR: Bash version too old ($BASH_VERSION)" >> "$LOG_FILE"
        exit 1
    fi
    
    print_success "Bash version compatible"
    echo "SUCCESS: Bash version compatible" >> "$LOG_FILE"
}

# Function to check SSH key for GitHub
check_ssh_key() {
    print_status "Testing SSH connection to GitHub..."
    
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        print_success "SSH key is properly configured for GitHub"
        echo "SUCCESS: SSH authentication verified" >> "$LOG_FILE"
    else
        print_warning "SSH key might not be configured for GitHub"
        print_status "You may need to set up your SSH key. Proceeding anyway..."
        echo "WARNING: SSH authentication not verified" >> "$LOG_FILE"
    fi
}

# Function to clone or update dot-files repository
clone_or_update_repo() {
    if [[ -d "$DOT_FILES_DIR" ]]; then
        print_status "Dot-files directory already exists: $DOT_FILES_DIR"
        print_status "Updating existing repository..."
        
        cd "$DOT_FILES_DIR"
        
        if git pull origin main 2>&1 | tee -a "$LOG_FILE"; then
            print_success "Repository updated successfully"
            echo "SUCCESS: Repository updated" >> "$LOG_FILE"
        else
            print_error "Failed to update repository"
            echo "ERROR: Failed to update repository" >> "$LOG_FILE"
            exit 1
        fi
        
        cd - > /dev/null
    else
        print_status "Cloning dot-files repository..."
        print_status "Repository: $REPO_URL"
        print_status "Destination: $DOT_FILES_DIR"
        
        if git clone "$REPO_URL" "$DOT_FILES_DIR" 2>&1 | tee -a "$LOG_FILE"; then
            print_success "Repository cloned successfully"
            echo "SUCCESS: Repository cloned" >> "$LOG_FILE"
        else
            print_error "Failed to clone repository"
            echo "ERROR: Failed to clone repository" >> "$LOG_FILE"
            print_status "Make sure your SSH key is properly configured for GitHub"
            exit 1
        fi
    fi
}

# Function to verify dot-files structure
verify_dot_files() {
    local index_file="$DOT_FILES_DIR/index.sh"
    
    if [[ ! -f "$index_file" ]]; then
        print_error "Expected file not found: $index_file"
        echo "ERROR: index.sh not found in dot-files" >> "$LOG_FILE"
        exit 1
    fi
    
    # Check if symlink files exist
    local missing_files=()
    for source_file in "${SYMLINK_SOURCES[@]}"; do
        if [[ ! -f "$source_file" ]]; then
            missing_files+=("$source_file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        print_warning "Some expected files are missing from dot-files repository:"
        for file in "${missing_files[@]}"; do
            print_warning "  - $file"
        done
        echo "WARNING: Missing files in dot-files repository" >> "$LOG_FILE"
    fi
    
    print_success "Dot-files structure verified"
    echo "SUCCESS: Dot-files structure verified" >> "$LOG_FILE"
}

# Function to backup existing .bash_profile
backup_bash_profile() {
    if [[ -f "$BASH_PROFILE" ]]; then
        print_status "Existing .bash_profile found, creating backup..."
        
        # Create backup directory
        mkdir -p "$BACKUP_DIR"
        
        # Create backup with timestamp
        local backup_file="$BACKUP_DIR/bash_profile_backup_$(date +%Y%m%d_%H%M%S)"
        
        if cp "$BASH_PROFILE" "$backup_file" 2>&1 | tee -a "$LOG_FILE"; then
            print_success "Backup created: $backup_file"
            echo "SUCCESS: Backup created at $backup_file" >> "$LOG_FILE"
        else
            print_error "Failed to create backup"
            echo "ERROR: Failed to create backup" >> "$LOG_FILE"
            exit 1
        fi
    else
        print_status "No existing .bash_profile found"
        echo "INFO: No existing .bash_profile to backup" >> "$LOG_FILE"
    fi
}

# Function to check if source line already exists
check_existing_source_line() {
    if [[ -f "$BASH_PROFILE" ]] && grep -q "source ~/dot-files/index.sh" "$BASH_PROFILE"; then
        print_status "Source line already exists in .bash_profile"
        echo "INFO: Source line already exists" >> "$LOG_FILE"
        return 0
    else
        return 1
    fi
}

# Function to add source line to .bash_profile
add_source_line() {
    if check_existing_source_line; then
        print_warning "Source line already exists in .bash_profile, skipping..."
        return 0
    fi
    
    print_status "Adding source line to .bash_profile..."
    
    # Create .bash_profile if it doesn't exist
    if [[ ! -f "$BASH_PROFILE" ]]; then
        print_status "Creating new .bash_profile..."
        touch "$BASH_PROFILE"
    fi
    
    # Add source line with a comment
    {
        echo ""
        echo "# Dot-files configuration - Added by install-dot-files.sh"
        echo "$SOURCE_LINE"
    } >> "$BASH_PROFILE"
    
    if [[ $? -eq 0 ]]; then
        print_success "Source line added to .bash_profile"
        echo "SUCCESS: Source line added to .bash_profile" >> "$LOG_FILE"
    else
        print_error "Failed to add source line to .bash_profile"
        echo "ERROR: Failed to add source line" >> "$LOG_FILE"
        exit 1
    fi
}

# Function to show .bash_profile preview
show_bash_profile_preview() {
    if [[ -f "$BASH_PROFILE" ]]; then
        print_status ".bash_profile preview (last 10 lines):"
        echo "========================================="
        tail -10 "$BASH_PROFILE" | while IFS= read -r line; do
            echo "  $line"
        done
        echo "========================================="
    fi
}

# Function to backup existing dotfiles
backup_existing_dotfiles() {
    local files_to_backup=()
    
    # Check which files need backing up
    for i in "${!SYMLINK_SOURCES[@]}"; do
        local source_file="${SYMLINK_SOURCES[$i]}"
        local target_file="${SYMLINK_TARGETS[$i]}"
        if [[ -f "$target_file" && ! -L "$target_file" ]]; then
            files_to_backup+=("$target_file")
        fi
    done
    
    if [[ ${#files_to_backup[@]} -gt 0 ]]; then
        print_status "Backing up existing dotfiles..."
        
        # Create backup directory
        mkdir -p "$DOTFILES_BACKUP_DIR"
        
        local timestamp=$(date +%Y%m%d_%H%M%S)
        
        for file in "${files_to_backup[@]}"; do
            local filename=$(basename "$file")
            local backup_file="$DOTFILES_BACKUP_DIR/${filename}_backup_$timestamp"
            
            if cp "$file" "$backup_file" 2>&1 | tee -a "$LOG_FILE"; then
                print_success "Backup created: $backup_file"
                echo "SUCCESS: Backup created for $file" >> "$LOG_FILE"
            else
                print_error "Failed to backup: $file"
                echo "ERROR: Failed to backup $file" >> "$LOG_FILE"
                exit 1
            fi
        done
    else
        print_status "No existing dotfiles need backing up"
        echo "INFO: No dotfiles to backup" >> "$LOG_FILE"
    fi
}

# Function to create symbolic links
create_symlinks() {
    print_status "Creating symbolic links for dotfiles..."
    
    local created_links=()
    local updated_links=()
    local skipped_links=()
    
    for i in "${!SYMLINK_SOURCES[@]}"; do
        local source_file="${SYMLINK_SOURCES[$i]}"
        local target_file="${SYMLINK_TARGETS[$i]}"
        local filename=$(basename "$target_file")
        
        # Skip if source file doesn't exist
        if [[ ! -f "$source_file" ]]; then
            print_warning "Source file not found, skipping: $source_file"
            skipped_links+=("$filename")
            continue
        fi
        
        # Check if target is already a symlink to the correct source
        if [[ -L "$target_file" && "$(readlink "$target_file")" == "$source_file" ]]; then
            print_status "Symlink already exists and is correct: $filename"
            echo "INFO: Correct symlink exists for $filename" >> "$LOG_FILE"
            continue
        fi
        
        # Remove existing file/symlink if it exists
        if [[ -e "$target_file" || -L "$target_file" ]]; then
            print_status "Removing existing file/symlink: $filename"
            if rm "$target_file" 2>&1 | tee -a "$LOG_FILE"; then
                echo "SUCCESS: Removed existing $filename" >> "$LOG_FILE"
            else
                print_error "Failed to remove existing file: $target_file"
                echo "ERROR: Failed to remove $target_file" >> "$LOG_FILE"
                exit 1
            fi
        fi
        
        # Create symbolic link
        print_status "Creating symlink: $filename -> $source_file"
        if ln -s "$source_file" "$target_file" 2>&1 | tee -a "$LOG_FILE"; then
            print_success "Symlink created: $filename"
            echo "SUCCESS: Created symlink for $filename" >> "$LOG_FILE"
            created_links+=("$filename")
        else
            print_error "Failed to create symlink: $filename"
            echo "ERROR: Failed to create symlink for $filename" >> "$LOG_FILE"
            exit 1
        fi
    done
    
    # Summary
    if [[ ${#created_links[@]} -gt 0 ]]; then
        print_success "Created symlinks: ${created_links[*]}"
    fi
    
    if [[ ${#skipped_links[@]} -gt 0 ]]; then
        print_warning "Skipped (missing source): ${skipped_links[*]}"
    fi
}

# Function to verify symlinks
verify_symlinks() {
    print_status "Verifying symbolic links..."
    
    local verified_links=()
    local broken_links=()
    
    for i in "${!SYMLINK_SOURCES[@]}"; do
        local source_file="${SYMLINK_SOURCES[$i]}"
        local target_file="${SYMLINK_TARGETS[$i]}"
        local filename=$(basename "$target_file")
        
        if [[ -L "$target_file" ]]; then
            local link_target=$(readlink "$target_file")
            if [[ "$link_target" == "$source_file" && -f "$source_file" ]]; then
                verified_links+=("$filename")
            else
                broken_links+=("$filename")
            fi
        fi
    done
    
    if [[ ${#verified_links[@]} -gt 0 ]]; then
        print_success "Verified symlinks: ${verified_links[*]}"
        echo "SUCCESS: Verified symlinks: ${verified_links[*]}" >> "$LOG_FILE"
    fi
    
    if [[ ${#broken_links[@]} -gt 0 ]]; then
        print_error "Broken symlinks found: ${broken_links[*]}"
        echo "ERROR: Broken symlinks: ${broken_links[*]}" >> "$LOG_FILE"
    fi
}

# Function to list available backups
list_backups() {
    if [[ -d "$BACKUP_DIR" && "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        print_status "Available .bash_profile backups:"
        ls -la "$BACKUP_DIR"/* 2>/dev/null | while IFS= read -r line; do
            echo "  $line"
        done
        echo ""
    fi
    
    if [[ -d "$DOTFILES_BACKUP_DIR" && "$(ls -A "$DOTFILES_BACKUP_DIR" 2>/dev/null)" ]]; then
        print_status "Available dotfiles backups:"
        ls -la "$DOTFILES_BACKUP_DIR"/* 2>/dev/null | while IFS= read -r line; do
            echo "  $line"
        done
        echo ""
    fi
}

# Main function
main() {
    print_status "Starting dot-files installation..."
    
    # Setup logging
    setup_logging
    
    # Check prerequisites
    check_bash_version
    check_git_installation
    check_ssh_key
    
    # Clone or update repository
    clone_or_update_repo
    
    # Verify dot-files structure
    verify_dot_files
    
    # Backup existing .bash_profile
    backup_bash_profile
    
    # Add source line to .bash_profile
    add_source_line
    
    # Backup existing dotfiles before creating symlinks
    backup_existing_dotfiles
    
    # Create symbolic links for dotfiles
    create_symlinks
    
    # Verify symbolic links
    verify_symlinks
    
    # Show preview
    show_bash_profile_preview
    
    # List available backups
    list_backups
    
    # Final summary
    echo ""
    print_status "Dot-files Installation Summary:"
    print_status "==============================="
    print_status "Repository: $REPO_URL"
    print_status "Location: $DOT_FILES_DIR"
    print_status "Profile: $BASH_PROFILE"
    print_status "Symlinked files:"
    for i in "${!SYMLINK_SOURCES[@]}"; do
        local source_file="${SYMLINK_SOURCES[$i]}"
        local target_file="${SYMLINK_TARGETS[$i]}"
        local filename=$(basename "$target_file")
        if [[ -L "$target_file" ]]; then
            print_status "  ✓ $filename -> $source_file"
        else
            print_warning "  ✗ $filename (not created)"
        fi
    done
    print_success "Dot-files have been successfully installed!"
    print_status "Log file: $LOG_FILE"
    print_status ""
    print_status "To apply changes immediately, run: source ~/.bash_profile"
    print_status "Or restart your terminal session"
}

# Run main function
main "$@" 