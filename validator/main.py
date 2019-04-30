#!/usr/bin/python3
# -*- coding: utf-8 -*-

import sys

from schemata.validator import DataModelValidator


def main(args):
    options = ''
    if len(args) >= 3:
        options = args[2]

    validator = DataModelValidator(args[1], options)

    result = validator.validate()

    exit(result)


# Entry point
if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(
            "Usage: validator [folder] [options]. Use --noLD for skipping NGSI-LD validation")
        exit(-1)

    main(sys.argv)
