#!/bin/bash

# Validate no files in .github/overrides/build-meta contain newlines

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"

OVERRIDES_DIR="$SCRIPT_DIR/overrides/build-meta"

FILES_WITH_TWO_LINES=""

# Find all files which contain at lest two lines
while IFS= read -r -d '' file
do
	if [ "$(wc -l < "$file")" -gt 1 ]; then
		FILES_WITH_TWO_LINES="$FILES_WITH_TWO_LINES $file"
	fi
done <   <(find "$OVERRIDES_DIR" -type f -print0)

# Check for newlines in overrides
if [ -n "$FILES_WITH_TWO_LINES" ]; then
	echo "The following files contain newlines:"
	echo "$FILES_WITH_TWO_LINES"
	exit 1
fi

exit 0
