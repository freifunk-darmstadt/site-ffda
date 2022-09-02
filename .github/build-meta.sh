#!/bin/bash

set -euxo pipefail

SCRIPT_DIR="$(dirname "$0")"
UPSTREAM_REPO_NAME="freifunk-darmstadt/site-ffda"

OVERRIDES_DIR="$SCRIPT_DIR/overrides/build-meta"

function set_output_value() {
	local output_file="$1"
	local name="$2"
	local value="$3"

	# Check if override is defined
	if [ -f "$OVERRIDES_DIR/$name" ]; then
		value="$(cat "$OVERRIDES_DIR/$name")"
		echo "::notice::Overriding $name with value \"$value\""
	fi

	echo "$name=$value" >> "$output_file"
}

# Get Git short hash for repo at $SCRIPT_DIR
GIT_SHORT_HASH="$(git -C "$SCRIPT_DIR" rev-parse --short HEAD)"

# Get date of last Git commit for repo at $SCRIPT_DIR
GIT_COMMIT_DATE="$(git -C "$SCRIPT_DIR" log -1 --format=%cd --date=format:'%Y%m%d')"

# Build BROKEN by default. Disable for release builds.
BROKEN="1"

# Don't deploy by default. Enable for release and testing builds.
DEPLOY="0"

# Don't release by default. Enable for tags.
CREATE_RELEASE="0"

# This is not the latest release by default.
LATEST_RELEASE="0"

# Don't link release by default. Enable for testing.
LINK_RELEASE="0"

# Target whitelist
if [ -n "$WORKFLOW_DISPATCH_TARGETS" ]; then
	# Get targets from dispatch event
	TARGET_WHITELIST="$WORKFLOW_DISPATCH_TARGETS"
else
	# Get targets from build-info.json
	TARGET_WHITELIST="$(jq -r -e '.build.targets | join(" ")' "$SCRIPT_DIR/build-info.json")"
fi

# Release Branch regex
RELEASE_BRANCH_RE="^v20[0-9]{2}\.[0-9]\.x$"
# Regex for testing firmware tag
TESTING_TAG_RE="^[2-9].[0-9]-[0-9]{8}$"
# Regex for custom testing firmware tag
CUSTOM_TESTING_TAG_RE="^[2-9].[0-9]-[0-9]{8}"
# Regex for unstable firmware tag
UNSTABLE_TAG_RE="^[2-9].[0-9]u-[0-9]{8}$"
# Regex for custom unstable firmware tag
CUSTOM_UNSTABLE_TAG_RE="^[2-9].[0-9]u-[0-9]{8}"
# Regex for release firmware tag
RELEASE_TAG_RE="^[2-9].[0-9].[0-9]$"
# Regex for release deployment firmware tag
RELEASE_DEPLOYMENT_TAG_RE="^[2-9].[0-9].[0-9]"

# Get Gluon version information
if [ -n "$WORKFLOW_DISPATCH_REPOSITORY" ] && [ -n "$WORKFLOW_DISPATCH_REFERENCE" ]; then
	# Get Gluon version information from dispatch event
	GLUON_REPOSITORY="$WORKFLOW_DISPATCH_REPOSITORY"
	GLUON_COMMIT="$WORKFLOW_DISPATCH_REFERENCE"
else
	# Get Gluon version information from build-info.json
	GLUON_REPOSITORY="$(jq -r -e .gluon.repository "$SCRIPT_DIR/build-info.json")"
	GLUON_COMMIT="$(jq -r -e .gluon.commit "$SCRIPT_DIR/build-info.json")"
fi

# Get Container version information
CONTAINER_VERSION="$(jq -r -e .container.version "$SCRIPT_DIR/build-info.json")"

# Get Default Release version from site.mk
DEFAULT_RELEASE_VERSION="$(make --no-print-directory -C "$SCRIPT_DIR/.." -f ci-build.mk version)"
DEFAULT_RELEASE_VERSION="$DEFAULT_RELEASE_VERSION-$GIT_SHORT_HASH"

# Create site-version from site.mk
SITE_VERSION="$(make --no-print-directory -C "$SCRIPT_DIR/.." -f ci-build.mk site-version)"
SITE_VERSION="$SITE_VERSION-ffda-$GIT_COMMIT_DATE-$GIT_SHORT_HASH"

# Enable Manifest generation conditionally
MANIFEST_STABLE="0"
MANIFEST_BETA="0"
MANIFEST_TESTING="0"
MANIFEST_UNSTABLE="0"

