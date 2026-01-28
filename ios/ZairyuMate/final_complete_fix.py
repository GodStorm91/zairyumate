#!/usr/bin/env python3
"""
FINAL COMPLETE FIX - Add files to Xcode project with proper group assignments
This ensures Xcode can find the files at their correct filesystem locations
"""
from pathlib import Path
from collections import defaultdict
import hashlib

def gen_id(seed):
    return hashlib.md5(str(seed).encode()).hexdigest().upper()[:24]

# Paths
proj = Path("/Users/khanhnguyen/project/zairyumate/ios/ZairyuMate")
pbx_file = proj / "ZairyuMate.xcodeproj" / "project.pbxproj"
src = proj / "ZairyuMate"

# Read project
text = pbx_file.read_text()
lines = text.splitlines()

# Backup
pbx_file.with_suffix('.pbxproj.FINAL_BACKUP').write_text(text)
print("✅ Backup created")

# Existing files
curr = {'ZairyuMateApp.swift', 'Constants.swift', 'Extensions.swift',
        'ColorTheme.swift', 'Typography.swift', 'Spacing.swift'}

# Existing group IDs
GROUPS = {
    'Core/Models': 'A10000033',
    'Core/Services': 'A10000034',
    'Core/Storage': 'A10000035',
    'Core/Utilities': 'A10000036',
    'UI/Theme': 'A10000039',
}

# Map files to groups
file_to_group = {}
all_files = []

for f in sorted(src.rglob("*.swift")):
    if f.name in curr:
        continue

    rel = f.relative_to(src)
    parent = str(rel.parent)

    file_to_group[f.name] = parent
    all_files.append(f.name)

# Add CoreData model
file_to_group['ZairyuMateDataModel.xcdatamodeld'] = 'Core/Storage'
all_files.append('ZairyuMateDataModel.xcdatamodeld')

print(f"Processing {len(all_files)} files across {len(set(file_to_group.values()))} groups")

# Generate entries
seed = 70000
file_ids = {}
refs, builds, sources = [], [], []

for fname in all_files:
    fid = gen_id(seed)
    bid = gen_id(seed+1)
    seed += 2

    file_ids[fname] = fid
    ftype = 'wrapper.xcdatamodeld' if '.xcdatamodeld' in fname else 'sourcecode.swift'

    refs.append(f'\t\t{fid} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = {fname}; sourceTree = "<group>"; }};')
    builds.append(f'\t\t{bid} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {fname} */; }};')
    sources.append(f'\t\t\t\t{bid} /* {fname} in Sources */,')

# Organize files by group for insertion
group_children = defaultdict(list)
for fname, group_path in file_to_group.items():
    if group_path in GROUPS:
        group_id = GROUPS[group_path]
        group_children[group_id].append((file_ids[fname], fname))

print(f"✅ {len(refs)} file refs")
print(f"✅ {len(builds)} build files")
print(f"✅ {len(sources)} sources")

# Process line by line
output = []
i = 0

while i < len(lines):
    line = lines[i]

    # 1. PBXBuildFile section
    if '/* End PBXBuildFile section */' in line:
        output.extend(builds)
        output.append(line)
        i += 1
        continue

    # 2. PBXFileReference section
    if '/* End PBXFileReference section */' in line:
        output.extend(refs)
        output.append(line)
        i += 1
        continue

    # 3. PBXSourcesBuildPhase
    if 'A10000042 /* Sources */' in line and i+1 < len(lines) and 'isa = PBXSourcesBuildPhase' in lines[i+1]:
        output.append(line)  # A10000042 /* Sources */ = {
        i += 1
        output.append(lines[i])  # isa = PBXSourcesBuildPhase;
        i += 1
        output.append(lines[i])  # buildActionMask...
        i += 1
        output.append(lines[i])  # files = (
        i += 1

        # Skip existing entries
        while i < len(lines) and ');' not in lines[i]:
            output.append(lines[i])
            i += 1

        # Add our sources before );
        output.extend(sources)
        output.append(lines[i])  # );
        i += 1

        # Rest until };
        while i < len(lines) and '};' not in lines[i]:
            output.append(lines[i])
            i += 1
        output.append(lines[i])  # };
        i += 1
        continue

    # 4. Add files to groups
    for group_id, children in group_children.items():
        # Match group definition
        if f'{group_id} /* ' in line and '= {' in line and 'isa = PBXGroup' in lines[i+1]:
            output.append(line)  # Group header
            i += 1
            output.append(lines[i])  # isa = PBXGroup;
            i += 1

            # Find children = (
            while i < len(lines) and 'children = (' not in lines[i]:
                output.append(lines[i])
                i += 1

            output.append(lines[i])  # children = (
            i += 1

            # Skip existing children
            while i < len(lines) and ');' not in lines[i]:
                output.append(lines[i])
                i += 1

            # Add our files before );
            for fid, fname in children:
                output.append(f'\t\t\t\t{fid} /* {fname} */,')

            output.append(lines[i])  # );
            i += 1

            # Rest until path and sourceTree
            while i < len(lines) and '};' not in lines[i]:
                output.append(lines[i])
                i += 1

            output.append(lines[i])  # };
            i += 1
            continue

    output.append(line)
    i += 1

# Write
result = '\n'.join(output) + '\n'
pbx_file.write_text(result)

print(f"\n✅ Project updated: {len(lines)} -> {len(output)} lines")

# Validate
if all(m in result for m in ['/* End PBXBuildFile section */', '/* End PBXFileReference section */']):
    print("✅ Validation passed!")
    print(f"\nAdded files to groups:")
    for group_id, children in group_children.items():
        print(f"  {group_id}: {len(children)} files")
else:
    print("❌ Validation failed!")
    pbx_file.write_text(text)
