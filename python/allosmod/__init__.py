from __future__ import print_function
import saliweb.backend
import subprocess
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

    def run(self):
        #preprocess job to keep track of iterations
        jobcounter = self.setup_run()
        self.debug_log("run jobctr %d" % jobcounter)
        #unzip input.zip, check inputs, make input scripts for subdirs
        if jobcounter == 1 or jobcounter == -99:
            self.unzip_input()
            self.archive_inputs()
            subprocess.call([os.path.join(self.config.script_directory,
                                          "run_all.sh")])
            shutil.copy("dirlist", "dirlist_all")

        #create sge script
        DIRFILE = open("dirlist","r")
        dir = DIRFILE.readline() #keep track of current job's directory

        ERRFILE = open("%s/error" % dir.replace('\n', ''),"r")
        err = int(ERRFILE.readline())
        self.debug_log("run err %d" % err)
        if err == 0 and jobcounter != -1:
            script = """
source ./%s/qsub.sh
pwd
hostname
awk '{print $0}' tempdir  |sh
rm tempdir
sleep 10s
""" % dir.replace('\n', '')
            NSIMFILE = open("%s/numsim" % dir.replace('\n', ''),"r")
            numsim = int(NSIMFILE.readline())
            r = self.runnercls(script)
            r.set_sge_options("-j y -l arch=linux-x64 -l netapp=2G,scratch=2G -l mem_free=5G -l h_rt=90:00:00 -t 1-%i -V" % numsim)

        elif err == 0 and jobcounter == -1:
            FOXSFILE = open("%s/allosmodfox" % dir.replace('\n', ''),"r")
            allosmodfox = int(FOXSFILE.readline())
            self.debug_log("run allosmodfox %d" % allosmodfox)
            if allosmodfox == 0:
                r = self.runnercls2()
            elif allosmodfox == 1:
                #execute foxs ensemble search, all files should be in directory called "input"
                subprocess.call([os.path.join(self.config.script_directory,
                                              "run_foxs_ensemble.sh")])
                script = """
source ./%s/qsub.sh
sleep 10s
""" % dir.replace('\n', '')
                
                NSIMFILE = open("%s/numsim" % dir.replace('\n', ''),"r")
                numsim = int(NSIMFILE.readline())
                r = self.runnercls(script)
                r.set_sge_options("-j y -l arch=linux-x64 -l netapp=1.0G,scratch=2.0G -l mem_free=4G -l h_rt=90:00:00 -t 1-1 -V")

                JobCounter().write(-1)
                with open('%s/allosmodfox' % dir.replace('\n', ''), 'w') as fh:
                    print("0", file=fh)
                self.debug_log("allosmodfox=-1 numsim %d" % numsim)
            else:
                script = """
echo fail
sleep 10s
"""
            
                r = self.runnercls(script)

        else:
            script = """
echo fail
sleep 10s
"""
            r = self.runnercls(script)
            
        return r

    def postprocess(self):
        MAXJOBS = 200
        jobcounter = JobCounter().get()
        self.debug_log("post jobctr %d" % jobcounter)

        #submit next job
        if jobcounter > -1 and jobcounter < MAXJOBS:
            self.reschedule_run()
        #sims are finished
        if jobcounter == -1:
#            PATH = './input/saxs.dat'
#            if path.exists(PATH) and path.isfile(PATH) and access(PATH, R_OK):
#                os.system("sleep 1m")
#            else:
#                os.system("sleep 5m")

            os.mkdir("output")
            DIRFILE = open("dirlist_all","r")
            r_dirs = DIRFILE.readlines()
            #if input dir made because no directory is uploaded, delete unecessary files
            os.system("rm -rf input/dirlist input/dirlist_all input/jobcounter input/output input/pwout") #input/input.zip
            os.system("cp error.log input/error.log output/")
            for dir in r_dirs:
                os.system("rm %s/numsim" % dir.replace('\n', ''))
                os.system("rm %s/error" % dir.replace('\n', ''))
                os.system("rm %s/qsub.sh" % dir.replace('\n', ''))

                os.system("mv %s output" % dir.replace('\n', ''))

            os.system("rm -rf dirlist dirlist_all jobcounter")
                
        #handle error
        if jobcounter >= MAXJOBS:
            os.system("echo Number of jobs have reached a maximum: %i >>error.log" % MAXJOBS)
            os.system("echo If less jobs were expected to run, this could be a user/server error >>error.log")
            os.system("mv %s output" % dir.replace('\n', ''))

    def complete(self):
        os.chmod(".", 0775)
        subprocess.call([os.path.join(self.config.script_directory,
                                      "zip_or_send_output.sh")])
        URLFOXS = open("urlout","r")
        urltest = URLFOXS.readlines()
        self.urlout = urltest[len(urltest)-1].strip()

    def send_job_completed_email(self):
        """Email the user (if requested) to let them know job results are
        available. Can be overridden to disable this behavior or to change
        the content of the email."""

        if self.urlout == 'nofoxs':
            subject = 'Sali lab AllosMod service: Job %s complete' \
                     % self.name
            body = 'Your job %s has finished.\n\n' % self.name + \
                   'Results can be found at %s\n' % self.url
            self.send_user_email(subject, body)
        elif self.urlout == 'fail':
            erremail = 'pweinkam@salilab.org'
            self.admin_fail(erremail)
        else:
            subject = 'Sali lab AllosMod-FoXS service: Job %s complete' \
                     % self.name
            body = 'Your job %s has finished.\n\n' % self.name + \
                   'Results can be found at %s\n' % self.urlout + \
                   'You may also download to simulation trajectories at %s\n' % self.url
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


def get_web_service(config_file):
    db = saliweb.backend.Database(Job)
    config = Config(config_file)
    return saliweb.backend.WebService(config, db)