# Only Sign manifest on release builds
SIGN_MANIFEST="0"

echo "GitHub Event-Name: $GITHUB_EVENT_NAME"
echo "GitHub Ref-Type: $GITHUB_REF_TYPE"
echo "GitHub Ref-Name: $GITHUB_REF_NAME"

if [ "$GITHUB_EVENT_NAME" = "push"  ] && [ "$GITHUB_REF_TYPE" = "branch" ]; then
	if [ "$GITHUB_REF_NAME" = "master" ]; then
		# Push to master - autoupdater Branch is testing and enabled
		AUTOUPDATER_ENABLED="1"
		AUTOUPDATER_BRANCH="testing"

		MANIFEST_TESTING="1"
	elif [ "$GITHUB_REF_NAME" = "unstable" ]; then
		# Push to unstable - autoupdater Branch is unstable and enabled
		AUTOUPDATER_ENABLED="1"
		AUTOUPDATER_BRANCH="unstable"

		MANIFEST_UNSTABLE="1"
	elif [[ "$GITHUB_REF_NAME" =~ $RELEASE_BRANCH_RE ]]; then
		# Push to release branch - autoupdater Branch is stable and enabled
		AUTOUPDATER_ENABLED="1"
		AUTOUPDATER_BRANCH="stable"

		MANIFEST_STABLE="1"
		MANIFEST_BETA="1"
	else
		# Push to unknown branch - Disable autoupdater
		AUTOUPDATER_ENABLED="0"
		AUTOUPDATER_BRANCH="testing"
	fi
elif [ "$GITHUB_EVENT_NAME" = "push"  ] && [ "$GITHUB_REF_TYPE" = "tag" ]; then
	if [[ "$GITHUB_REF_NAME" =~ $TESTING_TAG_RE ]]; then
		# Testing release - autoupdater Branch is testing and enabled
		AUTOUPDATER_ENABLED="1"
		AUTOUPDATER_BRANCH="testing"

		MANIFEST_TESTING="1"
		SIGN_MANIFEST="1"

		RELEASE_VERSION="$(echo "$GITHUB_REF_NAME" | tr '-' '~')"
		DEPLOY="1"
		LINK_RELEASE="1"
	elif [[ "$GITHUB_REF_NAME" =~ $UNSTABLE_TAG_RE ]]; then
		# unstable release - autoupdater Branch is unstable and enabled
		AUTOUPDATER_ENABLED="1"
		AUTOUPDATER_BRANCH="unstable"

		MANIFEST_UNSTABLE="1"
		SIGN_MANIFEST="1"

		RELEASE_VERSION="$(echo "$GITHUB_REF_NAME" | tr '-' '~')"
		DEPLOY="1"
		LINK_RELEASE="1"
	elif [[ "$GITHUB_REF_NAME" =~ $RELEASE_TAG_RE ]]; then
		# Stable release - autoupdater Branch is stable and enabled
		AUTOUPDATER_ENABLED="1"
		AUTOUPDATER_BRANCH="stable"

		MANIFEST_STABLE="1"
		MANIFEST_BETA="1"
		SIGN_MANIFEST="1"

		LATEST_RELEASE="1"

		RELEASE_VERSION="$GITHUB_REF_NAME"
		BROKEN="0"
		DEPLOY="1"
	elif [[ "$GITHUB_REF_NAME" =~ $RELEASE_DEPLOYMENT_TAG_RE ]]; then
		# Deployment release - autoupdater Branch is stable and enabled
		AUTOUPDATER_ENABLED="1"
		AUTOUPDATER_BRANCH="stable"

		RELEASE_VERSION="$GITHUB_REF_NAME"
		BROKEN="1"
		DEPLOY="0"
	else
		# Unknown release - Disable autoupdater
		AUTOUPDATER_ENABLED="0"
		AUTOUPDATER_BRANCH="testing"

		if [[ "$GITHUB_REF_NAME" =~ $CUSTOM_TESTING_TAG_RE ]]; then
			# Custom testing tag

			# Replace first occurence of - with ~ of GITHUB_REF_NAME for RELEASE_VERSION
			# shellcheck disable=SC2001
			RELEASE_VERSION="$(echo "$GITHUB_REF_NAME" | sed 's/-/~/')"
		elif [[ "$GITHUB_REF_NAME" =~ $CUSTOM_UNSTABLE_TAG_RE ]]; then
			AUTOUPDATER_BRANCH="unstable"
			# Custom unstable tag

			# Replace first occurence of - with ~ of GITHUB_REF_NAME for RELEASE_VERSION
			# shellcheck disable=SC2001
			RELEASE_VERSION="$(echo "$GITHUB_REF_NAME" | sed 's/-/~/')"
		fi

	fi

	CREATE_RELEASE="1"
