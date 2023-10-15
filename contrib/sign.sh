#!/bin/sh

set -e

SECRET="$1"
manifest="$2"

upper="$(mktemp)"

trap 'rm -f "$upper"' EXIT

awk 'BEGIN    {
	sep = 0
}

/^---$/ {
	sep = 1;
	next
}

{
	if(sep == 0) {
		print > "'"$upper"'"
	}
}' "$manifest"

ecdsasign "$upper" < "$SECRET"
