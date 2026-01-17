Add-Type -AssemblyName System.Windows.Forms
$info = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)

# Check OS
if (-not [Environment]::OSVersion.Platform -match "Win32NT") {
    [System.Windows.Forms.MessageBox]::Show("Error: This script is for Windows only.")
    exit
}

# GUI Folder Picker
$browser = New-Object System.Windows.Forms.FolderBrowserDialog
$browser.Description = "Select the parent folder where your course folders will be created"
if ($browser.ShowDialog() -ne "OK") { exit }
$base = $browser.SelectedPath

# Create Folders
$folders = @(
    "01-admin", "02-resources/slides", "02-resources/content", "02-resources/whiteboard",
    "03-notes/class_notes", "03-notes/reviews", "04-assessments/assignments", "04-assessments/projects",
    "05-exams/current/final", "05-exams/current/mid_term", "05-exams/current/other", "05-exams/current/quiz",
    "05-exams/olds/final", "05-exams/olds/mid_term", "05-exams/olds/other", "05-exams/olds/quiz",
    "archive"
)

foreach ($f in $folders) {
    New-Item -Path (Join-Path $base $f) -ItemType Directory -Force
}

[System.Windows.Forms.MessageBox]::Show("File structure created successfully at: $base")