#!/usr/bin/env bash

set -euxo pipefail


declare -r WORKING_DIRECTORY="$1"
declare -r PACKAGE_VERSION="$2"

declare -r COMPLETE_PACKAGE="COMPLETE"
declare -r DASHBOARD_PACKAGE="DASHBOARD"
declare -r DASHBOARD_PACKAGE_TYPE="DSH"
declare -r DEFAULT_PACKAGE_NAME="metadata.json"

declare -a PACKAGE_DIRS

declare CODE
declare BASE_CODE
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
  local first_package=$(find_packages . | head -1)

  if [[ -z "$first_package" ]]; then
    echo "No package file found."
    exit 1
  fi

  get_package_details "$first_package"

  BASE_CODE=$(cut -d '_' -f 1,2 <<< "$CODE")

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
      CODE="${CODE}_${COMPLETE_PACKAGE}"
    fi

    if [[ "$TYPE" == "$DASHBOARD_PACKAGE_TYPE" ]]; then
      CODE="${CODE}_${DASHBOARD_PACKAGE}"
    fi

    local final_package_name="${CODE}_${PACKAGE_VERSION}_DHIS${DHIS2_VERSION}"

    mv "../$ARCHIVE_DIR/$dir/$DEFAULT_PACKAGE_NAME" "../$ARCHIVE_DIR/$dir/$final_package_name.json"
    mv "../$ARCHIVE_DIR/$dir" "../$ARCHIVE_DIR/$final_package_name"
  done
}

function verison_packages() {
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

  verison_packages

  echo "::set-output name=archive_dir::$ARCHIVE_DIR"
  echo "::set-output name=package_locale::$LOCALE"
  echo "::set-output name=package_code::$BASE_CODE"
  echo "::set-output name=dhis2_version::$DHIS2_VERSION"
}

main
