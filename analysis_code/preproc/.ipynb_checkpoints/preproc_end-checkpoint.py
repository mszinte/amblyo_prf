"""
-----------------------------------------------------------------------------------------
preproc_end.py
-----------------------------------------------------------------------------------------
Goal of the script:
Arrange and average runs including leave-one-out averaging procedure, pick anat files
-----------------------------------------------------------------------------------------
Input(s):
sys.argv[1]: main project directory
sys.argv[2]: project name (correspond to directory)
sys.argv[3]: subject name
-----------------------------------------------------------------------------------------
Output(s):
# Preprocessed and averaged timeseries files
-----------------------------------------------------------------------------------------
To run:
1. cd to function
>> cd /home/mszinte/projects/stereo_prf/analysis_code/preproc/
2. run python command
python preproc_end.py [main directory] [project name] [subject name]
-----------------------------------------------------------------------------------------
Executions:
python preproc_end.py /scratch/mszinte/data stereo_prf sub-01
python preproc_end.py /scratch/mszinte/data stereo_prf sub-02
python preproc_end.py /scratch/mszinte/data stereo_prf sub-03
-----------------------------------------------------------------------------------------
Written by Martin Szinte (martin.szinte@gmail.com)
-----------------------------------------------------------------------------------------
"""

# Stop warnings
# -------------
import warnings
warnings.filterwarnings("ignore")

# General imports
import json
import sys
import os
import glob
import ipdb
import platform
import numpy as np
import nibabel as nb
import itertools as it
deb = ipdb.set_trace

# Inputs
main_dir = sys.argv[1]
project_dir = sys.argv[2]
sub_name = sys.argv[3]

# MRI analysis imports
trans_cmd = 'rsync -avuz --progress'
 
# Copy files in pp_data folder
dest_folder = "{}/{}/derivatives/pp_data/{}/func/fmriprep_dct".format(main_dir, project_dir, sub_name)
os.makedirs(dest_folder, exist_ok=True)
orig_folder = "{}/{}/derivatives/pybest/{}/ses-02/preproc/".format(main_dir, project_dir, sub_name)
pybest_files = glob.glob("{}/*_desc-preproc_bold.nii.gz".format(orig_folder))

for pybest_file in pybest_files:
    orig_file = pybest_file
    dest_file = "{}/{}".format(dest_folder,os.path.basename(pybest_file))
    os.system("{} {} {}".format(trans_cmd, orig_file, dest_file))

# Average tasks runs
preproc_files = glob.glob("{}/*_desc-preproc_bold.nii.gz".format(dest_folder))
avg_folder = "{}/{}/derivatives/pp_data/{}/func/fmriprep_dct_avg".format(main_dir, project_dir, sub_name)
os.makedirs(avg_folder, exist_ok=True)

avg_file = "{}/{}_task-prf_fmriprep_dct_bold_avg.nii.gz".format(avg_folder,sub_name)
img = nb.load(preproc_files[0])
data_avg = np.zeros(img.shape)

print("avg")
for file in preproc_files:
    print('add: {}'.format(file))
    data_val = []
    data_val_img = nb.load(file)
    data_val = data_val_img.get_fdata()
    data_avg += data_val/len(preproc_files)

avg_img = nb.Nifti1Image(dataobj=data_avg, affine=img.affine, header=img.header)
avg_img.to_filename(avg_file)

# Leave-one-out averages
if len(preproc_files):
    combi = list(it.combinations(preproc_files, len(preproc_files)-1))


for loo_num, avg_runs in enumerate(combi):
    print("loo_avg-{}".format(loo_num+1))

    # compute average between loo runs
    loo_avg_file = "{}/{}_task-prf_fmriprep_dct_bold_loo_avg-{}.nii.gz".format(avg_folder, sub_name, loo_num+1)
    
    img = nb.load(preproc_files[0])
    data_loo_avg = np.zeros(img.shape)

    for avg_run in avg_runs:
        print('loo_avg-{} add: {}'.format(loo_num+1, avg_run))
        data_val = []
        data_val_img = nb.load(avg_run)
        data_val = data_val_img.get_fdata()
        data_loo_avg += data_val/len(avg_runs)

    loo_avg_img = nb.Nifti1Image(dataobj=data_loo_avg, affine=img.affine, header=img.header)
    loo_avg_img.to_filename(loo_avg_file)

    # copy loo run (left one out run)
    for loo in preproc_files:
        if loo not in avg_runs:
            loo_file = "{}/{}_task-prf_fmriprep_dct_bold_loo-{}.nii.gz".format(avg_folder, sub_name, loo_num+1)
            print("loo: {}".format(loo))
            os.system("{} {} {}".format(trans_cmd, loo, loo_file))
                                                
# Anatomy
output_files = ['dseg','desc-preproc_T1w','desc-aparcaseg_dseg','desc-aseg_dseg','desc-brain_mask']
orig_folder_anat = "{}/{}/derivatives/fmriprep/fmriprep/{}/ses-02/anat/".format(main_dir, project_dir, sub_name, sub_name)
dest_folder_anat = "{}/{}/derivatives/pp_data/{}/anat".format(main_dir, project_dir, sub_name, sub_name)
os.makedirs(dest_folder_anat,exist_ok=True)

for output_file in output_files:
    orig_file = "{}/{}_ses-02_{}.nii.gz".format(orig_folder_anat, sub_name, output_file)
    dest_file = "{}/{}_{}.nii.gz".format(dest_folder_anat, sub_name, output_file)
    os.system("{} {} {}".format(trans_cmd, orig_file, dest_file))