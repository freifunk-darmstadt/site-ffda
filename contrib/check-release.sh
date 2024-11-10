#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source "${SCRIPT_DIR}/functions-sign.sh"

declare -A SIGKEYS

SIGKEYS["hexa-"]="c8e33aa86b1d3ad894d744d76232fa6325efb63672c3b972bb91f5197e2a96f9"
SIGKEYS["braack"]="52b8c8de3985035ffcb0246e537396906357d8d244930947e4bb2c3da370fff7"
SIGKEYS["andi-"]="73bea808dd08c77b4c68c80e9ebe10f5690459b77a4ad0e5074a4583e5775cbc"
SIGKEYS["fluxx"]="af9a8c08f975d54c9015d015668d3a084e61af43180cbe23def3f79c6e80b32c"
SIGKEYS["blocktrron"]="910ddca3b0561bebcb112ea20b714114fe1598b3dd376177fe1c38ed58b1477f"
SIGKEYS["noxnox"]="daa74de3bf1aa87301a28ac9081d021de0c92299ec457d177014a026c888d288"
SIGKEYS["tomh"]="bead63b9e44f5243e3030a37fdc0d1cd3efce65234c7bedfcff6ae6452d42e79"
SIGKEYS["skorpy"]="0ebac3d341673dbeb8b6d2499811ce7851516aae851d71067a3e16488dee44c7"
SIGKEYS["alex"]="5b8ce650fc50d845975567bd5418fcd5c091528e48e95cf0e2f0266ed509e013"
SIGKEYS["build.ffda.io"]="24f20f0e0d7711181c70c85a76dda08334a96acd631994ace9b61b57a159db7b"
SIGKEYS["github-actions-ci"]="cea1e84bf157d7362287fcd21d13de14634341e3d1ea7038000062743554dc88"

function usage() {
    echo "Usage: $0 <release-version> <branch>"
    echo "Example: $0 3.0.2 stable"
    exit 1
}

function cleanup() {
    rm -rf "$TEMP_DIR"
}

RELEASE_VERSION="${1:-}"
BRANCH="${2:-}"

[ -z "$RELEASE_VERSION" ] && usage
[ -z "$BRANCH" ] && usage

# Create Temporary working directory
TEMP_DIR="$(mktemp -d)"

MANIFEST_PATH="${TEMP_DIR}/checking.manifest"

# Download released manifest archive
MANIFEST_URL="https://firmware.darmstadt.freifunk.net/images/${RELEASE_VERSION}/sysupgrade/${BRANCH}.manifest"
echo "Download manifest from $MANIFEST_URL"
curl -s -L -o "${MANIFEST_PATH}" "${MANIFEST_URL}"

for name in "${!SIGKEYS[@]}"
do
    valid_ci_signature="$(get_valid_signature "${MANIFEST_PATH}" "${SIGKEYS[$name]}")"

    # Check if manifest is signed with the key under test
    if [ -n "$valid_ci_signature" ]; then
        echo "Manifest is signed with the \"${name}\" key"
        echo "Signature: $valid_ci_signature"
    fi
done

cleanup
