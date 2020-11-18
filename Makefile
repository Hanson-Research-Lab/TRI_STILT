.PHONY: clean data lint requirements sync_data_to_s3 sync_data_from_s3

#################################################################################
# GLOBALS                                                                       #
#################################################################################

PROJECT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PROJECT_NAME = EE_stilt
PYTHON_INTERPRETER = python3
SHELL= bash


#################################################################################
# COMMANDS                                                                      #
#################################################################################

## Install Dependencies
requirements: 
	$(PYTHON_INTERPRETER) setup.py
	$(PYTHON_INTERPRETER) -m pip install -U pip
	$(PYTHON_INTERPRETER) -m pip install -r requirements.txt

## Delete all compiled Python files
clean:
	find . -type f -name "*.py[co]" -delete
	find . -type d -name "__pycache__" -delete

## Make Dataset 
#Order of inputs: input path, output path (just what you want to name. Will add _min_year_max_year.csv to end of file), min year, max year, threshold (removes columns with over the threshold amount for missing data), IARC path, Pubchem Path, RSEI path
data: 
	$(PYTHON_INTERPRETER) src/data/make_data.py data/raw/Toxic_Release_Inventory_raw data/processed/TRI_clean 1990 1995 0.20 ./data/raw/IARC_Class_Full_List.csv ./data/raw/TRI_Pubchem_CIDs.csv ./data/raw/RSEI_Facility_Data.csv

#Convert the data into STILT Compatible Format
stilt_input:
	$(PYTHON_INTERPRETER) src/data/make_stilt_data_1.py data/processed/TRI_clean_1990_1995.csv data/processed/unique_TRI_location_height_year 1990 1999
	Rscript src/data/make_stilt_data_2.r data/processed/unique_TRI_location_height_year_RUN.csv data/processed/stilt_input/092520_receptor_subsample.rds TRUE

#Convert files from netCDF stilt outputs to shapefiles
stilt_output_conversion:
	$(PYTHON_INTERPRETER) src/stilt_post_processing/make_stilt_outputs.py data/processed/stilt_output/netcdf/092120_hysplit_v_stilt data/processed/stilt_output/shapefile/092120_hysplit_v_stilt.csv data/processed/unique_TRI_location_height_year_RUN.csv data/processed/unique_TRI_location_height_year_IDMAPPING.csv 0

## Lint using flake8
lint:
	flake8 src


########################################################################################
#CREATING AN ENTRY FOR RUNNING A SPECIAL BATCH FOR EXAMINING STYRENE CONCENTRATIONS
valid_data:
	$(PYTHON_INTERPRETER) src/data/make_data.py data/raw/Toxic_Release_Inventory_raw data/processed/TRI_valid 2010 2010 0.20 ./data/raw/IARC_Class_Full_List.csv ./data/raw/TRI_Pubchem_CIDs.csv ./data/raw/RSEI_Facility_Data.csv

#WENT OUT A SELECTED ONLY STYRENE (see notebook)
stilt_validation: 
	$(PYTHON_INTERPRETER) src/data/make_stilt_data_1.py data/processed/STYRENE_DEMO.csv data/processed/styrene 2010 2010
	Rscript src/data/make_stilt_data_2.r data/processed/styrene_RUN.csv data/processed/stilt_input/dummy_styrene.rds TRUE

#Convert netCDF files to a single shapefile
stilt_validation_output_conversion:
	$(PYTHON_INTERPRETER) src/stilt_post_processing/make_stilt_outputs.py data/processed/stilt_output/netcdf/092520_styrene data/processed/stilt_output/shapefile/092520_styrene_test.csv data/processed/styrene_stilt_RUN.csv data/processed/styrene_id_mappings.csv 0

##############################################################################
#DEV STUFF:
save_requirements:
	pip freeze > requirements.txt


.DEFAULT_GOAL := help

