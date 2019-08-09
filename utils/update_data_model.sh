#!/bin/sh

: '
This script updates a Data Model by copying its content from the FIWARE Data Models Repository


Usage: update_data_model.sh <dataModelName>

'

# -- PREPARATION PHASE --

TMP_DIRECTORY=__temp__

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <dataModelName>" >&2
  exit 1
fi

if [ -z "$TMP_DIRECTORY" ]; then
  echo "Please define the TMP_DIRECTORY env variable" >&2
  exit 1
fi

if [ -d "$TMP_DIRECTORY" ]; then
  rm -Rf ./$TMP_DIRECTORY
fi

mkdir $TMP_DIRECTORY && cd $TMP_DIRECTORY && mkdir backup && mkdir source

cd source
git clone https://github.com/FIWARE/dataModels

SOURCE_DATA_MODELS=`pwd`/dataModels

if [ -z "$SOURCE_DATA_MODELS" ]; then
  echo "Please define the SOURCE_DATA_MODELS env variable" >&2
  exit 1
fi


if [ ! -d "$SOURCE_DATA_MODELS/specs/$1" ]; then
  echo "Source Data Model does not exist" >&2
  exit 1
fi  


echo "Source Data Models: $SOURCE_DATA_MODELS"
echo "Data Model to be created: $1"

cd ../..

# End of the preparation phase

# ----- PROCESS STARTS HERE ----

cd ./$TMP_DIRECTORY

# Then clone the repository
git clone https://github.com/smart-data-models/dataModel.$1
git clone https://github.com/smart-data-models/dataModels

cd dataModel.$1

# Common Repository stuff
rsync -av --progress ../dataModels/templates/dataModel-Repository/ ./

# Copying Data Model Content
rsync -av --progress --exclude=harvest --exclude=unsupported --exclude=*.py --exclude=*.js --exclude=*.csv --exclude=auxiliary $SOURCE_DATA_MODELS/specs/$1/ ./


# If there is introduction but not README then move it
if [ -f "doc/introduction.md" ]; then
    rm README.md
    mv doc/introduction.md README.md
    rmdir doc
fi

# Now we add the corresponding badges to the README
mv README.md README.md.tmp
echo "[![Status badge](https://img.shields.io/badge/status-draft-red.svg)](RELEASE_NOTES)" >> README.md
echo "[![Build badge](https://img.shields.io/travis/smart-data-models/dataModel.$1.svg \"Travis build status\")](https://travis-ci.org/smart-data-models/dataModel.$1/)" >> README.md
echo "[![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)" >> README.md
cat README.md.tmp >> README.md
rm README.md.tmp

# Enabling Travis on it, before next commit
travis sync
sleep 3
travis enable --no-interactive

git add .
git commit -m "Updating from FIWARE Data Models"
git push origin master

cd ../dataModels

# Recreating the submodule 
git submodule deinit -f -- specs/$1
rm -rf .git/modules/specs/$1
git rm -f specs/$1
git add .
git commit -m "Recreation of $1"

# Now adding submodule
git submodule add --name $1 https://github.com/smart-data-models/dataModel.$1 specs/$1
git submodule update --remote

git add .
git commit -m "New / Updated Submodule: '$1'"
git push origin master
