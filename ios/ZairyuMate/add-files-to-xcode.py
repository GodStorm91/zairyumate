#!/usr/bin/env python3
"""
Add all missing Swift files and CoreData models to Xcode project
This script properly handles the pbxproj format including groups
"""
import os
import hashlib
from pathlib import Path
from collections import defaultdict

def generate_uuid():
    """Generate a unique 24-character hex ID for Xcode"""
    import random
    import string
    return ''.join(random.choices(string.hexdigits.upper()[:16], k=24))

# Project paths
project_root = Path("/Users/khanhnguyen/project/zairyumate/ios/ZairyuMate")
pbxproj_path = project_root / "ZairyuMate.xcodeproj" / "project.pbxproj"
source_root = project_root / "ZairyuMate"

print("Reading project file...")
with open(pbxproj_path, 'r') as f:
    original_content = f.read()

# Files already in project (from analysis)
existing_files = {
    "ZairyuMateApp.swift",
    "Constants.swift",
    "Extensions.swift",
    "ColorTheme.swift",
    "Typography.swift",
    "Spacing.swift",
    "Assets.xcassets"
}

# Collect all files to add
files_to_add = []
groups_needed = defaultdict(list)

print("Scanning for Swift files...")
for swift_file in sorted(source_root.rglob("*.swift")):
    filename = swift_file.name
    if filename in existing_files:
        continue

    rel_path = swift_file.relative_to(source_root)
    parent_path = str(rel_path.parent) if rel_path.parent != Path('.') else ""

    files_to_add.append({
        'name': filename,
        'path': filename,  # Just filename, group handles directory
        'parent': parent_path,
        'type': 'sourcecode.swift'
    })

    if parent_path:
        groups_needed[parent_path].append(filename)

print(f"Found {len(files_to_add)} Swift files to add")

# Add CoreData model
coredata_path = source_root / "Core/Storage/ZairyuMateDataModel.xcdatamodeld"
if coredata_path.exists():
    files_to_add.append({
        'name': 'ZairyuMateDataModel.xcdatamodeld',
        'path': 'ZairyuMateDataModel.xcdatamodeld',
        'parent': 'Core/Storage',
        'type': 'wrapper.xcdatamodeld'
    })
    print("Added CoreData model")

# Generate IDs and entries
file_refs = []
build_files = []
group_children = defaultdict(list)

for file_info in files_to_add:
    file_uuid = generate_uuid()
    build_uuid = generate_uuid()

    name = file_info['name']
    path = file_info['path']
    file_type = file_info['type']

    # PBXFileReference
    file_refs.append(
        f'\t\t{file_uuid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type}; path = {path}; sourceTree = "<group>"; }};'
    )

    # PBXBuildFile (only for source files)
    if file_type == 'sourcecode.swift':
        build_files.append(
            f'\t\t{build_uuid} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_uuid} /* {name} */; }};'
        )

        # Track for sources phase
        group_children['SOURCES'].append((build_uuid, name))

    # Track for group
    parent = file_info['parent']
    if parent:
        group_children[parent].append((file_uuid, name))

print(f"Generated {len(file_refs)} file references")
print(f"Generated {len(build_files)} build file entries")

# Now reconstruct the pbxproj file
lines = original_content.split('\n')
new_lines = []

# State tracking
in_buildfile_section = False
in_fileref_section = False
in_sources_phase = False
in_group_section = False
current_group = None

for i, line in enumerate(lines):
    # Detect sections
    if '/* Begin PBXBuildFile section */' in line:
        in_buildfile_section = True
        new_lines.append(line)
        # Add all build files
        for bf in build_files:
            new_lines.append(bf)
        continue

    if '/* End PBXBuildFile section */' in line:
        in_buildfile_section = False

    if '/* Begin PBXFileReference section */' in line:
        in_fileref_section = True
        new_lines.append(line)
        # Add all file references
        for fr in file_refs:
            new_lines.append(fr)
        continue

    if '/* End PBXFileReference section */' in line:
        in_fileref_section = False

    if '/* Begin PBXSourcesBuildPhase section */' in line:
        in_sources_phase = True

    if '/* End PBXSourcesBuildPhase section */' in line:
        in_sources_phase = False

    # In sources phase, add our files before the closing );
    if in_sources_phase and 'files = (' in line:
        new_lines.append(line)
        # Add all source files
        for uuid, name in group_children['SOURCES']:
            new_lines.append(f'\t\t\t\t{uuid} /* {name} in Sources */,')
        continue

    # Add to group sections
    if 'A10000033 /* Models */' in line and 'isa = PBXGroup' in line:
        # Add Models files
        new_lines.append(line)
        if i + 1 < len(lines) and 'children = (' in lines[i + 1]:
            new_lines.append(lines[i + 1])
            i += 1
            # Add model files
            for uuid, name in group_children.get('Core/Models', []):
                new_lines.append(f'\t\t\t\t{uuid} /* {name} */,')
            continue

    if 'A10000034 /* Services */' in line and 'isa = PBXGroup' in line:
        new_lines.append(line)
        if i + 1 < len(lines) and 'children = (' in lines[i + 1]:
            new_lines.append(lines[i + 1])
            i += 1
            for uuid, name in group_children.get('Core/Services', []):
                new_lines.append(f'\t\t\t\t{uuid} /* {name} */,')
            continue

    if 'A10000035 /* Storage */' in line and 'isa = PBXGroup' in line:
        new_lines.append(line)
        if i + 1 < len(lines) and 'children = (' in lines[i + 1]:
            new_lines.append(lines[i + 1])
            i += 1
            for uuid, name in group_children.get('Core/Storage', []):
                new_lines.append(f'\t\t\t\t{uuid} /* {name} */,')
            continue

    if 'A10000036 /* Utilities */' in line and 'isa = PBXGroup' in line:
        new_lines.append(line)
        if i + 1 < len(lines) and 'children = (' in lines[i + 1]:
            new_lines.append(lines[i + 1])
            i += 1
            for uuid, name in group_children.get('Core/Utilities', []):
                new_lines.append(f'\t\t\t\t{uuid} /* {name} */,')
            continue

    # Add more group handling as needed...
    new_lines.append(line)

# Write backup
backup_path = pbxproj_path.parent / "project.pbxproj.backup"
with open(backup_path, 'w') as f:
    f.write(original_content)
print(f"✅ Backed up original to {backup_path}")

# Write updated project
output = '\n'.join(new_lines)
with open(pbxproj_path, 'w') as f:
    f.write(output)

print(f"✅ Updated project.pbxproj with {len(files_to_add)} files")
print("\nNext: Run xcodebuild to verify the build")
