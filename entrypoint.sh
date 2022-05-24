#!/usr/bin/env bash

set -euxo pipefail

declare -r WORKING_DIRECTORY="$1"
declare -r PACKAGE_VERSION="$2"
declare -r DEFAULT_PACKAGE_NAME="metadata.json"
declare -a PACKAGE_DIRS
declare CODE
declare BASE_CODE
declare TYPE
declare DHIS2_VERSION
declare LOCALE
declare ARCHIVE_DIR

# Find all package directories.
findPackageDirs() {
  PACKAGE_DIRS=($(find * -type d | sort))

  if [[ -z "$PACKAGE_DIRS" ]]; then
    echo "No package directories found."
    exit 1
  fi
}

# $1 - directory
# Find "package" files within a given directory.
findPackages() {
  find "$1" -type f -name "$DEFAULT_PACKAGE_NAME" | sort
}

# $1 - file
# If the file's extension is json, it's a "package".
isPackage() {
  local file=$(basename "$1")
  [[ "${file#*.}" == "json" ]]
}

# $1 - file
# Get "package" JSON object from file.
getPackageObject() {
  if isPackage "$1"; then
    jq -r '.package' < "$1"
  fi
}

# Get the package details.
getPackageDetails() {
  local object=$(getPackageObject "$1")
  CODE=$(echo "$object" | jq -r '.code')
  TYPE=$(echo "$object" | jq -r '.type')
  DHIS2_VERSION=$(echo "$object" | jq -r '.DHIS2Version' | cut -d '.' -f 1,2)
  LOCALE=$(echo "$object" | jq -r '.locale')
}

# Create archive dir based on the package details.
createArchiveDir() {
  local first_package=$(findPackages *)

  if [[ -z "$first_package" ]]; then
    echo "No package file found."
    exit 1
  fi

  getPackageDetails "$first_package"

  BASE_CODE=$(cut -d '_' -f 1,2 <<< "$CODE")

  ARCHIVE_DIR="${BASE_CODE}_${PACKAGE_VERSION}_DHIS${DHIS2_VERSION}"

  mkdir -p "../$ARCHIVE_DIR"
}

# Move packages to the archive directory.
movePackages() {
  for dir in "${PACKAGE_DIRS[@]}"
  do
    cp -r "$dir" "../$ARCHIVE_DIR"
  done

  local package_files=($(findPackages "../$ARCHIVE_DIR"))

  if [[ -z "$package_files" ]]; then
    echo "No package files found in the archive dir."
    exit 1
  fi

  for file in "${package_files[@]}"
  do
    getPackageDetails "$file"

    if [[ "$TYPE" == "DSH" ]]; then
      CODE="${CODE}_${TYPE}"
    fi

    mv "$file" "$(dirname $file)/${CODE}_${PACKAGE_VERSION}_DHIS${DHIS2_VERSION}.json"
  done
}

cd "$WORKING_DIRECTORY"

findPackageDirs

createArchiveDir

movePackages

echo "::set-output name=archive_dir::$ARCHIVE_DIR"
echo "::set-output name=package_locale::$LOCALE"
echo "::set-output name=package_code::$BASE_CODE"
echo "::set-output name=dhis2_version::$DHIS2_VERSION"
