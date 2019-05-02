#!/bin/sh

TMP_DIRECTORY=__temp__

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <dataModelName>" >&2
  exit 1
fi

echo "Data Model to be created: $1"

if [ -z "$SOURCE_DATA_MODELS" ]; then
  echo "Please define the SOURCE_DATA_MODELS env variable" >&2
  exit 1
fi

if [ ! -f .password ]; then
  echo "Please provide a .pasword file for Github credentials" >&2
fi

echo "Source Data Models: $SOURCE_DATA_MODELS"

if [ -z "STMP_DIRECTORY" ]; then
  echo "Please define the TMP_DIRECTORY env variable" >&2
  exit 1
fi

if [ -d "$TMP_DIRECTORY" ]; then
  rm -Rf ./$TMP_DIRECTORY
fi

mkdir $TMP_DIRECTORY && cd $TMP_DIRECTORY && mkdir backup
cd ..


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
rsync -av --progress --exclude harvest --exclude *.py $SOURCE_DATA_MODELS/specs/$1/ ./

git add .
git commit -m "First version from FIWARE Data Models"
git push origin master

# Enabling Travis on it
travis enable --no-interactive

cd ../dataModels
git submodule add --name $1 https://github.com/front-runner-smart-cities/dataModel.$1 specs/$1
git submodule update --remote

git add .
git commit -m "New / Updated Submodule: '$1'"
git push origin master
