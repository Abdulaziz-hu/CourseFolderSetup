#Requires -Version 5.1
<#
.SYNOPSIS
    Enhanced Academic Course File Structure Setup for Windows
.DESCRIPTION
    Creates organized folder structures for academic courses with advanced features
.NOTES
    Version: 2.0
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Initialize variables
$script:locations = @()
$script:courseNames = @()
$script:createReadme = $false
$script:createGitignore = $false
$script:logFile = $null

# Define the folder structure (unchanged as requested)
$folders = @(
    "01-admin",
    "02-resources/slides", "02-resources/content", "02-resources/whiteboard",
    "03-notes/class_notes","03-notes/reviews",
    "04-assessments/assignments", "04-assessments/projects",
    "05-exams/current/final", "05-exams/current/mid_term", "05-exams/current/other", "05-exams/current/quiz",
    "05-exams/olds/final", "05-exams/olds/mid_term", "05-exams/olds/other", "05-exams/olds/quiz",
    "archive"
)

# Function to create main GUI
function Show-MainGUI {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "File Structure Setup v1.1.0"
    $form.Size = New-Object System.Drawing.Size(600, 550)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

    # Title Label
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Location = New-Object System.Drawing.Point(20, 15)
    $titleLabel.Size = New-Object System.Drawing.Size(560, 30)
    $titleLabel.Text = "Course Folder Structure Creator"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
    $form.Controls.Add($titleLabel)

    # Locations Group
    $locGroup = New-Object System.Windows.Forms.GroupBox
    $locGroup.Location = New-Object System.Drawing.Point(20, 55)
    $locGroup.Size = New-Object System.Drawing.Size(560, 150)
    $locGroup.Text = "Setup Locations"
    $form.Controls.Add($locGroup)

    # Location ListBox
    $locListBox = New-Object System.Windows.Forms.ListBox
    $locListBox.Location = New-Object System.Drawing.Point(10, 25)
    $locListBox.Size = New-Object System.Drawing.Size(420, 110)
    $locGroup.Controls.Add($locListBox)

    # Add Location Button
    $addLocBtn = New-Object System.Windows.Forms.Button
    $addLocBtn.Location = New-Object System.Drawing.Point(440, 25)
    $addLocBtn.Size = New-Object System.Drawing.Size(100, 30)
    $addLocBtn.Text = "Add Location"
    $addLocBtn.Add_Click({
        $browser = New-Object System.Windows.Forms.FolderBrowserDialog
        $browser.Description = "Select a parent folder for course structure"
        $browser.ShowNewFolderButton = $true
        if ($browser.ShowDialog() -eq "OK") {
            if ($locListBox.Items -notcontains $browser.SelectedPath) {
                $locListBox.Items.Add($browser.SelectedPath) | Out-Null
            } else {
                [System.Windows.Forms.MessageBox]::Show("Location already added!", "Duplicate", "OK", "Warning")
            }
        }
    })
    $locGroup.Controls.Add($addLocBtn)

    # Remove Location Button
    $removeLocBtn = New-Object System.Windows.Forms.Button
    $removeLocBtn.Location = New-Object System.Drawing.Point(440, 65)
    $removeLocBtn.Size = New-Object System.Drawing.Size(100, 30)
    $removeLocBtn.Text = "Remove"
    $removeLocBtn.Add_Click({
        if ($locListBox.SelectedIndex -ge 0) {
            $locListBox.Items.RemoveAt($locListBox.SelectedIndex)
        }
    })
    $locGroup.Controls.Add($removeLocBtn)

    # Clear All Button
    $clearLocBtn = New-Object System.Windows.Forms.Button
    $clearLocBtn.Location = New-Object System.Drawing.Point(440, 105)
    $clearLocBtn.Size = New-Object System.Drawing.Size(100, 30)
    $clearLocBtn.Text = "Clear All"
    $clearLocBtn.Add_Click({
        $locListBox.Items.Clear()
    })
    $locGroup.Controls.Add($clearLocBtn)

    # Course Names Group
    $courseGroup = New-Object System.Windows.Forms.GroupBox
    $courseGroup.Location = New-Object System.Drawing.Point(20, 215)
    $courseGroup.Size = New-Object System.Drawing.Size(560, 120)
    $courseGroup.Text = "Course Names (Optional - leave empty to create structure directly in selected locations)"
    $form.Controls.Add($courseGroup)

    # Course Names TextBox
    $courseTextBox = New-Object System.Windows.Forms.TextBox
    $courseTextBox.Location = New-Object System.Drawing.Point(10, 25)
    $courseTextBox.Size = New-Object System.Drawing.Size(540, 60)
    $courseTextBox.Multiline = $true
    $courseTextBox.ScrollBars = "Vertical"
    $courseTextBox.ForeColor = [System.Drawing.Color]::Gray
    $courseTextBox.Text = "Enter course names, one per line (e.g., CS101, MATH201)"
    
    # Add focus events for placeholder behavior
    $courseTextBox.Add_GotFocus({
        if ($this.Text -eq "Enter course names, one per line (e.g., CS101, MATH201)") {
            $this.Text = ""
            $this.ForeColor = [System.Drawing.Color]::Black
        }
    })
    $courseTextBox.Add_LostFocus({
        if ($this.Text -eq "") {
            $this.Text = "Enter course names, one per line (e.g., CS101, MATH201)"
            $this.ForeColor = [System.Drawing.Color]::Gray
        }
    })
    
    $courseGroup.Controls.Add($courseTextBox)

    $courseInfoLabel = New-Object System.Windows.Forms.Label
    $courseInfoLabel.Location = New-Object System.Drawing.Point(10, 90)
    $courseInfoLabel.Size = New-Object System.Drawing.Size(540, 20)
    $courseInfoLabel.Text = "Tip: Each course will be created as a subfolder in each selected location"
    $courseInfoLabel.ForeColor = [System.Drawing.Color]::Gray
    $courseGroup.Controls.Add($courseInfoLabel)

    # Options Group
    $optGroup = New-Object System.Windows.Forms.GroupBox
    $optGroup.Location = New-Object System.Drawing.Point(20, 345)
    $optGroup.Size = New-Object System.Drawing.Size(560, 90)
    $optGroup.Text = "Additional Options"
    $form.Controls.Add($optGroup)

    # README Checkbox
    $readmeCheck = New-Object System.Windows.Forms.CheckBox
    $readmeCheck.Location = New-Object System.Drawing.Point(10, 25)
    $readmeCheck.Size = New-Object System.Drawing.Size(250, 20)
    $readmeCheck.Text = "Create README.md in each folder"
    $optGroup.Controls.Add($readmeCheck)

    # .gitignore Checkbox
    $gitignoreCheck = New-Object System.Windows.Forms.CheckBox
    $gitignoreCheck.Location = New-Object System.Drawing.Point(10, 50)
    $gitignoreCheck.Size = New-Object System.Drawing.Size(250, 20)
    $gitignoreCheck.Text = "Create .gitignore file"
    $optGroup.Controls.Add($gitignoreCheck)

    # Create Log Checkbox
    $logCheck = New-Object System.Windows.Forms.CheckBox
    $logCheck.Location = New-Object System.Drawing.Point(280, 25)
    $logCheck.Size = New-Object System.Drawing.Size(250, 20)
    $logCheck.Text = "Generate creation log"
    $logCheck.Checked = $true
    $optGroup.Controls.Add($logCheck)

    # Progress Bar
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(20, 445)
    $progressBar.Size = New-Object System.Drawing.Size(560, 20)
    $progressBar.Style = "Continuous"
    $form.Controls.Add($progressBar)

    # Create Button
    $createBtn = New-Object System.Windows.Forms.Button
    $createBtn.Location = New-Object System.Drawing.Point(380, 475)
    $createBtn.Size = New-Object System.Drawing.Size(100, 35)
    $createBtn.Text = "Create"
    $createBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $createBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
    $createBtn.ForeColor = [System.Drawing.Color]::White
    $createBtn.FlatStyle = "Flat"
    $createBtn.Add_Click({
        if ($locListBox.Items.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Please add at least one location!", "Error", "OK", "Error")
            return
        }

        $script:locations = @($locListBox.Items)
        
        # Get course names, filtering out placeholder text
        $rawText = $courseTextBox.Text
        if ($rawText -eq "Enter course names, one per line (e.g., CS101, MATH201)") {
            $script:courseNames = @()
        } else {
            $script:courseNames = @($rawText -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
        }
        
        $script:createReadme = $readmeCheck.Checked
        $script:createGitignore = $gitignoreCheck.Checked
        
        if ($logCheck.Checked) {
            $script:logFile = Join-Path $env:TEMP "folder_creation_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        }

        $form.Hide()
        Create-FolderStructure -ProgressBar $progressBar -ParentForm $form
    })
    $form.Controls.Add($createBtn)

    # Cancel Button
    $cancelBtn = New-Object System.Windows.Forms.Button
    $cancelBtn.Location = New-Object System.Drawing.Point(490, 475)
    $cancelBtn.Size = New-Object System.Drawing.Size(90, 35)
    $cancelBtn.Text = "Cancel"
    $cancelBtn.Add_Click({ $form.Close() })
    $form.Controls.Add($cancelBtn)

    $form.ShowDialog() | Out-Null
}

# Function to create folder structure
function Create-FolderStructure {
    param(
        [System.Windows.Forms.ProgressBar]$ProgressBar,
        [System.Windows.Forms.Form]$ParentForm
    )

    $createdFolders = @()
    $errors = @()
    $startTime = Get-Date

    try {
        # Calculate total operations
        $totalOps = 0
        foreach ($location in $script:locations) {
            if ($script:courseNames.Count -eq 0) {
                $totalOps += $folders.Count
            } else {
                $totalOps += $folders.Count * $script:courseNames.Count
            }
        }

        $currentOp = 0
        $ProgressBar.Maximum = $totalOps

        # Log header
        if ($script:logFile) {
            "Folder Structure Creation Log" | Out-File -FilePath $script:logFile
            "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $script:logFile -Append
            "=" * 80 | Out-File -FilePath $script:logFile -Append
        }

        foreach ($location in $script:locations) {
            if ($script:courseNames.Count -eq 0) {
                # Create structure directly in location
                $basePath = $location
                foreach ($folder in $folders) {
                    $fullPath = Join-Path $basePath $folder
                    try {
                        New-Item -Path $fullPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
                        $createdFolders += $fullPath
                        
                        if ($script:createReadme) {
                            Create-ReadmeFile -Path $fullPath -FolderName (Split-Path $folder -Leaf)
                        }
                        
                        if ($script:logFile) {
                            "Created: $fullPath" | Out-File -FilePath $script:logFile -Append
                        }
                    } catch {
                        $errors += "Failed to create $fullPath : $_"
                        if ($script:logFile) {
                            "ERROR: $fullPath - $_" | Out-File -FilePath $script:logFile -Append
                        }
                    }
                    $currentOp++
                    $ProgressBar.Value = $currentOp
                    [System.Windows.Forms.Application]::DoEvents()
                }
                
                if ($script:createGitignore) {
                    Create-GitignoreFile -Path $basePath
                }
            } else {
                # Create structure in course subfolders
                foreach ($course in $script:courseNames) {
                    $basePath = Join-Path $location $course
                    foreach ($folder in $folders) {
                        $fullPath = Join-Path $basePath $folder
                        try {
                            New-Item -Path $fullPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
                            $createdFolders += $fullPath
                            
                            if ($script:createReadme) {
                                Create-ReadmeFile -Path $fullPath -FolderName (Split-Path $folder -Leaf)
                            }
                            
                            if ($script:logFile) {
                                "Created: $fullPath" | Out-File -FilePath $script:logFile -Append
                            }
                        } catch {
                            $errors += "Failed to create $fullPath : $_"
                            if ($script:logFile) {
                                "ERROR: $fullPath - $_" | Out-File -FilePath $script:logFile -Append
                            }
                        }
                        $currentOp++
                        $ProgressBar.Value = $currentOp
                        [System.Windows.Forms.Application]::DoEvents()
                    }
                    
                    if ($script:createGitignore) {
                        Create-GitignoreFile -Path $basePath
                    }
                }
            }
        }

        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds

        # Log summary
        if ($script:logFile) {
            "`n" + "=" * 80 | Out-File -FilePath $script:logFile -Append
            "Summary:" | Out-File -FilePath $script:logFile -Append
            "Total folders created: $($createdFolders.Count)" | Out-File -FilePath $script:logFile -Append
            "Total errors: $($errors.Count)" | Out-File -FilePath $script:logFile -Append
            "Duration: $([math]::Round($duration, 2)) seconds" | Out-File -FilePath $script:logFile -Append
            "Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $script:logFile -Append
        }

        # Show results
        $ParentForm.Show()
        $resultMsg = "Successfully created $($createdFolders.Count) folders in $([math]::Round($duration, 2)) seconds!"
        
        if ($errors.Count -gt 0) {
            $resultMsg += "`n`nErrors encountered: $($errors.Count)"
            $resultMsg += "`n" + ($errors -join "`n")
        }
        
        if ($script:logFile) {
            $resultMsg += "`n`nLog file saved to:`n$script:logFile"
        }

        [System.Windows.Forms.MessageBox]::Show($resultMsg, "Creation Complete", "OK", "Information")
        
        if ($script:logFile -and [System.Windows.Forms.MessageBox]::Show("Would you like to open the log file?", "Open Log", "YesNo", "Question") -eq "Yes") {
            Start-Process notepad.exe $script:logFile
        }

        $ParentForm.Close()

    } catch {
        $ParentForm.Show()
        [System.Windows.Forms.MessageBox]::Show("Critical error: $_", "Error", "OK", "Error")
    }
}

# Function to create README files
function Create-ReadmeFile {
    param(
        [string]$Path,
        [string]$FolderName
    )
    
    $readmePath = Join-Path $Path "README.md"
    $content = @"
# $FolderName

## Purpose
This folder is part of the course organization structure.

## Created
$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

---
*Auto-generated by Course Structure Setup Script*
"@
    
    try {
        $content | Out-File -FilePath $readmePath -Encoding UTF8 -ErrorAction Stop
    } catch {
        # Silently fail if README creation fails
    }
}

# Function to create .gitignore file
function Create-GitignoreFile {
    param([string]$Path)
    
    $gitignorePath = Join-Path $Path ".gitignore"
    $content = @"
# OS generated files
.DS_Store
Thumbs.db
desktop.ini

# Temporary files
*.tmp
*.temp
~$*

# Archive
*.zip
*.rar
*.7z

# Personal notes
*private*
*personal*
"@
    
    try {
        $content | Out-File -FilePath $gitignorePath -Encoding UTF8 -ErrorAction Stop
    } catch {
        # Silently fail if .gitignore creation fails
    }
}

# Main execution
try {
    # Check OS
    if (-not [Environment]::OSVersion.Platform -match "Win32NT") {
        [System.Windows.Forms.MessageBox]::Show("Error: This script is for Windows only.", "Platform Error", "OK", "Error")
        exit 1
    }

    Show-MainGUI

} catch {
    [System.Windows.Forms.MessageBox]::Show("An unexpected error occurred: $_", "Fatal Error", "OK", "Error")
    exit 1
}