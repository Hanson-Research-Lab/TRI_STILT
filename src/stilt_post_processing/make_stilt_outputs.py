# -*- coding: utf-8 -*-
import click
import glob
import pandas as pd
import math
import json
from urllib.request import urlopen
import glob
import numpy as np



#Click represents a package to easily interface between the terminal and python 
#Note all click commands must be in line with the function they are wrapping
@click.command()


def main()
    """ Runs data processing scripts to turn raw data from (../raw) into
        cleaned data ready to be analyzed (saved in ../processed).
    """
    #Steps of data preprocessing go in here:

    #Load the Data
    tri_raw_df = data_loader(input_filepath, int(min_year), int(max_year))
    #Clean the Data
    tri_clean = data_clean(tri_raw_df,float(threshold))

    #Filter down the data    
    iarc_merge = data_iarc_linkage(tri_clean,iarc_path,['1','2A','2B',np.nan])

    pubchem_merge = data_pubchem_linkage(iarc_merge, pubchem_path)
    rsei_merge = data_RSEI_data_linkage(pubchem_merge,rsei_path)
    rsei_merge.to_csv(output_filepath + '/TRI_base_process_90_99.csv')

if __name__ == '__main__': 
    main()