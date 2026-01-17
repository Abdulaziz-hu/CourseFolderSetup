#!/bin/bash

#############################################################################
# Academic Course File Structure Setup for Linux
# Version: 2.0
# Description: Creates organized folder structures for academic courses
#              with advanced features and optimizations
#############################################################################

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Global variables
declare -a LOCATIONS=()
declare -a COURSE_NAMES=()
CREATE_README=false
CREATE_GITIGNORE=false
CREATE_LOG=true
LOG_FILE=""
VERBOSE=false

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

# Print error and exit
die() {
    print_message "$RED" "ERROR: $*" >&2
    exit 1
}

# Check dependencies
check_dependencies() {
    local deps=("zenity")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        die "Missing required dependencies: ${missing[*]}\nInstall with: sudo apt-get install ${missing[*]}"
    fi
}

# Check OS
check_os() {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        zenity --error --text="This script is for Linux only.\nDetected OS: $OSTYPE" --width=300
        die "Unsupported operating system: $OSTYPE"
    fi
}

#############################################################################
# GUI Functions
#############################################################################

# Show main GUI
show_main_gui() {
    local choice
    choice=$(zenity --list \
        --title="Academic Course Structure Setup" \
        --text="Select an option to configure your course folder structure:" \
        --radiolist \
        --column="Select" --column="Option" --column="Description" \
        TRUE "add_locations" "Add folders where structure will be created" \
        FALSE "configure_options" "Configure additional options" \
        FALSE "create_structure" "Create folder structure" \
        FALSE "quit" "Exit the application" \
        --width=700 --height=350)
    
    echo "$choice"
}

