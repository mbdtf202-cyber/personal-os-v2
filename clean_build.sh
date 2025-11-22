#!/bin/bash
# Clean Xcode build artifacts
echo "Cleaning Xcode build artifacts..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo "Done! Please rebuild the project in Xcode."
