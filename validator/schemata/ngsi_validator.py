#!/usr/bin/python3
# -*- coding: utf-8 -*-

import urllib3
import sys


class NgsiValidator:
    V2_BROKER = 'http://localhost:1026/v2/entities/{}'
    LD_BROKER = 'http://localhost:1030/ngsi-ld/v1/entities/'

    JSON_MIME_TYPE = 'application/json'
    JSON_LD_MIME_TYPE = 'application/ld+json'

    def __init__(self):
        self.http = urllib3.PoolManager()
        return

    def validate(self, file, mode):
        headers = {
            'Content-Type': self.JSON_MIME_TYPE,
            'Fiware-Service': ''
        }

        if mode == 'v2_keyvalues':
            endpoint = self.V2_BROKER.format('?options=keyValues')
        elif mode == 'v2':
            endpoint = self.V2_BROKER.format('')
        elif mode == 'LD':
            headers['Content-Type'] = self.JSON_LD_MIME_TYPE
            endpoint = self.LD_BROKER

        headers['Fiware-Service'] = mode

        return self.do_validate(file, endpoint, headers)

    def do_validate(self, file, endpoint, headers):
        out = 0

        try:
            with open(file, encoding='utf-8') as json_file:
                text = json_file.read()

            r = self.http.request('POST', endpoint, body=text, headers=headers)

            if r.status == 201:
                print(f'{file} is valid NGSI')
            else:
                print(f'{file} is not valid NGSI: {r.status} {r.data}', file=sys.stderr)
                out = 1
        except Exception as e:
            print(f'Exception while validating {file}: {e}', file=sys.stderr)
            out = 1

        return out

    def close(self):
        self.http.clear()
