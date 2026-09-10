import os
import sys
import subprocess
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
from datetime import datetime

FOLDER_DESCRIPTIONS = {
    "01-admin": "Contains administrative documents, course syllabi, schedules, contact information for instructors/TAs, and important logistical guidelines.",
    "02-resources/slides": "Stores lecture slides, presentation decks, and visual handouts shared during classes or seminars.",
    "02-resources/content": "Houses supplementary reading materials, textbooks, articles, code samples, and reference documentation.",
    "02-resources/whiteboard": "Keeps exported whiteboard notes, screenshots taken during lectures, or handwritten lecture captures.",
    "03-notes/class_notes": "Dedicated space for personal or collaborative notes taken live during class sessions.",
    "03-notes/reviews": "Contains curated study guides, chapter summaries, exam review sheets, and concept checklists.",
    "04-assessments/assignments": "Stores homework assignments, problem sets, practical tasks, and submission check-ins.",
    "04-assessments/projects": "Houses major term projects, milestones, group work deliverables, source code, and final presentations.",
    "05-exams/current/final": "Reserved for study preparation materials, practice papers, and final exam details for the active term.",
    "05-exams/current/mid_term": "Contains mid-term exam papers, preparation guides, and grading rubrics for the active term.",
    "05-exams/current/other": "Holds quizzes, pop-tests, diagnostic quizzes, or unclassified assessments for the current term.",
    "05-exams/current/quiz": "Stores weekly or module-based quizzes and knowledge checks for the active term.",
    "05-exams/olds/final": "Archives past semesters' final exams and historical answer keys for exam practice.",
    "05-exams/olds/mid_term": "Archives previous semesters' mid-term exam sheets and historical grading criteria.",
    "05-exams/olds/other": "Stores old diagnostic tests, placement exams, and legacy quiz materials.",
    "05-exams/olds/quiz": "Maintains a library of past quizzes from previous terms for revision purposes.",
    "archive": "Long-term storage for legacy notes, deprecated assignments, and completed semester materials no longer actively in use."
}

FOLDERS = list(FOLDER_DESCRIPTIONS.keys())

