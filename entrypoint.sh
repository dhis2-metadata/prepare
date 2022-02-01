#!/usr/bin/env bash

set -euxo pipefail

declare -r WORKING_DIRECTORY="$1"
declare -r DEFAULT_PACKAGE_NAME="metadata.json"
declare -a PACKAGE_DIRS
declare CODE
declare PACKAGE_VERSION
declare DHIS2_VERSION
declare ARCHIVE_DIR
declare DESTINATION

# Find all sub-package directories.
findPackageDirs() {
  PACKAGE_DIRS=($(find * -type d | sort))
}

# $1 - directory
# Find "package" files.
findPackages() {
  find "$1" -type f -name "$DEFAULT_PACKAGE_NAME" | sort
}

# Create archive dir and it's destination, based on the package details.
createArchiveDir() {
  local first_package=$(findPackages *)

  getPackageDetails "$first_package"

  DESTINATION="$LOCALE/${CODE:0:4}/$PACKAGE_VERSION/DHIS$DHIS2_VERSION"

  ARCHIVE_DIR="${CODE:0:4}_${PACKAGE_VERSION}_DHIS${DHIS2_VERSION}"

  mkdir -p "../$ARCHIVE_DIR"
}

# Get the package details.
getPackageDetails() {
  local object=$(getPackageObject "$1")
  CODE=$(echo "$object" | jq -r '.code')
  PACKAGE_VERSION=$(echo "$object" | jq -r '.version')
  DHIS2_VERSION=$(echo "$object" | jq -r '.DHIS2Version' | cut -d '.' -f 1,2)
  LOCALE=$(echo "$object" | jq -r '.locale')
}

# Move packages to the archive directory.
movePackages() {
  for dir in "${PACKAGE_DIRS[@]}"
  do
    cp -r "$dir" "../$ARCHIVE_DIR"
  done

  local package_files=($(findPackages "../$ARCHIVE_DIR"))

  for file in "${package_files[@]}"
  do
    getPackageDetails "$file"
    mv "$file" "$(dirname $file)/${CODE}_${PACKAGE_VERSION}_DHIS${DHIS2_VERSION}.json"
  done
}

# $1 - file
# Check if the file is in a subset dir.
function isInSubsetDir {
  [[ "$1" =~ $SUBSET_DIR  ]]
}

# $1 - file
# If the extension is json, it's a "package".
isPackage() {
  local file=$(basename "$1")
  [[ "${file#*.}" == "json" ]]
}

# $1 - file
# If the extension is html or xlsx, it's a "reference".
isReference() {
  local file=$(basename "$1")
  [[ "${file#*.}" == "html" ]] || [[ "${file#*.}" == "xlsx" ]]
}

# $1 - file
# Get "package" JSON object from file.
getPackageObject() {
  if isPackage "$1"; then
    jq -r '.package' < "$1"
  fi
}

cd "$WORKING_DIRECTORY"

findPackageDirs

createArchiveDir

movePackages

echo "::set-output name=archive_dir::$ARCHIVE_DIR"
echo "::set-output name=destination::$DESTINATION"
