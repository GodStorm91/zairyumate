#!/bin/bash
# Simple script to add all Swift files to Xcode project using Xcode's command line tools

set -e

PROJECT_DIR="/Users/khanhnguyen/project/zairyumate/ios/ZairyuMate"
PROJECT_FILE="$PROJECT_DIR/ZairyuMate.xcodeproj"
SOURCE_DIR="$PROJECT_DIR/ZairyuMate"

echo "======================================"
echo "Adding Swift files to Xcode project"
echo "======================================"

# Backup the project file
BACKUP_FILE="$PROJECT_FILE/project.pbxproj.backup.$(date +%Y%m%d_%H%M%S)"
cp "$PROJECT_FILE/project.pbxproj" "$BACKUP_FILE"
echo "✅ Backup created: $(basename $BACKUP_FILE)"

# Find all Swift files (excluding those already in project)
EXISTING_FILES=("ZairyuMateApp.swift" "Constants.swift" "Extensions.swift" "ColorTheme.swift" "Typography.swift" "Spacing.swift")

echo ""
echo "Scanning for Swift files..."
SWIFT_FILES=()
while IFS= read -r -d '' file; do
    filename=$(basename "$file")
    # Check if already in project
    skip=false
    for existing in "${EXISTING_FILES[@]}"; do
        if [[ "$filename" == "$existing" ]]; then
            skip=true
            break
        fi
    done
    if [[ "$skip" == false ]]; then
        SWIFT_FILES+=("$file")
    fi
done < <(find "$SOURCE_DIR" -name "*.swift" -print0)

echo "Found ${#SWIFT_FILES[@]} Swift files to add"

# We'll use Xcode's project editing capabilities through a generated Ruby script
# This is more reliable than manual pbxproj editing

cat > "/tmp/add_files_to_xcode.rb" << 'RUBY_SCRIPT'
#!/usr/bin/env ruby

# This script adds files to an Xcode project by directly editing the pbxproj file
# It's a simplified version that doesn't require the xcodeproj gem

require 'fileutils'
require 'securerandom'

def generate_uuid
  # Generate a 24-character hex ID (Xcode style)
  SecureRandom.hex(12).upcase
end

project_dir = ARGV[0]
pbxproj_path = File.join(project_dir, 'ZairyuMate.xcodeproj', 'project.pbxproj')
source_dir = File.join(project_dir, 'ZairyuMate')

puts "Reading project file..."
content = File.read(pbxproj_path)

# Find all Swift files
existing_files = ['ZairyuMateApp.swift', 'Constants.swift', 'Extensions.swift', 'ColorTheme.swift', 'Typography.swift', 'Spacing.swift']
files_to_add = []

Dir.glob(File.join(source_dir, '**', '*.swift')).sort.each do |file_path|
  filename = File.basename(file_path)
  next if existing_files.include?(filename)

  rel_path = Pathname.new(file_path).relative_path_from(Pathname.new(source_dir))
  parent_dir = File.dirname(rel_path.to_s)
  parent_dir = '' if parent_dir == '.'

  files_to_add << {
    name: filename,
    path: filename,
    parent: parent_dir
  }
end

puts "Found #{files_to_add.length} files to add"

# Generate entries
file_refs = []
build_files = []
sources = []

files_to_add.each do |file_info|
  file_id = generate_uuid
  build_id = generate_uuid
  name = file_info[:name]

  # PBXFileReference
  file_refs << "\t\t#{file_id} /* #{name} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = #{name}; sourceTree = \"<group>\"; };"

  # PBXBuildFile
  build_files << "\t\t#{build_id} /* #{name} in Sources */ = {isa = PBXBuildFile; fileRef = #{file_id} /* #{name} */; };"

  # Source entry
  sources << "\t\t\t\t#{build_id} /* #{name} in Sources */,"
end

# Insert into content
lines = content.split("\n")
new_lines = []

# State machine to insert at right places
i = 0
while i < lines.length
  line = lines[i]

  # Insert build files
  if line.include?('/* End PBXBuildFile section */')
    build_files.each { |bf| new_lines << bf }
    new_lines << line
    i += 1
    next
  end

  # Insert file references
  if line.include?('/* End PBXFileReference section */')
    file_refs.each { |fr| new_lines << fr }
    new_lines << line
    i += 1
    next
  end

  # Insert sources
  if line.include?('runOnlyForDeploymentPostprocessing = 0;') && lines[i-3]&.include?('PBXSourcesBuildPhase')
    new_lines << line
    sources.each { |src| new_lines << src } if i + 1 < lines.length && !lines[i+1].include?('/* End PBXSourcesBuildPhase')
    i += 1
    next
  end

  new_lines << line
  i += 1
end

# Write back
File.write(pbxproj_path, new_lines.join("\n"))
puts "✅ Project file updated!"

RUBY_SCRIPT

chmod +x /tmp/add_files_to_xcode.rb
ruby /tmp/add_files_to_xcode.rb "$PROJECT_DIR"

echo ""
echo "======================================"
echo "✅ Done! Files added to project"
echo "======================================"