# Add locations GUI
add_locations_gui() {
    while true; do
        local action
        
        # Build current locations list
        local loc_list=""
        if [ ${#LOCATIONS[@]} -gt 0 ]; then
            loc_list="\n\nCurrent locations (${#LOCATIONS[@]}):\n"
            for loc in "${LOCATIONS[@]}"; do
                loc_list+="• $loc\n"
            done
        fi
        
        action=$(zenity --list \
            --title="Manage Setup Locations" \
            --text="Current locations: ${#LOCATIONS[@]}${loc_list}" \
            --radiolist \
            --column="Select" --column="Action" \
            TRUE "add" "Add new location" \
            FALSE "remove" "Remove a location" \
            FALSE "clear" "Clear all locations" \
            FALSE "back" "Back to main menu" \
            --width=600 --height=400)
        
        case "$action" in
            add)
                local new_loc
                new_loc=$(zenity --file-selection --directory \
                    --title="Select Parent Folder for Course Structure")
                
                if [ -n "$new_loc" ]; then
                    # Check for duplicates
                    local is_duplicate=false
                    for loc in "${LOCATIONS[@]}"; do
                        if [ "$loc" = "$new_loc" ]; then
                            is_duplicate=true
                            break
                        fi
                    done
                    
                    if [ "$is_duplicate" = true ]; then
                        zenity --warning --text="Location already added!" --width=300
                    else
                        LOCATIONS+=("$new_loc")
                        zenity --info --text="Location added successfully!\n\nTotal locations: ${#LOCATIONS[@]}" --width=300
                    fi
                fi
                ;;
            remove)
                if [ ${#LOCATIONS[@]} -eq 0 ]; then
                    zenity --warning --text="No locations to remove!" --width=300
                else
                    local to_remove
                    to_remove=$(zenity --list \
                        --title="Remove Location" \
                        --text="Select location to remove:" \
                        --column="Location" \
                        "${LOCATIONS[@]}" \
                        --width=600 --height=400)
                    
                    if [ -n "$to_remove" ]; then
                        local new_array=()
                        for loc in "${LOCATIONS[@]}"; do
                            if [ "$loc" != "$to_remove" ]; then
                                new_array+=("$loc")
                            fi
                        done
                        LOCATIONS=("${new_array[@]}")
                        zenity --info --text="Location removed!\n\nRemaining locations: ${#LOCATIONS[@]}" --width=300
                    fi
                fi
                ;;
            clear)
                if [ ${#LOCATIONS[@]} -gt 0 ]; then
                    if zenity --question --text="Clear all ${#LOCATIONS[@]} location(s)?" --width=300; then
                        LOCATIONS=()
                        zenity --info --text="All locations cleared!" --width=300
                    fi
                fi
                ;;
            back|"")
                break
                ;;
        esac
    done
}

# Configure course names
configure_courses_gui() {
    local courses_text=""
    if [ ${#COURSE_NAMES[@]} -gt 0 ]; then
        courses_text=$(printf "%s\n" "${COURSE_NAMES[@]}")
    fi
    
    local input
    input=$(zenity --text-info \
        --title="Configure Course Names (Optional)" \
        --editable \
        --width=600 --height=400 \
        --ok-label="Save" \
        --cancel-label="Cancel" \
        --filename=<(echo "$courses_text") 2>/dev/null || echo "")
    
    if [ -n "$input" ]; then
        COURSE_NAMES=()
        while IFS= read -r line; do
            line=$(echo "$line" | xargs) # Trim whitespace
            if [ -n "$line" ]; then
                COURSE_NAMES+=("$line")
            fi
        done <<< "$input"
        
        if [ ${#COURSE_NAMES[@]} -gt 0 ]; then
            zenity --info --text="Course names configured!\n\nTotal courses: ${#COURSE_NAMES[@]}" --width=300
        else
            zenity --info --text="No course names set.\n\nStructure will be created directly in selected locations." --width=400
        fi
    fi
}

# Configure options
configure_options_gui() {
    local current_options="Current Settings:\n\n"
    current_options+="• README files: $([ "$CREATE_README" = true ] && echo "Yes" || echo "No")\n"
    current_options+="• .gitignore file: $([ "$CREATE_GITIGNORE" = true ] && echo "Yes" || echo "No")\n"
    current_options+="• Creation log: $([ "$CREATE_LOG" = true ] && echo "Yes" || echo "No")\n"
    current_options+="• Verbose output: $([ "$VERBOSE" = true ] && echo "Yes" || echo "No")\n"
    
    local options
    options=$(zenity --list \
        --title="Configure Options" \
        --text="$current_options\nSelect options to configure:" \
        --checklist \
        --column="Enable" --column="Option" --column="Description" \
        $CREATE_README "readme" "Create README.md in each folder" \
        $CREATE_GITIGNORE "gitignore" "Create .gitignore file" \
        $CREATE_LOG "log" "Generate creation log file" \
        $VERBOSE "verbose" "Show detailed progress" \
        --separator="," \
        --width=600 --height=400)
    
    CREATE_README=false
    CREATE_GITIGNORE=false
    CREATE_LOG=false
    VERBOSE=false
    
    if [ -n "$options" ]; then
        IFS=',' read -ra OPTS <<< "$options"
        for opt in "${OPTS[@]}"; do
            case "$opt" in
                readme) CREATE_README=true ;;
                gitignore) CREATE_GITIGNORE=true ;;
                log) CREATE_LOG=true ;;
                verbose) VERBOSE=true ;;
            esac
        done
    fi
    
    configure_courses_gui
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

---
*Auto-generated by Course Structure Setup Script*
EOF
}

# Create .gitignore file
create_gitignore() {
    local path=$1
    local gitignore_path="$path/.gitignore"
    
    cat > "$gitignore_path" <<EOF
# OS generated files
.DS_Store
Thumbs.db
desktop.ini

# Temporary files
*.tmp
*.temp
~\$*

# Archive
*.zip
*.rar
*.7z

# Personal notes
*private*
*personal*
EOF
}

#############################################################################
# Main Structure Creation
#############################################################################

# Create folder structure
create_structure() {
    if [ ${#LOCATIONS[@]} -eq 0 ]; then
        zenity --error --text="No locations selected!\n\nPlease add at least one location." --width=300
        return 1
    fi
    
    # Initialize log
    if [ "$CREATE_LOG" = true ]; then
        LOG_FILE="/tmp/folder_creation_log_$(date +%Y%m%d_%H%M%S).txt"
        {
            echo "Folder Structure Creation Log"
            echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
            echo "$(printf '=%.0s' {1..80})"
            echo ""
        } > "$LOG_FILE"
    fi
    
    local created_count=0
    local error_count=0
    local start_time=$(date +%s)
    
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
    
    # Create progress function
    update_progress() {
        local percentage=$((current_op * 100 / total_ops))
        echo "$percentage"
        echo "# Creating folders... ($current_op/$total_ops) - $1"
    }
    
    # Main creation loop with progress
    (
        for location in "${LOCATIONS[@]}"; do
            if [ ${#COURSE_NAMES[@]} -eq 0 ]; then
                # Create directly in location
                local base_path="$location"
                
                for folder in "${FOLDERS[@]}"; do
                    local full_path="$base_path/$folder"
                    
                    if mkdir -p "$full_path" 2>/dev/null; then
                        ((created_count++))
                        
                        if [ "$CREATE_README" = true ]; then
                            local folder_name=$(basename "$folder")
                            create_readme "$full_path" "$folder_name" 2>/dev/null || true
                        fi
                        
                        if [ "$CREATE_LOG" = true ]; then
                            echo "Created: $full_path" >> "$LOG_FILE"
                        fi
                        
                        [ "$VERBOSE" = true ] && print_message "$GREEN" "✓ $full_path"
                    else
                        ((error_count++))
                        if [ "$CREATE_LOG" = true ]; then
                            echo "ERROR: Failed to create $full_path" >> "$LOG_FILE"
                        fi
                        [ "$VERBOSE" = true ] && print_message "$RED" "✗ $full_path"
                    fi
                    
                    ((current_op++))
                    update_progress "$full_path"
                done
                
                if [ "$CREATE_GITIGNORE" = true ]; then
                    create_gitignore "$base_path" 2>/dev/null || true
                fi
            else
                # Create in course subfolders
                for course in "${COURSE_NAMES[@]}"; do
                    local base_path="$location/$course"
                    
                    for folder in "${FOLDERS[@]}"; do
                        local full_path="$base_path/$folder"
                        
                        if mkdir -p "$full_path" 2>/dev/null; then
                            ((created_count++))
                            
                            if [ "$CREATE_README" = true ]; then
                                local folder_name=$(basename "$folder")
                                create_readme "$full_path" "$folder_name" 2>/dev/null || true
                            fi
                            
                            if [ "$CREATE_LOG" = true ]; then
                                echo "Created: $full_path" >> "$LOG_FILE"
                            fi
                            
                            [ "$VERBOSE" = true ] && print_message "$GREEN" "✓ $full_path"
                        else
                            ((error_count++))
                            if [ "$CREATE_LOG" = true ]; then
                                echo "ERROR: Failed to create $full_path" >> "$LOG_FILE"
                            fi
                            [ "$VERBOSE" = true ] && print_message "$RED" "✗ $full_path"
                        fi
                        
                        ((current_op++))
                        update_progress "$full_path"
                    done
                    
                    if [ "$CREATE_GITIGNORE" = true ]; then
                        create_gitignore "$base_path" 2>/dev/null || true
                    fi
                done
            fi
        done
        
        echo "100"
        echo "# Complete!"
    ) | zenity --progress \
        --title="Creating Folder Structure" \
        --text="Initializing..." \
        --percentage=0 \
        --width=500 \
        --auto-close
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Finalize log
    if [ "$CREATE_LOG" = true ]; then
        {
            echo ""
            echo "$(printf '=%.0s' {1..80})"
            echo "Summary:"
            echo "Total folders created: $created_count"
            echo "Total errors: $error_count"
            echo "Duration: $duration seconds"
            echo "Completed: $(date '+%Y-%m-%d %H:%M:%S')"
        } >> "$LOG_FILE"
    fi
    
    # Show results
    local result_msg="Successfully created $created_count folders in $duration seconds!"
    
    if [ $error_count -gt 0 ]; then
        result_msg+="\n\nErrors encountered: $error_count"
    fi
    
    if [ "$CREATE_LOG" = true ]; then
        result_msg+="\n\nLog file saved to:\n$LOG_FILE"
    fi
    
    zenity --info --text="$result_msg" --width=400 --title="Creation Complete"
    
    if [ "$CREATE_LOG" = true ]; then
        if zenity --question --text="Would you like to view the log file?" --width=300; then
            xdg-open "$LOG_FILE" 2>/dev/null || cat "$LOG_FILE"
        fi
    fi
}

#############################################################################
# Main Program
#############################################################################

main() {
    check_os
    check_dependencies
    
    print_message "$BLUE" "Academic Course Structure Setup v2.0"
    print_message "$BLUE" "$(printf '=%.0s' {1..50})"
    echo ""
    
    while true; do
        local choice
        choice=$(show_main_gui)
        
        case "$choice" in
            add_locations)
                add_locations_gui
                ;;
            configure_options)
                configure_options_gui
                ;;
            create_structure)
                create_structure
                ;;
            quit|"")
                print_message "$YELLOW" "Exiting..."
                exit 0
                ;;
            *)
                print_message "$RED" "Invalid option"
                ;;
        esac
    done
}

# Run main program
main "$@"