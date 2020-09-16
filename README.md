# TRI_STILT

Running TRI STILT Simulations


1. Want to be able to run the simulations then automatically trigger post processing where files are visualized and quantified in order to act as feedback mechanism. This requires batching the simulations then running them through a postprocessing step (on CHPC) where data, figures and metrics can all be collected. 

STILT: 
All code is housed in the TRI_STILT Repo within the Hanson Lab Github. In order to run simulations properly, This repo must be cloned onto CHPC servers. Additionally, a separate folder must be initialized for STILT simulations. See the read_me in the TRI_STILT repo for setup. All code operates under the Linux Make system. In this form, all analysis should be repeatable utilizing the original TRI data. 

Requirements
    1. Within CHPC, download and install stilt. See chpc_help.txt within TRI_STILT for more help. Note: none of this is protected information, so regular CHPC environment is fine.
        a. Extract the NARR data for the years of interest (using xtrct-grid) and place into the STILT working directory. 
    2. `git clone https://github.com/Hanson-Research-Lab/TRI_STILT.git`
    3. Create and activate a python virtual environment with your preferred package manager 
        a. I recommend pyenv or conda for this project 

Organization: 
Under the home directory, two folders should exist: 1) STILT – a cloned directory to run all STILT simulations. 2) TRI_STILT – a cloned directory to handle all pre/post data processing and visualization.  The TRI_STILT follows a specific template in order to keep the repo as clean as possible. Below is a summary and purpose of each folder/file: [TO DO]

Setup: 
1. CHPC Setup https://www.chpc.utah.edu/documentation/software/r-language.php
    - login to chpc `ssh uXXXXXXXX@XXXXpeak.chpc.utah.edu`
    - Setup R (need a custom environment for several of the libraries)
        - `module load R`
        - `mkdir -p ~/glmodules/myR` (replace if you want, any env is fine except R!!)
        - `cp /uufs/chpc.utah.edu/sys/modulefiles/CHPC-18/Core/R/$R_VERSION.lua ~/glmodules/myR/`
        - `mkdir -p ~/RLIBS/$R_VERSION`
        - `vim ~/glmodules/myR/$R_VERSION.lua`
            - add anywhere: 
            - `setenv("R_LIBS_USER",pathJoin("/uufs/chpc.utah.edu/common/home",os.getenv("USER"),"RLibs",myModuleVersion()))`
        - `module load myR`
        - To check the installation use `echo $R_LIBS_USER` and make sure this points to your RLibs
        
2. 




    1. With the virtual environment active, navigate into the TRI_STILT directory
    2. Run: 
        a. make clean
            i. Cleans the existing python caches 
        b. make requirements
            i. uses pip to install all requirements to run the src code

Pre-Processing: 
    1. make data
        a. Executes src/data/make_data.py. This script cleans and converts all TRI raw data into a single csv, with RSEI and Pubchem information attached, saved under the dedicated output filepath + ‘/TRI_base_process_90_99.csv’.  Change the inputs within the makefile as you deem fit for your project. For more information about the inputs, please view make_data.py.  
    2. make stilt_inputs
        a. Executes src/data/make_stilt.py. This script converts the TRI csv file, into a format agreeable with STILT. This code is still under revision. This outputs, two CSV files in the /data/processed folder – *_id_mappings.csv contains the original TRI releases with an id column. Since STILT simulations only calculate flux fields, no concentration data is needed to run simulations. In order to cut down the number of simulations run, a subset of unique YEAR, LAT, LONG and HEIGHT (indicitivate of stack vs fugitive) are run by STILT. These are denoted by the *_stilt_RUN.csv file. The mappings join the simulations back to their original releases is contained within *_id_mappings.csv. 
        b. *_stilt_RUN.csv must now be converted to an R file and expanded based upon the dates of interest. Once processed, this file is saved to ./stilt/data/receptors_XX.rds. 

Running STILT
    1. First, a simulation .r file must be created based upon the hyperparameters of interest. This file is located within the /stilt/code/example_run.r. Change the parameters as necessary to fit the simulation. 
    2. Once configured, copy this file into the STILT working directories. This will overwrite the current run_stilt.r file.
        a. cd -- 
        b. cp ./TRI_STILT/stilt/code/example_run.r ./STILT/r/run_stilt.r
        c. cp ./TRI_STILT/stilt/data/receptors_XX.rds ./STILT/
    3. To run the simulations simply run:
        a. cd ./STILT/
        b. RScript ./r/run_stilt.r
    4. This automatically batches all data through SLURM and no configuration of a compute node/slurm job is necessary. 
    5. All outputs will become available in ./out/footprints/ as netcdf files

Post-processing:
{IN PROGRESS}

STILT Tuning:
Ben Fasoli, a member of the STILT development team recommended we examine the effect of chaning particles and smoothing levels to find a stable model. In order to do this, we are looking at several factors: 
    3. The plume area as determined by convex hull
    4. The mean distance between the source point and each particle
    5. The coeffecient of variation for the “foot” of all the particles. 	
Ben noted that these values should reach an “elbow” point where the model stabalizes and isn’t highly dependent on small changes in particles and smoothing. Greg is beginning to run these simulations and store metrics and visualization to distill these ideal parameters. Note that these parameters also enable comparison between simulations to guage how the shape is changing (IOU between two plumes) and how much stability there is on a cell to cell basis (COV)

Validation:
There exist some EPA sensors which monitor chemicals within the air back to 1990 and are within reasonable proximity to a TRI release. In order to boost the strength of our validation, we plan to model relevant TRI releases through 2018 with comparable EPA sensor data to validate how well our model estimates chemical concentration. {IN PROGRESS}