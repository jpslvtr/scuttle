#!/bin/bash

# Create or empty the files.txt
> files.txt

# Function to append file contents to files.txt
append_file_content() {
    local file_path=$1
    echo "File: $file_path" >> files.txt
    echo "" >> files.txt
    cat "$file_path" >> files.txt
    echo "" >> files.txt
    echo "=================================================================" >> files.txt
    echo "" >> files.txt
}

# Iterate over each .dart file in the lib directory
for file in app/lib/*.dart; 
do
    append_file_content "$file"
done

# Append contents of additional files
append_file_content "app/ios/Podfile"
append_file_content "app/ios/Runner/Info.plist"
append_file_content "app/ios/Runner/GoogleService-Info.plist"
append_file_content "app/ios/Flutter/AppFrameworkInfo.plist"
append_file_content "app/pubspec.yaml"
append_file_content "wm-db.txt"
append_file_content "firebase.json"
append_file_content "functions/index.js"