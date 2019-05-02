# Data Model Validator

## Requirements

* Node/npm version >=10
* Python 3
* NGSIv2 Broker running on localhost:1026
* NGSI-LD Broker running on localhost:1030 (optional)

## How to run

```
pip3 install -r requirements.txt
npm install ajv-cli

python3 main.py <Folder> [--noLD]
```

## How to test

````
python -m unittest test/validator_test.py
