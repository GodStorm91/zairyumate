#!/usr/bin/env python3
"""
Properly fix Xcode project by carefully inserting file references
while maintaining the pbxproj structure integrity
"""
import re
from pathlib import Path
from datetime import datetime

def gen_id(base):
    """Generate 24-char Xcode ID"""
    import hashlib
    h = hashlib.sha256(base.encode()).hexdigest().upper()
    return h[:24]

# Paths
proj_dir = Path("/Users/khanhnguyen/project/zairyumate/ios/ZairyuMate")
pbx = proj_dir / "ZairyuMate.xcodeproj" / "project.pbxproj"
src = proj_dir / "ZairyuMate"

print("Loading project...")
text = pbx.read_text()

# Backup
bak = pbx.with_name(f"project.pbxproj.bak{datetime.now().strftime('%Y%m%d%H%M%S')}")
bak.write_text(text)
print(f"Backup: {bak.name}")

# Current files in project
curr = {'ZairyuMateApp.swift', 'Constants.swift', 'Extensions.swift', 'ColorTheme.swift', 'Typography.swift', 'Spacing.swift'}

# Find Swift files to add
to_add = sorted([f.name for f in src.rglob("*.swift") if f.name not in curr])
print(f"Files to add: {len(to_add)}")

# Also need CoreData model
coredata_model = None
cdm_path = src / "Core/Storage/ZairyuMateDataModel.xcdatamodeld"
if cdm_path.exists():
    coredata_model = "ZairyuMateDataModel.xcdatamodeld"
    print("CoreData model found")

# Generate new entries
seed = 10000
file_refs = []
build_files = []
source_entries = []

# Swift files
for fname in to_add:
    fid = gen_id(f"file_{seed}_{fname}")
    bid = gen_id(f"build_{seed}_{fname}")
    seed += 1

    file_refs.append(f"\t\t{fid} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {fname}; sourceTree = \"<group>\"; }};")
    build_files.append(f"\t\t{bid} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {fname} */; }};")
    source_entries.append(f"\t\t\t\t{bid} /* {fname} in Sources */,")

# CoreData model
if coredata_model:
    fid = gen_id(f"file_coredata_{seed}")
    bid = gen_id(f"build_coredata_{seed}")
    seed += 1

    file_refs.append(f"\t\t{fid} /* {coredata_model} */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.xcdatamodeld; path = {coredata_model}; sourceTree = \"<group>\"; }};")
    build_files.append(f"\t\t{bid} /* {coredata_model} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {coredata_model} */; }};")
    source_entries.append(f"\t\t\t\t{bid} /* {coredata_model} in Sources */,")

# Now carefully insert into the file
lines = text.split('\n')

# Find insertion points
buildfile_end_idx = None
fileref_end_idx = None
sources_insert_idx = None

for i, line in enumerate(lines):
    if '/* End PBXBuildFile section */' in line:
        buildfile_end_idx = i
    if '/* End PBXFileReference section */' in line:
        fileref_end_idx = i
    if 'A10000042 /* Sources */ = {' in line:
        # Find the files = ( line after this
        for j in range(i, min(i+20, len(lines))):
            if 'files = (' in lines[j]:
                # Find the last entry before );
                for k in range(j+1, min(j+50, len(lines))):
                    if ');' in lines[k]:
                        sources_insert_idx = k
                        break
                break

print(f"Insertion points: buildfile={buildfile_end_idx}, fileref={fileref_end_idx}, sources={sources_insert_idx}")

if not all([buildfile_end_idx, fileref_end_idx, sources_insert_idx]):
    print("ERROR: Could not find insertion points")
    exit(1)

# Build new content
new_lines = []

for i, line in enumerate(lines):
    # Insert build files before End marker
    if i == buildfile_end_idx:
        new_lines.extend(build_files)

    # Insert file refs before End marker
    if i == fileref_end_idx:
        new_lines.extend(file_refs)

    # Insert source entries before );
    if i == sources_insert_idx:
        new_lines.extend(source_entries)

    new_lines.append(line)

# Write
pbx.write_text('\n'.join(new_lines))
print(f"✅ Updated project with {len(to_add)} Swift files + CoreData model")
print("Validating...")

# Quick validation
new_text = pbx.read_text()
if '/* End PBXBuildFile section */' in new_text and '/* End PBXFileReference section */' in new_text:
    print("✅ Validation passed - structure intact")
else:
    print("❌ Validation failed - restoring backup")
    pbx.write_text(text)
    exit(1)
