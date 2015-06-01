import unittest
import allosmod
import saliweb.test
import saliweb.backend
import os

class JobTests(saliweb.test.TestCase):
    """Check custom Job class"""

    def test_init(self):
        """Test creation of Job object"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')

    def test_debug_log(self):
        """Test debug_log() method"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        j.debug_log("foo")
        j.debug_log("bar")
        with open('pwout') as fh:
            contents = fh.read()
        self.assertEqual(contents, "foo\nbar\n")
        os.unlink('pwout')

    def test_get_job_counter(self):
        """Test get_job_counter() method"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        with open('jobcounter', 'w') as fh:
            fh.write('42\n')
        self.assertEqual(j.get_job_counter(), 42)
        os.unlink('jobcounter')

if __name__ == '__main__':
    unittest.main()
