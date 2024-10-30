#!/bin/bash

# Navigate to the root directory
cd ..

# Use repopack to include specific files in the package
repopack --include "app/lib/**/*.dart,\
app/ios/Podfile,\
app/ios/Runner/Info.plist,\
app/ios/Runner/AppDelegate.swift,\
app/ios/Runner/GoogleService-Info.plist,\
app/ios/Flutter/AppFrameworkInfo.plist,\
app/pubspec.yaml,\
wm-db.txt,\
firebase.json,\
functions/index.js"