class CourseSetupApp:
    def __init__(self, root):
        self.root = root
        self.root.title("File Structure Setup v1.1.0")
        self.root.geometry("640x610")
        self.root.minsize(640, 610)

        try:
            if os.name == "nt":
                import ctypes
                ctypes.windll.shcore.SetProcessDpiAwareness(2)
            self.root.tk.call('tk', 'scaling', 1.3)
        except Exception:
            pass

        self.style = ttk.Style()
        if "clam" in self.style.theme_names():
            self.style.theme_use("clam")

        default_font = ("Segoe UI", 10 if os.name == "nt" else 11)
        self.style.configure(".", font=default_font)

        main_container = ttk.Frame(root, padding=12)
        main_container.pack(fill=tk.BOTH, expand=True)

        title_label = ttk.Label(
            main_container, 
            text="Course Folder Structure Creator", 
            font=("Segoe UI", 13, "bold"), 
            foreground="#0078d7"
        )
        title_label.pack(anchor="w", pady=(0, 8))

        loc_frame = ttk.LabelFrame(main_container, text="Setup Locations", padding=10)
        loc_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 8))

        self.loc_listbox = tk.Listbox(loc_frame, height=4, selectmode=tk.SINGLE, bd=1, relief="solid", exportselection=False)
        self.loc_listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=(0, 8))

        loc_btn_frame = ttk.Frame(loc_frame)
        loc_btn_frame.pack(side=tk.RIGHT, fill=tk.Y)

        ttk.Button(loc_btn_frame, text="Add Location", command=self.add_location, width=12).pack(fill=tk.X, pady=2)
        ttk.Button(loc_btn_frame, text="Remove", command=self.remove_location, width=12).pack(fill=tk.X, pady=2)
        ttk.Button(loc_btn_frame, text="Clear All", command=self.clear_locations, width=12).pack(fill=tk.X, pady=2)

        course_frame = ttk.LabelFrame(main_container, text="Course Names (Optional - leave empty to create directly)", padding=10)
        course_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 8))

        self.course_text = tk.Text(course_frame, height=3, fg="gray", font=default_font, bd=1, relief="solid")
        self.course_text.pack(fill=tk.BOTH, expand=True)
        self.placeholder = "Enter course names, one per line (e.g., CS101, MATH201)"
        self.course_text.insert("1.0", self.placeholder)
        self.course_text.bind("<FocusIn>", self.clear_placeholder)
        self.course_text.bind("<FocusOut>", self.restore_placeholder)

        opt_frame = ttk.LabelFrame(main_container, text="Additional Options", padding=10)
        opt_frame.pack(fill=tk.X, pady=(0, 8))

        self.readme_var = tk.BooleanVar(value=False)
        self.gitignore_var = tk.BooleanVar(value=False)
        self.log_var = tk.BooleanVar(value=False)
        self.open_folder_var = tk.BooleanVar(value=False)

        ttk.Checkbutton(opt_frame, text="Create README.md in each folder", variable=self.readme_var).grid(row=0, column=0, sticky="w", padx=5, pady=3)
        ttk.Checkbutton(opt_frame, text="Generate creation log", variable=self.log_var).grid(row=0, column=1, sticky="w", padx=25, pady=3)
        ttk.Checkbutton(opt_frame, text="Create .gitignore file", variable=self.gitignore_var).grid(row=1, column=0, sticky="w", padx=5, pady=3)
        ttk.Checkbutton(opt_frame, text="Open folder when finished", variable=self.open_folder_var).grid(row=1, column=1, sticky="w", padx=25, pady=3)

        self.progress = ttk.Progressbar(main_container, orient="horizontal", mode="determinate")
        self.progress.pack(fill=tk.X, pady=(4, 10))

        btn_frame = ttk.Frame(main_container)
        btn_frame.pack(fill=tk.X, pady=(0, 2))

        cancel_btn = ttk.Button(btn_frame, text="Cancel", command=root.quit, width=10)
        cancel_btn.pack(side=tk.RIGHT, padx=2)

        create_btn = ttk.Button(btn_frame, text="Create", command=self.create_structure, width=10)
        create_btn.pack(side=tk.RIGHT, padx=5)

    def clear_placeholder(self, event):
        if self.course_text.get("1.0", tk.END).strip() == self.placeholder:
            self.course_text.delete("1.0", tk.END)
            self.course_text.config(fg="black")

    def restore_placeholder(self, event):
        if not self.course_text.get("1.0", tk.END).strip():
            self.course_text.insert("1.0", self.placeholder)
            self.course_text.config(fg="gray")

    def add_location(self):
        folder = filedialog.askdirectory(title="Select Parent Folder", mustexist=True)
        if folder and folder not in self.loc_listbox.get(0, tk.END):
            self.loc_listbox.insert(tk.END, folder)

    def remove_location(self):
        selected = self.loc_listbox.curselection()
        if selected:
            self.loc_listbox.delete(selected)

    def clear_locations(self):
        self.loc_listbox.delete(0, tk.END)

    def open_path_in_native_explorer(self, path):
        try:
            if os.name == "nt":
                os.startfile(path)
            elif sys.platform == "darwin":
                subprocess.run(["open", path])
            else:
                subprocess.run(["xdg-open", path])
        except Exception:
            pass

    def create_structure(self):
        locations = self.loc_listbox.get(0, tk.END)
        if not locations:
            messagebox.showerror("Error", "Please add at least one location!")
            return

        raw_courses = self.course_text.get("1.0", tk.END).strip()
        if raw_courses == self.placeholder:
            courses = []
        else:
            courses = [c.strip() for c in raw_courses.split("\n") if c.strip()]

        create_readme = self.readme_var.get()
        create_gitignore = self.gitignore_var.get()
        generate_log = self.log_var.get()
        open_folder = self.open_folder_var.get()

        log_path = None
        if generate_log:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            log_path = os.path.join(os.environ.get("TEMP", "/tmp"), f"folder_creation_log_{timestamp}.txt")

        total_ops = sum(len(FOLDERS) * (len(courses) if courses else 1) for _ in locations)
        if create_readme:
            total_ops += sum((len(courses) if courses else 1) for _ in locations)

        current_op = 0
        created_count = 0
        errors = []

        log_file = open(log_path, "w", encoding="utf-8") if log_path else None
        if log_file:
            log_file.write(f"Folder Structure Creation Log\nStarted: {datetime.now()}\n" + "="*80 + "\n")

        self.progress["maximum"] = total_ops if total_ops > 0 else 1
        self.progress["value"] = 0

        first_location_to_open = None
        for location in locations:
            if not first_location_to_open:
                first_location_to_open = location

            target_bases = [os.path.join(location, c) for c in courses] if courses else [location]
            for base_path in target_bases:
                if create_readme:
                    try:
                        self.write_root_readme(base_path)
                        if log_file:
                            log_file.write(f"Created: {os.path.join(base_path, 'README.md')}\n")
                    except Exception as e:
                        errors.append(f"Failed root README in {base_path}: {e}")
                    current_op += 1
                    self.progress["value"] = current_op
                    self.root.update_idletasks()

                for folder in FOLDERS:
                    # Fix nested paths (like 02-resources/slides) safely using os.path.split or normpath
                    parts = folder.split("/")
                    full_path = os.path.join(base_path, *parts)
                    try:
                        os.makedirs(full_path, exist_ok=True)
                        created_count += 1
                        if create_readme:
                            self.write_sub_readme(full_path, folder)
                        if log_file:
                            log_file.write(f"Created: {full_path}\n")
                    except Exception as e:
                        errors.append(f"Failed {full_path}: {e}")
                        if log_file:
                            log_file.write(f"ERROR: {full_path} - {e}\n")

                    current_op += 1
                    self.progress["value"] = current_op
                    self.root.update_idletasks()

                if create_gitignore:
                    self.write_gitignore(base_path)

        if log_file:
            log_file.write("\n" + "="*80 + f"\nSummary: Created {created_count}, Errors: {len(errors)}\n")
            log_file.close()

        msg = f"Successfully created {created_count} folders!"
        if errors:
            msg += f"\nErrors: {len(errors)}"
        if log_path:
            msg += f"\n\nLog saved to:\n{log_path}"
        messagebox.showinfo("Creation Complete", msg)

        # Open the main parent folder rather than the last nested child subfolder
        if open_folder and first_location_to_open and os.path.exists(first_location_to_open):
            self.open_path_in_native_explorer(first_location_to_open)

    def write_root_readme(self, path):
        readme_path = os.path.join(path, "README.md")
        content = (
            "# Course Directory Guide\n\n"
            "Welcome to your structured course workspace! This standardized system is engineered to help you stay organized, "
            "keep track of learning materials, and manage assessments smoothly throughout your academic term.\n\n"
            "## Directory Architecture Overview\n"
            "- **01-admin/**: Logistical records, official course outlines, schedules, and instructor communication details.\n"
            "- **02-resources/**: Reference materials split across slides (`slides/`), readings (`content/`), and whiteboard captures (`whiteboard/`).\n"
            "- **03-notes/**: Your active class tracking (`class_notes/`) and curated review guides (`reviews/`).\n"
            "- **04-assessments/**: Ongoing coursework including homework assignments (`assignments/`) and major group or individual projects (`projects/`).\n"
            "- **05-exams/**: Dedicated space separated into current term milestones (`current/`) and archived past papers (`olds/`).\n"
            "- **archive/**: Long-term archival storage for legacy or completed items.\n\n"
            "## Best Practices for Usage\n"
            "1. **Keep Files Categorized**: Store downloaded files directly in their respective category folders instead of cluttering the root path.\n"
            "2. **Leverage Sub-READMEs**: Every subfolder contains its own detailed context guide explaining its specific purpose.\n"
            "3. **Regular Backups**: Sync this directory with cloud solutions (like Git, OneDrive, or Google Drive) for data safety.\n\n"
            f"*Initialized on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}*\n"
        )
        with open(readme_path, "w", encoding="utf-8") as f:
            f.write(content)

    def write_sub_readme(self, path, folder_key):
        readme_path = os.path.join(path, "README.md")
        folder_name = os.path.basename(path)
        description = FOLDER_DESCRIPTIONS.get(folder_key, "This folder is part of the course organization structure.")
        
        content = (
            f"# {folder_name}\n\n"
            f"## Purpose & Description\n"
            f"{description}\n\n"
            "## Recommended Usage Guidelines\n"
            "- Save relevant files and notes directly here as you progress through the course content.\n"
            "- Keep naming conventions compatible (e.g., prefixing files with dates or task numbers like `01_intro.pdf`).\n"
            "- Review contents periodically and shift old elements into the `archive` folder if needed.\n\n"
            f"## Created\n"
            f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
        )
        with open(readme_path, "w", encoding="utf-8") as f:
            f.write(content)

    def write_gitignore(self, path):
        gitignore_path = os.path.join(path, ".gitignore")
        content = "# OS generated files\n.DS_Store\nThumbs.db\ndesktop.ini\n\n# Temporary files\n*.tmp\n*.temp\n"
        with open(gitignore_path, "w", encoding="utf-8") as f:
            f.write(content)

if __name__ == "__main__":
    root = tk.Tk()
    app = CourseSetupApp(root)
    root.mainloop()