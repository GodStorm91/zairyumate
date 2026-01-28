#!/usr/bin/env python3
import os
import re
from pathlib import Path
from datetime import datetime

def generate_uuid(seed):
    """Generate a 24-character uppercase hex ID"""
    import hashlib
    hash_obj = hashlib.md5(str(seed).encode())
    return hash_obj.hexdigest().upper()[:24]

# Configuration
project_dir = Path("/Users/khanhnguyen/project/zairyumate/ios/ZairyuMate")
pbxproj_path = project_dir / "ZairyuMate.xcodeproj" / "project.pbxproj"
source_dir = project_dir / "ZairyuMate"

print("Reading Xcode project...")
with open(pbxproj_path) as f:
    original = f.read()

# Backup
backup_path = pbxproj_path.with_name(f"project.pbxproj.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}")
with open(backup_path, 'w') as f:
    f.write(original)
print(f"Backup: {backup_path.name}")

# Files currently in project
current_files = {'ZairyuMateApp.swift', 'Constants.swift', 'Extensions.swift', 'ColorTheme.swift', 'Typography.swift', 'Spacing.swift'}

# Find all Swift files
files = []
for p in sorted(source_dir.rglob("*.swift")):
    if p.name not in current_files:
        files.append(p.name)

print(f"Adding {len(files)} Swift files...")

# Generate entries
uuid_seed = 50000
refs = []
builds = []
sources = []

for fname in sorted(files):
    fid = generate_uuid(uuid_seed)
    bid = generate_uuid(uuid_seed + 1)
    uuid_seed += 2

    refs.append(f'\t\t{fid} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {fname}; sourceTree = "<group>"; }};')
    builds.append(f'\t\t{bid} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {fname} */; }};')
    sources.append(f'\t\t\t\t{bid} /* {fname} in Sources */,')

# Modify content
lines = original.split('\n')
result = []

for i, line in enumerate(lines):
    result.append(line)

    # Add after last PBXBuildFile
    if i == 16:  # After last existing PBXBuildFile
        result.extend(builds)

    # Add after last PBXFileReference
    if i == 29:  # After last existing PBXFileReference
        result.extend(refs)

    # Add to sources (before closing of sources section)
    if i == 293:  # After last existing source entry
        result.extend(sources)

# Write
with open(pbxproj_path, 'w') as f:
    f.write('\n'.join(result))

print(f"✅ Added {len(files)} files to Xcode project")
print("Next: Build the project to verify")
