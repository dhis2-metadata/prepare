#!/usr/bin/env bash

set -euxo pipefail


declare -r WORKING_DIRECTORY="$1"
declare -r PACKAGE_VERSION="$2"

declare -r COMPLETE_PACKAGE="COMPLETE"
declare -r DASHBOARD_PACKAGE="DASHBOARD"
declare -r DASHBOARD_PACKAGE_TYPE="DSH"
declare -r DEFAULT_PACKAGE_NAME="metadata.json"

declare -a PACKAGE_DIRS

declare CODE # The code of the current package component.
declare FULL_CODE # The code of the COMPLETE package component for multi-component packages or other standalone package category.
declare BASE_CODE # The code of the package.
declare TYPE
declare DHIS2_VERSION
declare LOCALE
declare ARCHIVE_DIR


# Find all package directories.
function find_package_dirs() {
  PACKAGE_DIRS=($(find * -type d | sort))

  if [[ -z "$PACKAGE_DIRS" ]]; then
    echo "No package directories found."
    exit 1
  fi
}

# $1 - directory
# Find "package" files within a given directory.
function find_packages() {
  find "$1" -type f -name "${2:-*.json}" | sort
}

# $1 - file
# If the file's extension is json, it's a "package".
function is_package() {
  local file=$(basename "$1")
  [[ "${file#*.}" == "json" ]]
}

# $1 - file
# Get "package" JSON object from file.
function get_package_object() {
  if is_package "$1"; then
    jq -r '.package' < "$1"
  fi
}

# Get the package details.
function get_package_details() {
  local object=$(get_package_object "$1")
  CODE=$(echo "$object" | jq -r '.code')
  TYPE=$(echo "$object" | jq -r '.type')
  DHIS2_VERSION=$(echo "$object" | jq -r '.DHIS2Version' | cut -d '.' -f 1,2)
  LOCALE=$(echo "$object" | jq -r '.locale')
}

# Create archive dir based on the package details.
function create_archive_dir() {
  local packages=$(find_packages .)
  local first_package=$(echo "$packages"| head -1)
  local complete_package="$COMPLETE_PACKAGE/$DEFAULT_PACKAGE_NAME"

  # shellcheck disable=SC2143
  if [[ -n $(echo "$packages" | grep "$complete_package") ]]; then
    get_package_details "$complete_package"
    FULL_CODE="${CODE}_${COMPLETE_PACKAGE}"
  else
    get_package_details "$first_package"
    FULL_CODE="$CODE"
  fi

  BASE_CODE="$CODE"

  ARCHIVE_DIR="${BASE_CODE}_${PACKAGE_VERSION}_DHIS${DHIS2_VERSION}"

  mkdir -p "../$ARCHIVE_DIR"
}

# Move packages to the archive directory with human-readable names.
function move_packages() {
  for dir in "${PACKAGE_DIRS[@]}"
  do
    cp -r "$dir" "../$ARCHIVE_DIR"
    get_package_details "../$ARCHIVE_DIR/$dir/$DEFAULT_PACKAGE_NAME"

    if [[ "$CODE" == "$BASE_CODE" ]]; then
      CODE="$FULL_CODE"
    fi

    if [[ "$TYPE" == "$DASHBOARD_PACKAGE_TYPE" ]]; then
      CODE="${CODE}_${DASHBOARD_PACKAGE}"
    fi

    local final_package_name="${CODE}_${PACKAGE_VERSION}_DHIS${DHIS2_VERSION}"

    mv "../$ARCHIVE_DIR/$dir/$DEFAULT_PACKAGE_NAME" "../$ARCHIVE_DIR/$dir/$final_package_name.json"
    mv "../$ARCHIVE_DIR/$dir" "../$ARCHIVE_DIR/$final_package_name"
  done
}

function version_packages() {
  local package_files=($(find_packages "../$ARCHIVE_DIR"))

  for file in "${package_files[@]}"
  do
    local tmp_file=$(mktemp)
    jq ".package .version = \"$PACKAGE_VERSION\"" "$file" > "$tmp_file" && mv "$tmp_file" "$file"
  done
}

function main() {
  cd "$WORKING_DIRECTORY"

  find_package_dirs

  create_archive_dir

  move_packages

  version_packages

  echo "archive_dir=$ARCHIVE_DIR" >> $GITHUB_OUTPUT
  echo "package_locale=$LOCALE" >> $GITHUB_OUTPUT
  echo "package_code=$FULL_CODE" >> $GITHUB_OUTPUT
  echo "package_base_code=$BASE_CODE" >> $GITHUB_OUTPUT
  echo "dhis2_version=$DHIS2_VERSION" >> $GITHUB_OUTPUT
}

main
