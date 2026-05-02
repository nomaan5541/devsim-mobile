import os
import json

SOURCE_DIR = r"c:\Users\nomaa\Downloads\devsim_mobile\web_projects_source"
OUTPUT_FILE = r"c:\Users\nomaa\Downloads\devsim_mobile\assets\projects_bundle.json"

def bundle_projects():
    bundle = {}
    projects = [d for d in os.listdir(SOURCE_DIR) if os.path.isdir(os.path.join(SOURCE_DIR, d)) and not d.startswith('.')]
    
    print(f"Bundling {len(projects)} projects...")
    
    for project in projects:
        project_path = os.path.join(SOURCE_DIR, project)
        bundle[project] = {}
        
        for root, dirs, files in os.walk(project_path):
            for file in files:
                if file.startswith('.'): continue
                
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, project_path)
                
                try:
                    with open(full_path, 'r', encoding='utf-8', errors='ignore') as f:
                        bundle[project][rel_path] = f.read()
                except Exception as e:
                    print(f"Skipping {full_path}: {e}")
                    
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(bundle, f)
        
    print(f"Success! Bundle created at {OUTPUT_FILE}")

if __name__ == "__main__":
    bundle_projects()
