#!/usr/bin/python3
# -*- coding: utf-8 -*-

import os
import subprocess


class SchemaValidator:
    base_dir = ''
    extra_schemata = list()

    def __init__(self, folder):
        self.base_dir = folder
        self.extra_schemata = self.find_extra_schema(self.base_dir)

    def validate(self, file):
        dir_name = os.path.dirname(file)

        params = list()
        params.extend(['ajv', 'validate'])
        params.extend(['-d', file])
        params.extend(['-s', os.path.join(dir_name, 'schema.json')])

        for schema in self.extra_schemata:
            params.extend(['-r', schema])

        return subprocess.run(params).returncode

    def find_extra_schema(self, folder):
        if not os.path.exists(folder):
            print(f'Warning: Extra schema folder {folder} does not exist')
            return list()

        out = list()
        files = os.listdir(folder)

        for f in files:
            tested = os.path.join(folder, f)
            if os.path.isfile(tested) and f.endswith('-schema.json'):
                out.append(tested)
            elif os.path.isdir(tested):
                out.extend(self.find_extra_schema(tested))

        return out
