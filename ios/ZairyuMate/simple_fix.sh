#!/bin/bash
# Simple script to add all Swift files to Xcode project
# Uses a straightforward file generation approach

set -e

PROJECT_DIR="/Users/khanhnguyen/project/zairyumate/ios/ZairyuMate"
PROJECT_FILE="$PROJECT_DIR/ZairyuMate.xcodeproj/project.pbxproj"
SOURCE_DIR="$PROJECT_DIR/ZairyuMate"

# Backup
cp "$PROJECT_FILE" "$PROJECT_FILE.final_backup"
echo "✅ Backup created"

# Generate a temp file with all additions
TEMP_REFS="/tmp/xcode_refs.txt"
TEMP_BUILDS="/tmp/xcode_builds.txt"
TEMP_SOURCES="/tmp/xcode_sources.txt"

> "$TEMP_REFS"
> "$TEMP_BUILDS"
> "$TEMP_SOURCES"

# Existing files
EXISTING="ZairyuMateApp.swift Constants.swift Extensions.swift ColorTheme.swift Typography.swift Spacing.swift"

# Counter for unique IDs
COUNTER=50000

echo "Generating file references..."

# Find all Swift files
find "$SOURCE_DIR" -name "*.swift" -type f | sort | while read -r filepath; do
    filename=$(basename "$filepath")

    # Skip if already in project
    if echo "$EXISTING" | grep -q "$filename"; then
        continue
    fi

    # Generate IDs (simple incrementing hex)
    FILE_ID=$(printf "FILE%020d" $COUNTER)
    BUILD_ID=$(printf "BUILD%019d" $COUNTER)
    COUNTER=$((COUNTER + 1))

    # File reference
    echo "\t\t$FILE_ID /* $filename */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = $filename; sourceTree = \"<group>\"; };" >> "$TEMP_REFS"

    # Build file
    echo "\t\t$BUILD_ID /* $filename in Sources */ = {isa = PBXBuildFile; fileRef = $FILE_ID /* $filename */; };" >> "$TEMP_BUILDS"

    # Source entry
    echo "\t\t\t\t$BUILD_ID /* $filename in Sources */," >> "$TEMP_SOURCES"
done

# Add CoreData model
FILE_ID="FILECOREDATA00000000"
BUILD_ID="BUILDCOREDATA0000000"
echo "\t\t$FILE_ID /* ZairyuMateDataModel.xcdatamodeld */ = {isa = PBXFileReference; lastKnownFileType = wrapper.xcdatamodeld; path = ZairyuMateDataModel.xcdatamodeld; sourceTree = \"<group>\"; };" >> "$TEMP_REFS"
echo "\t\t$BUILD_ID /* ZairyuMateDataModel.xcdatamodeld in Sources */ = {isa = PBXBuildFile; fileRef = $FILE_ID /* ZairyuMateDataModel.xcdatamodeld */; };" >> "$TEMP_BUILDS"
echo "\t\t\t\t$BUILD_ID /* ZairyuMateDataModel.xcdatamodeld in Sources */," >> "$TEMP_SOURCES"

echo "✅ Generated $(wc -l < $TEMP_REFS) file references"
echo "✅ Generated $(wc -l < $TEMP_BUILDS) build file entries"
echo "✅ Generated $(wc -l < $TEMP_SOURCES) source entries"

# Now insert into project file using awk
awk '
BEGIN {
    buildfile_section = 0
    fileref_section = 0
    sources_section = 0
}

# Insert build files before End PBXBuildFile section
/\/\* End PBXBuildFile section \*\// {
    if (!buildfile_section) {
        system("cat /tmp/xcode_builds.txt")
        buildfile_section = 1
    }
}

# Insert file refs before End PBXFileReference section
/\/\* End PBXFileReference section \*\// {
    if (!fileref_section) {
        system("cat /tmp/xcode_refs.txt")
        fileref_section = 1
    }
}

# Insert sources before closing of sources build phase
/A10000042 \/\* Sources \*\/ = \{/,/^\t\};$/ {
    if (/files = \(/) {
        print
        getline
        # Skip existing entries
        while (!/\t\t\t\);/) {
            print
            getline
        }
        # Insert our sources
        if (!sources_section) {
            system("cat /tmp/xcode_sources.txt")
            sources_section = 1
        }
    }
}

# Print all lines
{ print }
' "$PROJECT_FILE" > "$PROJECT_FILE.new"

# Replace original
mv "$PROJECT_FILE.new" "$PROJECT_FILE"

echo ""
echo "✅ Project updated!"
echo "Validating..."

# Validate
if grep -q "/* End PBXBuildFile section */" "$PROJECT_FILE" && \
   grep -q "/* End PBXFileReference section */" "$PROJECT_FILE"; then
    echo "✅ Project file valid!"
    echo ""
    wc -l "$PROJECT_FILE"
else
    echo "❌ Project file corrupted, restoring backup"
    mv "$PROJECT_FILE.final_backup" "$PROJECT_FILE"
    exit 1
fi
