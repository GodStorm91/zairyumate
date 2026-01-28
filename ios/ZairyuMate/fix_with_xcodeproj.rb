#!/usr/bin/env ruby
require 'xcodeproj'

# Paths
project_path = '/Users/khanhnguyen/project/zairyumate/ios/ZairyuMate/ZairyuMate.xcodeproj'
source_root = '/Users/khanhnguyen/project/zairyumate/ios/ZairyuMate/ZairyuMate'

puts "=" * 70
puts "FIXING XCODE PROJECT WITH XCODEPROJ GEM"
puts "=" * 70

# Open project
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

puts "✅ Loaded project: #{project.path.basename}"
puts "✅ Target: #{target.name}\n"

# Existing files to skip
existing = ['ZairyuMateApp.swift', 'Constants.swift', 'Extensions.swift',
            'ColorTheme.swift', 'Typography.swift', 'Spacing.swift']

# Find all Swift files
swift_files = Dir.glob(File.join(source_root, '**', '*.swift')).sort
files_to_add = swift_files.reject { |f| existing.include?(File.basename(f)) }

puts "Found #{files_to_add.length} Swift files to add\n"

# Add each file to appropriate group
files_to_add.each do |file_path|
  rel_path = Pathname.new(file_path).relative_path_from(Pathname.new(source_root))
  parent_dir = rel_path.dirname.to_s

  # Find or create group
  group = project.main_group['ZairyuMate']
  unless parent_dir == '.'
    parent_dir.split('/').each do |dir_name|
      group = group[dir_name] || group.new_group(dir_name, dir_name)
    end
  end

  # Add file to group
  file_ref = group.new_file(file_path)

  # Add to target
  target.add_file_references([file_ref])

  puts "  + #{rel_path}"
end

# Add CoreData model
coredata_path = File.join(source_root, 'Core/Storage/ZairyuMateDataModel.xcdatamodeld')
if File.exist?(coredata_path)
  puts "\n✅ Adding CoreData model"
  storage_group = project.main_group['ZairyuMate']['Core']['Storage']
  model_ref = storage_group.new_file(coredata_path)
  target.add_file_references([model_ref])
end

# Save
project.save

puts "\n" + "=" * 70
puts "✅ PROJECT SAVED!"
puts "=" * 70
puts "\nRun: xcodebuild -scheme ZairyuMate build"
