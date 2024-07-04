#!/bin/bash

cd app

# Clean Flutter project
flutter clean

# Get Flutter packages
flutter pub get

# Navigate to iOS directory
cd ios

# Deintegrate CocoaPods
pod deintegrate

# Install CocoaPods
pod install

# Navigate back to root directory
cd ..

# Run Flutter project
flutter run
