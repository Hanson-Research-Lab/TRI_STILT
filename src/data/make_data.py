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

#INPUT: ALL TRI DATA 
#EXPORT CLEANED TRI DATA WITH LINKAGES 

def data_loader(TRI_path, min_year, max_year):
    """Converts a folder of TRI data into a single dataframe frame

    ===
    Inputs: 
    1. TRI_path - path to TRI data labeled with tri_YEAR_ut.csv
    2. min_year - the minimum TRI year of interest
    3. max_year - the maximum TRI year of interest

    Returns: 
    1. a pandas dataframe of all TRI releases from the min_year to the max_year
    """

    temp_list = []
    #Collect all data and compress into a dataframe  
    for filename in sorted(glob.glob(TRI_path + "/tri_[1,2][0-9][8,9,1][0-9]*")):
        temp_df = pd.read_csv(filename)
        temp_list.append(temp_df)

    raw_TRI_df = pd.concat(temp_list)
    
    #Standardize column labels
    raw_TRI_df.rename(columns=lambda x: ' '.join(x.split('.')[1:]), inplace=True)
    raw_TRI_df.rename(columns=lambda x: x.replace(' ',''), inplace=True)

    #ONLY STACK AND FUGITIVE RELEASES
    raw_TRI_df = raw_TRI_df[(raw_TRI_df['51-FUGITIVEAIR']>0) | (raw_TRI_df['52-STACKAIR']>0)]

    #Select the data of interest
    return raw_TRI_df.loc[(raw_TRI_df['YEAR']>=min_year) & (raw_TRI_df["YEAR"] <= max_year)]

def data_clean(tri_data_raw, threshold):
    """Cleans TRI data by removing any columns with high amounts of missing data

    ===
    Inputs: 
    1. tri_data_raw - pandas dataframe containing TRI data (comes from data_loader)
    2. threshold - Missing data percentage cutoff for removal 

    Returns: 
    1. pandas dataframe with clean data
    """
    clean_index = tri_data_raw.isna().sum()<math.floor(tri_data_raw.shape[0]*threshold)
    tri_data_raw.loc[:,clean_index.index[clean_index==True]]
    return tri_data_raw[['YEAR','TRIFD','FRSID','FACILITYNAME','CITY','COUNTY','ST','ZIP','LATITUDE','LONGITUDE','INDUSTRYSECTORCODE','INDUSTRYSECTOR','CHEMICAL','CAS#/COMPOUNDID','METAL','CARCINOGEN' ,'UNITOFMEASURE','51-FUGITIVEAIR','52-STACKAIR','INDUSTRYSECTORCODE','PRODUCTIONWSTE(81-87)']]

def data_iarc_linkage(TRI_clean_df, IARC_path, classes_of_interest):
    """Link TRI to IARC chemical data

    ===
    Inputs: 
    1. TRI_clean_df - cleaned TRI data, most likely coming from data_clean
    1. IARC_path - path to IARC chemical data list (csv format) [SOURCE]
    2. classes_of_interest - list of IARC designations of interest (1, 2A, 2B, 3) 

    Returns: 
    1. dataframe with linked IARC data
    """

    #Load IARC Data
    iarc_df = pd.read_csv(IARC_path)

    #Standardize the Column Names
    iarc_df.rename(columns=lambda x: x.replace(' ','_'), inplace=True)
    iarc_df.rename(columns=lambda x: x.replace('.',''), inplace=True)

    #The CAS numbers are not standardized between groups. Let's change that!
    #A CASRN contains a first number (2-7 digits) - second number (2 digits) - third number - 1 digit=
    iarc_df.CAS_No = iarc_df.CAS_No.str.replace('-','').apply('{:0>9}'.format)
    iarc_df.CAS_No = iarc_df.CAS_No.str.replace('000000nan',str(np.nan))

    #Select those chemicals with a 1,2A or 2B designation (KNOWN CARCINOGENS)
    known_carc = iarc_df[iarc_df.Group.isin(classes_of_interest)]

    #within the known carcinogens group, cobalt and Di(2-ethylhexyl)phthalate contain duplicates, we need to remove these
    known_carc = known_carc[known_carc.Agent != 'Cobalt metal without tungsten carbide']
    known_carc = known_carc[known_carc.Agent != 'Bis(2-ethylhexyl) phthalate (see Di(2-ethylhexyl) phthalate)']
    
    #Merge the data
    iarc_merge = known_carc.merge(TRI_clean_df, 
                                        left_on='CAS_No', 
                                        right_on='CAS#/COMPOUNDID',
                                        how='inner').drop(columns =['Agent','Volume','Year','Additional_information'])

    #Acid mists and Bis(2-ethylhexyl) phthalate have a special see other chemical. Fix those entries
    iarc_merge.loc[iarc_merge.CHEMICAL== "Strong-inorganic-acid mists containing sulfuric acid (see Acid mists)",
       'Group'] = '1'

    iarc_merge.loc[iarc_merge.CHEMICAL== "Bis(2-ethylhexyl) phthalate (see Di(2-ethylhexyl) phthalate)",
       'Group'] = '2B'

    return iarc_merge

