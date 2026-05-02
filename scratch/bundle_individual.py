import os
import json

SOURCE_DIR = r"c:\Users\nomaa\Downloads\devsim_mobile\web_projects_source"
OUTPUT_DIR = r"c:\Users\nomaa\Downloads\devsim_mobile\assets\projects"

def bundle_projects_individual():
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        
    projects = [d for d in os.listdir(SOURCE_DIR) if os.path.isdir(os.path.join(SOURCE_DIR, d)) and not d.startswith('.')]
    
    print(f"Bundling {len(projects)} projects individually...")
    
    for project in projects:
        project_path = os.path.join(SOURCE_DIR, project)
        project_data = {}
        
        for root, dirs, files in os.walk(project_path):
            for file in files:
                if file.startswith('.'): continue
                
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, project_path)
                
                try:
                    with open(full_path, 'r', encoding='utf-8', errors='ignore') as f:
                        project_data[rel_path] = f.read()
                except Exception as e:
                    print(f"Skipping {full_path}: {e}")
        
        # Save as individual JSON
        output_file = os.path.join(OUTPUT_DIR, f"{project}.json")
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(project_data, f)
            
    print(f"Success! Individual bundles created in {OUTPUT_DIR}")

if __name__ == "__main__":
    bundle_projects_individual()
