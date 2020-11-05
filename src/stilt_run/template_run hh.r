#!/usr/bin/env Rscript
# STILT R Executable
# For documentation, see https://uataq.github.io/stilt/
# Ben Fasoli

# User inputs ------------------------------------------------------------------
project <- '{{project_name}}'
stilt_wd <- file.path('{{wd}}', project)
output_wd <- file.path(stilt_wd, 'out')
lib.loc <- .libPaths()[1]

# Parallel simulation settings
n_cores <- 1
n_nodes <- 1
slurm   <- n_nodes > 1
slurm_options <- list(
  time      = '10:00:00',
  account   = 'CHANGEME',
  partition = 'CHANGEME'
)

# Add receptors file 
receptors <- readRDS('CHANGEME.rds')

# Footprint grid settings, must set at least xmn, xmx, ymn, ymx below
hnf_plume <- T
projection <- '+proj=longlat'
smooth_factor <- 1
time_integrate <- T
xmn <- -114.12
xmx <- -109.00
ymn <- 36.94
ymx <- 42.06
xres <- 0.01
yres <- xres

# Meteorological data input
met_path   <- '/uufs/chpc.utah.edu/common/home/YOURUID/STILT_DIRECTORY/UT_NARR/'
met_file_format <- 'UT_NARR%Y%m'
n_met_min <- 1
met_subgrid_buffer <- 0.1
met_subgrid_enable <- F
met_subgrid_levels <- NA

# Model control
n_hours    <- 24  #Number of hours to run each simulation. Negative is backward in time
numpar     <- 10000  ## Number of particles - Per Ben Fasoli - Aim for 200 particles/hour, so numpar >-5000. I set to 10000 based on the 1km RMSE
rm_dat     <- T    ##Logical indicator - delete particle information after simulation - Default = T
run_foot   <- T    ##Logical indicator - produce footprints - Run foot or Run traj must be = T
run_trajec <- T    ##Logical indicator - produce trajectories (should be T)
timeout    <- 3600  ##Number of seconds to allow the model to complete before moving to the next simulation. Defaults to one hour
varsiwant  <- c('time', 'indx', 'long', 'lati', 'zagl', 'foot', 'mlht', 'dens',
                'samt', 'sigw', 'tlgr')  ##Model variable - if you don't list it, it doesnt run it. 