def data_pubchem_linkage(TRI_clean_df, pubchem_id_path):
    """Link pubchem information to TRI Data

    Note: Currently there is no information coming in for Creosote, PCBs, Sulfuric Acids containing. These chemicals are either conglomerates or not represented in pubchem. For now they are being ommited.

    ===
    Inputs: 
    1. TRI_clean_df - cleaned TRI data, most likely coming from data_clean
    2. pubchem_id_path - path to pubchem ID list for CAS #'s in TRI_clean_df 

    Returns: 
    1. dataframe with linked pubchem information data
    """

    #Load Pubchem IDs
    pubchem_ids = pd.read_csv(pubchem_id_path)

    #Verify there are no missing chemicals. If there are missing chemicals print them out and 
    if TRI_clean_df.CHEMICAL.drop_duplicates().reset_index(drop=True).equals(pubchem_ids.CHEMICAL) != True:
        print('There are chemical(s) in TRI_clean_df which have no pubchem ids. Pubchem data was not added.')
        print('Please add the ids in data/raw/TRI_Pubchem_CIDS for the following chemicals:')
        print(TRI_clean_df.CHEMICAL.drop_duplicates().reset_index(drop=True)[~TRI_clean_df.CHEMICAL.drop_duplicates().reset_index(drop=True).isin(pubchem_ids.CHEMICAL)])
        return TRI_clean_df
    
    ##Adding Pubchem information: 
    tox_df = []
    computed_df = []
    exp_df = []

    pubchem_api_link = 'https://pubchem.ncbi.nlm.nih.gov/rest/pug_view/data/compound/XXX/JSON'

    #First we need to query all the of the urls
    #NOTE THERE IS STILL A PROBLEM WITH METHYL ISOBUTYL KETONE. For some reason the API hates the query
    for pubchem_id in pubchem_ids.Pubchem_ID:

        #Want only the URLs which are not nan to continue through the pipeline
        try:
            URL = pubchem_api_link.replace('XXX',str(int(pubchem_id)))
        except ValueError:
            print("No pubchem information detected in TRI Pubchem CID csv")
            continue

        #Collect the Information from the API
        data = json.load(urlopen(URL))
        section_temp = pd.DataFrame(data)

        #Breakdown the information from the JSON File
        section_temp = pd.DataFrame(section_temp['Record'].loc['Section'])  

        cp_prop = pandas_expander(section_temp,'Chemical and Physical Properties','Section')
        computed_prop = pandas_expander(cp_prop,'Computed Properties','Section')
        exp_prop = pandas_expander(cp_prop,'Experimental Properties','Section')

        tox_prop = pandas_expander(section_temp,'Toxicity','Section')
        tox_info = pandas_expander(tox_prop,'Toxicological Information','Section')


        #Collect the information into a dataframe: 
        #Toxicity Information
        temp_tox = tox_converter(tox_info,pubchem_id)
        tox_df.append(temp_tox)

        #Computed Information
        temp_computed = comp_converter(computed_prop,pubchem_id)
        computed_df.append(temp_computed)
        
        #Experimental Information
        temp_exp = exp_converter(exp_prop,pubchem_id)
        exp_df.append(temp_exp)

    #Harmonize the information    
    tox_df = pd.concat(tox_df)
    computed_df =pd.concat(computed_df)
    exp_df =pd.concat(exp_df)
    temp = tox_df.merge(computed_df)
    pubchem_df = exp_df.merge(temp)

    #Create a shared index for join
    TRI_clean_df =  TRI_clean_df.merge(pubchem_ids,how='left')
    
    #Return a merged version of the data
    return TRI_clean_df.merge(pubchem_df, how='left')

 #Functions to help deal with the JSON format of pubchem

