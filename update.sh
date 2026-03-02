#!/bin/bash

# Read the version from pubspec.yaml
version=$(grep version pubspec.yaml | awk -F'[ +]' '{print $2}' | tr -d "'")

# Define the variable name and file name
variable="appVersion"
filename="lib/constants/version.dart"

# Write the version to the Dart file
echo "const $variable = '$version';" > $filename