elif [ "$GITHUB_EVENT_NAME" = "workflow_dispatch" ] || [ "$GITHUB_EVENT_NAME" = "pull_request" ]; then
	# Workflow Dispatch - autoupdater Branch is testing and disabled
	AUTOUPDATER_ENABLED="0"
	AUTOUPDATER_BRANCH="testing"
else
	echo "Unknown ref type $GITHUB_REF_TYPE"
	exit 1
fi

# Ensure we don't {sign,deploy,release} on pull requests
if [ "$GITHUB_EVENT_NAME" = "pull_request" ]; then
	DEPLOY="0"
	CREATE_RELEASE="0"
	SIGN_MANIFEST="0"
fi

# Signing should only happen when pushed to the upstream repository.
# Skip this step for the pipeline to succeed but inform the user.
if [ "$GITHUB_REPOSITORY" != "$UPSTREAM_REPO_NAME" ] && [ "$SIGN_MANIFEST" != "0" ]; then
	SIGN_MANIFEST="0"

	echo "::warning::Skip manifest signature due to action running in fork."
fi

# We should neither deploy in a fork, as the workflow is hard-coding out firmware-server
if [ "$GITHUB_REPOSITORY" != "$UPSTREAM_REPO_NAME" ] && [ "$DEPLOY" != "0" ]; then
	DEPLOY="0"

	echo "::warning::Skip deployment due to action running in fork."
fi

# Determine Version to use
RELEASE_VERSION="${RELEASE_VERSION:-$DEFAULT_RELEASE_VERSION}"

# Write build-meta to dedicated file before appending GITHUB_OUTPUT.
# This way, we can create an artifact for our build-meta to eventually upload to a release.
BUILD_META_TMP_DIR="$(mktemp -d)"
BUILD_META_OUTPUT="$BUILD_META_TMP_DIR/build-meta.txt"

# shellcheck disable=SC2129
# Not the nicest way to do this, but it works.
set_output_value "$BUILD_META_OUTPUT" "build-meta-output" "$BUILD_META_TMP_DIR"
set_output_value "$BUILD_META_OUTPUT" "container-version" "$CONTAINER_VERSION"
set_output_value "$BUILD_META_OUTPUT" "gluon-repository" "$GLUON_REPOSITORY"
set_output_value "$BUILD_META_OUTPUT" "gluon-commit" "$GLUON_COMMIT"
set_output_value "$BUILD_META_OUTPUT" "site-version" "$SITE_VERSION"
set_output_value "$BUILD_META_OUTPUT" "release-version" "$RELEASE_VERSION"
set_output_value "$BUILD_META_OUTPUT" "autoupdater-enabled" "$AUTOUPDATER_ENABLED"
set_output_value "$BUILD_META_OUTPUT" "autoupdater-branch" "$AUTOUPDATER_BRANCH"
set_output_value "$BUILD_META_OUTPUT" "broken" "$BROKEN"
set_output_value "$BUILD_META_OUTPUT" "manifest-stable" "$MANIFEST_STABLE"
set_output_value "$BUILD_META_OUTPUT" "manifest-beta" "$MANIFEST_BETA"
set_output_value "$BUILD_META_OUTPUT" "manifest-testing" "$MANIFEST_TESTING"
set_output_value "$BUILD_META_OUTPUT" "manifest-unstable" "$MANIFEST_UNSTABLE"
set_output_value "$BUILD_META_OUTPUT" "sign-manifest" "$SIGN_MANIFEST"
set_output_value "$BUILD_META_OUTPUT" "deploy" "$DEPLOY"
set_output_value "$BUILD_META_OUTPUT" "link-release" "$LINK_RELEASE"
set_output_value "$BUILD_META_OUTPUT" "create-release" "$CREATE_RELEASE"
set_output_value "$BUILD_META_OUTPUT" "latest-release" "$LATEST_RELEASE"
set_output_value "$BUILD_META_OUTPUT" "target-whitelist" "$TARGET_WHITELIST"

# Copy over to GITHUB_OUTPUT
cat "$BUILD_META_OUTPUT" >> "$GITHUB_OUTPUT"

# Display Output so we can conveniently check it from CI log viewer
cat "$GITHUB_OUTPUT"

exit 0
