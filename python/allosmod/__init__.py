import saliweb.backend
import subprocess
import os
import re
import copy
import math
import random
from operator import itemgetter 

class Job(saliweb.backend.Job):
    runnercls = saliweb.backend.SGERunner
    
    def run(self):
        #preprocess job to keep track of iterations
        subprocess.call(["/netapp/sali/allosmod/preproccess.sh"])
        CTRFILE = open("jobcounter","r")
        jobcounter = int(CTRFILE.readline())

        #unzip input.zip, check inputs, make input scripts for subdirs
        if jobcounter == 1 or jobcounter == -1:
            subprocess.call(["/netapp/sali/allosmod/run_all.sh"])
            os.system("cp dirlist dirlist_all")

        #create sge script
        DIRFILE = open("dirlist","r")
        dir = DIRFILE.readline()

        ERRFILE = open("%s/error" % dir.replace('\n', ''),"r")
        err = int(ERRFILE.readline())

        if err == 0:
            script = """
source ./%s/qsub.sh
""" % dir.replace('\n', '')

            NSIMFILE = open("%s/numsim" % dir.replace('\n', ''),"r")
            numsim = int(NSIMFILE.readline())

            r = self.runnercls(script)
            r.set_sge_options("-j y -l arch=lx24-amd64 -l netapp=0.5G,scratch=0.5G -l mem_free=2G -l h_rt=4:00:00 -t 1-%i -V" % numsim)

        else:
            script = """
echo fail
"""
            r = self.runnercls(script)
            
        return r

    def postprocess(self):
        MAXJOBS = 200
        CTRFILE = open("jobcounter","r")
        jobcounter = int(CTRFILE.readline())

        #submit next job
        if jobcounter > 0 and jobcounter < MAXJOBS:
            self.reschedule_run()
        #job finished
        if jobcounter == -1:
            os.system("mkdir output")
            DIRFILE = open("dirlist_all","r")
            r_dirs = DIRFILE.readlines()
            for dir in r_dirs:
                os.system("rm %s/numsim" % dir.replace('\n', ''))
                os.system("rm %s/error" % dir.replace('\n', ''))
                os.system("rm %s/qsub.sh" % dir.replace('\n', ''))

                os.system("mv %s output" % dir.replace('\n', ''))

            os.system("zip -r output.zip output")
            os.system("rm -rf dirlist dirlist_all jobcounter input.zip output")

        #handle error
        if jobcounter >= MAXJOBS:
            os.system("echo Number of jobs have reached a maximum: %i >>error.log" % MAXJOBS)
            os.system("echo If less jobs were expected to run, this could be a user/server error >>error.log")

def get_web_service(config_file):
    db = saliweb.backend.Database(Job)
    config = saliweb.backend.Config(config_file)
    return saliweb.backend.WebService(config, db)
