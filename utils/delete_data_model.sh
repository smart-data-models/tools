#!/bin/sh

: '
This script deletes an existing Data Model

WARNING: If a repository already exists it will be deleted, although a backup will be created

Usage: delete_data_model.sh <dataModelName>

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

if [ -z "$TMP_DIRECTORY" ]; then
  echo "Please define the TMP_DIRECTORY env variable" >&2
  exit 1
fi

if [ -d "$TMP_DIRECTORY" ]; then
  rm -Rf ./$TMP_DIRECTORY
fi

mkdir $TMP_DIRECTORY && cd $TMP_DIRECTORY && mkdir backup

echo "Data Model to be deleted: $1"

cd ..

# End of the preparation phase

# ----- PROCESS STARTS HERE ----

# Check whether a Repo already exist
curl --silent -X GET \
  https://api.github.com/orgs/smart-data-models/repos \
  -H 'Accept: */*' \
  -H 'Cache-Control: no-cache' \
  -H 'cache-control: no-cache'   | grep dataModel.$1 > /dev/null

if [ "$?" -eq 0 ]; then
  echo "Repository already existing: dataModel.$1. Deleting it. Creating a backup before"
  cd $TMP_DIRECTORY/backup && git clone --recurse-submodules https://github.com/smart-data-models/dataModel.$1
  cd .. && git clone https://github.com/smart-data-models/dataModels
  cd ..
  curl --silent -X DELETE \
  https://api.github.com/repos/smart-data-models/dataModel.$1 \
  -H 'Accept: */*' \
  -H "Authorization: Basic `cat .password`"
  
  # Now deleting submodule
  cd $TMP_DIRECTORY/dataModels

  # Recreating the submodule 
  git submodule deinit -f -- specs/$1
  rm -rf .git/modules/specs/$1
  git rm -f specs/$1
  git add .
  git commit -m "Deletion of $1"
  
  git push origin master
  
fi
