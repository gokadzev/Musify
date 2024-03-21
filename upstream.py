#!/usr/bin/env python3
import datetime
import re

# Get today's date
today = datetime.date.today()
# Format date as YYYY.MM.DD
new_version = today.strftime("%Y.%-m.%-d")

# Open and read the pubspec.yaml file
with open('pubspec.yaml', 'r') as file:
    data = file.read()

# Replace the version number with the new version
data = re.sub(r'version: \d+\.\d+\.\d+', 'version: ' + new_version, data)

# Write the updated content back to the file
with open('pubspec.yaml', 'w') as file:
    file.write(data)

# Print message indicating the version update
print(f"Flutter version updated to {new_version}")
