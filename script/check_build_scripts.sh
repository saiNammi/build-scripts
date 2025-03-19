#!/bin/bash

# Fail on any error
set -e

VARIABLE_FILE="script/variable.sh"

# Fetch modified build scripts
MODIFIED_SCRIPTS=$(git diff --name-only origin/validate_wheel_on_pr...HEAD -- '*.sh')

# Fetch modified build_info.json files
MODIFIED_JSONS=$(git diff --name-only origin/validate_wheel_on_pr...HEAD -- '*/build_info.json')

# Exit if no build scripts are modified
if [[ -z "$MODIFIED_SCRIPTS" ]]; then
  echo "No build script modifications detected. Exiting Travis job."
  exit 0
fi

for script in $MODIFIED_SCRIPTS; do
  echo "printing script path $script"
  PACKAGE_DIR=$(dirname "$script")
  BUILD_SCRIPT_PATH="$(pwd)/$script"
  BUILD_INFO_FILE="$(pwd)/$PACKAGE_DIR/build_info.json"

  echo "----------------------------------"
  echo "Build Script: $BUILD_SCRIPT_PATH"
  echo "Package Directory: $PACKAGE_DIR"

  # Check if build_info.json is modified
  if echo "$MODIFIED_JSONS" | grep -q "$BUILD_INFO_FILE"; then
    echo "Using modified build_info.json"
    VERSION=$(git show HEAD:"$BUILD_INFO_FILE" | jq -r '.version')
    WHEEL_BUILD=$(git show HEAD:"$BUILD_INFO_FILE" | jq -r '.wheel_build')
  elif [[ -f "$BUILD_INFO_FILE" ]]; then
    echo "Using existing build_info.json"
    echo "Checking file: $BUILD_INFO_FILE"
    cat "$BUILD_INFO_FILE"  # Debug: Print file content
    
    VERSION=$(jq -r '.version' "$BUILD_INFO_FILE")
    WHEEL_BUILD=$(jq -r '.wheel_build' "$BUILD_INFO_FILE")
    echo "Extracted Version: $VERSION"
    echo "Extracted Wheel Build: $WHEEL_BUILD"
  else
    echo "No build_info.json found in $PACKAGE_DIR"
    exit 0
  fi

  echo "Version: $VERSION"
  echo "Wheel Build: $WHEEL_BUILD"

  if [[ "$WHEEL_BUILD" == "false" ]]; then
    echo "wheel_build is set to false. Exiting Travis job."
    exit 0
  fi

  # Append variables to variable.sh
  echo "export PKG_DIR_PATH=\"$(pwd)/\"" >> "$VARIABLE_FILE"
  echo "export BUILD_SCRIPT=\"$script\"" >> "$VARIABLE_FILE"
  echo "export VERSION=\"$VERSION\"" >> "$VARIABLE_FILE"

  chmod +x script/variable.sh

  # Proceed with further steps
  echo "Processing $PACKAGE_DIR..."
done