# Transport and dispersion settings
capemin     <- -1   ##No convection
cmass       <- 0    ##Compute grid; 0=concentrations, 1=mass
conage      <- 48   ##Particle to or from puff conversions at conage (hours)
cpack       <- 1    ##Binary concentration packing; 0=None, 1=non-zero, 2=points, 3=polar
delt        <- 1    ##Integration time step; 0=autoset; >0= constant
dxf         <- 1    ##Horizontal X-grid adjustment factor for ensemble
dyf         <- 1    ##Horizontal Y-grid adjustment factor for ensemble
dzf         <- 0.01  ##Vertical (0.01 ~ 250m) factor for ensembl
efile       <- ''    ##Temporal emissions file - to use if there is a change in emissions rate
emisshrs    <- 24  ##Time from the simulation start time; smothing the particles. ***Set to 24 NEED TO CHECK***
frhmax      <- 3     ##The range is 0.5 - 3 and we are setting at the max
frhs        <- 1     ##Standard horizontal puff rounding
frme        <- 0.1   ##mass rounding fraction for enhanced merging
frmr        <- 0     ##Mass removal fraction during enhanced merging
frts        <- 0.1   ##temporal puff rounding fraction
frvs        <- 0.01  ##Vertical puff rounding fraction
hscale      <- 10800  ##Horizontal lagrangian time scale (sec)
ichem       <- 8  ##Stilt mode: Mixing ratio 6 and varying layer 9
idsp        <- 2  ##Stilt particle dispersion scheme
initd       <- 0  ##Initial dispersion; particle
k10m        <- 1  ##Use surface 10m winds/2m temp
kagl        <- 1  ##Traj output heights are written as AGL
kbls        <- 1  ##Boundary layer stability from fluxes
kblt        <- 5  ##Boundary layer turbulence Hanna
kdef        <- 0  ##Horizontal turbulence vertical
khinp       <- 0  ##If non-zero particle age in hours is read from a file
khmax       <- 9999  ##Max duration for particle trajectory
kmix0       <- 250  ##minimum mixing depth - 150 is the default; nightime boundary layer height. PBL height (50 - 300 is Ben's range)
kmixd       <- 3    ##Modified Richardson - STILT Default
kmsl        <- 0    ##Interpretation of height in the control file; above ground
kpuff       <- 0    ##Linear with time puff growth
krand       <- 4    ##Random initial seed
krnd        <- 6    ##Enhanced puff merging takes place at 6 hours; default
kspl        <- 1    ##Inverval (hrs) at which puff splitting routines are called
kwet        <- 1    ##Precip defined in met file
kzmix       <- 0    ## No vertical mixing
maxdim      <- 1    ## One pollutant per particle
maxpar      <- numpar
mgmin       <- 10   ##Min met subgrid
mhrs        <- 9999  ##Max duration
nbptyp      <- 1     ##Number of redistributed particle size
ncycl       <- 0     ##Pardump output cycle time
ndump       <- 0     ##Default -; no pardump file written. Can change to hours
ninit       <- 1     ##Initialization at model startup
nstr        <- 0     ##No new trajectory is started  ***DOUBLE CHECK***
nturb       <- 0     ##Turbulence Off
nver        <- 0     ##Trajectory vertical split
outdt       <- 0     ##Output frequency in minutes of teh endpoint positions in teh Particle.dat file
p10f        <- 1     ##Dust sthreshold velocity - default value
pinbc       <- ''    ##Particle input file (time-varying boundary)
pinpf       <- ''    ##Initial conditions or boundary conditions
poutf       <- ''    ##Name for the particle dump output
qcycle      <- 0     ##Number of hours between emission start cycles (0 = not cycled). >0 = # emission hours at t *Goes with NUMPAR and ICHEM=10*
rhb         <- 80    ##Initial relative humidity required to define the base ofa  cloud; Default 80
rht         <- 60    ##The cloud continues up until relative humidity drops below this value; Default 60
splitf      <- 1     ##Automatic size adjustment factor for horizongal splitting; Default 1
tkerd       <- 0.18  ##Unstable turbulent kinetic energy ratio
tkern       <- 0.18  ##Stable turbulent kinetic energy ratio
tlfrac      <- 0.1   ##Fraction of Lagrangian vertical time scale used to cal dispersion time step in STILT
tout        <- 0     ##trajectory output interval in minutes **Default is 60 NEED TO CHECK**
tratio      <- 0.75  ##Advection stability ratio
tvmix       <- 1     ##Vertical mixing scale factor
veght       <- 0.5   ##Height below which particles time is spent is tallied to calculate footprint for particle_stilt.dat; default = 0.5
vscale      <- 200   ##Vertical Lagrangian time scale (sec) for unstable PBL  **DIDN'T SEE THIS IN DOC - SAME AS BELOW?** Per Ben Fasoli - Ignored in STILT (vscales=-1; Hanna Lagrangian Time Scale)
vscaleu     <- 200   ##Vertical Lagrangian time scale (sec) for unstable PBL Per Ben Fasoli - Ignored in STILT (vscales=-1; Hanna Lagrangian Time Scale)
vscales     <- -1    ##Vertical Lagrangian time scale(sec) for stable PBL; Default is 5; -1 results in the Hanna vertical Lagrangian which is what we want
wbbh        <- 0     ##Trajectory height at which vertical velocity switches from rise to fall
wbwf        <- 0     ##Trajectory fixed fall velocity (m/s>0)
wbwr        <- 0     ##Trajectory fixed rise velocity (m/s)
wvert       <- FALSE ##Vertical interpolation scheme
w_option    <- 0     ## STILT specific option: vertical motion calculation method; 0= use vertical velocity from data
zicontroltf <- 0     ## STILT specific option: Scale the PBL heights in STILT uniformly; default =0
ziscale     <- rep(list(rep(1, 24)), nrow(receptors))  ##STILT SPECIFIC OPTION: manually scale the mixed-layer height
z_top       <- 25000  ##STILT specific option: top of model domain in meters above ground level

# Transport error settings
horcoruverr <- NA
siguverr    <- NA
tluverr     <- NA
zcoruverr   <- NA

horcorzierr <- NA
sigzierr    <- NA
tlzierr     <- NA


# Interface to mutate the output object with user defined functions
before_trajec <- function() {output}
before_footprint <- function() {output}


# Startup messages -------------------------------------------------------------
message('Initializing STILT')
message('Number of receptors: ', nrow(receptors))
message('Number of parallel threads: ', n_nodes * n_cores)


