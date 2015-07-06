from __future__ import print_function
import saliweb.backend
import subprocess
import zipfile
import glob
import os
import re
import copy
import math
import random
import shutil
import tarfile
import time
from operator import itemgetter 
from os import path, access, R_OK

class FoXSError(Exception):
    pass

class AllosModLogError(Exception):
    pass

def zip_dir(z, dirpath):
    """Recursively add a directory to a zipfile"""
    dirpath = dirpath.rstrip('/')
    for root, dirs, files in os.walk(dirpath):
        for f in files:
            z.write(root + '/' + f)

class JobCounter(object):
    """Track where in a multi-step job we are.
       State is stored in a file called 'jobcounter' in the job directory."""

    def get(self):
        """Read jobcounter file and return it.
           -1 is all sims complete,
           -99 is first pass,
           >0 indicates number of jobs cycles completed"""
        with open("jobcounter") as fh:
            return int(fh.readline())

    def set(self, val):
        with open("jobcounter", "w") as fh:
            print("%d" % val, file=fh)


class Job(saliweb.backend.Job):
    runnercls = saliweb.backend.SGERunner
    runnercls2 = saliweb.backend.DoNothingRunner
    urlout = ''

    def debug_log(self, msg):
        """Write a progress message to the debug log file"""
        with open('pwout', 'a') as fh:
            print(msg, file=fh)

    def setup_run(self):
        """Determine where we are in a multi-run job"""
        job_counter = JobCounter()
        if os.path.exists("dirlist"): # after first pass
            with open('dirlist') as fh:
                dirs = fh.readlines()
            if len(dirs) > 1:
                # Remove first entry from dirlist and set up to run next one
                del dirs[0]
                with open('dirlist', 'w') as fh:
                    for dir in dirs:
                        fh.write(dir)
                job_counter.set(job_counter.get() + 1)
            else:
                # All sims complete
                job_counter.set(-1)

        else: # first pass
            dirs = [d for d in os.listdir('.') if os.path.isdir(d)]
            if len(dirs) > 1:
                job_counter.set(1)
            else:
                job_counter.set(-99)
        return job_counter.get()

    def unzip_input(self):
        """Extract inputs and check for sanity"""
        if os.path.exists('input.zip'):
            subprocess.check_call(["unzip", "input.zip"])
        # Test for 0 directories or >100 directories
        num_dirs = num_files = 0
        for d in os.listdir('.'):
            if os.path.isdir(d):
                if os.path.exists(os.path.join(d, 'list')) \
                   and os.path.exists(os.path.join(d, 'input.dat')) \
                   and os.path.exists(os.path.join(d, 'align.ali')):
                    num_dirs += 1
                else:
                    shutil.rmtree(d)
            num_files += 1
        if num_dirs > 100:
            raise saliweb.backend.SanityError(
                  "Individual server jobs should have no more than 100 "
                  "input directories to minimize the output file size and "
                  "to prevent disk writing errors")
        elif num_dirs == 0:
            if num_files > 0:
                # non batch jobs; move files into input (to fix; this
                # breaks job resubmission)
                if os.path.exists('input.zip'):
                    os.unlink('input.zip')
                os.mkdir('input')
                for f in os.listdir('.'):
                    if f != 'input':
                        shutil.move(f, 'input')
            else:
                raise saliweb.backend.SanityError("NO FILES UPLOADED")

    def archive_inputs(self):
        """Archive all input files"""
        archive = self.config.input_archive_directory
        if archive is None:
            return
        ndate = time.strftime("%Y_%b%d")
        for d in [x for x in os.listdir('.') if os.path.isdir(x)]:
            tarname = os.path.join(archive, "%s_%s_%s.tar.gz"
                                   % (ndate, self.name, d))
            t = tarfile.open(tarname, 'w:gz')
            t.add(d)
            t.close()

    def run(self):
        #preprocess job to keep track of iterations
        jobcounter = self.setup_run()
        self.debug_log("run jobctr %d" % jobcounter)
        #unzip input.zip, check inputs, make input scripts for subdirs
        if jobcounter == 1 or jobcounter == -99:
            self.unzip_input()
            self.archive_inputs()
            subprocess.call([os.path.join(self.config.script_directory,
                                          "run_all.sh"),
                             self.config.local_scratch,
                             self.config.global_scratch])
            shutil.copy("dirlist", "dirlist_all")

        #create sge script
        with open("dirlist") as fh:
            #keep track of current job's directory
            dir = fh.readline().rstrip('\r\n')

        with open("%s/error" % dir) as fh:
            err = int(fh.readline())
        self.debug_log("run err %d" % err)
        if err == 0 and jobcounter != -1:
            script = """
cd %s
source ./qsub.sh
pwd
hostname
sleep 10s
""" % dir
            with open("%s/numsim" % dir) as fh:
                numsim = int(fh.readline())
            r = self.runnercls(script)
            r.set_sge_options("-j y -l arch=linux-x64 -l netapp=2G,scratch=2G -l mem_free=5G -l h_rt=90:00:00 -t 1-%i -V" % numsim)

        elif err == 0 and jobcounter == -1:
            r = self.runnercls2()
        else:
            script = """
echo fail
sleep 10s
"""
            r = self.runnercls(script)
            
        return r

    def check_log_errors(self):
        """Check log files for error messages"""
        sge_logs = glob.glob("*.o*")
        for logfile in sge_logs:
            for line in open(logfile):
                if 'Traceback (most recent call last)' in line \
                   or 'Summary of failed models' in line \
                   or 'awk: fatal' in line:
                    raise AllosModLogError("Job reported an error in %s: %s"
                                           % (logfile, line))

    def postprocess(self):
        self.check_log_errors()
        MAXJOBS = 200
        jobcounter = JobCounter().get()
        self.debug_log("post jobctr %d" % jobcounter)

        #submit next job
        if jobcounter > -1 and jobcounter < MAXJOBS:
            self.reschedule_run()
        #sims are finished
        if jobcounter == -1:
            os.mkdir("output")
            with open("dirlist_all") as fh:
                r_dirs = [line.rstrip('\r\n') for line in fh]
            #if input dir made because no directory is uploaded, delete unecessary files
            os.system("rm -rf input/dirlist input/dirlist_all input/jobcounter input/output input/pwout") #input/input.zip
            os.system("cp error.log input/error.log output/")
            for dir in r_dirs:
                os.system("rm %s/numsim" % dir)
                os.system("rm %s/error" % dir)
                os.system("rm %s/qsub.sh" % dir)

                os.system("mv %s output" % dir)

            os.system("rm -rf dirlist dirlist_all jobcounter")
                
        #handle error
        if jobcounter >= MAXJOBS:
            os.system("echo Number of jobs have reached a maximum: %i >>error.log" % MAXJOBS)
            os.system("echo If less jobs were expected to run, this could be a user/server error >>error.log")
            os.system("mv %s output" % dir)

    def complete(self):
        if os.path.exists('output/input/saxs.dat'):
            self._complete_foxs()
        else:
            self._complete_nofoxs()

    def collect_energies(self, subdir):
        """Write the energy of each model produced (if any) into energy.dat"""
        n_models = len(glob.glob(os.path.join(subdir, "pm.pdb.B[1-8]*pdb")))
        if n_models == 0:
            return
        with open(os.path.join(subdir, 'pm.pdb.D00000001')) as fh:
            energies = []
            # Accumulate the energy for the last step in each MD simulation
            for line in fh:
                if line.startswith('# Molecular dynamics simulation'):
                    energies.append(prevline.split())
                prevline = line
            energies.append(prevline.split())
        # The last n_models energies are the final energies of the models
        with open(os.path.join(subdir, 'energy.dat'), 'w') as fh:
            for e in energies[-n_models:]:
                # Discard first field (the MD step number)
                print(" ".join(e[1:]), file=fh)

    def _complete_nofoxs(self):
        """Complete a regular AllosMod run"""
        # Collect energies
        for g in glob.glob("output/*/pred_dE*/*"):
            self.collect_energies(g)

        for g in glob.glob("output/*/scan"):
            os.unlink(g)

        # zip outputs
        z = zipfile.ZipFile('output.zip', 'w', allowZip64=True)
        zip_dir(z, 'output')
        z.close()

        shutil.rmtree('output')
        self.urlout = 'nofoxs'

    def _complete_foxs(self):
        """Complete an AllosMod-FoXS run"""
        # Make directory group writeable so FoXS can access it
        os.chmod(".", 0775)
        subprocess.call([os.path.join(self.config.script_directory,
                                      "zip_or_send_output.sh")])
        with open("urlout") as fh:
            urltest = fh.readlines()
        self.urlout = urltest[-1].strip()
        if self.urlout == 'fail':
            raise FoXSError("FoXS failed to generate outputs")

    def send_job_completed_email(self):
        """Email the user (if requested) to let them know job results are
        available. Can be overridden to disable this behavior or to change
        the content of the email."""

        if self.urlout == 'nofoxs':
            subject = 'Sali lab AllosMod service: Job %s complete' \
                     % self.name
            body = 'Your job %s has finished.\n\n' % self.name + \
                   'Results can be found at %s\n' % self.url
        else:
            subject = 'Sali lab AllosMod-FoXS service: Job %s complete' \
                     % self.name
            body = 'Your job %s has finished.\n\n' % self.name + \
                   'Results can be found at %s\n' % self.urlout + \
                   'You may also download simulation trajectories at %s\n' % self.url
        self.send_user_email(subject, body)


class Config(saliweb.backend.Config):
    def populate(self, config):
        saliweb.backend.Config.populate(self, config)
        # Read our service-specific configuration
        self.script_directory = config.get('allosmod', 'script_directory')
        if config.has_option('allosmod', 'input_archive_directory'):
            self.input_archive_directory = config.get('allosmod',
                                                      'input_archive_directory')
        else:
            self.input_archive_directory = None
        self.local_scratch = config.get('allosmod', 'local_scratch')
        self.global_scratch = config.get('allosmod', 'global_scratch')


def get_web_service(config_file):
    db = saliweb.backend.Database(Job)
    config = Config(config_file)
    return saliweb.backend.WebService(config, db)
