#!/usr/bin/env python3
"""
Fix Xcode project by adding all missing Swift files to project.pbxproj
"""
import os
import re
from pathlib import Path

# Project paths
project_root = Path("/Users/khanhnguyen/project/zairyumate/ios/ZairyuMate")
pbxproj_path = project_root / "ZairyuMate.xcodeproj" / "project.pbxproj"
source_root = project_root / "ZairyuMate"

# Read current project file
with open(pbxproj_path, 'r') as f:
    pbxproj_content = f.read()

# Files already in project
existing_files = {
    "ZairyuMateApp.swift",
    "Constants.swift",
    "Extensions.swift",
    "ColorTheme.swift",
    "Typography.swift",
    "Spacing.swift"
}

# Find all Swift files
all_swift_files = []
for swift_file in source_root.rglob("*.swift"):
    rel_path = swift_file.relative_to(source_root)
    filename = swift_file.name

    # Skip if already in project
    if filename in existing_files:
        continue

    # Determine the group path
    parent_parts = list(rel_path.parent.parts)

    all_swift_files.append({
        'filename': filename,
        'rel_path': str(rel_path),
        'group_path': parent_parts,
        'full_path': str(swift_file)
    })

print(f"Found {len(all_swift_files)} missing Swift files to add")

# Generate unique IDs (using sequential IDs starting from A10000050)
id_counter = 50

# Collect PBXFileReference entries
file_references = []
build_files = []
sources_to_add = []

# Group structure mapping
group_mapping = {
    'Models': 'A10000033',
    'Services': 'A10000034',
    'Storage': 'A10000035',
    'Utilities': 'A10000036',
    'Components': 'A10000037',
    'Styles': 'A10000038',
    'Theme': 'A10000039',
    'Home': 'A10000028',
    'Profile': 'A10000029',
    'Documents': 'A10000030',
    'Timeline': 'A10000031',
    'Settings': 'A10000032',
}

# Need to create new groups
new_groups = {}
new_group_counter = 100

for file_info in all_swift_files:
    # Generate IDs
    file_ref_id = f"A100000{id_counter:02d}"
    build_file_id = f"A100000{id_counter+1:02d}"
    id_counter += 2

    filename = file_info['filename']
    rel_path = file_info['rel_path']

    # Create PBXFileReference
    file_ref = f'\t\t{file_ref_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = "<group>"; }};'
    file_references.append(file_ref)

    # Create PBXBuildFile
    build_file = f'\t\t{build_file_id} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {filename} */; }};'
    build_files.append(build_file)

    # Add to sources
    sources_to_add.append(f'\t\t\t\t{build_file_id} /* {filename} in Sources */,')

    # Determine which group this belongs to
    group_path = file_info['group_path']
    if len(group_path) > 0:
        group_name = group_path[-1]  # Last directory name

        # Map to existing group or create new
        if group_name in group_mapping:
            group_id = group_mapping[group_name]
        else:
            # Create new group if needed
            if group_name not in new_groups:
                new_group_id = f"A100001{new_group_counter:02d}"
                new_group_counter += 1
                new_groups[group_name] = {
                    'id': new_group_id,
                    'files': [],
                    'path': group_path
                }
            group_id = new_groups[group_name]['id']
            new_groups[group_name]['files'].append((file_ref_id, filename))
    else:
        # Root level - shouldn't happen but handle it
        group_id = 'A10000020'  # ZairyuMate group

# Now update the pbxproj file
lines = pbxproj_content.split('\n')
new_lines = []

i = 0
while i < len(lines):
    line = lines[i]

    # Add PBXBuildFile entries after line 16
    if i == 16 and build_files:
        for bf in build_files:
            new_lines.append(bf)

    # Add PBXFileReference entries after line 29
    if i == 29 and file_references:
        for fr in file_references:
            new_lines.append(fr)

    # Add sources to PBXSourcesBuildPhase after line 293
    if i == 293 and sources_to_add:
        for src in sources_to_add:
            new_lines.append(src)

    new_lines.append(line)
    i += 1

# Write updated project file
output_content = '\n'.join(new_lines)

# Backup original
backup_path = pbxproj_path.parent / "project.pbxproj.backup"
with open(backup_path, 'w') as f:
    f.write(pbxproj_content)
print(f"Backed up original to {backup_path}")

# Write new version
with open(pbxproj_path, 'w') as f:
    f.write(output_content)

print(f"✅ Added {len(all_swift_files)} Swift files to Xcode project")
print(f"✅ Created {len(build_files)} build file references")
print(f"✅ Updated project.pbxproj")
