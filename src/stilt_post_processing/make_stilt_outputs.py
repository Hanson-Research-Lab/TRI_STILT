# -*- coding: utf-8 -*-
#Libraries
import click
import glob
import pandas as pd
import numpy as np
import xarray as xr 
import geopandas as gpd
import fiona
from shapely.geometry import Point
import descartes
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

def stilt_post_processing(stilt_df, threshold,epsg):
    '''Takes a stilt particle output, in a pandas dataframe, and converts to a geopandas object.  

    Input:
    ----------
    stilt_df - an output coming from nc_open, based upon netcdf to pandas conversion
    threshold - a value for filtering - if null no filtering is performed on the data. 

    Returns:
    sim_avg: a geodataframe of the average non-log_conc per the simulation run (48 hr with current setup) transformed to points for comparison
    '''  
    if threshold != None:
        stilt_df = stilt_df[stilt_df.foot>threshold] 
    
    sim_avg = stilt_df.groupby(['lat','lon']).agg({'foot':'mean'}).reset_index()

    #Converting to a geo-type object
    sim_avg = gpd.GeoDataFrame(sim_avg, geometry=gpd.points_from_xy(sim_avg.lon, sim_avg.lat)).set_crs(epsg=4326)
    sim_avg = sim_avg.to_crs(epsg=epsg)
    return sim_avg


#Click represents a package to easily interface between the terminal and python 
#Note all click commands must be in line with the function they are wrapping
@click.command()
@click.argument('stilt_filepath', type=click.Path(exists=True))
@click.argument('save_filepath', type=click.Path(exists=True))
@click.argument('gridding_threshold')
@click.argument('epsg')

def main(stilt_filepath, save_filepath, gridding_threshold ,epsg):
    """ Runs data processing scripts to turn raw data from (../raw) into
        cleaned data ready to be analyzed (saved in ../processed).
    """
    
    #extract the name from the stilt savefilepath to ensure processed aligns with raw
    file_name = stilt_filepath.split('/')[-1]

    #Make a save directory for storing processed files
    temp_dir = save_filepath + '/' +file_name
    os.mkdir(temp_dir)

    #convert the netcdf's to shapefiles and save
    for files in glob.glob(stilt_filepath + '/*.nc'):
        #Create a directory for the shapefile
        temp_name = temp_dir + '/' + files.split('/')[-1].split('.nc')[0]
        os.mkdir(temp_name)

        #extract and organize the information from the netcdf file
        temp_stilt = nc_open(files)
        temp_stilt_avg = stilt_post_processing(temp_stilt,float(gridding_threshold), int(epsg))
        temp_stilt_avg.to_file(temp_name +'/stilt_output.shp')

if __name__ == '__main__': 
    main()