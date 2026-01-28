#!/usr/bin/env python3
"""
Comprehensively fix the Xcode project by adding all missing Swift files.
Uses a reliable string manipulation approach with proper pbxproj format.
"""

import re
from pathlib import Path
from datetime import datetime

def generate_xcode_id(counter):
    """Generate Xcode-style 24-char hex ID"""
    # Use a predictable but unique pattern
    base = f"FILE{counter:08d}"
    # Pad to 24 chars
    return (base + "0" * 24)[:24].upper()

# Paths
project_root = Path("/Users/khanhnguyen/project/zairyumate/ios/ZairyuMate")
pbxproj_file = project_root / "ZairyuMate.xcodeproj" / "project.pbxproj"
source_dir = project_root / "ZairyuMate"

print("=" * 60)
print("XCODE PROJECT FIXER")
print("=" * 60)

# Read original
with open(pbxproj_file, 'r') as f:
    content = f.read()

# Backup
backup_file = pbxproj_file.with_suffix('.pbxproj.backup.' + datetime.now().strftime('%Y%m%d_%H%M%S'))
with open(backup_file, 'w') as f:
    f.write(content)
print(f"✅ Backup created: {backup_file.name}")

# Files already in project
existing_refs = set()
for match in re.finditer(r'/\* (.+?\.swift) \*/ = \{isa = PBXFileReference', content):
    existing_refs.add(match.group(1))

print(f"\n📋 Currently in project: {len(existing_refs)} files")
for f in sorted(existing_refs):
    print(f"  - {f}")

# Find all Swift files
all_swift_files = {}
for swift_path in sorted(source_dir.rglob("*.swift")):
    filename = swift_path.name
    if filename not in existing_refs:
        rel_path = swift_path.relative_to(source_dir)
        parent_dir = str(rel_path.parent) if rel_path.parent != Path('.') else ""
        all_swift_files[filename] = {
            'path': str(rel_path),
            'parent': parent_dir,
            'filename': filename
        }

print(f"\n📁 Found {len(all_swift_files)} missing Swift files")

# Also add CoreData model
coredata_model = source_dir / "Core/Storage/ZairyuMateDataModel.xcdatamodeld"
if coredata_model.exists():
    print("✅ Found CoreData model")

# Group structure mapping (from existing pbxproj)
GROUP_IDS = {
    'App': 'A10000022',
    'Core': 'A10000024',
    'Core/Models': 'A10000033',
    'Core/Services': 'A10000034',
    'Core/Storage': 'A10000035',
    'Core/Utilities': 'A10000036',
    'Features': 'A10000023',
    'Features/Home': 'A10000028',
    'Features/Profile': 'A10000029',
    'Features/Documents': 'A10000030',
    'Features/Timeline': 'A10000031',
    'Features/Settings': 'A10000032',
    'UI': 'A10000025',
    'UI/Components': 'A10000037',
    'UI/Styles': 'A10000038',
    'UI/Theme': 'A10000039',
}

# Need to create subgroups for nested structures
SUBGROUPS_NEEDED = {
    'Features/Home/ViewModels': None,
    'Features/Home/Views': None,
    'Features/Profile/ViewModels': None,
    'Features/Profile/Views': None,
    'Features/Documents/ViewModels': None,
    'Features/Documents/Views': None,
    'Features/Settings/Views': None,
    'Features/Auth/Views': None,
    'UI/Components/Buttons': None,
    'UI/Components/Cards': None,
    'UI/Components/Inputs': None,
    'UI/Components/Navigation': None,
    'UI/Components/Overlays': None,
    'UI/Components/Rings': None,
}

# Generate IDs for subgroups
subgroup_counter = 200
for subgroup_path in sorted(SUBGROUPS_NEEDED.keys()):
    SUBGROUPS_NEEDED[subgroup_path] = generate_xcode_id(subgroup_counter)
    GROUP_IDS[subgroup_path] = SUBGROUPS_NEEDED[subgroup_path]
    subgroup_counter += 1

# Generate entries
file_counter = 1000
file_refs_section = []
build_files_section = []
sources_list = []
group_files = {}  # group_path -> [(file_id, filename)]

for filename, info in sorted(all_swift_files.items()):
    file_id = generate_xcode_id(file_counter)
    build_id = generate_xcode_id(file_counter + 1)
    file_counter += 2

    parent = info['parent']

    # File reference
    file_refs_section.append(
        f'\t\t{file_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = "<group>"; }};'
    )

    # Build file
    build_files_section.append(
        f'\t\t{build_id} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {filename} */; }};'
    )

    # Sources entry
    sources_list.append(f'\t\t\t\t{build_id} /* {filename} in Sources */,')

    # Group membership
    if parent not in group_files:
        group_files[parent] = []
    group_files[parent].append((file_id, filename))

# Add CoreData model
if coredata_model.exists():
    file_id = generate_xcode_id(file_counter)
    build_id = generate_xcode_id(file_counter + 1)
    file_counter += 2

    file_refs_section.append(
        f'\t\t{file_id} /* ZairyuMateDataModel.xcdatamodeld */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.xcdatamodeld; path = ZairyuMateDataModel.xcdatamodeld; sourceTree = "<group>"; }};'
    )
    build_files_section.append(
        f'\t\t{build_id} /* ZairyuMateDataModel.xcdatamodeld in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* ZairyuMateDataModel.xcdatamodeld */; }};'
    )
    sources_list.append(f'\t\t\t\t{build_id} /* ZairyuMateDataModel.xcdatamodeld in Sources */,')

    if 'Core/Storage' not in group_files:
        group_files['Core/Storage'] = []
    group_files['Core/Storage'].append((file_id, 'ZairyuMateDataModel.xcdatamodeld'))

