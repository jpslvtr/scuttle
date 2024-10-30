#!/bin/bash

# Exit on error
set -e

cd ..
cd app

echo "Cleaning Flutter project..."
flutter clean

echo "Getting Flutter dependencies..."
flutter pub get

echo "Moving to iOS directory..."
cd ios

echo "Removing Pods..."
rm -rf Pods
rm -rf Podfile.lock

echo "Installing Pods..."
pod install

echo "Moving back to app directory..."
cd ..

echo "Running Flutter..."
flutter run