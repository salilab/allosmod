from modeller.alignment import alignment
from modeller import physical
from modeller.energy_data import energy_data
from modeller.selection import selection
from modeller.automodel import automodel, randomize
import modeller.modfile as modfile
from modeller.automodel.autosched import mk_scale
from modeller.schedule import schedule, step
from modeller.optimizers import molecular_dynamics as MD
from modeller.optimizers import conjugate_gradients as CG

#: MD optimization
MDopt = schedule(4,
       [ step(CG(max_iterations=500), 2, mk_scale(default=0.00001, nonbond=0.0)) ] + \
       [ step(CG(max_iterations=500), 9999, mk_scale(default=rng, nonbond=0.0)) for rng in \
                  (0.00001,0.0001,0.001,0.01,0.1,0.5,1.0) ] + \
       [ step(MD(temperature=rng, cap_atom_shift=0.028, md_time_step=1.0, equilibrate=20, max_iterations=50000), 9999, mk_scale(default=1.00, nonbond=0.001)) for rng in \
         (50.0,100.0,200.0,300.0) ] + \
       [ step(MD(temperature=300.0, cap_atom_shift=0.028, md_time_step=1.0, equilibrate=20, max_iterations=50000), 9999, mk_scale(default=1.00, nonbond=0.01)),
         step(MD(temperature=300.0, cap_atom_shift=0.028, md_time_step=1.0, equilibrate=20, max_iterations=50000), 9999, mk_scale(default=1.00, nonbond=0.1)),
         step(MD(temperature=300.0, cap_atom_shift=0.028, md_time_step=1.0, equilibrate=20, max_iterations=50000), 9999, mk_scale(default=1.00, nonbond=0.5)),
         step(MD(temperature=300.0, cap_atom_shift=0.028, md_time_step=1.0, equilibrate=20, max_iterations=50000), 9999, physical.values(default=1.00)) ])

#: MD equilibration and simulation
def consttemp(atmsel, actions):
    """constant temperature MD"""
    MDtemp=300.0    # temperature for the MD run
    tmstep=3.0      # MD timestep
    nmov=2000       # number of trajectory snapshots
    incequil=200    
    incmov=1000     # number of timesteps = nmov*incmov
    #cap_atom_shift is 3 std dev above average avg max atomic move step, this will change as a function of MDtemp and tmstep
    cap_atom_shift=(0.000101389*MDtemp+0.0525431)*(tmstep/3.0)
    write_intermediates = True
    if MDtemp > 300.0:
        EQtemp1=300.0+(MDtemp-300.0)/10.0
        EQtemp2=300.0+(MDtemp-300.0)/6.0
        EQtemp3=300.0+(MDtemp-300.0)/4.0
        EQtemp4=300.0+(MDtemp-300.0)/3.0
        EQtemp5=300.0+(MDtemp-300.0)/2.5
        EQtemp6=300.0+(MDtemp-300.0)/2.0
        EQtemp7=300.0+(MDtemp-300.0)/1.5
        EQtemp8=MDtemp
        EQtemp9=MDtemp
        EQtemp10=MDtemp
        EQits=50000
    else:
        EQtemp1=300.0
        EQtemp2=300.0
        EQtemp3=300.0
        EQtemp4=300.0
        EQtemp5=300.0
        EQtemp6=300.0
        EQtemp7=300.0
        EQtemp8=300.0
        EQtemp9=300.0
        EQtemp10=300.0
        EQits=50000

    mdl = atmsel.get_model()
    edat = energy_data(copy=mdl.env.edat)
    edat.contact_shell=4.0
    edat.update_dynamic=0.39

    _refineCT(write_intermediates, edat, atmsel, actions, cap=cap_atom_shift, timestep=tmstep,
           equil_its=EQits, equil_equil=20,
           equil_temps=(EQtemp1, EQtemp2, EQtemp3, EQtemp4, EQtemp5, EQtemp6, EQtemp7, EQtemp8, EQtemp9, EQtemp10),
           sampl_its=incmov, sampl_equil=incequil,
           sampl_temp=MDtemp, sampl_nmov=nmov)

#: Omit optimization
MDnone = schedule(4,
       [ step(CG(max_iterations=500), 2, mk_scale(default=0.00001, nonbond=0.0)) ])

#: Omit refinement
def none(atmsel, actions):
    write_intermediates = False
    mdl = atmsel.get_model()
    edat = energy_data(copy=mdl.env.edat)

    _refineCT(write_intermediates, edat, atmsel, actions, cap=0.01, timestep=0.01,
           equil_its=1, equil_equil=1,
           equil_temps=(0.01, 0.01),
           sampl_its=1, sampl_equil=1,
           sampl_temp=0.01, sampl_nmov=1)

#: Refine glycosylation
def moderate(atmsel, actions):
    """contant temperature annealing"""
    _refine(atmsel, actions, cap=0.03, timestep=1.0,
           equil_its=300, equil_equil=20,
           equil_temps=(50.0, 150.0, 250.0, 300.0),
           sampl_its=1000, sampl_equil=200,
           sampl_temps=(400.0, 500.0, 300.0, 200.0, 50.0))

