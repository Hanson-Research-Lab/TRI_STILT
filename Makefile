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
data: 
	$(PYTHON_INTERPRETER) src/data/make_data.py data/raw/Toxic_Release_Inventory_raw data/processed 1990 1999 0.20 ./data/raw/IARC_Class_Full_List.csv ./data/raw/TRI_Pubchem_CIDs.csv ./data/raw/RSEI_Facility_Data.csv

#Convert the data into STILT Compatible Format
stilt_input:
	$(PYTHON_INTERPRETER) src/data/make_stilt_data_1.py data/processed/TRI_base_process_90_99.csv data/processed/unique_TRI_location_height_year 1990 1999
	Rscript src/data/make_stilt_data_2.r data/processed/unique_TRI_location_height_year_stilt_RUN.csv data/processed/stilt_input/090920_valid_run_1.rds TRUE

#Convert files from netCDF stilt outputs to shapefiles [TO DO: Add multiplication ]
stilt_output_conversion:
	$(PYTHON_INTERPRETER) src/stilt_post_processing/make_stilt_outputs.py data/raw/STILT/091620_tuning_run_1 data/processed/stilt_output 0 3857

## Lint using flake8
lint:
	flake8 src

#DEV STUFF:
save_requirements:
	pip freeze > requirements.txt

#################################################################################
# PROJECT RULES                                                                 #
#################################################################################


#################################################################################
# Self Documenting Commands                                                     #
#################################################################################

.DEFAULT_GOAL := help

# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
# sed script explained:
# /^##/:
# 	* save line in hold space
# 	* purge line
# 	* Loop:
# 		* append newline + line to hold space
# 		* go to next line
# 		* if line starts with doc comment, strip comment character off and loop
# 	* remove target prerequisites
# 	* append hold space (+ newline) to line
# 	* replace newline plus comments by `---`
# 	* print line
# Separate expressions are necessary because labels cannot be delimited by
# semicolon; see <http://stackoverflow.com/a/11799865/1968>

