#!/usr/bin/env python3
"""
ULTIMATE XCODE PROJECT FIX
Adds ALL files with complete group hierarchy including subgroups
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

# Read original (clean version)
backup = pbx_file.with_suffix('.pbxproj.manual_backup')
text = backup.read_text()
lines = text.splitlines()

pbx_file.with_suffix('.pbxproj.ULTIMATE_BACKUP').write_text(text)
print("=" * 70)
print("ULTIMATE XCODE PROJECT FIX")
print("=" * 70)
print(f"✅ Backup: ULTIMATE_BACKUP\n")

# Existing files
curr = {'ZairyuMateApp.swift', 'Constants.swift', 'Extensions.swift',
        'ColorTheme.swift', 'Typography.swift', 'Spacing.swift'}

# Existing group IDs
BASE_GROUPS = {
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

# Scan filesystem and map files to groups
file_map = {}  # filename -> group_path
for f in sorted(src.rglob("*.swift")):
    if f.name in curr:
        continue
    rel = f.relative_to(src)
    file_map[f.name] = str(rel.parent)

# Add CoreData model
file_map['ZairyuMateDataModel.xcdatamodeld'] = 'Core/Storage'

print(f"📁 Found {len(file_map)} files")

# Determine which new subgroups we need to create
all_groups = set(file_map.values())
new_groups_needed = sorted(all_groups - set(BASE_GROUPS.keys()))

print(f"🆕 Need to create {len(new_groups_needed)} new subgroups:\n")
for g in new_groups_needed:
    files_in_group = [f for f, path in file_map.items() if path == g]
    print(f"  {g}: {len(files_in_group)} files")

# Create subgroup definitions
seed = 80000
subgroups = {}
for group_path in new_groups_needed:
    parts = group_path.split('/')
    group_name = parts[-1]
    parent_path = '/'.join(parts[:-1])

    subgroups[group_path] = {
        'id': gen_id(seed),
        'name': group_name,
        'path': group_name,  # Relative to parent
        'parent': parent_path,
        'files': []
    }
    BASE_GROUPS[group_path] = subgroups[group_path]['id']
    seed += 1

# Generate file entries
seed = 90000
file_ids = {}
refs, builds, sources = [], [], []

for fname, group_path in file_map.items():
    fid = gen_id(seed)
    bid = gen_id(seed+1)
    seed += 2

    file_ids[fname] = fid
    ftype = 'wrapper.xcdatamodeld' if '.xcdatamodeld' in fname else 'sourcecode.swift'

    refs.append(f'\t\t{fid} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = {fname}; sourceTree = "<group>"; }};')
    builds.append(f'\t\t{bid} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {fname} */; }};')
    sources.append(f'\t\t\t\t{bid} /* {fname} in Sources */,')

    # Assign to group
    if group_path in subgroups:
        subgroups[group_path]['files'].append((fid, fname))

# Also populate base groups
base_group_files = defaultdict(list)
for fname, group_path in file_map.items():
    if group_path in BASE_GROUPS and group_path not in subgroups:
        fid = file_ids[fname]
        base_group_files[BASE_GROUPS[group_path]].append((fid, fname))

print(f"\n✅ Generated:")
print(f"  - {len(refs)} file references")
print(f"  - {len(builds)} build files")
print(f"  - {len(sources)} sources")
print(f"  - {len(subgroups)} subgroups")

# Process line by line
output = []
i = 0

while i < len(lines):
    line = lines[i]

    # 1. Insert build files
    if '/* End PBXBuildFile section */' in line:
        output.extend(builds)
        output.append(line)
        i += 1
        continue

    # 2. Insert file references
    if '/* End PBXFileReference section */' in line:
        output.extend(refs)
        output.append(line)
        i += 1
        continue

    # 3. Insert sources
    if 'A10000042 /* Sources */' in line and i+1 < len(lines) and 'isa = PBXSourcesBuildPhase' in lines[i+1]:
        output.append(line)
        i += 1
        output.append(lines[i])
        i += 1
        output.append(lines[i])
        i += 1
        output.append(lines[i])
        i += 1
        while i < len(lines) and ');' not in lines[i]:
            output.append(lines[i])
            i += 1
        output.extend(sources)
        output.append(lines[i])
        i += 1
        while i < len(lines) and '};' not in lines[i]:
            output.append(lines[i])
            i += 1
        output.append(lines[i])
        i += 1
        continue

    # 4. Add files to base groups + link subgroups to parents
    for group_path, group_id in BASE_GROUPS.items():
        if f'{group_id} /* ' in line and '= {' in line:
            # Check if next line is isa = PBXGroup
            if i+1 < len(lines) and 'isa = PBXGroup' in lines[i+1]:
                output.append(line)
                i += 1
                output.append(lines[i])
                i += 1

                # Find children = (
                while i < len(lines) and 'children = (' not in lines[i]:
                    output.append(lines[i])
                    i += 1

                output.append(lines[i])  # children = (
                i += 1

                # Skip existing
                while i < len(lines) and ');' not in lines[i]:
                    output.append(lines[i])
                    i += 1

                # Add our files
                if group_id in base_group_files:
                    for fid, fname in base_group_files[group_id]:
                        output.append(f'\t\t\t\t{fid} /* {fname} */,')

                # Add subgroups that are children of this group
                for sg_path, sg_info in subgroups.items():
                    if sg_info['parent'] == group_path:
                        output.append(f'\t\t\t\t{sg_info["id"]} /* {sg_info["name"]} */,')

                output.append(lines[i])  # );
                i += 1

                while i < len(lines) and '};' not in lines[i]:
                    output.append(lines[i])
                    i += 1

                output.append(lines[i])  # };
                i += 1
                continue

    # 5. Insert subgroup definitions before End PBXGroup section
    if '/* End PBXGroup section */' in line:
        for sg_path in sorted(subgroups.keys()):
            sg = subgroups[sg_path]
            output.append(f'\t\t{sg["id"]} /* {sg["name"]} */ = {{')
            output.append('\t\t\tisa = PBXGroup;')
            output.append('\t\t\tchildren = (')
            for fid, fname in sg['files']:
                output.append(f'\t\t\t\t{fid} /* {fname} */,')
            output.append('\t\t\t);')
            output.append(f'\t\t\tpath = {sg["path"]};')
            output.append('\t\t\tsourceTree = "<group>";')
            output.append('\t\t};')

    output.append(line)
    i += 1

# Write
result = '\n'.join(output) + '\n'
pbx_file.write_text(result)

print(f"\n✅ PROJECT UPDATED!")
print(f"   Lines: {len(lines)} → {len(output)}")

# Validate
if all(m in result for m in ['/* End PBXBuildFile section */', '/* End PBXGroup section */']):
    print("✅ Validation passed")
    print("\n" + "=" * 70)
    print("BUILD TEST:")
    print("  xcodebuild -scheme ZairyuMate -destination 'platform=iOS Simulator,name=iPhone 17' build")
    print("=" * 70)
else:
    print("❌ Validation failed")
    pbx_file.write_text(text)
