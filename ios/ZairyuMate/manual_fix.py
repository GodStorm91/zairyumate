#!/usr/bin/env python3
"""
Manual, careful Xcode project fix
Line-by-line processing with explicit section handling
"""
from pathlib import Path
import hashlib

def gen_id(seed):
    """Generate 24-char ID"""
    return hashlib.md5(str(seed).encode()).hexdigest().upper()[:24]

proj = Path("/Users/khanhnguyen/project/zairyumate/ios/ZairyuMate")
pbx_file = proj / "ZairyuMate.xcodeproj" / "project.pbxproj"
src_dir = proj / "ZairyuMate"

# Read original
original = pbx_file.read_text()
lines = original.splitlines()

# Backup
pbx_file.with_suffix('.pbxproj.manual_backup').write_text(original)
print("Backup created")

# Find Swift files
curr_files = {'ZairyuMateApp.swift', 'Constants.swift', 'Extensions.swift',
              'ColorTheme.swift', 'Typography.swift', 'Spacing.swift'}

new_files = []
for f in sorted(src_dir.rglob("*.swift")):
    if f.name not in curr_files:
        new_files.append(f.name)

new_files.append("ZairyuMateDataModel.xcdatamodeld")  # CoreData model

print(f"Adding {len(new_files)} files")

# Generate entries
seed = 60000
refs, builds, sources = [], [], []

for fname in new_files:
    fid = gen_id(seed)
    bid = gen_id(seed+1)
    seed += 2

    ftype = 'wrapper.xcdatamodeld' if '.xcdatamodeld' in fname else 'sourcecode.swift'

    refs.append(f'\t\t{fid} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = {fname}; sourceTree = "<group>"; }};')
    builds.append(f'\t\t{bid} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {fname} */; }};')
    sources.append(f'\t\t\t\t{bid} /* {fname} in Sources */,')

print(f"Generated: {len(refs)} refs, {len(builds)} builds, {len(sources)} sources")

# Process line by line
output = []
i = 0

while i < len(lines):
    line = lines[i]

    # Section 1: PBXBuildFile - add before End marker
    if '/* End PBXBuildFile section */' in line:
        output.extend(builds)
        output.append(line)
        i += 1
        continue

    # Section 2: PBXFileReference - add before End marker
    if '/* End PBXFileReference section */' in line:
        output.extend(refs)
        output.append(line)
        i += 1
        continue

    # Section 3: PBXSourcesBuildPhase - add to files array
    if 'A10000042 /* Sources */' in line and 'isa = PBXSourcesBuildPhase' in lines[i+1]:
        # Copy the Sources build phase header
        output.append(line)
        i += 1
        output.append(lines[i])  # isa = PBXSourcesBuildPhase
        i += 1
        output.append(lines[i])  # buildActionMask
        i += 1

        # Now we're at "files = ("
        output.append(lines[i])  # files = (
        i += 1

        # Copy existing file entries
        while i < len(lines) and ');' not in lines[i]:
            output.append(lines[i])
            i += 1

        # Add our new sources before the closing );
        output.extend(sources)

        # Add the closing );
        output.append(lines[i])  # );
        i += 1

        # Copy the rest until };
        while i < len(lines) and '};' not in lines[i]:
            output.append(lines[i])
            i += 1

        output.append(lines[i])  # };
        i += 1
        continue

    # Default: copy line as-is
    output.append(line)
    i += 1

# Write result
result_text = '\n'.join(output) + '\n'
pbx_file.write_text(result_text)

print(f"\n✅ Updated project file")
print(f"Original: {len(lines)} lines")
print(f"New: {len(output)} lines")

# Validate
if '/* End PBXBuildFile section */' in result_text and \
   '/* End PBXFileReference section */' in result_text:
    print("✅ Structure valid!")
else:
    print("❌ Validation failed!")
    pbx_file.write_text(original)
