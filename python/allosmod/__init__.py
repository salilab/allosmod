import saliweb.backend
import subprocess
import os
import re
import copy
import math
from operator import itemgetter 

class Job(saliweb.backend.Job):
    runnercls = saliweb.backend.SGERunner
    
    def run(self):
        # Uncomment to get all logging output
        #self.logger.setLevel(logging.DEBUG)
        #self.logger.info('Starting run method')

        #subprocess.call(["/netapp/sali/allosmod/run_all.sh"])
        #subprocess.call(["foo.sh","args"],shell=True)
#        script = """
#ls * >pp
#pwd >>pp
#"""
#source ./qsub.sh
#"""
        
        script = """
touch testing_file1.out
mkdir testing_folder
mv testing_file1.out testing_folder
"""
        r = self.runnercls(script)
        #r.set_sge_options('-l o64=true -l diva1=1G,scratch=1G -l mem_free=2G -l h_rt=4:00:00 -t 1-2')
#        self.logger.info('Ending run method')
        return r

def get_web_service(config_file):
    db = saliweb.backend.Database(Job)
    config = saliweb.backend.Config(config_file)
    return saliweb.backend.WebService(config, db)
