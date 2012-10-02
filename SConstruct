import saliweb.build

vars = Variables('config.py')
env = saliweb.build.Environment(vars, ['conf/live.conf'], service_module='allosmod')
Help(vars.GenerateHelpText(env))

env.InstallAdminTools()
env.InstallCGIScripts()

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
