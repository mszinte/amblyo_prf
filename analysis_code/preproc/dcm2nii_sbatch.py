"""
-----------------------------------------------------------------------------------------
dcm2nii_sbatch.py
-----------------------------------------------------------------------------------------
Goal of the script:
* Transform the origin file structure into a clean BIDS structure, following https://bids-specification.readthedocs.io
* Convert dicom to niix following structure in a csv file job_list.csv stored in stereo_prf/dcm2niix/
-----------------------------------------------------------------------------------------
Input(s):
path to the project data folder (stereo_prf) - inside that folder, you should find sourcedata, derivatives, ...
-----------------------------------------------------------------------------------------
Output(s):
the BIDS folder structure with the files converted in nifti
-----------------------------------------------------------------------------------------
To run:
Find where dcm2nii_sbatch.py is located (say in ~/XX/), and where your project files are located (say ~/path2stereo_prf/) and run:
>> python ~/XX/dcm2nii_sbatch.py ~/path2stereo_prf/
Example:
From mesocentre:
>> python  ~/projects/stereo_prf/analysis_code/preproc/dcm2nii_sbatch.py '/scratch/mszinte/data/stereo_prf/'
From invibe nohost:
>> python  ~/disks/meso_H/projects/stereo_prf/analysis_code/preproc/dcm2nii_sbatch.py '~/disks/meso_S/data/stereo_prf/'
-----------------------------------------------------------------------------------------
Written by Adrien Chopin (adrien.chopin@gmail.com) - 2022
-----------------------------------------------------------------------------------------
"""

import pandas as pd
import os
import sys

project_dir = os.path.expanduser(sys.argv[1])
rootpath = os.path.join(project_dir,'sourcedata') # data directory
filepath = os.path.join(rootpath,'dcm2niix','job_list.csv')
print('Opening', filepath)
data = pd.read_csv(filepath, sep=';')
# check data integrity
print(data.head())

# define roots for source and destination
sourceroot = os.path.join(rootpath,'Big_data_STAM')
destroot = os.path.join(rootpath,'dcm2niix')

# loop through the file to read the source and destination files, with mask renaming
# first create the folder structure
for i in range(0, len(data)):
    source = os.path.join(sourceroot,data.iloc[i].sources)
    if not(os.path.exists(source)):
        print('This source does not seem to exist - check it before we run the whole thing: '+source)
        break
    dest_dir_lvl1 = os.path.join(destroot,"sub-{p:02.0f}".format(p=data.iloc[i]['sub']))
    if not(os.path.exists(dest_dir_lvl1)):
        os.mkdir(dest_dir_lvl1)   
        print('Creating directory '+dest_dir_lvl1)
    dest_dir_lvl2 = os.path.join(dest_dir_lvl1,"ses-{p:02.0f}".format(p=data.iloc[i].ses))
    if not(os.path.exists(dest_dir_lvl2)):
        os.mkdir(dest_dir_lvl2)
        print('Creating directory '+dest_dir_lvl2)
    dest_dir_lvl3 = os.path.join(dest_dir_lvl2,data.iloc[i].data_type)    
    if not(os.path.exists(dest_dir_lvl3)):
        os.mkdir(dest_dir_lvl3)
        print('Creating directory '+dest_dir_lvl3)
        
# then do the conversion job
for i in range(0, len(data)):
    source = os.path.join(sourceroot,data.iloc[i].sources)
    dest_dir = os.path.join(destroot,"sub-{p:02.0f}".format(p=data.iloc[i]['sub']),"ses-{p:02.0f}".format(p=data.iloc[i].ses),data.iloc[i].data_type)
    dest_file = "sub-{p:02.0f}".format(p=data.iloc[i]['sub'])+"_ses-{p:02.0f}".format(p=data.iloc[i].ses)+'_task-'+data.iloc[i].task+"_run-{p:1.0f}".format(p=data.iloc[i].run)+'_'+data.iloc[i].modality
    print('Attempting to convert from '+source+' to '+dest_dir+' with file '+dest_file)
    print('dcm2niix -z y -s n -x n –b y –ba y -v 1 -f '+dest_file+' -o '+dest_dir+' \''+source+'\'') #change print for os.system
    # ex: os.system('dcm2niix -z y -s n -x n –b y –ba y -v 1 -f \'test\' -o \'/home/achopin/disks/meso_S/data/stereo_prf/sourcedata/dcm2niix/sub-01/\' \'/home/achopin/disks/meso_S/data/stereo_prf/sourcedata/Big_data_STAM/AM52/am52 pRF selected runs/01b_epi_retino_DICOM/epi01_neuro_retinotopy_11/\'')
    # -z y : gzip the files
    # -s n : convert all images in folder
    # -x n : do not crop
    # -b y : generate BIDS structure
    # -ba y: BIDS anonimization
    # -v 1 : verbose level 1
    # -f XXX: renaming mask here (or just output file name) 
    # -o YY : output folder YY
    # input folder XX ALWAYS needs to be the last argument