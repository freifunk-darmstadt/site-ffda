#!/bin/bash

set -euo pipefail

function usage() {
    echo "Usage: $0 <release-version> <private-key-path>"
    echo "Example: $0 2.0.0 /path/to/private-key.ecdsakey"
    exit 1
}

function get_signature() {
    local secret manifest upper

    secret="$1"
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

    ecdsasign "$upper" < "$secret"
    rm -f "$upper"
}

# This Script is used to sign a Firmware Release using
# a private ECDSA key.

DEFAULT_GITHUB_REPOSITORY_URL="freifunk-darmstadt/site-ffda"

GITHUB_REPOSITORY_URL="${GITHUB_REPOSITORY_URL:-$DEFAULT_GITHUB_REPOSITORY_URL}"

RELEASE_VERSION="${1:-}"
PRIVATE_KEY_PATH="${2:-}"

[ -z "$RELEASE_VERSION" ] && usage
[ -z "$PRIVATE_KEY_PATH" ] && usage

# Create Temporary working directory
TEMP_DIR="$(mktemp -d)"

# Download released manifest archive
MANIFEST_ARCHIVE_URL="https://github.com/${GITHUB_REPOSITORY_URL}/releases/download/${RELEASE_VERSION}/manifest.tar.xz"
echo "Download manifest archvie from $MANIFEST_ARCHIVE_URL"
curl -s -L -o "${TEMP_DIR}/manifest.tar.xz" "${MANIFEST_ARCHIVE_URL}"

# Extract manifest archive
echo "Extracting manifest archive to $TEMP_DIR"
tar xf "${TEMP_DIR}/manifest.tar.xz" -C "${TEMP_DIR}"

# Sign manifest
for manifest_path in "${TEMP_DIR}/"*.manifest; do
    echo ""

    # Get filename without extension
    manifest_branch_name="$(basename "$manifest_path" .manifest)"

    # Get Signature
    signature="$(get_signature "$PRIVATE_KEY_PATH" "$manifest_path")"

    echo "Signature for $manifest_branch_name"
    echo "$signature"
done

# Remove Temporary working directory
rm -rf "$TEMP_DIR"