print(f"\n🔧 Generated {len(file_refs_section)} file references")
print(f"🔧 Generated {len(build_files_section)} build files")
print(f"🔧 Generated {len(sources_list)} source entries")

# Now modify the content
lines = content.split('\n')
new_content_lines = []

i = 0
while i < len(lines):
    line = lines[i]

    # 1. Insert build files after the first PBXBuildFile
    if '/* Begin PBXBuildFile section */' in line:
        new_content_lines.append(line)
        i += 1
        # Skip existing build files
        while i < len(lines) and '/* End PBXBuildFile section */' not in lines[i]:
            new_content_lines.append(lines[i])
            i += 1
        # Insert new build files before the End marker
        for bf in build_files_section:
            new_content_lines.append(bf)
        continue

    # 2. Insert file references after existing ones
    if '/* Begin PBXFileReference section */' in line:
        new_content_lines.append(line)
        i += 1
        # Skip existing file refs
        while i < len(lines) and '/* End PBXFileReference section */' not in lines[i]:
            new_content_lines.append(lines[i])
            i += 1
        # Insert new file refs before the End marker
        for fr in file_refs_section:
            new_content_lines.append(fr)
        continue

    # 3. Insert into Sources build phase
    if 'A10000042 /* Sources */ = {' in line:
        new_content_lines.append(line)
        i += 1
        # Find the files = ( section
        while i < len(lines):
            new_content_lines.append(lines[i])
            if 'files = (' in lines[i]:
                i += 1
                # Skip existing source entries
                while i < len(lines) and ');' not in lines[i]:
                    new_content_lines.append(lines[i])
                    i += 1
                # Insert new sources before );
                for src in sources_list:
                    new_content_lines.append(src)
                break
            i += 1
        continue

    # 4. Add files to appropriate groups
    # Check if this line starts a group we care about
    for group_path, group_id in GROUP_IDS.items():
        group_name = group_path.split('/')[-1]
        if f'{group_id} /* {group_name} */' in line and 'isa = PBXGroup' in line:
            new_content_lines.append(line)
            i += 1
            # Find children = (
            while i < len(lines):
                new_content_lines.append(lines[i])
                if 'children = (' in lines[i]:
                    i += 1
                    # Add subgroup references if this group needs them
                    subgroups_added = False
                    for subgroup_path, subgroup_id in sorted(SUBGROUPS_NEEDED.items()):
                        if subgroup_path.startswith(group_path + '/'):
                            subgroup_name = subgroup_path.split('/')[-1]
                            if not subgroups_added:
                                # Insert before closing )
                                # First, collect existing children
                                existing_children = []
                                temp_i = i
                                while temp_i < len(lines) and ');' not in lines[temp_i]:
                                    existing_children.append(lines[temp_i])
                                    temp_i += 1
                                # Add subgroup reference
                                if subgroup_id and group_files.get(subgroup_path):
                                    new_content_lines.append(f'\t\t\t\t{subgroup_id} /* {subgroup_name} */,')
                                    subgroups_added = True

                    # Skip existing children
                    while i < len(lines) and ');' not in lines[i]:
                        new_content_lines.append(lines[i])
                        i += 1

                    # Add files for this group before );
                    if group_path in group_files:
                        for file_id, filename in group_files[group_path]:
                            new_content_lines.append(f'\t\t\t\t{file_id} /* {filename} */,')
                    break
                i += 1
            continue

    new_content_lines.append(line)
    i += 1

# Create subgroup definitions before End PBXGroup section
subgroup_definitions = []
for subgroup_path, subgroup_id in sorted(SUBGROUPS_NEEDED.items()):
    if subgroup_id and group_files.get(subgroup_path):
        subgroup_name = subgroup_path.split('/')[-1]
        children_entries = []
        for file_id, filename in group_files[subgroup_path]:
            children_entries.append(f'\t\t\t\t{file_id} /* {filename} */,')

        subgroup_def = f'''\t\t{subgroup_id} /* {subgroup_name} */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{chr(10).join(children_entries)}
\t\t\t);
\t\t\tpath = {subgroup_name};
\t\t\tsourceTree = "<group>";
\t\t}};'''
        subgroup_definitions.append(subgroup_def)

# Insert subgroup definitions before /* End PBXGroup section */
final_lines = []
for line in new_content_lines:
    if '/* End PBXGroup section */' in line:
        # Insert subgroups before this
        for subgroup_def in subgroup_definitions:
            final_lines.append(subgroup_def)
    final_lines.append(line)

# Write updated project
new_content = '\n'.join(final_lines)
with open(pbxproj_file, 'w') as f:
    f.write(new_content)

print(f"\n✅ Project file updated successfully!")
print(f"✅ Added {len(all_swift_files)} Swift files")
print(f"✅ Added CoreData model")
print(f"✅ Created {len([s for s in SUBGROUPS_NEEDED.values() if s])} subgroups")
print("\n" + "=" * 60)
print("NEXT STEP: Run xcodebuild to verify")
print("=" * 60)
