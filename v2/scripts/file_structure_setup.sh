#!/bin/bash

#############################################################################
# Academic Course File Structure Setup for Linux
# Version: 1.1.0
# Description: Creates organized folder structures for academic courses
#              with advanced GUI, automatic dependency management, and
#              multi-distro support
#############################################################################

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m' # No Color

# Global variables
declare -a LOCATIONS=()
declare -a COURSE_NAMES=()
CREATE_README=false
CREATE_GITIGNORE=false
CREATE_LOG=true
LOG_FILE=""
CREATED_COUNT=0
ERROR_COUNT=0
PACKAGE_MANAGER=""
DISTRO_NAME=""

# Define the folder structure (unchanged as requested)
readonly FOLDERS=(
    "01-admin"
    "02-resources/slides"
    "02-resources/content"
    "02-resources/whiteboard"
    "03-notes/class_notes"
    "03-notes/reviews"
    "04-assessments/assignments"
    "04-assessments/projects"
    "05-exams/current/final"
    "05-exams/current/mid_term"
    "05-exams/current/other"
    "05-exams/current/quiz"
    "05-exams/olds/final"
    "05-exams/olds/mid_term"
    "05-exams/olds/other"
    "05-exams/olds/quiz"
    "archive"
)

#############################################################################
# Utility Functions
#############################################################################

# Print colored message
print_message() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Print error
print_error() {
    print_message "$RED" "✗ ERROR: $*" >&2
}

# Print success
print_success() {
    print_message "$GREEN" "✓ $*"
}

# Print info
print_info() {
    print_message "$CYAN" "ℹ $*"
}

# Print warning
print_warning() {
    print_message "$YELLOW" "⚠ $*"
}

#############################################################################
# System Detection and Dependency Management
#############################################################################

# Detect Linux distribution and package manager
detect_system() {
    print_info "Detecting system configuration..."
    
    # Check OS
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        print_error "This script is for Linux only. Detected OS: $OSTYPE"
        exit 1
    fi
    
    # Detect distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_NAME=$ID
    elif [ -f /etc/redhat-release ]; then
        DISTRO_NAME="rhel"
    elif [ -f /etc/debian_version ]; then
        DISTRO_NAME="debian"
    else
        DISTRO_NAME="unknown"
    fi
    
    # Detect package manager
    if command -v apt-get &> /dev/null; then
        PACKAGE_MANAGER="apt"
    elif command -v dnf &> /dev/null; then
        PACKAGE_MANAGER="dnf"
    elif command -v yum &> /dev/null; then
        PACKAGE_MANAGER="yum"
    elif command -v pacman &> /dev/null; then
        PACKAGE_MANAGER="pacman"
    elif command -v zypper &> /dev/null; then
        PACKAGE_MANAGER="zypper"
    else
        PACKAGE_MANAGER="unknown"
    fi
    
    print_success "Detected: $DISTRO_NAME with $PACKAGE_MANAGER package manager"
}

# Install package based on detected system
install_package() {
    local package=$1
    local install_cmd=""
    
    case "$PACKAGE_MANAGER" in
        apt)
            install_cmd="sudo apt-get update && sudo apt-get install -y $package"
            ;;
        dnf)
            install_cmd="sudo dnf install -y $package"
            ;;
        yum)
            install_cmd="sudo yum install -y $package"
            ;;
        pacman)
            install_cmd="sudo pacman -S --noconfirm $package"
            ;;
        zypper)
            install_cmd="sudo zypper install -y $package"
            ;;
        *)
            print_error "Unknown package manager. Cannot install $package automatically."
            return 1
            ;;
    esac
    
    print_info "Installing $package..."
    if eval "$install_cmd"; then
        print_success "$package installed successfully!"
        return 0
    else
        print_error "Failed to install $package"
        return 1
    fi
}

