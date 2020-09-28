# -*- coding: utf-8 -*-
import click
import glob
import pandas as pd

import math
import json
from urllib.request import urlopen
import glob
import numpy as np

#Build pipe: 
def STILT_converter(df,min_year,max_year,save_base_name):
    """
    Converts a dataframe containing LATITUDE LONGITUDE Stackheight, CHEMICAL and a zagl to a csv for STILT pipeline. 

    ===
    Inputs:
    1. df - dataframe containing expanded fugitive and stack releases, renamed zagl. 
    2. min_year - minimum year of TRI releases 
    3. max_year - maximum year of analysis for TRI releases
    4. save_base_name - the base save name for an id mappings file (USE FOR JOIN after STILT RUN) and a stilt run (USE FOR STILT) csv file

    Outputs: 
    1. Saves all files - no output returned 
    """

    #Create a base dataframe which houses all stilt runs as seperated by lat/long/stackheight/chemical/amount and year. 
    base_df = df[(df.YEAR >= min_year) & (df.YEAR <=max_year)][['LATITUDE','LONGITUDE','StackHeight','CHEMICAL','Release (lbs/year)','YEAR']].rename(columns={'LATITUDE':'lati','LONGITUDE':'long','CHEMICAL':'Chemical','StackHeight':'zagl'})

    #Stilt only runs particles based upon location and time (concentration unnessecary. Create a subset to run simulations on and an id to remerge on (for convolutional toxicity calculation))
    stilt_run_id = base_df.drop_duplicates(['lati','long','zagl','YEAR']).drop(columns=['Chemical','Release (lbs/year)']).sort_values(by='YEAR').reset_index(drop=True).reset_index().rename(columns = {'index':'id'})

    #Add the id to the base_df 
    stilt_trace_mapping = base_df.merge(stilt_run_id, on=['lati','long','zagl','YEAR']).sort_values(by='id')

    #save the files
    stilt_trace_mapping.to_csv(str(save_base_name + '_IDMAPPING.csv'),index=False)
    stilt_run_id.to_csv(str(save_base_name + '_RUN.csv'),index = False)

#Click represents a package to easily interface between the terminal and python 
#Note all click commands must be in line with the function they are wrapping
@click.command()
@click.argument('tri_filepath', type=click.Path(exists=True))
@click.argument('output_filepath', type=click.Path())
@click.argument('min_year')
@click.argument('max_year')

def main(tri_filepath, output_filepath, min_year, max_year):
    """ Takes raw TRI data, selects out data from the min-max year and saves in format compatible with stilt.
    """

    #Load TRI data: 
    tri_df = pd.read_csv(tri_filepath).drop(columns=['Unnamed: 0'])

    #This separates fugitive and stack releases - setting the stack height of the release for fugitive releases to 0
    fug = tri_df[tri_df['51-FUGITIVEAIR']>0]
    fug['StackHeight']=0
    fug = fug.rename(columns = {'51-FUGITIVEAIR':'Release (lbs/year)'})
    fug = fug.drop(columns = ['52-STACKAIR'])

    stack = tri_df[tri_df['52-STACKAIR']>0]
    stack = stack.rename(columns = {'52-STACKAIR':'Release (lbs/year)'})
    stack = stack.drop(columns = ['51-FUGITIVEAIR'])

    #Concatenate the results together
    stack_fug_df = pd.concat([stack,fug])

    #Convert into the STILT format
    STILT_converter(stack_fug_df,int(min_year),int(max_year),output_filepath)

if __name__ == '__main__': 
    main()