#: Refine quickly using AllosMod energy landscape
def moderate_am(atmsel, actions):
    """contant temperature annealing"""
    MDtemp=300.0    # temperature for the MD run
    tmstep=2.0
    #cap_atom_shift is 3 std dev above average avg max atomic move step, this will change as a function of MDtemp and tmstep
    cap_atom_shift=(0.000101389*MDtemp+0.0525431)*(tmstep/3.0)
    write_intermediates = True

    EQtemp1=300.0+(MDtemp-300.0)/6.0
    EQtemp2=300.0+(MDtemp-300.0)/3.0
    EQtemp3=300.0+(MDtemp-300.0)/2.0
    EQtemp4=300.0+(MDtemp-300.0)/1.5
    EQtemp5=300.0+(MDtemp-300.0)/1.25
    EQtemp6=MDtemp
    
    mdl = atmsel.get_model()
    edat = energy_data(copy=mdl.env.edat)
    edat.contact_shell=4.0
    edat.update_dynamic=0.39

    _refineCT(write_intermediates, edat, atmsel, actions, cap=cap_atom_shift, timestep=tmstep,
           equil_its=300, equil_equil=20,
           equil_temps=(EQtemp1, EQtemp2, EQtemp3, EQtemp4, EQtemp5, EQtemp6),
           sampl_its=1000, sampl_equil=200,
           sampl_temp=MDtemp, sampl_nmov=100)

def _refine(atmsel, actions, cap, timestep, equil_its, equil_equil,
           equil_temps, sampl_its, sampl_equil, sampl_temps, **args):
    from modeller.optimizers import molecular_dynamics

    mdl = atmsel.get_model()
    md = molecular_dynamics(cap_atom_shift=cap, md_time_step=timestep,
                            md_return='FINAL', output=mdl.optimize_output,
                            actions=actions, **args)
    init_vel = True
    # First run for equilibration, the second for sampling:
    for (its, equil, temps) in ((equil_its, equil_equil, equil_temps),
                                (sampl_its, sampl_equil, sampl_temps)):
        for temp in temps:
            md.optimize(atmsel, max_iterations=its, equilibrate=equil,
                        temperature=temp, init_velocities=init_vel)
            init_vel=False

def _refineCT(write_intermediates, edat, atmsel, actions, cap, timestep, equil_its, equil_equil,
             equil_temps, sampl_its, sampl_equil, sampl_temp, sampl_nmov, **args):
    from modeller.optimizers import molecular_dynamics
    
    mdl = atmsel.get_model()
    
    md = molecular_dynamics(cap_atom_shift=cap, md_time_step=timestep,
                            md_return='FINAL', output=mdl.optimize_output,
                            actions=actions, edat=edat, **args)
    init_vel = True
    # First run equilibration
    ctr=500
    for temp in equil_temps:
        md.optimize(atmsel, max_iterations=equil_its, equilibrate=equil_equil,
                    temperature=temp, init_velocities=init_vel, md_time_step=timestep)
        init_vel=False
        if write_intermediates:
            ctr=ctr+1
            atmsel.get_model().write_int(ctr, 0001)


    init_vel=False
    # Begin simulation
    ctr=1000
    for i in range(sampl_nmov):
        md.optimize(atmsel, max_iterations=sampl_its, equilibrate=sampl_equil,
                    temperature=sampl_temp, init_velocities=init_vel, md_time_step=3.0)
        if write_intermediates:
            ctr=ctr+1
            atmsel.get_model().write_int(ctr, 0001)

class AllosModel(automodel):
    spline_on_site = False
    starting_model = 1 #necessary
    ending_model = 1 #necessary
    write_intermediates = True #necessary

    def __init__(self, env, alnfile, knowns, sequence,
                 deviation=None, library_schedule=None, csrfile=None,
                 inifile=None, assess_methods=None):
        automodel.__init__(self, env, alnfile, knowns, sequence, deviation,
                           library_schedule, csrfile, inifile, assess_methods)
        if deviation:
            self.rand_method = randomize.xyz

    def set_defaults(self):
        automodel.set_defaults(self)
        self.rand_method = None

    def refine(self, atmsel, actions):
        """Refine the optimized model with MD and CG"""
        # Save the current model:
        if self.fit_in_refine != 'NO_FIT':
            self.write(file='TO_BE_REFINED.TMP')

        # Possibly skip selecting hot atoms only and optimize all atoms:
        if self.refine_hot_only:
            self.initial_refine_hot(atmsel)

        # Do simulated annealing MD:
        if self.md_level:
            self.md_level(atmsel, actions)

        # Possibly skip 'HOT CG' after MD:
        if self.refine_hot_only:
            self.final_refine_hot(atmsel)

        # Evaluate gross changes between the initial and final refined model:
        if 'NO_FIT' not in self.fit_in_refine:
            aln = alignment(self.env)
            mdl2 = read_model(file='TO_BE_REFINED.TMP')
            casel = selection(self).only_atom_types('CA')
            casel.superpose(mdl2, aln)
            casel = selection(self)
            casel.superpose(mdl2, aln)
            modfile.delete('TO_BE_REFINED.TMP')
