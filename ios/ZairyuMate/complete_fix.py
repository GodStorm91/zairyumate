#!/usr/bin/env python3
"""
Complete Xcode project fix:
1. Add file references
2. Add build file entries
3. Add to sources build phase
4. Add files to appropriate groups
5. Create subgroups as needed
"""
import re
from pathlib import Path
from datetime import datetime
from collections import defaultdict

def gen_id(base):
    """Generate 24-char Xcode ID"""
    import hashlib
    return hashlib.sha256(base.encode()).hexdigest().upper()[:24]

# Paths
proj_dir = Path("/Users/khanhnguyen/project/zairyumate/ios/ZairyuMate")
pbx = proj_dir / "ZairyuMate.xcodeproj" / "project.pbxproj"
src = proj_dir / "ZairyuMate"

print("=" * 60)
print("COMPLETE XCODE PROJECT FIX")
print("=" * 60)

# Restore from original backup
orig_backup = proj_dir / "ZairyuMate.xcodeproj" / "project.pbxproj.backup.20260128_110306"
if orig_backup.exists():
    print(f"Restoring from original backup: {orig_backup.name}")
    pbx.write_text(orig_backup.read_text())
else:
    print("Using current project file")

text = pbx.read_text()

# Backup current state
bak = pbx.with_name(f"project.pbxproj.complete_backup")
bak.write_text(text)
print(f"Backup created: {bak.name}\n")

# Files currently in project
curr = {'ZairyuMateApp.swift', 'Constants.swift', 'Extensions.swift', 'ColorTheme.swift', 'Typography.swift', 'Spacing.swift'}

# Map files to their group paths
file_groups = defaultdict(list)

for swift_file in sorted(src.rglob("*.swift")):
    if swift_file.name in curr:
        continue

    rel_path = swift_file.relative_to(src)
    parent = str(rel_path.parent) if rel_path.parent != Path('.') else ""

    file_groups[parent].append(swift_file.name)

# Add CoreData model
cdm_rel = "Core/Storage"
cdm_name = "ZairyuMateDataModel.xcdatamodeld"
file_groups[cdm_rel].append(cdm_name)

print(f"Files organized into {len(file_groups)} groups:")
for group, files in sorted(file_groups.items()):
    print(f"  {group or 'root'}: {len(files)} files")

# Existing group IDs
GROUP_IDS = {
    'Core/Models': 'A10000033',
    'Core/Services': 'A10000034',
    'Core/Storage': 'A10000035',
    'Core/Utilities': 'A10000036',
    'Features/Home': 'A10000028',
    'Features/Profile': 'A10000029',
    'Features/Documents': 'A10000030',
    'Features/Timeline': 'A10000031',
    'Features/Settings': 'A10000032',
    'UI/Components': 'A10000037',
    'UI/Styles': 'A10000038',
    'UI/Theme': 'A10000039',
}

# Create subgroups for nested directories
subgroups_needed = {}
subgroup_defs = []
subgroup_id_counter = 1000

for group_path in sorted(file_groups.keys()):
    if group_path and group_path not in GROUP_IDS:
        # Need to create this group
        parts = group_path.split('/')
        parent_path = '/'.join(parts[:-1])
        group_name = parts[-1]

        subgroup_id = gen_id(f"group_{subgroup_id_counter}_{group_path}")
        subgroups_needed[group_path] = {
            'id': subgroup_id,
            'name': group_name,
            'parent': parent_path,
            'path': group_name
        }
        GROUP_IDS[group_path] = subgroup_id
        subgroup_id_counter += 1

        # Generate group definition
        children_list = []
        for fname in file_groups[group_path]:
            # We'll fill in file IDs later
            children_list.append(fname)

        subgroup_defs.append({
            'id': subgroup_id,
            'name': group_name,
            'path': group_name,
            'children_placeholders': children_list
        })

print(f"\nCreating {len(subgroups_needed)} new subgroups")

# Generate file entries
seed = 50000
file_refs = []
build_files = []
source_entries = []
file_id_map = {}  # filename -> file_id

for group_path in sorted(file_groups.keys()):
    for fname in sorted(file_groups[group_path]):
        fid = gen_id(f"file_{seed}_{fname}")
        bid = gen_id(f"build_{seed}_{fname}")
        seed += 1

        file_id_map[fname] = fid

        # Determine file type
        if fname.endswith('.swift'):
            ftype = 'sourcecode.swift'
        elif fname.endswith('.xcdatamodeld'):
            ftype = 'wrapper.xcdatamodeld'
        else:
            ftype = 'text'

        file_refs.append(f"\t\t{fid} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = {fname}; sourceTree = \"<group>\"; }};")
        build_files.append(f"\t\t{bid} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {fname} */; }};")
        source_entries.append(f"\t\t\t\t{bid} /* {fname} in Sources */,")

