import unittest
import zipfile
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

    def test_unzip_input_no_zip(self):
        """Test unzip_input() with no zip file"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        d = saliweb.test.RunInTempDir()
        open('input.txt', 'w')
        j.unzip_input()
        # files were moved to input/
        os.unlink('input/input.txt')
        os.rmdir('input')

    def test_unzip_input_no_files(self):
        """Test unzip_input() with no files"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        d = saliweb.test.RunInTempDir()
        self.assertRaises(saliweb.backend.SanityError, j.unzip_input)

    def test_unzip_input_too_many_dirs(self):
        """Test unzip_input() with too many directories"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        d = saliweb.test.RunInTempDir()
        self.make_zip(101)
        self.assertRaises(saliweb.backend.SanityError, j.unzip_input)

    def test_unzip_input_ok(self):
        """Test unzip_input() with ok input"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        d = saliweb.test.RunInTempDir()
        self.make_zip(2)
        j.unzip_input()
        self.assertTrue(os.path.exists('dir0'))
        self.assertTrue(os.path.exists('dir1'))

    def test_archive_inputs_no_archive(self):
        """Test archive_inputs() with no archive dir set"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        d = saliweb.test.RunInTempDir()
        j.config.input_archive_directory = None
        self.make_zip(2)
        j.unzip_input()
        j.archive_inputs()

    def test_archive_inputs(self):
        """Test archive_inputs()"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        d = saliweb.test.RunInTempDir()
        archive = saliweb.test.TempDir()
        j.config.input_archive_directory = archive.tmpdir
        self.make_zip(2)
        j.unzip_input()
        j.archive_inputs()
        files = sorted(os.listdir(archive.tmpdir))
        self.assertEqual(len(files), 2)
        self.assertTrue(files[0].endswith('testjob_dir0.tar.gz'))
        self.assertTrue(files[1].endswith('testjob_dir1.tar.gz'))

    def make_zip(self, numdirs):
        z = zipfile.ZipFile('input.zip', 'w')
        t = open('tempz', 'w')
        for i in range(numdirs):
            dirname = 'dir%d' % i
            z.write('tempz', '%s/list' % dirname)
            z.write('tempz', '%s/input.dat' % dirname)
            z.write('tempz', '%s/align.ali' % dirname)
        os.unlink('tempz')

if __name__ == '__main__':
    unittest.main()