def pandas_expander(df,TOC_of_interest,section):
    temp = df[df.TOCHeading ==TOC_of_interest][section]
    return pd.DataFrame(temp.iloc[0])

def tox_converter(df,pubchem_id):
    temp_list =[]
    for props in df['TOCHeading'].to_list():
        try: 
            a = pandas_expander(df,props,'Information')['Value']
            temp_list.append(a[0]['StringWithMarkup'][0]['String'])
        except:
            temp_list.append('')

    temp_df = pd.DataFrame(temp_list).T
    temp_df.columns = df['TOCHeading'].to_list()
    temp_df['Pubchem_ID'] = int(pubchem_id)
    return temp_df

def comp_converter(df,pubchem_id):
    temp_list =[]
    for props in df['TOCHeading'].to_list():
        try: 
            a = pandas_expander(df,props,'Information')['Value']
            temp_list.append(a[0]['Number'][0])
        except:
            temp_list.append('')

    temp_df = pd.DataFrame(temp_list).T
    temp_df.columns = df['TOCHeading'].to_list()
    temp_df['Pubchem_ID'] = int(pubchem_id)
    return temp_df

def exp_converter(df,pubchem_id):
    temp_list =[]
    for props in df['TOCHeading'].to_list():
        try: 
            a = pandas_expander(df,props,'Information')['Value'].iloc[0]['StringWithMarkup']
            temp_list.append(a[0]['String'])
        except:
            temp_list.append('')

    temp_df = pd.DataFrame(temp_list).T
    temp_df.columns = df['TOCHeading'].to_list()
    temp_df['Pubchem_ID'] = int(pubchem_id)
    return temp_df

def data_RSEI_data_linkage(TRI_clean_df, RSEI_path):
    """Link TRI to RSEI data about the TRI release

    ===
    Inputs: 
    1. TRI_clean_df - cleaned TRI data, most likely coming from data_clean
    2. RSEI_path - path to RSEI data (csv format) [SOURCE] 

    Returns: 
    1. dataframe with RSEI data merged
    """
    #Load the Data
    RSEI_fac_df = pd.read_csv(RSEI_path)

    merge = pd.merge(TRI_clean_df.reset_index(),
                    RSEI_fac_df,
                    left_on ='FRSID',
                    right_on = 'FRSID',
                    how='left')[TRI_clean_df.columns.to_list() + ['StackHeight','StackVelocity','StackDiameter','StackHeightSource','StackVelocitySource','StackDiameterSource']]

    return merge

def unzipper(input_filepath, output_filepath):
    """"Recursively unzips any files with .zip extension into the designated output folder

    ===
    Inputs:
        path: path to data sources in zipped format

    Returns:
    """
    #Find all .zip files within the input path
    zipped_folder_path = glob.glob(input_filepath + '/*.zip')

    #Unzip the files within the folder path
    for zipped_path in zipped_folder_path:
        with zipfile.ZipFile(zipped_path, 'r') as zip_ref:
            zip_ref.extractall(output_filepath)


#Click represents a package to easily interface between the terminal and python 
#Note all click commands must be in line with the function they are wrapping
@click.command()
@click.argument('input_filepath', type=click.Path(exists=True))
@click.argument('output_filepath', type=click.Path())
@click.argument('min_year')
@click.argument('max_year')
@click.argument('threshold')
@click.argument('iarc_path', type=click.File('rb'))
@click.argument('pubchem_path', type=click.File('rb'))
@click.argument('rsei_path', type=click.File('rb'))

def main(input_filepath, output_filepath, min_year,max_year, threshold, iarc_path, pubchem_path, rsei_path):
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

    #merge on the pubchem information 
    pubchem_merge = data_pubchem_linkage(iarc_merge, pubchem_path)
    rsei_merge = data_RSEI_data_linkage(pubchem_merge,rsei_path)
    rsei_merge.to_csv(output_filepath +'_{0}_{1}.csv'.format(int(min_year),int(max_year)))

if __name__ == '__main__': 
    main()