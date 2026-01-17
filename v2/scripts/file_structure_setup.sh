#!/bin/bash

# Check OS
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "Error: This script is for Linux only."
    exit 1
fi

# GUI Folder Picker
BASE_DIR=$(zenity --file-selection --directory --title="Select Parent Folder")

if [ -z "$BASE_DIR" ]; then
    exit 1
fi

# Create Folders
folders=(
    "01-admin" 
    "02-resources/slides" "02-resources/content" "02-resources/whiteboard"
    "03-notes/class_notes" "03-notes/reviews"
    "04-assessments/assignments" "04-assessments/projects"
    "05-exams/current/final" "05-exams/current/mid_term" "05-exams/current/other" "05-exams/current/quiz"
    "05-exams/olds/final" "05-exams/olds/mid_term" "05-exams/olds/other" "05-exams/olds/quiz"
    "archive"
)

for f in "${folders[@]}"; do
    mkdir -p "$BASE_DIR/$f"
done

zenity --info --text="File structure created successfully at: $BASE_DIR"