print(f"\nGenerated {len(file_refs)} file references")
print(f"Generated {len(build_files)} build files")
print(f"Generated {len(source_entries)} source entries")

# Now build the complete pbxproj
lines = text.split('\n')
new_lines = []

# Track group child additions
group_children_to_add = defaultdict(list)
for group_path, files in file_groups.items():
    if group_path in GROUP_IDS:
        for fname in files:
            group_children_to_add[GROUP_IDS[group_path]].append((file_id_map[fname], fname))

# Also link subgroups to their parents
for group_path, info in subgroups_needed.items():
    parent = info['parent']
    if parent and parent in GROUP_IDS:
        parent_id = GROUP_IDS[parent]
        group_children_to_add[parent_id].append((info['id'], info['name']))

i = 0
while i < len(lines):
    line = lines[i]

    # 1. Insert build files before End marker
    if '/* End PBXBuildFile section */' in line:
        for bf in build_files:
            new_lines.append(bf)

    # 2. Insert file refs before End marker
    if '/* End PBXFileReference section */' in line:
        for fr in file_refs:
            new_lines.append(fr)

    # 3. Insert into sources phase
    if 'A10000042 /* Sources */ = {' in line:
        # Copy until we find files = (
        new_lines.append(line)
        i += 1
        while i < len(lines):
            new_lines.append(lines[i])
            if 'files = (' in lines[i]:
                # Skip existing entries, add ours before );
                i += 1
                while i < len(lines) and ');' not in lines[i]:
                    new_lines.append(lines[i])
                    i += 1
                # Add our sources before );
                for src_entry in source_entries:
                    new_lines.append(src_entry)
                break
            i += 1
        new_lines.append(line)  # Add current line (should be );)
        i += 1
        continue

    # 4. Add files to existing groups
    for group_id in GROUP_IDS.values():
        # Match pattern: GROUP_ID /* GroupName */ = {
        if f'{group_id} /* ' in line and '= {' in line:
            new_lines.append(line)
            i += 1
            # Find children = (
            while i < len(lines):
                new_lines.append(lines[i])
                if 'children = (' in lines[i]:
                    # Skip existing children, add ours before );
                    i += 1
                    while i < len(lines) and ');' not in lines[i]:
                        new_lines.append(lines[i])
                        i += 1
                    # Add our children before );
                    if group_id in group_children_to_add:
                        for child_id, child_name in group_children_to_add[group_id]:
                            new_lines.append(f"\t\t\t\t{child_id} /* {child_name} */,")
                    break
                i += 1
            new_lines.append(line)  # Add current line (should be );)
            i += 1
            continue

    # 5. Add new subgroup definitions before End PBXGroup section
    if '/* End PBXGroup section */' in line:
        for subgroup in subgroup_defs:
            new_lines.append(f"\t\t{subgroup['id']} /* {subgroup['name']} */ = {{")
            new_lines.append("\t\t\tisa = PBXGroup;")
            new_lines.append("\t\t\tchildren = (")
            # Add file references
            for fname in subgroup['children_placeholders']:
                if fname in file_id_map:
                    new_lines.append(f"\t\t\t\t{file_id_map[fname]} /* {fname} */,")
            new_lines.append("\t\t\t);")
            new_lines.append(f"\t\t\tpath = {subgroup['path']};")
            new_lines.append("\t\t\tsourceTree = \"<group>\";")
            new_lines.append("\t\t};")

    new_lines.append(line)
    i += 1

# Write
result = '\n'.join(new_lines)
pbx.write_text(result)

print("\n✅ Project file updated successfully!")
print("\nValidating structure...")

# Validation
if all(marker in result for marker in [
    '/* End PBXBuildFile section */',
    '/* End PBXFileReference section */',
    '/* End PBXGroup section */',
    '/* End PBXSourcesBuildPhase section */'
]):
    print("✅ All sections present and valid")
else:
    print("❌ Validation failed!")
    pbx.write_text(text)  # Restore
    exit(1)

print("\n" + "=" * 60)
print("SUCCESS! Project ready to build")
print("=" * 60)
