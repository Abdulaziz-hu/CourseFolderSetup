# File Structure Notes

## Folder Map

```bash
01-admin/
- Syllabus.pdf
- Schedule_and_Deadlines
- Instructor_Contact

02-resources/
- slides/ (ordered by chapters)
- content/ (Textbook, PDFs, articles)
- whiteboard/ (Whiteboard photos, lecture recordings, etc.)

03-notes/
- class_notes/ (Raw notes from lectures)
- reviews/ (Summaries and "Review" sheets)

04-assessments/
- assignments/ (Folder for each: HW01, HW02, etc.)
- projects/ (Research papers or group work)

05-exams/
- current (exams that I have taken already)
    - final/
    - mid_term/
    - other/
    - quiz/
- olds/ (Past papers, "Old" quizzes, practice questions, etc)
    - final/
    - mid_term/
    - other/
    - quiz/

archive/
```

*There's a script abialable for Windows 11 and linux for automatically creating the file strcuture for you.*

## Naming Scheme

use underscores for space (_) and dashes (-) between numbers

- **naming files:** (`YYYYMMDD-file_name.txt`)
- **example:** `20261217-file_structure_notes.txt`

## Script Instructions

- **Windows 11 (file_structure_setup.ps1):**
    - Save the code as `file_structure_setup.ps1`.
    - Right-click the file and select **Run with PowerShell**.

- **Linux (file_structure_setup.sh):**
    - Save the code as `file_structure_setup.sh`.
    - Make it executable (using the terminal, ensure you are in same direcorty as the script, then use the following command): `chmod +x file_structure_setup.sh`.
    - Run it: `./file_structure_setup.sh`.