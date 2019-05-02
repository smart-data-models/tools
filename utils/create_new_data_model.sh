#!/bin/sh

: '
This script creates a new Data Model by copying its content from the FIWARE Data Models Repository
A new Data Model (vertical theme) is stored in an independent repository

WARNING: If a repository already exists it will be deleted, although a backup will be created

Usage: create_new_data_model.sh <dataModelName>

'

# -- PREPARATION PHASE --

TMP_DIRECTORY=__temp__

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <dataModelName>" >&2
  exit 1
fi

if [ ! -f .password ]; then
  echo "Please provide a .pasword file for Github credentials" >&2
  exit 1
fi

if [ -z "STMP_DIRECTORY" ]; then
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

# Check whether a Repo already exist
curl --silent -X GET \
  https://api.github.com/orgs/front-runner-smart-cities/repos \
  -H 'Accept: */*' \
  -H 'Cache-Control: no-cache' \
  -H 'cache-control: no-cache'   | grep dataModel.$1 > /dev/null

if [ "$?" -eq 0 ]; then
  echo "Repository already existing: dataModel.$1. Deleting it. Creating a backup before"
  cd $TMP_DIRECTORY/backup && git clone --recurse-submodules https://github.com/front-runner-smart-cities/dataModel.$1
  cd ../..
  curl --silent -X DELETE \
  https://api.github.com/repos/front-runner-smart-cities/dataModel.$1 \
  -H 'Accept: */*' \
  -H "Authorization: Basic `cat .password`"
fi  

echo "Creating Repository: dataModel.$1"

curl -X POST \
  https://api.github.com/orgs/front-runner-smart-cities/repos \
  -H 'Accept: */*' \
  -H "Authorization: Basic `cat .password`" \
  -H 'Cache-Control: no-cache' \
  -H 'Content-Type: application/json' \
  -d '{
        "name": "dataModel.'$1'",
        "description": "'$1' Data Model",
        "private": false,
        "has_issues": true,
        "has_projects": false,
        "has_wiki": true,
        "allow_squash_merge": true,
        "auto_init": true
  }'

cd ./$TMP_DIRECTORY

# Then clone the new created repository
git clone https://github.com/front-runner-smart-cities/dataModel.$1
git clone https://github.com/front-runner-smart-cities/dataModels

cd dataModel.$1

# Common Repository stuff
rsync -av --progress ../dataModels/templates/dataModel-Repository/ ./

# Copying Data Model Content
rsync -av --progress --exclude=harvest --exclude=unsupported --exclude=*.py $SOURCE_DATA_MODELS/specs/$1/ ./

git add .
git commit -m "First version from FIWARE Data Models"
git push origin master

# Enabling Travis on it
travis enable --no-interactive

cd ../dataModels

# Recreating the submodule 
git submodule deinit -f -- specs/$1
rm -rf .git/modules/specs/$1
git rm -f specs/$1
git add .
git commit -m "Recreation of $1"

# Now adding submodule
git submodule add --name $1 https://github.com/front-runner-smart-cities/dataModel.$1 specs/$1
git submodule update --remote

git add .
git commit -m "New / Updated Submodule: '$1'"
git push origin master
