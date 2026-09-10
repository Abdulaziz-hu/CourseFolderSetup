# Course Structure Setup (Python)

### Quick Start Instructions

1. **Clone or Download** this repository/folder containing `app.py`.
2. **Open a terminal/command prompt** inside the project folder.
3. **Create and Activate a Virtual Environment** (Optional but recommended):
   ```bash
   python -m venv .venv
   # On Windows:
   .venv\Scripts\activate
   # On macOS/Linux:
   source .venv/bin/activate
   ```
1. Install Requirements:
    ```bash
    pip install -r requirements.txt
    ```
2. Run the Application:
    ```bash
    python app.py
    ```
3. Build the app:
    ```bash
    pyinstaller --onedir --noconsole --name="CourseFolderSetup" app.py
    ```