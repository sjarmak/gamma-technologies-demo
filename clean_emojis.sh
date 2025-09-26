#!/usr/bin/env bash
set -euo pipefail

echo "Cleaning emojis from repository files..."

# List of common emojis used in this repo
EMOJIS=(
"" "" "" "" "" "" "" "" "" "" 
"" "" "" "" "" "" "" "" "" ""
"" "" "" "" "" "" "" "" "" ""
"" "" "" "" "" "" "" "" "" ""
"" "" "" "" "" "" "" "" "" ""
"" "" "" "" "" "" "" "" "" ""
)

# Function to clean emojis from a file
clean_file() {
local file="$1"
echo "Cleaning: $file"

# Create temp file
local temp_file=$(mktemp)

# Copy original file
cp "$file" "$temp_file"

# Remove each emoji
for emoji in "${EMOJIS[@]}"; do
sed -i '' "s/$emoji//g" "$temp_file"
done

# Remove extra spaces that might have been left
sed -i '' 's/ */ /g' "$temp_file"
sed -i '' 's/^ *//g' "$temp_file"

# Replace original file
mv "$temp_file" "$file"
}

# Find and clean all markdown files
find . -name "*.md" -type f | while read -r file; do
clean_file "$file"
done

# Also clean any shell scripts that might have emojis
find . -name "*.sh" -type f | while read -r file; do
if grep -q "\|\|\|\|" "$file" 2>/dev/null; then
clean_file "$file"
fi
done

echo "Emoji cleaning completed."
