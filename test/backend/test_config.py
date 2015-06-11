import unittest
import allosmod
import saliweb.test
import saliweb.backend
import os

basic_config = """
[general]
admin_email: test@salilab.org
service_name: test_service
socket: test.socket

[backend]
user: test
state_file: state_file
check_minutes: 10

[frontend:foo]
service_name: Foo

[frontend:bar]
service_name: Bar

[database]
db: testdb
frontend_config: frontend.conf
backend_config: backend.conf

[directories]
install: /
incoming: /in
preprocessing: /preproc

[oldjobs]
archive: 1h
expire: 1d

[allosmod]
script_directory: sdir
local_scratch: /tmp
global_scratch: /scrapp
"""

def make_config(fname, archive_dir=None):
    with open(fname, 'w') as fh:
        fh.write(basic_config)
        if archive_dir:
            fh.write("input_archive_directory: %s\n" % archive_dir)

class Tests(saliweb.test.TestCase):
    """Check custom Config class"""

    def test_no_archive(self):
        """Test Config with no archive dir"""
        make_config('test.config')
        c = allosmod.Config('test.config')
        self.assertEqual(c.script_directory, 'sdir')
        self.assertEqual(c.local_scratch, '/tmp')
        self.assertEqual(c.global_scratch, '/scrapp')
        self.assertEqual(c.input_archive_directory, None)
        os.unlink('test.config')

    def test_archive(self):
        """Test Config with archive dir"""
        make_config('test.config', "test/archive")
        c = allosmod.Config('test.config')
        self.assertEqual(c.input_archive_directory, "test/archive")
        os.unlink('test.config')

if __name__ == '__main__':
    unittest.main()
