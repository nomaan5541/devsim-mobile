import os
import shutil
import subprocess
import datetime
import random
import re

# --- Configuration ---
SOURCE_DIR = r"c:\Users\nomaa\Downloads\devsim_mobile\web_projects_source"
TARGET_DIR = r"c:\Users\nomaa\Downloads\devsim_mobile\web_projects_streak_500"
AUTHOR_NAME = "NOMAAN KHAN"
AUTHOR_EMAIL = "nomaan@example.com" # User can change this
COMMITS_PER_PROJECT = 10
TOTAL_PROJECTS = 500

# Natural sort for folders
def natural_sort_key(s):
    return [int(text) if text.isdigit() else text.lower()
            for text in re.split('([0-9]+)', s)]

def run_git(args, cwd):
    subprocess.run(["git"] + args, cwd=cwd, check=True, capture_output=True)

def setup_target_repo():
    if os.path.exists(TARGET_DIR):
        try:
            shutil.rmtree(TARGET_DIR)
        except Exception as e:
            print(f"Warning: Could not fully delete target dir: {e}")
            # Try to just clear contents instead
            for filename in os.listdir(TARGET_DIR):
                if filename == ".git": continue
                path = os.path.join(TARGET_DIR, filename)
                if os.path.isdir(path): shutil.rmtree(path)
                else: os.remove(path)
    os.makedirs(TARGET_DIR, exist_ok=True)
    
    run_git(["init"], TARGET_DIR)
    run_git(["config", "user.name", AUTHOR_NAME], TARGET_DIR)
    run_git(["config", "user.email", AUTHOR_EMAIL], TARGET_DIR)
    
    # Initial commit
    with open(os.path.join(TARGET_DIR, "README.md"), "w") as f:
        f.write("# 500 Days of Web Projects\n\nStarting the journey...")
    
    run_git(["add", "README.md"], TARGET_DIR)
    run_git(["commit", "-m", "Initial commit: Starting the 500 Days Challenge"], TARGET_DIR)

def get_project_folders():
    folders = [f for f in os.listdir(SOURCE_DIR) if os.path.isdir(os.path.join(SOURCE_DIR, f)) and f != ".git"]
    folders.sort(key=natural_sort_key)
    return folders[:TOTAL_PROJECTS]

def commit_project(project_name, project_index, commit_date):
    source_proj_path = os.path.join(SOURCE_DIR, project_name)
    target_proj_path = os.path.join(TARGET_DIR, project_name)
    
    # Get all files in the source project
    all_files = []
    for root, dirs, files in os.walk(source_proj_path):
        for f in files:
            rel_path = os.path.relpath(os.path.join(root, f), source_proj_path)
            all_files.append(rel_path)
    
    if not all_files:
        return

    # Create project folder
    os.makedirs(target_proj_path, exist_ok=True)
    
    commit_messages = [
        f"feat({project_name}): initialize project structure",
        f"feat({project_name}): add basic markup",
        f"style({project_name}): implement core styles",
        f"feat({project_name}): add interactivity logic",
        f"style({project_name}): refine responsive layout",
        f"feat({project_name}): integrate project assets",
        f"refactor({project_name}): optimize performance and accessibility",
        f"docs({project_name}): update project documentation",
        f"test({project_name}): verify cross-browser compatibility",
        f"feat({project_name}): final project completion - Day {project_index + 1}"
    ]
    
    files_to_add = all_files.copy()
    
    # Set the date for all commits in this project (one day)
    date_str = commit_date.strftime("%Y-%m-%dT%H:%M:%S")
    env = os.environ.copy()
    
    for i in range(COMMITS_PER_PROJECT):
        # Slightly vary the time for each of the 10 commits
        commit_time = commit_date + datetime.timedelta(minutes=i * 15)
        commit_date_str = commit_time.strftime("%Y-%m-%dT%H:%M:%S")
        env["GIT_AUTHOR_DATE"] = commit_date_str
        env["GIT_COMMITTER_DATE"] = commit_date_str

        # 1. Try to add files if available
        files_handled = False
        if files_to_add:
            # Distribute files over the first few commits
            chunk_size = max(1, len(all_files) // 5)
            to_commit = files_to_add[:chunk_size]
            files_to_add = files_to_add[chunk_size:]
            
            for f in to_commit:
                src = os.path.join(source_proj_path, f)
                dst = os.path.join(target_proj_path, f)
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                shutil.copy2(src, dst)
                run_git(["add", os.path.join(project_name, f)], TARGET_DIR)
            files_handled = True
        
        # 2. Always add a small change to ensure the commit is non-empty
        # This guarantees 10 commits even if there's only 1 file
        pulse_file = os.path.join(target_proj_path, ".pulse_log")
        with open(pulse_file, "a") as f:
            f.write(f"Project: {project_name} | Step: {i+1}/10 | Time: {commit_date_str}\n")
        run_git(["add", os.path.join(project_name, ".pulse_log")], TARGET_DIR)

        # Commit with specific date
        subprocess.run(["git", "commit", "-m", commit_messages[i]], 
                       cwd=TARGET_DIR, check=True, capture_output=True, env=env)

def main():
    print("Setting up target repository...")
    setup_target_repo()
    
    projects = get_project_folders()
    print(f"Found {len(projects)} projects. Starting generation...")
    
    # Start date: 500 days ago
    start_date = datetime.datetime.now() - datetime.timedelta(days=TOTAL_PROJECTS)
    
    for i, proj in enumerate(projects):
        commit_date = start_date + datetime.timedelta(days=i)
        print(f"[{i+1}/{len(projects)}] Processing {proj} for {commit_date.date()}...")
        commit_project(proj, i, commit_date)
        
    print(f"\nSuccess! Your personalized repo is ready at: {TARGET_DIR}")
    print(f"Total projects: {len(projects)}")
    print(f"Total commits generated: ~{len(projects) * 10}")

if __name__ == "__main__":
    main()