# Check and install dependencies with user prompt
check_and_install_dependencies() {
    local deps=("zenity")
    local missing=()
    
    print_info "Checking dependencies..."
    
    # Check which dependencies are missing
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -eq 0 ]; then
        print_success "All dependencies are installed!"
        return 0
    fi
    
    # Display missing dependencies
    print_warning "Missing dependencies: ${missing[*]}"
    
    # If zenity itself is missing, use terminal prompt
    if [[ " ${missing[*]} " =~ " zenity " ]]; then
        echo ""
        print_info "This script requires 'zenity' for the graphical interface."
        echo -e "${YELLOW}Would you like to install it now? (y/n)${NC}"
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            if install_package "zenity"; then
                print_success "Dependencies installed successfully!"
                echo ""
                print_info "Please run the script again to start."
                exit 0
            else
                print_error "Failed to install dependencies."
                echo ""
                print_info "Please install manually using:"
                case "$PACKAGE_MANAGER" in
                    apt) echo "  sudo apt-get install zenity" ;;
                    dnf) echo "  sudo dnf install zenity" ;;
                    yum) echo "  sudo yum install zenity" ;;
                    pacman) echo "  sudo pacman -S zenity" ;;
                    zypper) echo "  sudo zypper install zenity" ;;
                    *) echo "  Use your system's package manager to install: ${missing[*]}" ;;
                esac
                exit 1
            fi
        else
            print_error "Cannot continue without required dependencies."
            exit 1
        fi
    fi
}

#############################################################################
# GUI Functions
#############################################################################

# Show welcome screen
show_welcome() {
    zenity --info \
        --title="Academic Course Structure Setup" \
        --width=500 \
        --height=200 \
        --text="<big><b>Academic Course Structure Setup v1.1.0</b></big>

Welcome! This tool will help you create organized folder structures for your academic courses.

<b>Features:</b>
• Multiple location support
• Optional course subfolders
• Auto-generated README files
• Git integration
• Detailed logging

Click OK to continue..." 2>/dev/null || return 1
}

