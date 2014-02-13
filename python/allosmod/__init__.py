import saliweb.backend
import subprocess
import os
import re
import copy
import math
import random
from operator import itemgetter 
from os import path, access, R_OK

class Job(saliweb.backend.Job):
    runnercls = saliweb.backend.SGERunner
    runnercls2 = saliweb.backend.DoNothingRunner
    urlout = ''
    
    def run(self):
        #preprocess job to keep track of iterations
        subprocess.call(["/netapp/sali/allosmod/preproccess.sh"])
        CTRFILE = open("jobcounter","r") #jobcounter: -1 is all sims complete, -99 is first pass, >0 indicates number of jobs cycles completed
        jobcounter = int(CTRFILE.readline())
        os.system("echo run jobctr %i >>pwout" % jobcounter)
        #unzip input.zip, check inputs, make input scripts for subdirs
        if jobcounter == 1 or jobcounter == -99:
            subprocess.call(["/netapp/sali/allosmod/run_all.sh"])
            os.system("cp dirlist dirlist_all")

        #create sge script
        DIRFILE = open("dirlist","r")
        dir = DIRFILE.readline() #keep track of current job's directory

        ERRFILE = open("%s/error" % dir.replace('\n', ''),"r")
        err = int(ERRFILE.readline())
        os.system("echo run err %i >>pwout" % err)
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
            os.system("echo run allosmodfox %i >>pwout" % allosmodfox)
            if allosmodfox == 0:
                r = self.runnercls2()
            elif allosmodfox == 1:
                #execute foxs ensemble search, all files should be in directory called "input"
                os.system("/netapp/sali/allosmod/run_foxs_ensemble.sh")
                script = """
source ./%s/qsub.sh
sleep 10s
""" % dir.replace('\n', '')
                
                NSIMFILE = open("%s/numsim" % dir.replace('\n', ''),"r")
                numsim = int(NSIMFILE.readline())
                r = self.runnercls(script)
                r.set_sge_options("-j y -l arch=linux-x64 -l netapp=1.0G,scratch=2.0G -l mem_free=4G -l h_rt=90:00:00 -t 1-1 -V")

                os.system("echo -1 >jobcounter")
                os.system("echo 0 >%s/allosmodfox" % dir.replace('\n', ''))
                os.system("echo allosmodfox=-1 numsim %i >>pwout" % numsim)
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
        CTRFILE = open("jobcounter","r")
        jobcounter = int(CTRFILE.readline())

        os.system("echo post jobctr %i >>pwout" % jobcounter)
        #submit next job
        if jobcounter > -1 and jobcounter < MAXJOBS:
            self.reschedule_run()
        #sims are finished
        if jobcounter == -1:
#            PATH = './input/saxs.dat'
#            if path.exists(PATH) and path.isfile(PATH) and access(PATH, R_OK):
#                os.system("sleep 1m")
#                os.system("echo sleep 1m >>pwout")
#            else:
#                os.system("sleep 5m")
#                os.system("echo sleep 5m >>pwout")
                
            os.system("mkdir output")
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
        os.system("/netapp/sali/allosmod/zip_or_send_output2.sh")
        os.system("/netapp/sali/allosmod/zip_or_send_output.sh")
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

def get_web_service(config_file):
    db = saliweb.backend.Database(Job)
    config = saliweb.backend.Config(config_file)
    return saliweb.backend.WebService(config, db)

