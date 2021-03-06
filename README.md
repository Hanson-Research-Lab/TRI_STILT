# STILT for TRI Modeling: 
[Greg Lee](https://greglee1905.github.io/personalpage/), [Heidi Hanson](https://medicine.utah.edu/surgery/research/research-sections/uinquire/research-groups/hanson/), [Joemy Ramsay](https://medicine.utah.edu/surgery/research/research-sections/uinquire/research-groups/hanson/members.php), [Derek Malia](http://home.chpc.utah.edu/~u0703457/dereks_homepage/) and [Ben Fasoli](https://benfasoli.com/)<br>
September 26th 2020

<p align="center">
  <a href="https://github.com/Hanson-Research-Lab">
    <img src="logo.png"/>
  </a>
</p>

## Structure & Organization
Inspired by the [cookiecutter Data Science Project Structure](https://drivendata.github.io/cookiecutter-data-science/).

- CHPC HOME DIRECTORY 
    - _STILT_ - Initialized via `Rscript -e  "uataq::stilt_init('my_folder_name',branch='hysplit-merge')"`. Bolded names represent changes from the cloned repo
        - _bin_ - Initialized STILT Directory (no modifications)
        - _Dockerfile_ - Initialized STILT Directory (no modifications)
        - _docs_ - Initialized STILT Directory (no modifications)
        - _README.md_ - Initialized STILT Directory (no modifications)
        - _exe_ - Initialized STILT Directory (no modifications)
        - **_out_** - STILT Model Outputs
            - _particles_ - Particle trajectories and simulation configuration information are packaged and saved in a compressed .rds
            - _footprints_ - ppm/flux output placed on a netCDF grid (where grid cells are represented by centroids)
            - _by ids_ - simulation details
        - **_r_** - Houses scripts used to execute stilt
            - _run stilt.r_ - Main script utilized to execute STILT. Note, when building out a template in TRI_STILT/src/stilt_run, copy the file but leave the run nomenclature the same
            - _src_ - Initialized STILT Directory (no modifications) containing all STILT code
            - _stilt cli.r_ - Initialized STILT script (no modifications)
            - _dependencies.r_ - Initialized STILT script (no modifications)
        - _rslurm STILT_ - Initialized STILT Directory (no modifications)
        - _setup_ - Initialized STILT Directory (no modifications)
        - _stilt-tutorials_ - Initialized STILT Directory (no modifications) created when the test setup scripts are run
        - _test_ - Initialized STILT Directory (no modifications) created when the test setup scripts are run
        - **_UT NARR_** - xtrct-grid for NARR data within the Utah boundaries (+/- 6 degrees lat/long from Utah Center) 

    - _TRI_STILT_ - A cloned directory to handle all pre/post data processing and visualization
        - **_data_** - Houses data only. Data descriptions/origins are found in data_origin.txt which should be modified if data is added. 
            - _processed_ - Processed raw data. Often this will take the form of cleaned data, stilt inputs and stilt outputs. 
            - _raw_ - Immutable raw data. All results should be reproducible from this subset of data. 
            - _validation_ - Data to validate model results. A workflow is in development to script this process. 
        - **_figures_** - Storage for figures. For consistency, please use the same name for the stilt_input.rds, figures, stilt_run.r and output netcdf/csv/shapefiles
        - **_notebooks_** - Jupyter notebooks for data exploration, visualization and testing. It is preferred that code in the pipeline be transformed to a scripted form to ensure the project retains its repeatability and readability. 
            - _descriptiveanalysis.ipynb_ - Loading and exploring the raw TRI data, exploring the distributions of chemicals and spacial locations through time. 
            - _epavalidation.ipynb_ - A start to validation results from STILT simulations. Within, the nearest 100 TRI releases to every EPA sensor are found and saved in data/validation. A test simulation is run with 100 relevant TRI releases using a non-standard data isolation procedure (before 2015 due to not all NARR data being converted). Relevant data sets include `data/validation/092920_epa_valid_2014.csv`, `data/processed/stilt_input/092920_epa_valid_2014.rds`, `src/validation/092920_epa_validation.r` (convert csv to rds file) and `src/stilt_run/092920_epa_validation.r` (run_stilt.r file for STILT control).
            - _hysplitvsstilt.ipynb_ - Comparing results from HYSPLIT and STILT. HYSPLIT simulations were saved under validation data. If you need to recreate these simulations, please look into the Environmental Exposome and set a HYSPLIT model of 100 puffs.
            - _postprocessing.ipynb_ - A test script to demonstrate the basic post processing necessary after make stilt_output_conversion. This details how to extract and visualize portions of the saved .csv file. 
            - _stiltparametertuning.ipynb_ - An exploration into metrics to optimize STILT hyperparameters. At this point, Ben estimates it will be unnecessary unless the computational load becomes too heavy for the traditional program. 
        - **_src_** - folder to house all scripts to run pre and post-processing of STILT inputs
            - _data_ - Clean, link and process data to become ammenable to STILT modeling
            - _stiltpostprocessing_ - Converts netCDF to csv and links back to STILT simulations
            - _stiltrun_ - scripts to copy and past as `run_stilt.r` to control simulation. For base case see `src/stilt_run/template_run.r`
            - _validation_ - Scripts related to validation. Widely unfinished at this point in time. 
        - **_gitignore_** - git file to allocate files and folders which should not be added to the repo
        - **_chpc help.txt_** - a quick guide on how to use chpc. 
        - _LICENSE_ - License for code: MIT license
        - **_Makefile_** - Control file to run simulations - change to desired parameters and paths before running simulations
        - **_README.md_** - This file!
        - **_requirements.txt_** - pip requirements for python venv
        - _setup.py_ - A setup script to verify a virutal environment is setup correctly

<br>

---
## Setup: 
All steps create an environment on CHPC to run STILT simulations. 

1. **[CHPC](https://www.chpc.utah.edu/documentation/software/r-language.php)**
    - login to chpc `ssh uXXXXXXXX@XXXXpeak.chpc.utah.edu`
    - Create a directory for modules (unless you already have one built)
        - `mkdir ./gl_modules`
    - Setup a custom R environment to download the required libraries
        - `module load R`
        - `mkdir -p ~/gl_modules/myR` (replace if you want, any env is fine except R!!)
        - `ls /uufs/chpc.utah.edu/sys/modulefiles/CHPC-18/Core/R/` (and look for the most recent version of R. Here will use )
        - `cp /uufs/chpc.utah.edu/sys/modulefiles/CHPC-18/Core/R/4.0.2.lua ~/gl_modules/myR/`
        - `mkdir -p ~/RLibs/4.0.2/` (creating a place to install any new libraries)
        - `vim ~/gl_modules/myR/4.0.2.lua`
            - add anywhere: 
            - `setenv("R_LIBS_USER",pathJoin("/uufs/chpc.utah.edu/common/home",os.getenv("USER"),"RLibs",myModuleVersion()))`
        - Reload Terminal to update all scripts
        - Enable Modules (This should be done a new CHPC instance is accessed, unless custom.sh is modified to include these commands) 
            - `module use ~/gl_modules`
            - `module load myR`
            - `module load netcdf-c`
        - To check the installation use `echo $R_LIBS_USER` and make sure this points to your RLibs

2. **[STILT](https://github.com/uataq/stilt)**
    - Install the library using an R terminal
        - `install.packages(c("rslurm","splitstackshape"),lib=c(paste("/uufs/chpc.utah.edu/common/home/",Sys.getenv("USER"),"/RLibs/",Sys.getenv("R_VERSION"),sep="")), repos=c("http://cran.us.r-project.org"),verbose=TRUE)`
        - `if (!require('devtools')) install.packages('devtools')`
        - `devtools::install_github('benfasoli/uataq')`
    - Create a project in the root directory
        - `Rscript -e  "uataq::stilt_init('my_folder_name')"`
        - For the purposes of this tutorial, name the project STILT
    - Test simulation (Necessary to configure all files)
        - `bash ./test/test_setup.sh`
        - `bash ./test/test_run_stilt.sh`

3. **Python Virtual Environment on CHPC**  
    - Load the python version of interest
        - `which python (view current version of python)`
        - `module spider python`
    - Activate python 3.7
        - `module load python/3.7.3`
        - `which python` (should see a chpc origin)
    - Gather python3.7 and install with system site packages (this will create the virtual environment within gl_modules -- mystiltenv)
        - `python3.7 -m venv --system-site-packages ~/gl_modules/mystilt_env`
    - Launch the virtual environemnt
        - `module unload python/3.7.3`
        - `source ~/gl_modules/mystilt_env/bin/activate.csh`
    - You should see the virtual environment active - see a (mystilt_env) [uxxxxx@kingspeak1:~]

4. **TRI_STILT**
    - Install the Repo
        -`git clone https://github.com/Hanson-Research-Lab/TRI_STILT.git`
    - Install Libraries
        - `make clean` cleans the existing python caches
        - `make requirements` uses pip to install all requirements to run the src code
            - Currently an issue with RTree and CHPC!

5. **Extracting Utah Data from NARR Files** 
    - If available use the following to sync the UT NARR files: 
        - `rsync -azv /uufs/chpc.utah.edu/common/home/u0890227/STILT/UT_NARR ~/`
    - If not available, the LAIR group holds versions of NARR data which can be converted to get the same NARR files using [xtrct-grid](https://github.com/benfasoli/xtrct-grid), a software package from Ben Fasoli. 
        1. git clone https://github.com/benfasoli/xtrct-grid.git
        2. access using python3 ./xtrct-grid/entrypoint.py
        3. Isolate the NARR data for Utah (based upon these grid points:(45.3210,117,0937) (45.3210,105.0937) (33.3210,117,093) (33.3210,105.0937))
        4. To run: 
            - create new script within xtrct-grid called batch_extract_grid.py
            - Insert the following code: 
                ```
                import glob
                import subprocess
                import os

                #Double check this data is still available with Derrick Malia of LAIR
                import_path = '/uufs/chpc.utah.edu/common/home/lin-group5/NARR/'
                count=0

                for filename in glob.glob(import_path+'NARR199[0-9]*'):
                        narr_filename = filename.split('/')[-1]
                        out_name = "UT_"+narr_filename

                        #Take all the names and run them through the python 3 script. This is intended to be run from the xtrct-grid folder  
                        print(narr_filename)
                        p=subprocess.Popen('python3 ./entrypoint.py \
                                                --input_dir=$INPUT_DIR \
                    --input={0} \
                    --output_dir=$OUTPUT_DIR \
                    --output={1} \
                    --xmin=-117.0937 \
                    --xmax=-105.0937 \
                    --ymin=33.3210 \
                    --ymax=45.3210'.format(narr_filename,out_name),stdout=subprocess.PIPE,shell=True)

                        p.wait()

                        print(narr_filename + ' conversion complete')
                        count +=1
                ```
            - create a directory where you want to store the data: 
                - `mkdir /uufs/chpc.utah.edu/common/home/u0890227/STILT/UT_NARR`
            - Write the input and output directories 
                - `export INPUT_DIR=/uufs/chpc.utah.edu/common/home/lin-group5/NARR`
                - `export OUTPUT_DIR=/uufs/chpc.utah.edu/common/home/u0890227/STILT/UT_NARR`
            - Navigate to xtrct-grid directory and execute: 
                - Activate a compute node for ~ 4 hrs
                - `python3 batch_extract_grid.py`

<br>

---
## Pre-Processing

All steps are built utilizing a make style system. Before running, please edit the `Makefile` with the desired directories and variables. If choosing to run this on CHPC, you will need to use an interactive compute node or slurm job. For an interactive node use `srun --time=1:00:00 --ntasks=16 --nodes=1 --account=hanson --partition=notchpeak --pty /bin/bash -l`. 

1. **Clean Data** 
    - **Description:** <br>Executes src/data/make_data.py. This script cleans and converts all TRI raw data into a single csv, with RSEI and Pubchem information attached. Change the inputs within the makefile as you deem fit for your project. For code details please visit src/data/make_data.py.
    - **Assumptions:**
        1. Keeps only Fugitive and Stack Air Releases
        2. Removes any columns with over the threshold amount for missing data
        3. Keeps select columns of use: YEAR, TRIFD, FRSID, FACILITYNAME, CITY, COUNTRY, ST, ZIP, LATITUDE, LONGITUDE, INDUSTRYSECTORCODE, CHEMICAL, CAS#/COMPOUNDID, METAL, CARCINOGEN, UNITOFMEASURE, 51-FUGITIVEAIR and 52-STACKAIR. 
        4. IARC does not exist for the following chemicals so they are filled accordingly.  
            - Strong-inorganic-acid mists containing sulfuric acid (see Acid mists) - CLASS 1 
            - Bis(2-ethylhexyl) phthalate (see Di(2-ethylhexyl) phthalate) - CLASS 2B
        5. Pubchem merge is conditionally dependent on all chemical files being present within the `TRI_Pubchem_CIDS.csv` file. If chemicals are not found, this step is skipped. Within the CIDS.csv several of the chemicals do not have an ID (Creosote, PCB, Sulfuric Acid (1994..) and methyl isobutyl ketone). This indicates the chemical does not have a functional or easily defineable pubchem CID. 
        6. The primary purpose of the RSEI merge is to estimate stack height of fugitive releases
        7. Keeping all data which is not of IARC class 3 (known to not be carcinogenic)
    - **Makefile Command:** `make data`
    - **Inputs:**
        1. _Source Script_ - src/data/make_data.py
        2. _Input Filepath_ - Path to TRI data. All TRI release files must be labeled as tri_YEAR_ut.csv.
        3. _Output Filepath_ - Path to export cleaned data. Note: only the label of the file is needed as the years of the simulation and csv are added to the export ie `data/processed/test_clean` will fill to `data/processed/test_clean_1990_2018.csv`.
        4. _Min Year_ - An integer filter to keep only tri releases from the min year on (>=)
        5. _Max Year_ - An integer filter to keep only tri releases from the max year and below (<=)
        6. _Threshold_ - Missing values threshold. Throws out any variables which have greater than that percentage of missing data. 0.2 ~ 20% of rows are missing within that column
        7. _IARC Path_ - Path to IARC chemical data 
        8. _Pubchem Path_ - Path to Pubchem path. NOTE: pubchem is linked via a pubchem ID to the name of the chemical. This file is done for chemicals from 1990-1999. If these simulations are run in the future, a user will need to edit this file to include pubchem IDs for all new chemicals. If information is not available for all chemicals, this step is skipped and no pubchem information is linked. 
        9. _RSEI Path_ - Path to RSEI data from the EPA. 
    - **Outputs:** 
        1. Single csv file of name output_filepath_name_min_year_max_year.csv. I recommend placing this output within data/processed

2. **Convert to STILT Input Format:** 
    - **Description:** <br> Takes the cleaned TRI filepath and extracts the height, latitude,  longitude and time for STILT simulations. Aggregations occur for simulations and fugitive and stack releases are seperated per simulation run. Columns are renamed to lati, long, zagl and run_times. DO NOT ALTER THESE OR THE SIMULATIONS WILL SHOW AN IMPORT NULL ERROR. Per each TRI year, an expansion step is performed so releases happen on a daily basis. 
    - **Assumptions:**
        1. Currently date expansion is accounting for leap years
        2. No dates in the year are being omitted. If you wanted to change this edit the RDF File Conversion script
        3. Simulations which have identical year, lati, long and release height can be considered identical for modeling purposes
    - **Makefile Command:** `make stilt_input`
    - **Inputs:**
        1. Python Processing
            - _Source Script_ - `src/data/make_stilt_data_1.py`
            - _TRI Filepath_ - Path to the cleaned TRI data csv file aka: output_filepath_name_min_year_max_year.csv
            - _Output Filepath_ - File path and name for the exported data. Two outputs are produced to compress the number of simulations run. For example if output filepath is labeled data/processed/temp_tri, two outputs would appear within data/processed titled:
                - `temp_tri_RUN.csv` - input for STILT
                - `temp_tri_IDMAPPING.csv` - Compression map to find which simulations pair with what chemicals. Selections are removed based upon identical simulation height, lat/long and year (time). 
            - _Min Year_ - An additional year filter (in case you want to run different inputs from the same TRI file)
            - _Max Year_ - An additional year filter
        2. RDF File Conversion 
            - _Source Script_ - `src/data/make_stilt_data_2.r`
            - _Input path_ - Path to the `_RUN.csv` file
            - _Output path_ - Save path with rds extension. Recommended save in `data/processed/stilt_input/temp_name.rds`
            - _Random Sample_ - Boolean to indicate whether a subsample should be taken of the original data. [CURRENTLY UNIMPLEMENTED!]
    - **Outputs:**
        1. `_RUN.csv` - unique TRI releases based upon lati, long, zagl and year
        2. `_IDMAPPING.csv` - map to connect stilt simulations back to TRI releases
        3. `temp_name.rds` - Conversion of _RUN.csv to rds file format with extension of dates from year to all days within the year

<br>

---
## Running Simulations on CHPC

1. **Create a run_stilt.r file** 
    - **Description:** <br> In order to run stilt, a run_stilt.r file need to provided to the STILT program which governs all of the configuration [variables](https://uataq.github.io/stilt/#/configuration). For clarity, please create this file under and `src/stilt_run/date_description.r`, changing date and description for the run accordingly. I find it easiest to copy the `/src/stilt_run/template_run.r` file and only change what is necessary within a local editor, than push the changes to github and sync with CHPC.
    - **Changes:** 
        - _slurm options_ - change the time, account and partition based upon your CHPC account. Account reflects the lab name typically and partition represents the CHPC compute node you will use to run the program.
        - _run times_ - Add in the name of the rds file from the previous step (`temp_name.rds`). No filepath is necessary here as this file will be moved into the stilt main directory. 
        - _time integrate_ - Changed to TRUE (not default) so STILT will create a sum over the allocated n_hour time window
        - _xmn xmx ymn ymx and xres_ - changed to reflect the boundary of Utah with a bit of a cushion. 
        - _met directory_ - changed to reflect the directory within the STILT project where the UT NARR data is stored. 
        - _met file format_ - changed to reflect the naming nomenclature of UT_NARR files
        - _n hours_ - changed to be 24 to reflect the simulations are running for 24 hours following the release
        - _numpar_ - changed to 1000 on recommendation from Ben Fasoli. For highest efficiency this parameter may need to be tuned (see `notebooks/stilt_parameter_tuning.ipynb` for more on this). 
        - _emisshrs_ - set to 24 to model a continuous release instead of a single release. This may require more particles. 
        - _kmix0_ - variable (50-300). Note this marks one of the instabilities of stilt is nightime meteorology

2. **Starting a STILT Simulation** 
    - **Description:** <br> All steps up to this point have been run within the TRI_STILT project folder. These steps can be run on CHPC on locally, whichever suits you best. The following steps require the CHPC user to be within their home directory (both TRI_STILT and STILT directories should be visible with the `ls` command). This portion showcases all the steps to batch a simulation run out to slurm. I would recommend collapsing all these steps into bash script (sh)
    - **Procedure**
        1. Clear any previous STILT outputs
            - `rm ./STILT/out/particles/*`
            - `rm ./STILT/out/footprints/*`
            - `rm ./STILT/out/by_id/*`
        2. Copy over the file to run stilt and rename to typical stilt convention
            - `cp ./TRI_STILT/src/stilt_run/date_description.r ./STILT/r/run_stilt.r`
        3. Copy over the data for the run
            - `cp ./TRI_STILT/data/processed/stilt_input/temp_name.rds ./STILT/`
        4. Load module and run the program 
            - `module use ~/gl_modules`
            - `module load netcdf-c`
            - `module load myR`
            - `cd ./STILT/`
            - `Rscript r/run_stilt.r`
        5. STILT automatically batches in the simulations to CHPC (Thanks Ben and UATAQ team!)
    - **CHPC Helpful Commands** 
        - `squeue -u uXXXXXXX` : shows jobs related to you 
        - `sinfo` - status of different partitions
        - `scancel job_id` - cancel a job
        - `scontrol show job job_number` - shows information about a run

3. **Collecting Simulation Footprints** 
    - **Description:** <br> As the job processes simulation data will be processed into the `./STILT/out/footprints/` directory. Once completed (check with squeue - should see no active jobs) the data needs to be moved to TRI_STILT for storage and post-processing. This involves a quick move of the data! Again, this can be modified into a single bash script or kept single. Whichever works best for you!
    - **Procedure:**
        1. Make a new directory for the simulation run within TRI_STILT
            - `mkdir ./TRI_STILT/data/processed/stilt_output/netcdf/run_name`
        2. Copy the files into this new directory
            - `cp ./STILT/out/footprints/* ./TRI_STILT/data/processed/stilt_output/netcdf/run_name/`

<br>

---
## Post-Processing

These steps become more intensive in terms of processing. It is best to either use slurm batch scripting or an interactive node (see pre-processing for creating an interactive node session) if you choose to run this portion of the program on CHPC

1. **Pair netCDF Footprints to TRI Releases** 
    - **Description:** <br> In pre-processing, the TRI release amounts were removed to eliminate simulation overlap. Now these concentrations must be multiplied on a lbs/day basis to the stilt 0.01 x 0.01 km flux field. Furthermore, for ease of use, the individual release dataframes are combined into a single output frame for easier post-processing. 
    - **Assumptions:**
        1. Not yet accounting for leap year
        2. csv is a workable output
        3. This is still a slow process. Needs acceleration for large batches to not create a bottleneck. Consider join instead of merge within make_stilt_outputs.py or a better method for compression of data into a single UT_exposure dataframe. 
        4. The footprint files export ppm/flux, summed over the total simulation window timing. When we multiply by lbs/day this gives the mixing ratio. I am not sure that units work particularly well for validation. SO THIS IS SOMETHING THAT SHOULD BE LOOKED AT AGAIN. 
    - **Makefile Command:** `make stilt_input`
    - **Inputs:**
        1. _stilt netcdf file path_ - file path to folder of STILT footprints (netcdf .nc format) 
        2. _save file csv_ - filepath and name to save the final csv 
        3. _run file path_ - filepath to the csv file used to create the stilt outputs `_RUN.csv`
        4. _id mappings file path_ - filepath to the csv file with the TRI mappings ie `_IDMAPPINGS.csv` 
        5. _gridding threshold_ - Threshold to limit values which are included from the netcdf files (exported as a grid with 0's for those grid cells with nothing in them)

    - **Outputs:**
        1. Single csv file to the save file path. Below are the specifics of the dataframe. 
            - _lat_ - Grid cell latitude center
            - _lon_ - Grid cell longitude center
            - _foot_ - Grid cell flux
            - _lbsperday_ - Grid cell calculated concentration (Release/365 * foot). Does not account for leap year
            - _id_ - ID used to merge back to original TRI releases (ID maps a single simulation back to all TRI releases with that lat, long, zagl and year)
            - _TRI_source_lati_ - TRI source emission latitude 
            - _TRI_source_long_ - TRI source emission latitude 
            - _zagl_ - Height of the release (in meters)
            - _Chemical_ - Chemical released
            - _Release (lbs/year)_ - Initial TRI release
            - _YEAR_ - Year the TRI report was submitted
            - _ss name_ - name of the related STILT simulation
            - _ss path_ - path to related STILT simulation
            - _ss date_ - date the simulation was run

2. **Visualizing Output** 
    - **Description:** <br> In order to visualize and explore outputs from post-processing, a simple jupyter notebook was put together called post_processing.ipynb. Within the notebook, an output .csv can be loaded into a geodataframe and visualized. 

<p align="center">
  <a href="https://github.com/Hanson-Research-Lab">
    <img src="figures/hysplit_v_stilt/all_simulations_with_source.png"/>
  </a>
</p>

<br>

---
## Validation

**Parameter Tuning** <br>
Intially, we believed there was some tuning processes to elucidate the ideal model parameters for our case. To evaluate how particles and smoothing affected model we came up with three metrics.  Note that these parameters also enable comparison between simulations to guage how the shape is changing (IOU between two plumes) and how much stability there is on a cell to cell basis (COV) 

1. The plume area as determined by convex hull
2. The mean distance between the source point and grid cells > 0
3. The coeffecient of variation for the foot of the simulation

After chatting with Ben, it was decided that 1,000 particles was alright for our use case. If we ever need to return to those intial metrics, they are housed in `notebooks/stilt_parameter_tuning.ipynb`.

**Comparison to Hysplit** <br>
STILT and HYSPLIT are both programs capable of tracking particles in time. Initially they started as the same program and have diverged over time. We wanted to sanity check our STILT simulations by comparins HYSPLIT and STILT simulations. This work is done within `notebooks/hysplit_vs_stilt.ipynb` with figures in `figures/hysplit_v_stilt`. 

**EPA Monitor Validation** <br>
There exist some EPA sensors which monitor chemicals within the air back to 1990 and are within reasonable proximity to a TRI release. In order to boost the strength of our validation, we plan to model relevant TRI releases through 2018 with comparable EPA sensor data to validate how well our model estimates chemical concentration. {IN PROGRESS --> see `notebooks/epa_validation.ipynb`}

This section is where the most work needs to be done. Specifically, the lead sensors need to be isolated, and simulations run. Then we need to start to distill the signal from noise utilizing windows where lead is being produced and not produced

Note: This requires an added datafile from the UBOX (TRI_ValidationSet.csv into `data/validation/`)