# Show main menu with improved GUI
show_main_menu() {
    local loc_count=${#LOCATIONS[@]}
    local course_count=${#COURSE_NAMES[@]}
    
    local status_text="<b>Current Configuration:</b>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 Locations: <b>$loc_count</b> selected
📚 Courses: <b>$course_count</b> configured
📄 README files: $([ "$CREATE_README" = true ] && echo "✓ Yes" || echo "✗ No")
🔧 .gitignore: $([ "$CREATE_GITIGNORE" = true ] && echo "✓ Yes" || echo "✗ No")
📋 Creation log: $([ "$CREATE_LOG" = true ] && echo "✓ Yes" || echo "✗ No")
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

<b>What would you like to do?</b>"

    zenity --list \
        --title="Academic Course Structure Setup" \
        --width=700 \
        --height=500 \
        --text="$status_text" \
        --radiolist \
        --column="" --column="Action" --column="Description" \
        TRUE "locations" "📁 Manage Setup Locations ($loc_count selected)" \
        FALSE "courses" "📚 Configure Course Names ($course_count courses)" \
        FALSE "options" "⚙️  Additional Options & Settings" \
        FALSE "create" "🚀 Create Folder Structure" \
        FALSE "quit" "❌ Exit Application" \
        --hide-header 2>/dev/null
}

# Manage locations with improved interface
manage_locations() {
    while true; do
        local loc_list=""
        if [ ${#LOCATIONS[@]} -gt 0 ]; then
            loc_list="<b>Currently Selected Locations:</b>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"
            local i=1
            for loc in "${LOCATIONS[@]}"; do
                loc_list+="$i. $loc
"
                ((i++))
            done
            loc_list+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

"
        else
            loc_list="<b>No locations selected yet.</b>

"
        fi
        
        local action
        action=$(zenity --list \
            --title="Manage Setup Locations" \
            --width=750 \
            --height=500 \
            --text="${loc_list}Select an action:" \
            --radiolist \
            --column="" --column="Action" --column="Description" \
            TRUE "add" "➕ Add New Location" \
            FALSE "remove" "➖ Remove a Location" \
            FALSE "clear" "🗑️  Clear All Locations" \
            FALSE "back" "⬅️  Back to Main Menu" \
            --hide-header 2>/dev/null)
        
        case "$action" in
            add)
                local new_loc
                new_loc=$(zenity --file-selection --directory \
                    --title="Select Parent Folder for Course Structure" \
                    --filename="$HOME/" 2>/dev/null)
                
                if [ -n "$new_loc" ] && [ -d "$new_loc" ]; then
                    # Check for duplicates
                    local is_duplicate=false
                    for loc in "${LOCATIONS[@]}"; do
                        if [ "$loc" = "$new_loc" ]; then
                            is_duplicate=true
                            break
                        fi
                    done
                    
                    if [ "$is_duplicate" = true ]; then
                        zenity --warning \
                            --title="Duplicate Location" \
                            --width=400 \
                            --text="⚠️ This location is already in your list!

<b>Location:</b> $new_loc" 2>/dev/null
                    else
                        LOCATIONS+=("$new_loc")
                        zenity --info \
                            --title="Location Added" \
                            --width=400 \
                            --text="✓ Location added successfully!

<b>Total locations:</b> ${#LOCATIONS[@]}" 2>/dev/null
                    fi
                elif [ -n "$new_loc" ]; then
                    # Path was provided but doesn't exist
                    zenity --error \
                        --title="Invalid Location" \
                        --width=450 \
                        --text="❌ The selected location does not exist or is not accessible!

<b>Path:</b> $new_loc

Please select a valid directory." 2>/dev/null
                fi
                ;;
            remove)
                if [ ${#LOCATIONS[@]} -eq 0 ]; then
                    zenity --warning \
                        --title="No Locations" \
                        --width=350 \
                        --text="⚠️ No locations to remove!" 2>/dev/null
                else
                    # Create list for selection
                    local list_items=()
                    local i=1
                    for loc in "${LOCATIONS[@]}"; do
                        list_items+=("FALSE" "$i" "$loc")
                        ((i++))
                    done
                    
                    local to_remove
                    to_remove=$(zenity --list \
                        --title="Remove Location" \
                        --width=700 \
                        --height=400 \
                        --text="Select locations to remove:" \
                        --checklist \
                        --column="Remove" --column="#" --column="Location" \
                        "${list_items[@]}" \
                        --separator="|" 2>/dev/null)
                    
                    if [ -n "$to_remove" ]; then
                        # Get indices to remove
                        IFS='|' read -ra indices <<< "$to_remove"
                        local removed_count=0
                        
                        # Remove in reverse order to maintain indices
                        for ((i=${#indices[@]}-1; i>=0; i--)); do
                            local idx=$((${indices[i]} - 1))
                            unset 'LOCATIONS[$idx]'
                            ((removed_count++))
                        done
                        
                        # Rebuild array
                        LOCATIONS=("${LOCATIONS[@]}")
                        
                        zenity --info \
                            --title="Locations Removed" \
                            --width=400 \
                            --text="✓ Removed $removed_count location(s)!

<b>Remaining locations:</b> ${#LOCATIONS[@]}" 2>/dev/null
                    fi
                fi
                ;;
            clear)
                if [ ${#LOCATIONS[@]} -gt 0 ]; then
                    if zenity --question \
                        --title="Clear All Locations" \
                        --width=400 \
                        --text="⚠️ Clear all ${#LOCATIONS[@]} location(s)?

This action cannot be undone." 2>/dev/null; then
                        LOCATIONS=()
                        zenity --info \
                            --title="Locations Cleared" \
                            --width=350 \
                            --text="✓ All locations cleared!" 2>/dev/null
                    fi
                else
                    zenity --info \
                        --title="No Locations" \
                        --width=350 \
                        --text="ℹ No locations to clear." 2>/dev/null
                fi
                ;;
            back|"")
                break
                ;;
        esac
    done
}

# Configure course names with improved interface
configure_courses() {
    local courses_text=""
    if [ ${#COURSE_NAMES[@]} -gt 0 ]; then
        courses_text=$(printf "%s\n" "${COURSE_NAMES[@]}")
    fi
    
    local info_text="<b>Configure Course Names (Optional)</b>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Enter course names below, one per line.

<b>Examples:</b>
• CS101 - Introduction to Programming
• MATH201 - Calculus II
• PHYS301 - Quantum Mechanics

If you leave this empty, the folder structure will be created directly in your selected locations.

<b>Currently:</b> ${#COURSE_NAMES[@]} course(s) configured
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Enter your course names:"

    local input
    input=$(zenity --text-info \
        --title="Configure Course Names" \
        --editable \
        --width=700 \
        --height=500 \
        --ok-label="Save" \
        --cancel-label="Cancel" \
        --extra-button="Clear All" \
        --filename=<(echo "$courses_text") 2>/dev/null || echo "CANCEL")
    
    local exit_code=$?
    
    if [ "$input" = "Clear All" ] || [ $exit_code -eq 1 ]; then
        if zenity --question \
            --title="Clear Courses" \
            --width=400 \
            --text="Clear all course names?" 2>/dev/null; then
            COURSE_NAMES=()
            zenity --info \
                --title="Courses Cleared" \
                --width=350 \
                --text="✓ All course names cleared!" 2>/dev/null
        fi
    elif [ "$input" != "CANCEL" ] && [ -n "$input" ]; then
        COURSE_NAMES=()
        while IFS= read -r line; do
            line=$(echo "$line" | xargs) # Trim whitespace
            if [ -n "$line" ]; then
                COURSE_NAMES+=("$line")
            fi
        done <<< "$input"
        
        if [ ${#COURSE_NAMES[@]} -gt 0 ]; then
            zenity --info \
                --title="Courses Configured" \
                --width=400 \
                --text="✓ Course names saved successfully!

<b>Total courses:</b> ${#COURSE_NAMES[@]}" 2>/dev/null
        else
            zenity --info \
                --title="No Courses" \
                --width=450 \
                --text="ℹ No course names configured.

The folder structure will be created directly in your selected locations." 2>/dev/null
        fi
    fi
}

# Configure additional options
configure_options() {
    local options
    options=$(zenity --list \
        --title="Additional Options" \
        --width=650 \
        --height=450 \
        --text="<b>Select the options you want to enable:</b>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Configure additional features for your folder structure
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" \
        --checklist \
        --column="" --column="Option" --column="Description" \
        $CREATE_README "readme" "Create README.md files in each folder" \
        $CREATE_GITIGNORE "gitignore" "Create .gitignore file for version control" \
        $CREATE_LOG "log" "Generate detailed creation log file" \
        --separator="," \
        --hide-header 2>/dev/null)
    
    CREATE_README=false
    CREATE_GITIGNORE=false
    CREATE_LOG=false
    
    if [ -n "$options" ]; then
        IFS=',' read -ra OPTS <<< "$options"
        for opt in "${OPTS[@]}"; do
            case "$opt" in
                readme) CREATE_README=true ;;
                gitignore) CREATE_GITIGNORE=true ;;
                log) CREATE_LOG=true ;;
            esac
        done
    fi
    
    local enabled_features="<b>Options Updated!</b>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
<b>Current Settings:</b>

📄 README files: $([ "$CREATE_README" = true ] && echo "✓ Enabled" || echo "✗ Disabled")
🔧 .gitignore file: $([ "$CREATE_GITIGNORE" = true ] && echo "✓ Enabled" || echo "✗ Disabled")
📋 Creation log: $([ "$CREATE_LOG" = true ] && echo "✓ Enabled" || echo "✗ Disabled")
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    zenity --info \
        --title="Options Saved" \
        --width=450 \
        --text="$enabled_features" 2>/dev/null
}

#############################################################################
# File Creation Functions
#############################################################################

# Create README file
create_readme() {
    local path=$1
    local folder_name=$2
    local readme_path="$path/README.md"
    
    cat > "$readme_path" <<EOF
# $folder_name

## Purpose
This folder is part of the course organization structure.

## Created
$(date '+%Y-%m-%d %H:%M:%S')

## Location
\`$path\`

---
*Auto-generated by Course Structure Setup Script v1.1.0*
EOF
}

# Create .gitignore file
create_gitignore() {
    local path=$1
    local gitignore_path="$path/.gitignore"
    
    cat > "$gitignore_path" <<EOF
# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
desktop.ini

# Temporary files
*.tmp
*.temp
~\$*
*.swp
*.swo
*~

# Archives
*.zip
*.rar
*.7z
*.tar
*.tar.gz

# Personal/Private notes
*private*
*personal*
*secret*

# IDE/Editor directories
.vscode/
.idea/
*.sublime-*

# Python
__pycache__/
*.py[cod]
*.pyo

# Node
node_modules/

# Build outputs
*.out
*.o
*.exe
EOF
}

#############################################################################
# Main Structure Creation
#############################################################################

# Create folder structure with beautiful progress
create_structure() {
    if [ ${#LOCATIONS[@]} -eq 0 ]; then
        zenity --error \
            --title="No Locations" \
            --width=450 \
            --text="❌ <b>No locations selected!</b>

Please add at least one location before creating the folder structure.

Go to: <b>Manage Setup Locations</b>" 2>/dev/null
        return 1
    fi
    
    # Show confirmation dialog
    local confirm_text="<b>Ready to Create Folder Structure</b>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
<b>Configuration Summary:</b>

📁 Locations: ${#LOCATIONS[@]}
📚 Courses: ${#COURSE_NAMES[@]}$([ ${#COURSE_NAMES[@]} -eq 0 ] && echo " (direct creation)")
📂 Folders per structure: ${#FOLDERS[@]}
📄 README files: $([ "$CREATE_README" = true ] && echo "Yes" || echo "No")
🔧 .gitignore: $([ "$CREATE_GITIGNORE" = true ] && echo "Yes" || echo "No")
📋 Creation log: $([ "$CREATE_LOG" = true ] && echo "Yes" || echo "No")
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

<b>Proceed with creation?</b>"

    if ! zenity --question \
        --title="Confirm Creation" \
        --width=500 \
        --ok-label="Create Now" \
        --cancel-label="Cancel" \
        --text="$confirm_text" 2>/dev/null; then
        return 0
    fi
    
    # Initialize log
    if [ "$CREATE_LOG" = true ]; then
        LOG_FILE="/tmp/folder_creation_log_$(date +%Y%m%d_%H%M%S).txt"
        {
            echo "╔════════════════════════════════════════════════════════════════════════════╗"
            echo "║         Academic Course Folder Structure Creation Log                     ║"
            echo "╚════════════════════════════════════════════════════════════════════════════╝"
            echo ""
            echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
            echo "System: $DISTRO_NAME with $PACKAGE_MANAGER"
            echo ""
            echo "Configuration:"
            echo "  • Locations: ${#LOCATIONS[@]}"
            echo "  • Courses: ${#COURSE_NAMES[@]}"
            echo "  • README files: $([ "$CREATE_README" = true ] && echo "Yes" || echo "No")"
            echo "  • .gitignore: $([ "$CREATE_GITIGNORE" = true ] && echo "Yes" || echo "No")"
            echo ""
            echo "$(printf '─%.0s' {1..80})"
            echo ""
        } > "$LOG_FILE"
    fi
    
    CREATED_COUNT=0
    ERROR_COUNT=0
    local start_time=$(date +%s)
    local error_details=""
    
    # Calculate total operations
    local total_ops=0
    for loc in "${LOCATIONS[@]}"; do
        if [ ${#COURSE_NAMES[@]} -eq 0 ]; then
            total_ops=$((total_ops + ${#FOLDERS[@]}))
        else
            total_ops=$((total_ops + ${#FOLDERS[@]} * ${#COURSE_NAMES[@]}))
        fi
    done
    
    local current_op=0
    
    # Main creation loop with progress
    (
        for location in "${LOCATIONS[@]}"; do
            echo "# 🏗️  Working on: $location"
            
            if [ ${#COURSE_NAMES[@]} -eq 0 ]; then
                # Create directly in location
                for folder in "${FOLDERS[@]}"; do
                    local full_path="$location/$folder"
                    
                    # Create the folder and capture any errors
                    local mkdir_output
                    if mkdir_output=$(mkdir -p "$full_path" 2>&1); then
                        CREATED_COUNT=$((CREATED_COUNT + 1))
                        
                        if [ "$CREATE_README" = true ]; then
                            local folder_name
                            folder_name=$(basename "$folder")
                            create_readme "$full_path" "$folder_name" 2>/dev/null || true
                        fi
                        
                        if [ "$CREATE_LOG" = true ]; then
                            echo "✓ Created: $full_path" >> "$LOG_FILE"
                        fi
                    else
                        ERROR_COUNT=$((ERROR_COUNT + 1))
                        error_details+="Failed: $full_path - $mkdir_output\n"
                        if [ "$CREATE_LOG" = true ]; then
                            echo "✗ ERROR: Failed to create $full_path - $mkdir_output" >> "$LOG_FILE"
                        fi
                    fi
                    
                    current_op=$((current_op + 1))
                    local percentage=$((current_op * 100 / total_ops))
                    echo "$percentage"
                    echo "# Creating: $(basename "$folder") ($current_op/$total_ops)"
                done
                
                if [ "$CREATE_GITIGNORE" = true ]; then
                    create_gitignore "$location" 2>/dev/null || true
                fi
            else
                # Create in course subfolders
                for course in "${COURSE_NAMES[@]}"; do
                    local base_path="$location/$course"
                    echo "# 📚 Creating course: $course"
                    
                    for folder in "${FOLDERS[@]}"; do
                        local full_path="$base_path/$folder"
                        
                        # Create the folder and capture any errors
                        local mkdir_output
                        if mkdir_output=$(mkdir -p "$full_path" 2>&1); then
                            CREATED_COUNT=$((CREATED_COUNT + 1))
                            
                            if [ "$CREATE_README" = true ]; then
                                local folder_name
                                folder_name=$(basename "$folder")
                                create_readme "$full_path" "$folder_name" 2>/dev/null || true
                            fi
                            
                            if [ "$CREATE_LOG" = true ]; then
                                echo "✓ Created: $full_path" >> "$LOG_FILE"
                            fi
                        else
                            ERROR_COUNT=$((ERROR_COUNT + 1))
                            error_details+="Failed: $full_path - $mkdir_output\n"
                            if [ "$CREATE_LOG" = true ]; then
                                echo "✗ ERROR: Failed to create $full_path - $mkdir_output" >> "$LOG_FILE"
                            fi
                        fi
                        
                        current_op=$((current_op + 1))
                        local percentage=$((current_op * 100 / total_ops))
                        echo "$percentage"
                        echo "# Creating: $course/$(basename "$folder") ($current_op/$total_ops)"
                    done
                    
                    if [ "$CREATE_GITIGNORE" = true ]; then
                        create_gitignore "$base_path" 2>/dev/null || true
                    fi
                done
            fi
        done
        
        echo "100"
        echo "# ✅ Complete!"
    ) | zenity --progress \
        --title="Creating Folder Structure" \
        --text="Initializing..." \
        --percentage=0 \
        --width=600 \
        --auto-close 2>/dev/null
    
    local progress_exit=$?
    local progress_exit=$?
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Finalize log
    if [ "$CREATE_LOG" = true ]; then
        {
            echo ""
            echo "$(printf '─%.0s' {1..80})"
            echo ""
            echo "Summary:"
            echo "  ✓ Total folders created: $CREATED_COUNT"
            echo "  ✗ Total errors: $ERROR_COUNT"
            echo "  ⏱  Duration: $duration seconds"
            if [ -n "$error_details" ]; then
                echo ""
                echo "Error Details:"
                echo -e "$error_details"
            fi
            echo ""
            echo "Completed: $(date '+%Y-%m-%d %H:%M:%S')"
            echo ""
            echo "╔════════════════════════════════════════════════════════════════════════════╗"
            echo "║                         Operation Complete                                 ║"
            echo "╚════════════════════════════════════════════════════════════════════════════╝"
        } >> "$LOG_FILE"
    fi
    
    # Check if user cancelled
    if [ $progress_exit -eq 1 ]; then
        zenity --warning \
            --title="Cancelled" \
            --width=400 \
            --text="⚠️ Operation cancelled by user.

Created $CREATED_COUNT folders before cancellation." 2>/dev/null
        return 0
    fi
    
    # Show results
    local result_msg="<big><b>✅ Creation Complete!</b></big>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
<b>Results:</b>

✓ Folders created: <b>$CREATED_COUNT</b>
⏱  Time taken: <b>$duration seconds</b>"
    
    if [ $ERROR_COUNT -gt 0 ]; then
        result_msg+="
✗ Errors encountered: <b>$ERROR_COUNT</b>

<span foreground='red'>Some folders could not be created. Check the log for details.</span>"
    fi
    
    if [ "$CREATE_LOG" = true ]; then
        result_msg+="

📋 Log file saved to:
<tt>$LOG_FILE</tt>"
    fi
    
    result_msg+="
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    zenity --info \
        --title="Creation Complete" \
        --width=550 \
        --text="$result_msg" 2>/dev/null
    
    if [ "$CREATE_LOG" = true ]; then
        if zenity --question \
            --title="View Log" \
            --width=400 \
            --ok-label="View Log" \
            --cancel-label="Close" \
            --text="📋 Would you like to view the detailed log file?" 2>/dev/null; then
            
            # Try to open with default text editor
            if command -v xdg-open &> /dev/null; then
                xdg-open "$LOG_FILE" &
            elif command -v gedit &> /dev/null; then
                gedit "$LOG_FILE" &
            elif command -v kate &> /dev/null; then
                kate "$LOG_FILE" &
            elif command -v nano &> /dev/null; then
                x-terminal-emulator -e nano "$LOG_FILE" &
            else
                zenity --text-info \
                    --title="Creation Log" \
                    --filename="$LOG_FILE" \
                    --width=800 \
                    --height=600 2>/dev/null
            fi
        fi
    fi
    
    # Ask if user wants to create another structure
    if zenity --question \
        --title="Create Another?" \
        --width=400 \
        --ok-label="Yes" \
        --cancel-label="No" \
        --text="Would you like to create another folder structure?" 2>/dev/null; then
        return 0
    else
        print_success "Thank you for using Course Structure Setup!"
        exit 0
    fi
}

#############################################################################
# Main Program
#############################################################################

main() {
    # Clear screen and show header
    clear
    echo ""
    print_message "$BLUE" "╔════════════════════════════════════════════════════════════════════════════╗"
    print_message "$BLUE" "║       Academic Course File Structure Setup - Version 1.1.0                  ║"
    print_message "$BLUE" "╚════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Detect system
    detect_system
    
    # Check and install dependencies
    check_and_install_dependencies
    
    echo ""
    print_info "Starting GUI interface..."
    sleep 1
    
    # Show welcome screen
    if ! show_welcome; then
        print_warning "Setup cancelled by user."
        exit 0
    fi
    
    # Main loop
    while true; do
        local choice
        choice=$(show_main_menu)
        
        case "$choice" in
            locations)
                manage_locations
                ;;
            courses)
                configure_courses
                ;;
            options)
                configure_options
                ;;
            create)
                create_structure
                ;;
            quit|"")
                if zenity --question \
                    --title="Exit" \
                    --width=350 \
                    --text="Are you sure you want to exit?" 2>/dev/null; then
                    print_info "Exiting..."
                    exit 0
                fi
                ;;
            *)
                print_error "Invalid option"
                ;;
        esac
    done
}

# Run main program with error handling
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    trap 'print_error "Script interrupted"; exit 130' INT
    trap 'print_error "Script terminated"; exit 143' TERM
    
    main "$@"
fi