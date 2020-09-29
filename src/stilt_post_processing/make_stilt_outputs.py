# -*- coding: utf-8 -*-
#Libraries
import click
import glob
import pandas as pd
import numpy as np
import xarray as xr 
import geopandas as gpd
from shapely.geometry import Point
import os 

#PIPE to convert stilt netcdf files to shapefiles 

def nc_open(path):
    """
    A function to open netcdf4 files. Requires xarray
    ===
    Input:
    path - path to the cdf file

    Output: 
    df - converted cdf file to dataframe object
    """
    df = xr.open_dataarray(path)
    return df.to_dataframe().reset_index()

def stilt_netcdf_to_gdf(stilt_df, threshold):
    '''Takes a stilt footprint, filters based upon a threshold and averages the simulation 

    Input:
    ----------
    stilt_df - an output coming from nc_open, based upon netcdf to pandas conversion
    threshold - a value for filtering - if null no filtering is performed on the data. 
    epsg - coordinate selection for mapping

    Returns:
    sim_avg: a geodataframe of the average non-log_conc per the simulation run (48 hr with current setup) transformed to points for comparison
    '''  
    if threshold != None:
        stilt_df = stilt_df[stilt_df.foot>threshold] 
    
    sim_avg = stilt_df.groupby(['lat','lon']).agg({'foot':'mean'}).reset_index()
    return sim_avg



#Click represents a package to easily interface between the terminal and python 
#Note all click commands must be in line with the function they are wrapping
@click.command()
@click.argument('stilt_filepath', type=click.Path(exists=True))
@click.argument('save_filepath')
@click.argument('run_df_path', type=click.Path(exists=True))
@click.argument('id_mappings_path', type=click.Path(exists=True))
@click.argument('gridding_threshold')

def main(stilt_filepath, save_filepath, run_df_path,id_mappings_path, gridding_threshold):
    """ Runs data processing scripts to turn raw data from (../raw) into
        cleaned data ready to be analyzed (saved in ../processed).

    ----------
    Input:
    stilt_netcdf_path - file path to save cdf files from STILT modeling
    shapefile_save_path - file path for final geodataframe output
    run_df_path - file path to the csv file used to create the stilt outputs (comes from make stilt input)
    id_mappings_path - file path which links the original tri releases with the stilt output files
    gridding_threshold - a value for filtering - if null no filtering is performed on the data. 
    epsg - coordinate selection for mapping
    Returns:
    A saved shapefile within the desired shapefile_save_path location
    """

    #Load the Mapping Files
    run_df = pd.read_csv(run_df_path)
    id_mappings_df = pd.read_csv(id_mappings_path)
    temp_data_list = []
    
    # Gather Chemical information based upon the id_mappings
    for files in glob.glob(stilt_filepath + '/*.nc'):

        #Extract information from the data label
        filename = files.split('/')[-1].split('.nc')[0]
        YEAR = int(filename.split('_')[0][0:4])
        longi = float(filename.split('_')[1])
        lati = float(filename.split('_')[2])
        zagl = float(filename.split('_')[3])

        #Pair with original chemical data 
        temp_find = run_df[(run_df.YEAR == YEAR) & (run_df.zagl == zagl) & (run_df.long.round(6) == longi) & (run_df.lati.round(6) == lati)]
        temp_id = temp_find['id'].values[0]
        temp_data_list.append([filename,files,temp_id])

    #Pull all data into a single dataframe
    stilt_sim_df = pd.DataFrame(temp_data_list, columns = ['ss_name','ss_path','id'])

    #Merge the original chemical and release amount information
    stilt_sim_df = id_mappings_df.merge(stilt_sim_df)

    #Extract the Datetime Information
    stilt_sim_df['ss_date']=stilt_sim_df['ss_name'].str.split('_').str[0]

    #Collect the netcdf information -> calculate grid concentrations -> save as shapefile
    temp_data_list = []
    for rows in range(stilt_sim_df.shape[0]):
        #Load the netcdf file
        stilt_sim_gdf = nc_open(stilt_sim_df['ss_path'].iloc[rows])
        
        #Convert to a geodataframe
        stilt_sim_gdf = stilt_netcdf_to_gdf(stilt_sim_gdf,float(gridding_threshold))

        #Calculate the concentrations per cell
        stilt_sim_gdf['lbsperday'] = stilt_sim_gdf.foot * stilt_sim_df['Release (lbs/year)'].iloc[rows]/365 #not accounting for leap year yet
        stilt_sim_gdf['id'] = stilt_sim_df['id'].iloc[rows]
        temp_data_list.append(stilt_sim_gdf)

    #Concatenate into a single dataframe and merge with the stilt_sim_df metadata
    stilt_sim_gdf = pd.concat(temp_data_list)
    stilt_sim_gdf = stilt_sim_gdf.merge(stilt_sim_df).rename(columns = {'lati':'TRI_source_lati','long':'TRI_source_long'})

    #Save as a csv (do not convert to geopandas until all processing is done to accelerate speeds)
    stilt_sim_gdf.to_csv(save_filepath,index=False)

if __name__ == '__main__': 
    main()