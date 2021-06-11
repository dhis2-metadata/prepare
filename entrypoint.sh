#!/usr/bin/env bash

set -e

declare -a SOURCES
declare -r MAIN_DIR="complete"
declare -r SUBSET_DIR="dashboard"
declare DEFAULT_PATH
declare DEFAULT_NAME
declare MATRIX="[]"

# create array of source files for upload
function getUploadables {
  SOURCES=($(find "$MAIN_DIR" -type f | sort))

  if [ -d "$SUBSET_DIR" ]; then
    subset=($(find "$SUBSET_DIR" -type f | sort))
    SOURCES+=("${subset[@]}")
  fi
}

# $1 file
# check if the file is in a subset dir
function isInSubsetDir {
  [[ "$1" =~ $SUBSET_DIR  ]]
}

# $1 - file
# if the extension is json, it's a "package"
function isPackage {
  [[ "${1#*.}" == "json" ]]
}

# $1 - file
# if the extension is html or xlsx, it's a "reference"
function isReference {
  [[ "${1#*.}" == "html" ]] || [[ "${1#*.}" == "xlsx" ]]
}

# $1 - file
# get "package" JSON object from file
function getPackageObject {
  if isPackage "$1"; then
    jq -r '.package' < "$1"
  fi
}

# $1 & $2 - file path
# create source->destination JSON
function createJson {
  jq -n --arg key "$1" --arg value "$2" '[{"source": $key, "destination": $value}]'
}

# $1 & $2 - JSON
# append JSON $2 to $1
function addToJson {
  echo "$1" | jq -c --argjson new "$2" '. += $new'
}

# $1 - JSON
# create path from "package" JSON object
function createPath {
  # get package details from object
  locale=$(echo "$1" | jq -r '.locale')
  code=$(echo "$1" | jq -r '.code')
  type=$(echo "$1" | jq -r '.type')
  package_version=$(echo "$1" | jq -r '.version')
  # remove "patch" part of version for path
  dhis2_version=$(echo "$1" | jq -r '.DHIS2Version' | cut -d '.' -f 1,2)

  # construct path
  echo "$locale/$code/$type/$package_version/$dhis2_version"
}

# $1 - array of files
# get default path and file name from the first "package" found
function getDefaultDestination {
  files=("$@")

  for file in "${files[@]}"
  do
    object=$(getPackageObject "$file")

    # remove locale from path
    path=$(createPath "$object")
    DEFAULT_PATH=${path#*/}

    # remove locale from name
    name=$(echo "$object" | jq -r '.name')
    DEFAULT_NAME=${name%-*}

    # return after first found file
    return
  done
}

# $1 - source file
# $2 - destination path
# create destination from source file
function createDestination {
  addition=$(createJson "$1" "$2.${1#*.}")
  MATRIX=$(addToJson "$MATRIX" "$addition")
}

# $1 - array of files
# create matrix of sources and destinations
function createMatrix {
  files=("$@")

  # default reference path and file name
  getDefaultDestination "${files[@]}"

  # create source -> destination for all files
  for file in "${files[@]}"
  do
    packageObject=$(getPackageObject "$file")
    path=$(createPath "$packageObject")

    file_name=$(echo "$packageObject" | jq -r '.name')

    if isPackage "$file"; then
      # include subset dir in path if the file is coming from it
      if isInSubsetDir "$file"; then
        path+="/$SUBSET_DIR"
      fi

      createDestination "$file" "$path/$file_name"
    fi

    if isReference "$file"; then
      # get reference locale from "parent" directory of the file
      locale=$(basename $(dirname "$file"))

      # include subset dir in path if the file is coming from it
      if isInSubsetDir "$file"; then
        createDestination "$file" "$locale/$DEFAULT_PATH/$SUBSET_DIR/$DEFAULT_NAME-$locale-ref"
      else
        createDestination "$file" "$locale/$DEFAULT_PATH/$DEFAULT_NAME-$locale-ref"
      fi
    fi
  done
}

getUploadables

createMatrix "${SOURCES[@]}"

echo "::set-output name=matrix::$MATRIX"
