#!/bin/bash

# Function to display and log version information
version_check() {
  tool=$1
  command=$2
  $command --version | head -n 1 | awk -v tool="$tool" '{print tool ": " $0}'
}

# Check versions of core user-facing tools and tee to file
(
  echo "Core User-Facing Tools:"
  version_check "Git" "git"
  version_check "jq" "jq"
  version_check "curl" "curl"
  version_check "Emacs" "emacs"
  version_check "ImageMagick" "convert"  
  version_check "OpenSSH" "ssh -V"
  version_check "AWS CLI" "aws --version"
  version_check "Bash" "bash --version"
  version_check "GnuPG" "gpg --version"
  version_check "Zsh" "zsh --version"
  version_check "Poetry" "poetry --version"
) | tee /tmp/tool_versions.txt

# Generate QR code and save to PNG file
mkdir -p /tmp/outputs  # Create the output directory if it doesn't exist
date=$(date +%Y-%m-%d)  # Get the current date
qrencode -o "/tmp/outputs/tool_versions_$date.png" < /tmp/tool_versions.txt

# Generate QR code of the concise list
qrencode -t UTF8 < /tmp/tool_versions.txt
