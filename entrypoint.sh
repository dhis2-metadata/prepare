#!/usr/bin/env bash

set -euxo pipefail

# TODO:
# Find all uploadable files (metadata.json, reference.xlsx) within the sub-package dirs (00, DB, ST, etc)
## Should sub-package dirs be listed explicitly or implicitly grab all existing ones?
# Rename metadata.json to "$packagePrefix_$packageVersion_$dhis2Version"
# New destination path in S3 is $locale/$package_prefix/$package_version/$dhis2_version

#declare -a SOURCES
#declare -r CHECKOUT_PATH="$1"
declare -a PACKAGE_DIRS
declare -r DEFAULT_PACKAGE_NAME="metadata.json"
#declare -r MAIN_DIR="complete"
#declare -r SUBSET_DIR="dashboard"
#declare DEFAULT_PATH
#declare DEFAULT_NAME
declare CODE
declare PACKAGE_VERSION
declare DHIS2_VERSION
declare ARCHIVE_DIR
declare DESTINATION
# TODO No need for strategy matrix?
#declare MATRIX="[]"

# TODO get uploadable dirs instead of files?
findPackageDirs() {
  PACKAGE_DIRS=($(find * -type d | sort))
#  SOURCES=($(find * -type f -name "metadata.json" -or -name "reference.xlsx" | sort))

#  if [ -d "$SUBSET_DIR" ]; then
#    subset=($(find "$SUBSET_DIR" -type f | sort))
#    SOURCES+=("${subset[@]}")
#  fi

#  echo "${SOURCES[@]}"
#  echo "${PACKAGE_DIRS[@]}"
}

findPackages() {
  find "$1" -type f -name "$DEFAULT_PACKAGE_NAME" | sort
}

# TODO should be outside the checkout path - ../ARCHIVE_DIR or $GITHUB_WORKSPACE/ARCHIVE_DIR
createArchiveDir() {
  # TODO should it use the first file found?
#  local OBJECT=$(getPackageObject "$SOURCES")

#  local CODE=$(echo "$OBJECT" | jq -r '.code')
#  local PACKAGE_VERSION=$(echo "$OBJECT" | jq -r '.version')
#  local DHIS2_VERSION=$(echo "$OBJECT" | jq -r '.DHIS2Version' | cut -d '.' -f 1,2)
  local first_package=$(findPackages *)

  getPackageDetails "$first_package"

  DESTINATION="$LOCALE/${CODE:0:4}/$PACKAGE_VERSION/$DHIS2_VERSION"

  ARCHIVE_DIR="../${CODE:0:4}_${PACKAGE_VERSION}_DHIS${DHIS2_VERSION}"

  mkdir -p "$ARCHIVE_DIR"
}

# TODO Globals bad?
getPackageDetails() {
  local object=$(getPackageObject "$1")
  CODE=$(echo "$object" | jq -r '.code')
  PACKAGE_VERSION=$(echo "$object" | jq -r '.version')
  DHIS2_VERSION=$(echo "$object" | jq -r '.DHIS2Version' | cut -d '.' -f 1,2)
  LOCALE=$(echo "$object" | jq -r '.locale')
}

# TODO cp parent dirs and rename the files
movePackages() {
#  files=("$@")
#  dirs=("$@")

  for dir in "${PACKAGE_DIRS[@]}"
  do
    cp -r "$dir" "$ARCHIVE_DIR"
  done

  local package_files=($(findPackages "$ARCHIVE_DIR"))

  for file in "${package_files[@]}"
  do
    getPackageDetails "$file"
    mv "$file" "$(dirname $file)/${CODE}_${PACKAGE_VERSION}_DHIS${DHIS2_VERSION}.json"
  done


#  for file in "${files[@]}"
#  do
#    if isPackage "$file"; then
#      local OBJECT=$(getPackageObject "$file")
#      local CODE=$(echo "$OBJECT" | jq -r '.code')
#      local PACKAGE_VERSION=$(echo "$OBJECT" | jq -r '.version')
#      local DHIS2_VERSION=$(echo "$OBJECT" | jq -r '.DHIS2Version' | cut -d '.' -f 1,2)
#      local SUB_PACKAGE=$(dirname "$file")
#
#      mkdir -p "${ARCHIVE_DIR}/${SUB_PACKAGE}"
#      cp "$file" "${ARCHIVE_DIR}/${SUB_PACKAGE}/${CODE}_${PACKAGE_VERSION}_DHIS${DHIS2_VERSION}.json"
#    fi
#
#    if isReference "$file"; then
#      mkdir -p "${ARCHIVE_DIR}/${SUB_PACKAGE}"
#      cp "$file" "${ARCHIVE_DIR}/${SUB_PACKAGE}/$(basename $file)"
#    fi
#  done
}

