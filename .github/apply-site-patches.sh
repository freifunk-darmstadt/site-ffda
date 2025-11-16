#!/bin/bash

set -e

REPO_PATH="$1"
PATCHES_PATH="$(pwd)/$2"

for patch in "$PATCHES_PATH"/*.patch; do
	[ -e "$patch" ] || continue
	echo "Applying patch $patch"
	git -C "$REPO_PATH" am "$patch"
done