# Source dependencies ----------------------------------------------------------
setwd(stilt_wd)
source('r/dependencies.r')


# Structure out directory ------------------------------------------------------
# Outputs are organized in three formats. by-id contains simulation files by
# unique simulation identifier. particles and footprints contain symbolic links
# to the particle trajectory and footprint files in by-id
system(paste0('rm -r ', output_wd, '/footprints'), ignore.stderr = T)
if (run_trajec) {
  system(paste0('rm -r ', output_wd, '/by-id'), ignore.stderr = T)
  system(paste0('rm -r ', output_wd, '/met'), ignore.stderr = T)
  system(paste0('rm -r ', output_wd, '/particles'), ignore.stderr = T)
}
for (d in c('by-id', 'particles', 'footprints')) {
  d <- file.path(output_wd, d)
  if (!file.exists(d))
    dir.create(d, recursive = T)
}

stilt_apply(FUN = simulation_step,
            slurm = slurm,
            slurm_options = slurm_options,
            n_cores = n_cores,
            n_nodes = n_nodes,
            before_footprint = list(before_footprint),
            before_trajec = list(before_trajec),
            lib.loc = lib.loc,
            capemin = capemin,
            cmass = cmass,
            conage = conage,
            cpack = cpack,
            delt = delt,
            dxf = dxf,
            dyf = dyf,
            dzf = dzf,
            efile = efile,
            emisshrs = emisshrs,
            frhmax = frhmax,
            frhs = frhs,
            frme = frme,
            frmr = frmr,
            frts = frts,
            frvs = frvs,
            hnf_plume = hnf_plume,
            horcoruverr = horcoruverr,
            horcorzierr = horcorzierr,
            hscale = hscale,
            ichem = ichem,
            idsp = idsp,
            initd = initd,
            k10m = k10m,
            kagl = kagl,
            kbls = kbls,
            kblt = kblt,
            kdef = kdef,
            khinp = khinp,
            khmax = khmax,
            kmix0 = kmix0,
            kmixd = kmixd,
            kmsl = kmsl,
            kpuff = kpuff,
            krand = krand,
            krnd = krnd,
            kspl = kspl,
            kwet = kwet,
            kzmix = kzmix,
            maxdim = maxdim,
            maxpar = maxpar,
            met_file_format = met_file_format,
            met_path = met_path,
            met_subgrid_buffer = met_subgrid_buffer,
            met_subgrid_enable = met_subgrid_enable,
            met_subgrid_levels = met_subgrid_levels,
            mgmin = mgmin,
            n_hours = n_hours,
            n_met_min = n_met_min,
            ncycl = ncycl,
            ndump = ndump,
            ninit = ninit,
            nstr = nstr,
            nturb = nturb,
            numpar = numpar,
            nver = nver,
            outdt = outdt,
            output_wd = output_wd,
            p10f = p10f,
            pinbc = pinbc,
            pinpf = pinpf,
            poutf = poutf,
            projection = projection,
            qcycle = qcycle,
            r_run_time = receptors$run_time,
            r_lati = receptors$lati,
            r_long = receptors$long,
            r_zagl = receptors$zagl,
            rhb = rhb,
            rht = rht,
            rm_dat = rm_dat,
            run_foot = run_foot,
            run_trajec = run_trajec,
            siguverr = siguverr,
            sigzierr = sigzierr,
            smooth_factor = smooth_factor,
            splitf = splitf,
            stilt_wd = stilt_wd,
            time_integrate = time_integrate,
            timeout = timeout,
            tkerd = tkerd,
            tkern = tkern,
            tlfrac = tlfrac,
            tluverr = tluverr,
            tlzierr = tlzierr,
            tout = tout,
            tratio = tratio,
            tvmix = tvmix,
            varsiwant = list(varsiwant),
            veght = veght,
            vscale = vscale,
            vscaleu = vscaleu,
            vscales = vscales,
            w_option = w_option,
            wbbh = wbbh,
            wbwf = wbwf,
            wbwr = wbwr,
            wvert = wvert,
            xmn = xmn,
            xmx = xmx,
            xres = xres,
            ymn = ymn,
            ymx = ymx,
            yres = yres,
            zicontroltf = zicontroltf,
            ziscale = ziscale,
            z_top = z_top,
            zcoruverr = zcoruverr)
