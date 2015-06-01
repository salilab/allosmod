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

    def test_setup_run_after_first(self):
        """Test setup_run() method after first pass"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        d = saliweb.test.RunInTempDir()
        with open('dirlist', 'w') as fh:
            fh.write('foo\nbar\n')
        with open('jobcounter', 'w') as fh:
            fh.write('42\n')
        job_counter = j.setup_run()
        self.assertEqual(job_counter, 43)
        with open('dirlist') as fh:
            contents = fh.read()
        self.assertEqual(contents, 'bar\n')

    def test_setup_run_after_last_sim(self):
        """Test setup_run() method after last simulation is done"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        d = saliweb.test.RunInTempDir()
        with open('dirlist', 'w') as fh:
            fh.write('foo\n')
        with open('jobcounter', 'w') as fh:
            fh.write('42\n')
        job_counter = j.setup_run()
        self.assertEqual(job_counter, -1)
        with open('dirlist') as fh:
            contents = fh.read()
        # should be untouched
        self.assertEqual(contents, 'foo\n')

    def test_setup_run_first_pass_no_dirs(self):
        """Test setup_run() method, first pass, no directories"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        d = saliweb.test.RunInTempDir()
        open('dummy', 'w') # touch a dummy file
        job_counter = j.setup_run()
        self.assertEqual(job_counter, -99)

    def test_setup_run_first_pass_one_dir(self):
        """Test setup_run() method, first pass, one directory"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        d = saliweb.test.RunInTempDir()
        os.mkdir('test_dir1')
        job_counter = j.setup_run()
        self.assertEqual(job_counter, -99)

    def test_setup_run_first_pass_multiple_dirs(self):
        """Test setup_run() method, first pass, multiple directories"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        d = saliweb.test.RunInTempDir()
        os.mkdir('test_dir1')
        os.mkdir('test_dir2')
        job_counter = j.setup_run()
        self.assertEqual(job_counter, 1)

if __name__ == '__main__':
    unittest.main()
