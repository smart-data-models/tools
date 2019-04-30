#!/bin/sh

# First create a new repository

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <dataModelName>" >&2
  exit 1
fi

echo "Data Model to be created: $1"

if [ -z "$SOURCE_DATA_MODELS" ]; then
  echo "Please define the SOURCE_DATA_MODELS env variable" >&2
  exit 1
fi

echo "Source Data Models: $SOURCE_DATA_MODELS"

curl -X POST \
  https://api.github.com/orgs/front-runner-smart-cities/repos \
  -H 'Accept: */*' \
  -H 'Authorization: Basic a' \
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

TMP_DIRECTORY=__temp__

if [ -d "$TMP_DIRECTORY" ]; then
  rm -Rf ./$TMP_DIRECTORY
fi

mkdir $TMP_DIRECTORY && cd $TMP_DIRECTORY

# Then clone the new created repository
git clone https://github.com/front-runner-smart-cities/dataModel.$1
git clone https://github.com/front-runner-smart-cities/dataModels

cd dataModel.$1

# Common stuff
cp ../dataModels/templates/dataModel-Repository/* .

rsync -av --progress --exclude harvest --exclude *.py $SOURCE_DATA_MODELS/specs/$1/ ./

git add .
git commit -m "First version from FIWARE Data Models"
git push origin master

cd ../dataModels
git submodule add --name $1 https://github.com/front-runner-smart-cities/dataModel.$1 specs/$1
git add .
git commit -m "New Submodule: '$1'"
git push origin master