# $1 file
# check if the file is in a subset dir
function isInSubsetDir {
  [[ "$1" =~ $SUBSET_DIR  ]]
}

# $1 - file
# if the extension is json, it's a "package"
isPackage() {
  local file=$(basename "$1")
  [[ "${file#*.}" == "json" ]]
}

# $1 - file
# if the extension is html or xlsx, it's a "reference"
isReference() {
  local file=$(basename "$1")
  [[ "${file#*.}" == "html" ]] || [[ "${file#*.}" == "xlsx" ]]
}

# $1 - file
# get "package" JSON object from file
getPackageObject() {
  if isPackage "$1"; then
    jq -r '.package' < "$1"
  fi
}

# $1 & $2 - file path
# create source->destination JSON
#function createJson {
#  jq -n --arg key "$1" --arg value "$2" '[{"source": $key, "destination": $value}]'
#}

# $1 & $2 - JSON
# append JSON $2 to $1
#function addToJson {
#  echo "$1" | jq -c --argjson new "$2" '. += $new'
#}

# $1 - JSON
# create path from "package" JSON object
#function createPath {
#  # get package details from object
#  locale=$(echo "$1" | jq -r '.locale')
#  code=$(echo "$1" | jq -r '.code')
#  type=$(echo "$1" | jq -r '.type')
#  package_version=$(echo "$1" | jq -r '.version')
#  # remove "patch" part of version for path
#  dhis2_version=$(echo "$1" | jq -r '.DHIS2Version' | cut -d '.' -f 1,2)
#
#  # construct path
#  echo "$locale/$code/$type/$package_version/$dhis2_version"
#}

# $1 - array of files
# get default path and file name from the first "package" found
#function getDefaultDestination {
#  files=("$@")
#
#  for file in "${files[@]}"
#  do
#    object=$(getPackageObject "$file")
#
#    # remove locale from path
#    path=$(createPath "$object")
#    DEFAULT_PATH=${path#*/}
#
#    # remove locale from name
#    name=$(echo "$object" | jq -r '.name')
#    DEFAULT_NAME=${name%-*}
#
#    # return after first found file
#    return
#  done
#}

# $1 - source file
# $2 - destination path
# create destination from source file
#function createDestination {
#  addition=$(createJson "$1" "$2.${1#*.}")
#  MATRIX=$(addToJson "$MATRIX" "$addition")
#}

# $1 - array of files
# create matrix of sources and destinations
#function createMatrix {
#  files=("$@")
#
#  # default reference path and file name
#  getDefaultDestination "${files[@]}"
#
#  # create source -> destination for all files
#  for file in "${files[@]}"
#  do
#    packageObject=$(getPackageObject "$file")
#    path=$(createPath "$packageObject")
#
#    file_name=$(echo "$packageObject" | jq -r '.name')
#
#    if isPackage "$file"; then
#      # include subset dir in path if the file is coming from it
#      if isInSubsetDir "$file"; then
#        path+="/$SUBSET_DIR"
#      fi
#
#      createDestination "$file" "$path/$file_name"
#    fi
#
#    if isReference "$file"; then
#      # get reference locale from "parent" directory of the file
#      locale=$(basename $(dirname "$file"))
#
#      # include subset dir in path if the file is coming from it
#      if isInSubsetDir "$file"; then
#        createDestination "$file" "$locale/$DEFAULT_PATH/$SUBSET_DIR/$DEFAULT_NAME-$locale-ref"
#      else
#        createDestination "$file" "$locale/$DEFAULT_PATH/$DEFAULT_NAME-$locale-ref"
#      fi
#    fi
#  done
#}

findPackageDirs

createArchiveDir

movePackages

echo "::set-output name=archive_dir::$ARCHIVE_DIR"
echo "::set-output name=destination::$ARCHIVE_DIR"

exit 0
#####################################################
createMatrix "${SOURCES[@]}"

echo "$MATRIX" | jq

echo "::set-output name=matrix::$MATRIX"
