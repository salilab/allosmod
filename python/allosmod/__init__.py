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
    runnercls2 = saliweb.backend.LocalRunner
    
    def run(self):
        #preprocess job to keep track of iterations
        subprocess.call(["/netapp/sali/allosmod/preproccess.sh"])
        CTRFILE = open("jobcounter","r") #jobcounter: -1 is all sims complete, -99 is first pass, >0 indicates number of jobs submitted
        jobcounter = int(CTRFILE.readline())
        os.system("echo run jobctr %i >>pwout" % jobcounter)
        #unzip input.zip, check inputs, make input scripts for subdirs
        if jobcounter == 1 or jobcounter == -99:
            subprocess.call(["/netapp/sali/allosmod/run_all.sh"])
            os.system("cp dirlist dirlist_all")

        #create sge script
        DIRFILE = open("dirlist","r")
        dir = DIRFILE.readline()

        ERRFILE = open("%s/error" % dir.replace('\n', ''),"r")
        err = int(ERRFILE.readline())
        os.system("echo run err %i >>pwout" % err)
        if err == 0 and jobcounter != -1:
            script = """
source ./%s/qsub.sh
""" % dir.replace('\n', '')
            NSIMFILE = open("%s/numsim" % dir.replace('\n', ''),"r")
            numsim = int(NSIMFILE.readline())
            r = self.runnercls(script)
            r.set_sge_options("-j y -l arch=lx24-amd64 -l netapp=1.0G,scratch=1.0G -l mem_free=2G -l h_rt=8:00:00 -t 1-%i -V" % numsim)

        elif err == 0 and jobcounter == -1:
            SCANFILE = open("%s/scan" % dir.replace('\n', ''),"r")
            scan = int(SCANFILE.readline())
            os.system("echo run scan %i >>pwout" % scan)
            if scan == 0:
                script = """
echo finished
"""
                r = self.runnercls2("echo finished")
                r.set_sge_options("-j y -l arch=lx24-amd64 -l netapp=0.5G,scratch=0.5G -l mem_free=0.5G -l h_rt=0:01:00 -t 1-1 -V")
            elif scan == -1:
                #execute quick cooling on multiple nodes
                script = """
source ./%s/qsub.sh
""" % dir.replace('\n', '')
                NSIMFILE = open("%s/numsim" % dir.replace('\n', ''),"r")
                numsim = int(NSIMFILE.readline())
                os.system("echo scan=-1 numsim %i >>pwout" % numsim)
                r = self.runnercls(script)
                r.set_sge_options("-j y -l arch=lx24-amd64 -l netapp=1.0G,scratch=1.0G -l mem_free=1G -l h_rt=8:00:00 -t 1-%i -V" % numsim)
                os.system("echo -1 >jobcounter")
                os.system("echo 0 >%s/scan" % dir.replace('\n', ''))
            else:
                #scan for diverse structures, set up quick cooling on multiple nodes
                script = """
cd %s
/netapp/sali/allosmod/scan_quickcool.sh %i
""" % (dir, scan)
                os.system("echo 0 >jobcounter")
                os.system("echo -1 >%s/scan" % dir.replace('\n', ''))
            
                r = self.runnercls(script)
                r.set_sge_options("-j y -l arch=lx24-amd64 -l netapp=1.0G,scratch=1.0G -l mem_free=1G -l h_rt=8:00:00 -t 1-1 -V")

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

        os.system("echo post jobctr %i >>pwout" % jobcounter)
        #submit next job
        if jobcounter > -1 and jobcounter < MAXJOBS:
            self.reschedule_run()
        #sims are finished
        if jobcounter == -1:
            os.system("sleep 5m")
            os.system("mkdir output")
            DIRFILE = open("dirlist_all","r")
            r_dirs = DIRFILE.readlines()
            #if input dir made because no directory is uploaded, delete unecessary files
            os.system("rm -rf input/dirlist input/dirlist_all input/jobcounter input/input.zip input/output input/pwout")
            for dir in r_dirs:
                os.system("rm %s/numsim" % dir.replace('\n', ''))
                os.system("rm %s/error" % dir.replace('\n', ''))
                os.system("rm %s/qsub.sh" % dir.replace('\n', ''))
                os.system("rm %s/coolist_*" % dir.replace('\n', ''))

                os.system("mv %s output" % dir.replace('\n', ''))

            os.system("rm -rf dirlist dirlist_all jobcounter")
                
        #handle error
        if jobcounter >= MAXJOBS:
            os.system("echo Number of jobs have reached a maximum: %i >>error.log" % MAXJOBS)
            os.system("echo If less jobs were expected to run, this could be a user/server error >>error.log")
            os.system("mv %s output" % dir.replace('\n', ''))

    def complete(self):
        os.chmod(".", 0775)
        os.system("/netapp/sali/allosmod/zip_or_send_output.sh")

def get_web_service(config_file):
    db = saliweb.backend.Database(Job)
    config = saliweb.backend.Config(config_file)
    return saliweb.backend.WebService(config, db)
