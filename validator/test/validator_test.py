import unittest
import os

from schemata.validator import DataModelValidator


class TestValidator(unittest.TestCase):
    dir_test = os.path.dirname(os.path.abspath(__file__))

    def test_validation_ok(self):
        fixtures_dir = os.path.join(self.dir_test, 'fixtures/schema_ok/')

        validator = DataModelValidator(fixtures_dir, '--noLD')
        self.assertEqual(0, validator.validate())

    def test_validation_error(self):
        fixtures_dir = os.path.join(self.dir_test, 'fixtures/schema_error/')

        validator = DataModelValidator(fixtures_dir, '--noLD')
        self.assertNotEqual(0, validator.validate())

    def test_dir_not_found(self):
        validator = DataModelValidator('./dir_not_found/', '--noLD')
        self.assertEqual(-1, validator.validate())


if __name__ == '__main__':
    unittest.main()
