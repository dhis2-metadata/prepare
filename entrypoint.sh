#!/usr/bin/env bash

set -euxo pipefail

declare -r WORKING_DIRECTORY="$1"
declare -r PACKAGE_VERSION="$2"
declare -r DEFAULT_PACKAGE_NAME="metadata.json"
declare -r DEFAULT_PACKAGE_DIR="packages"
declare -r COMPLETE_PACKAGE="COMPLETE"
declare -r DASHBOARD_PACKAGE="DASHBOARD"
declare -r DASHBOARD_PACKAGE_TYPE="DSH"
declare -a PACKAGE_DIRS
declare CODE
declare BASE_CODE
declare TYPE
declare DHIS2_VERSION
declare LOCALE
declare ARCHIVE_DIR

# Find all package directories.
# TODO Remove?
findPackageDirs() {
  PACKAGE_DIRS=($(find $DEFAULT_PACKAGE_DIR/* -type d | sort))

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
  local first_package=($(findPackages $DEFAULT_PACKAGE_DIR/* | head -1))

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
  # TODO Remove?
#  for dir in "${PACKAGE_DIRS[@]}"
#  do
#    cp -r "$dir" "../$ARCHIVE_DIR"
#  done
  cp -r "$DEFAULT_PACKAGE_DIR/" "../$ARCHIVE_DIR"

  local package_files=($(findPackages "../$ARCHIVE_DIR"))

  if [[ -z "$package_files" ]]; then
    echo "No package files found in the archive dir."
    exit 1
  fi

  echo "${package_files[@]}"
  local dashboard_packages=()
  local non_dashboard_packages=()

  # filter dashboard packages
  for file in "${package_files[@]}"
  do
    getPackageDetails "$file"

    if [[ "$TYPE" == "$DASHBOARD_PACKAGE_TYPE" ]]; then
      dashboard_packages+=("$file")
    else
      non_dashboard_packages+=("$file")
    fi
  done

  # create func
  for file in "${dashboard_packages[@]}"
  do
    getPackageDetails "$file"

    local package_name="$CODE"

    if [[ "$CODE" == "$BASE_CODE" ]]; then
      package_name="${package_name}_${COMPLETE_PACKAGE}"
    fi

    package_name="${package_name}_${DASHBOARD_PACKAGE}_${PACKAGE_VERSION}_DHIS${DHIS2_VERSION}"
    mv "$file" "$(dirname $file)/$package_name.json"
    mv "$(dirname $file)" "$(dirname $(dirname $file))/$package_name"
  done

  # create func
  for file in "${non_dashboard_packages[@]}"
  do
    getPackageDetails "$file"

    local package_name="$CODE"

    if [[ "$CODE" == "$BASE_CODE" ]]; then
      package_name="${package_name}_${COMPLETE_PACKAGE}"
    fi

    package_name="${package_name}_${PACKAGE_VERSION}_DHIS${DHIS2_VERSION}"
    mv "$file" "$(dirname $file)/$package_name.json"
    mv "$(dirname $file)" "$(dirname $(dirname $file))/$package_name"
  done

#  for file in "${package_files[@]}"
#  do
#    getPackageDetails "$file"
#
#    local basepackage_name="$CODE"
#    local package_name="$basepackage_name"
#    local package_suffix="_${PACKAGE_VERSION}_DHIS${DHIS2_VERSION}"
#    local package_dir
#
#    # start with dashboards, rest in another list for later
#    if [[ "$TYPE" == "$DASHBOARD_PACKAGE_TYPE" ]]; then
#      mv "$file" "$(dirname $file)/${basepackage_name}_${DASHBOARD_PACKAGE}.json"
#    else
#      non_dashboard_packages+=("$file")
#    fi

#    mv "$file" "$(dirname $file)/$final_package_name.json"
#    mv "$(dirname $file)" "../$ARCHIVE_DIR/$final_package_dir"

#    # If the package is a complete/full one - add COMPLETE identifier to dir/file name.
#    if [[ "$CODE" == "$BASE_CODE" ]]; then
#      package_name="${basepackage_name}_${COMPLETE_PACKAGE}"
#
#      package_dir="$package_name"
#    fi
#
#    # If the package type is dashboard - add DASHBOARD identifier to dir/file name.
#    if [[ "$TYPE" == "$DASHBOARD_PACKAGE_TYPE" ]]; then
#      package_name="${package_name}_${DASHBOARD_PACKAGE}"
#
#      package_dir="$basepackage_name/$package_name"
#    fi
#
#    local final_package_name="${package_name}_${package_suffix}"
#
#    local final_package_dir="${package_dir}_${package_suffix}"
#
##    mv "$file" "$(dirname $file)/$final_package_name.json"
##    mv "$(dirname $file)" "../$ARCHIVE_DIR/$final_package_dir"
#  done
}

cd "$WORKING_DIRECTORY"

findPackageDirs

createArchiveDir

movePackages

echo "::set-output name=archive_dir::$ARCHIVE_DIR"
echo "::set-output name=package_locale::$LOCALE"
echo "::set-output name=package_code::$BASE_CODE"
echo "::set-output name=dhis2_version::$DHIS2_VERSION"
