#!/usr/bin/python3
# -*- coding: utf-8 -*-

import os
import sys
import re
from .schema_validator import SchemaValidator
from .ngsi_validator import NgsiValidator


class DataModelValidator:
    pattern1 = re.compile(".*example(-[0-9])?\\.json$")
    pattern2 = re.compile(".*example(-[0-9])?-normalized\\.json$")
    pattern3 = re.compile(".*example(-[0-9])?-normalized-ld\\.jsonld$")

    def __init__(self, folder, options):
        self.base_dir = folder
        self.options = options

        self.validateLD = (self.options.find('--noLD') == -1)

        self.schema_validator = SchemaValidator(self.base_dir)
        self.ngsi_validator = None

    def validate(self):
        if self.ngsi_validator is None:
            self.ngsi_validator = NgsiValidator()

        out = self._process_file(self.base_dir)

        self.ngsi_validator.close()
        self.ngsi_validator = None

        return out

    def _process_file(self, input_file):
        if not os.path.exists(input_file):
            print(f'{input_file} does not exist', file=sys.stderr)
            return -1

        out = 0
        if os.path.isfile(input_file):
            ngsi_result = 0

            if self.pattern1.match(input_file):
                schema_result = self.schema_validator.validate(input_file)
                ngsi_result = self.ngsi_validator.validate(
                    input_file, 'v2_keyvalues')
                if out == 0:
                    out = schema_result
            elif self.pattern2.match(input_file):
                ngsi_result = self.ngsi_validator.validate(input_file, 'v2')
            elif self.validateLD and self.pattern3.match(input_file):
                ngsi_result = self.ngsi_validator.validate(input_file, 'LD')

            if out == 0:
                out = ngsi_result
        elif os.path.isdir(input_file):
            for f in (os.listdir(input_file)):
                result = self._process_file(os.path.join(input_file, f))
                if out == 0:
                    out = result

        return out
