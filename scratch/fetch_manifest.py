import requests
import os
import json
import base64
import time

# Configuration
REPO_OWNER = "codetap-org"
REPO_NAME = "web-projects"
BRANCH = "main"

def get_folders():
    url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/contents?ref={BRANCH}"
    response = requests.get(url)
    if response.status_code != 200:
        print(f"Error fetching folders: {response.status_code}")
        return []
    
    items = response.json()
    folders = [item for item in items if item['type'] == 'dir']
    # Sort folders by name (assuming format like 01-xxx, 10-xxx, 100-xxx)
    # Natural sort for numbers
    import re
    def natural_sort_key(s):
        return [int(text) if text.isdigit() else text.lower()
                for text in re.split('([0-9]+)', s['name'])]
    
    folders.sort(key=natural_sort_key)
    return folders

def get_folder_contents(path):
    url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/contents/{path}?ref={BRANCH}"
    response = requests.get(url)
    if response.status_code != 200:
        print(f"Error fetching contents for {path}: {response.status_code}")
        return []
    return response.json()

def download_project(folder_name, folder_path):
    print(f"Processing project: {folder_name}")
    contents = get_folder_contents(folder_path)
    project_files = {}
    
    for item in contents:
        if item['type'] == 'file':
            # Fetch file content
            file_response = requests.get(item['download_url'])
            if file_response.status_code == 200:
                project_files[item['name']] = file_response.text
        elif item['type'] == 'dir':
            # Recursive fetch (limited depth for simplicity)
            sub_contents = get_folder_contents(item['path'])
            for sub_item in sub_contents:
                if sub_item['type'] == 'file':
                    sub_file_response = requests.get(sub_item['download_url'])
                    if sub_file_response.status_code == 200:
                        project_files[f"{item['name']}/{sub_item['name']}"] = sub_file_response.text
    
    return project_files

def main():
    folders = get_folders()
    print(f"Found {len(folders)} folders.")
    
    # We don't want to download all 500 at once in this script for the user (might hit API limits)
    # But let's create a manifest first.
    manifest = []
    for i, folder in enumerate(folders):
        manifest.append({
            "day": i + 1,
            "name": folder['name'],
            "path": folder['path']
        })
    
    with open("web_projects_manifest.json", "w") as f:
        json.dump(manifest, f, indent=2)
    
    print("Manifest saved to web_projects_manifest.json")

if __name__ == "__main__":
    main()
