import saliweb.build
import saliweb.backend

class Config(saliweb.backend.Config):
    def populate(self, config):
        saliweb.backend.Config.populate(self, config)
        # Read our service-specific configuration
        self.script_directory = config.get('allosmod', 'script_directory')


vars = Variables('config.py')
env = saliweb.build.Environment(vars, ['conf/live.conf'],
                                service_module='allosmod', config_class=Config)
Help(vars.GenerateHelpText(env))

env.InstallAdminTools()
env.InstallCGIScripts()
env.InstallHTML(['html/jquery-1.8.1.min.js',
               'html/allosmod.js',
               'html/allosmod.css'])

f = env.Frontend('allosmod_foxs')
f.InstallCGIScripts()
f.InstallHTML(['allosmod_foxs/html/jquery-1.8.1.min.js',
               'allosmod_foxs/html/allosmod_foxs.js',
               'allosmod_foxs/html/allosmod_foxs.css'])
f.InstallTXT(['allosmod_foxs/txt/help.txt', 'allosmod_foxs/txt/contact.txt'])

Export('env')
SConscript('python/allosmod/SConscript')
SConscript('lib/SConscript')
SConscript('txt/SConscript')
SConscript('test/SConscript')
SConscript('html/SConscript')
SConscript('scripts/SConscript')
