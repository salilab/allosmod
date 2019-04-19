import unittest
import zipfile
import allosmod
import saliweb.test
import saliweb.backend
import os

def _make_zip_or_send_output(ok):
    fname = 'zip_or_send_output.sh'
    with open(fname, 'w') as fh:
        fh.write("#!/bin/sh\n")
        fh.write("echo '%s' > urlout\n" % ("http://foo" if ok else "fail"))
    os.chmod(fname, 493) # 493 = octal 755

def _make_run_all(outdir, dirs):
    fname = os.path.join(outdir, 'run_all.sh')
    with open(fname, 'w') as fh:
        fh.write("#!/bin/sh\n")
        for d in dirs:
            fh.write("echo '%s' > dirlist\n" % d)
    os.chmod(fname, 493) # 493 = octal 755

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

    def test_run_first_pass(self):
        """Test run() method, first pass"""
        script_dir = saliweb.test.TempDir()
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        j.config.input_archive_directory = None
        j.config.local_scratch = ''
        j.config.global_scratch = ''
        d = saliweb.test.RunInTempDir()
        os.mkdir('test_dir1')
        for f in ('list', 'input.dat', 'align.ali'):
            with open('test_dir1/%s' % f, 'w') as fh:
                fh.write('')
        with open('test_dir1/error', 'w') as fh:
            fh.write('0')
        with open('test_dir1/numsim', 'w') as fh:
            fh.write('0')
        # Mock out run_all script
        j.config.script_directory = script_dir.tmpdir
        _make_run_all(script_dir.tmpdir, ('test_dir1',))
        j.run()

    def test_run_first_pass_error(self):
        """Test run() method, first pass, error encountered"""
        script_dir = saliweb.test.TempDir()
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        j.config.input_archive_directory = None
        j.config.local_scratch = ''
        j.config.global_scratch = ''
        d = saliweb.test.RunInTempDir()
        os.mkdir('test_dir1')
        for f in ('list', 'input.dat', 'align.ali'):
            with open('test_dir1/%s' % f, 'w') as fh:
                fh.write('')
        with open('test_dir1/error', 'w') as fh:
            fh.write('1')
        with open('test_dir1/numsim', 'w') as fh:
            fh.write('0')
        # Mock out run_all script
        j.config.script_directory = script_dir.tmpdir
        _make_run_all(script_dir.tmpdir, ('test_dir1',))
        r = j.run()
        self.assertEqual(r.__class__, saliweb.backend.DoNothingRunner)

    def test_run_last_pass(self):
        """Test run() method, last pass"""
        script_dir = saliweb.test.TempDir()
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        j.config.input_archive_directory = None
        j.config.local_scratch = ''
        j.config.global_scratch = ''
        d = saliweb.test.RunInTempDir()
        with open('jobcounter', 'w') as fh:
            fh.write('-1')
        os.mkdir('test_dir1')
        for f in ('list', 'input.dat', 'align.ali'):
            with open('test_dir1/%s' % f, 'w') as fh:
                fh.write('')
        with open('test_dir1/error', 'w') as fh:
            fh.write('0')
        with open('test_dir1/numsim', 'w') as fh:
            fh.write('0')
        # Mock out run_all script
        j.config.script_directory = script_dir.tmpdir
        _make_run_all(script_dir.tmpdir, ('test_dir1',))
        j.run()

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

    def test_unzip_input_bad_dirs(self):
        """Test unzip_input() with only invalid directories"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        d = saliweb.test.RunInTempDir()
        z = zipfile.ZipFile('input.zip', 'w')
        t = open('tempz', 'w')
        for i in range(3):
            dirname = 'dir%d' % i
            if i != 0: z.write('tempz', '%s/list' % dirname)
            if i != 1: z.write('tempz', '%s/input.dat' % dirname)
            if i != 2: z.write('tempz', '%s/align.ali' % dirname)
        z.close()
        os.unlink('tempz')
        j.unzip_input()
        # Only input/ should remain; bad dirs should have been deleted
        self.assertEqual(os.listdir('.'), ['input'])
        self.assertEqual(os.listdir('input'), [])

    def make_zip(self, numdirs):
        z = zipfile.ZipFile('input.zip', 'w')
        t = open('tempz', 'w')
        for i in range(numdirs):
            dirname = 'dir%d' % i
            z.write('tempz', '%s/list' % dirname)
            z.write('tempz', '%s/input.dat' % dirname)
            z.write('tempz', '%s/align.ali' % dirname)
        os.unlink('tempz')

    def test_email_nofoxs(self):
        """Test send_job_completed_email, no FoXS"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        j.urlout = 'nofoxs'
        def test_nofoxs(subject, body):
            self.assertEqual(subject,
                         "Sali lab AllosMod service: Job testjob complete")
        j.send_user_email = test_nofoxs
        j.send_job_completed_email()

    def test_email_foxs(self):
        """Test send_job_completed_email, with FoXS"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        j.urlout = 'foxs_url'
        def test_foxs(subject, body):
            self.assertEqual(subject,
                         "Sali lab AllosMod-FoXS service: Job testjob complete")
            self.assertTrue("You may also download simulation trajectories"
                            in body)
        j.send_user_email = test_foxs
        j.send_job_completed_email()

    def test_complete_nofoxs_ok(self):
        """Test job completion, no FoXS, all OK"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        d = saliweb.test.RunInTempDir()
        subd = 'output/land1/pred_dECALCrAS1000/land1.pdb_0'
        os.makedirs(subd)
        for f in ('output/land1/scan',
                  os.path.join(subd, 'pm.pdb.B10010001.pdb'),
                  os.path.join(subd, 'pm.pdb.B10020001.pdb')):
            with open(f, 'w') as fh:
                fh.write('dummy')
        with open(os.path.join(subd, 'pm.pdb.D00000001'), 'w') as fh:
            fh.write("""
# Molecular dynamics simulation at 0.01 K
#  Step   Current energy Av shift Mx shift   Kinetic energy    Kinetic temp.
      0      14091.83789   0.0000   0.0000          0.08312          0.00993
      2      14091.83789   0.0000   0.0000          0.08367          0.01000
# Molecular dynamics simulation at 0.01 K
#  Step   Current energy Av shift Mx shift   Kinetic energy    Kinetic temp.
      0      14091.83789   0.0000   0.0000          0.08367          0.01000
      2      14091.83789   0.0000   0.0000          0.08368          0.01000
# Molecular dynamics simulation at 0.01 K
#  Step   Current energy Av shift Mx shift   Kinetic energy    Kinetic temp.
      0      14091.83789   0.0000   0.0000          0.08367          0.01000
      2         10.00000   0.0000   0.0000          1.00000          0.00000
# Molecular dynamics simulation at 0.01 K
#  Step   Current energy Av shift Mx shift   Kinetic energy    Kinetic temp.
      0      14091.83789   0.0000   0.0000          0.08367          0.01000
      2         42.00000   0.0000   0.0000          2.00000          0.00000
""")
        j.finalize()
        # output dir should have been replaced by output.zip
        self.assertEqual(os.listdir('.'), ['output.zip'])
        z = zipfile.ZipFile('output.zip')
        self.assertEqual(len(z.namelist()), 4)
        z.extractall()
        # scan file should not be in the archive
        self.assertFalse(os.path.exists('output/land1/scan'))
        with open(os.path.join(subd, "energy.dat")) as fh:
            contents = fh.read()
        self.assertEqual(contents,
                         '10.00000 0.0000 0.0000 1.00000 0.00000\n'
                         '42.00000 0.0000 0.0000 2.00000 0.00000\n')

    def test_complete_nofoxs_failure(self):
        """Test job completion, no FoXS, failure encountered"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        d = saliweb.test.RunInTempDir()
        with open('failure.log', 'w') as fh:
            fh.write('error')
        os.mkdir('output')
        j.finalize()
        # output dir should have been replaced by output.zip
        self.assertEqual(sorted(os.listdir('.')), ['failure.log', 'output.zip'])

    def test_complete_foxs_allosmod_failure(self):
        """Test job completion, with FoXS, AllosMod failure encountered"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        d = saliweb.test.RunInTempDir()
        os.mkdir('output')
        os.mkdir('output/input')
        with open('output/input/saxs.dat', 'w') as fh:
            fh.write('test')
        with open('failure.log', 'w') as fh:
            fh.write('error')
        j.finalize()
        # output dir should have been replaced by output.zip
        self.assertEqual(sorted(os.listdir('.')), ['failure.log', 'output.zip'])

    def test_complete_foxs_ok(self):
        """Test OK job completion, with FoXS"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        d = saliweb.test.RunInTempDir()
        os.mkdir('output')
        os.mkdir('output/input')
        with open('output/input/saxs.dat', 'w') as fh:
            fh.write('test')
        # Mock out run-FoXS script
        j.config.script_directory = os.getcwd()
        _make_zip_or_send_output(ok=True)
        j.finalize()
        # output dir not replaced with output.zip (normally this is done
        # by the run-FoXS script, but it was mocked out)
        self.assertEqual(sorted(os.listdir('.')),
                         ['output', 'urlout', 'zip_or_send_output.sh'])

    def test_complete_foxs_failure(self):
        """Test OK job completion, with FoXS, FoXS failure"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        d = saliweb.test.RunInTempDir()
        os.mkdir('output')
        os.mkdir('output/input')
        with open('output/input/saxs.dat', 'w') as fh:
            fh.write('test')
        # Mock out run-FoXS script
        j.config.script_directory = os.getcwd()
        _make_zip_or_send_output(ok=False)
        self.assertRaises(allosmod.FoXSError, j.finalize)

    def test_make_failure_log_ok(self):
        """Test make_failure_log() method, no failures"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        d = saliweb.test.RunInDir(j.directory)
        j.make_failure_log()
        self.assertFalse(j.has_failure_log())

    def test_make_failure_log_errs(self):
        """Test make_failure_log() method, with errors"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        d = saliweb.test.RunInDir(j.directory)
        os.mkdir('subdir')
        with open(os.path.join('subdir', 'error.log'), 'w') as fh:
            fh.write('error')
        j.make_failure_log()
        self.assertTrue(j.has_failure_log())
        with open('failure.log') as fh:
            contents = fh.read()
        self.assertEqual(contents, "\nOne or more errors were detected and "
                         "the job did not complete successfully.\nPlease see "
                         "the following files inside output.zip for more "
                         "information:\n./subdir/error.log\n")

    def test_check_log_errors(self):
        """Test check_log_errors() method"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        d = saliweb.test.RunInDir(j.directory)
        j.check_log_errors()
        for err in ('Traceback (most recent call last):',
                    'Summary of failed models', 'awk: foo bar fatal',
                    'awk: line:2   ^ syntax error'):
            with open('test.o1234.1', 'w') as fh:
                fh.write(err)
            self.assertRaises(allosmod.AllosModLogError, j.check_log_errors)
        # Tracebacks handled internally by AllosMod aren't considered errors
        with open('test.o1234.1', 'w') as fh:
            fh.write("Traceback (most recent call last):\n")
            fh.write("MODELLER has failed to create an initial model "
                     "of the following structure:\n")
        j.check_log_errors()

    def test_check_preprocess(self):
        """Test preprocess() method"""
        j = self.make_test_job(allosmod.Job, 'RUNNING')
        d = saliweb.test.RunInDir(j.directory)
        for f in ('dirlist', 'dirlist_all', 'jobcounter', 'job-state', 'pwout',
                  'sge-script.sh', 'sge-script.sh.o9058604.1'):
            open(f, 'w').close()
        os.mkdir('input')
        for f in ('error', 'error.log', 'numsim', 'qsub.sh'):
            open('input/%s' % f, 'w').close()
        os.mkdir('input/pred_dECALCrAS1000')
        os.mkdir('input/pred_dECALCrAS1000/jobname.pdb_0')
        j.preprocess()
        # Most files should have been cleaned up
        os.unlink('input/qsub.sh')
        os.rmdir('input')
        self.assertEqual(os.listdir('.'), ['pwout'])

if __name__ == '__main__':
    unittest.main()
