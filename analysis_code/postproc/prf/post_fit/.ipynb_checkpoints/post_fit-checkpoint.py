"""
-----------------------------------------------------------------------------------------
post_fit.py
-----------------------------------------------------------------------------------------
Goal of the script:
Combine fit files, compute pRF derivatives
-----------------------------------------------------------------------------------------
Input(s):
sys.argv[1]: main project directory
sys.argv[2]: project name (correspond to directory)
sys.argv[3]: subject name (e.g. sub-01)
-----------------------------------------------------------------------------------------
Output(s):
Combined estimate nifti file and pRF derivative nifti file
-----------------------------------------------------------------------------------------
To run:
>> cd to function
>> python prf/post_fit/post_fit.py [main directory] [project name] [subject num]
-----------------------------------------------------------------------------------------
Exemple:
cd ~/projects/stereo_prf/analysis_code/postproc/
ipython prf/post_fit/post_fit.py /scratch/mszinte/data stereo_prf sub-01
ipython prf/post_fit/post_fit.py /scratch/mszinte/data stereo_prf sub-02
ipython prf/post_fit/post_fit.py /scratch/mszinte/data stereo_prf sub-03
-----------------------------------------------------------------------------------------
Written by Martin Szinte (martin.szinte@gmail.com)
-----------------------------------------------------------------------------------------
"""

# General imports
import warnings
warnings.filterwarnings("ignore")
import os
import sys
import json
import numpy as np
import ipdb
import glob
import nibabel as nb
deb = ipdb.set_trace

# Functions import
from utils.prf_utils import fit2deriv

# Define analysis parameters
with open('settings.json') as f:
    json_s = f.read()
    analysis_info = json.loads(json_s)

# Inputs
main_dir = sys.argv[1]
project_dir = sys.argv[2]
subject = sys.argv[3]

# Define directories
pp_dir = "{}/{}/derivatives/pp_data".format(main_dir, project_dir)
prf_fit_dir = "{}/{}/derivatives/pp_data/{}/prf/fit".format(main_dir, project_dir, subject,)

# Get timeseries filenames
pp_avg_fns = glob.glob("{}/{}/func/fmriprep_dct_avg/*avg*.nii.gz".format(pp_dir,subject))

# Compute derivatives
for pp_avg_fn in pp_avg_fns:
    
    fit_fn = "{}/{}_prf-fit.nii.gz".format(prf_fit_dir, os.path.basename(pp_avg_fn)[:-7])
    pred_fn = "{}/{}_prf-pred.nii.gz".format(prf_fit_dir, os.path.basename(pp_avg_fn)[:-7])
    deriv_fn = "{}/{}_prf-deriv.nii.gz".format(prf_fit_dir, os.path.basename(pp_avg_fn)[:-7])
    
    if os.path.isfile(fit_fn) == False:
        sys.exit('Missing files, analysis stopped : {}'.format(fit_fn))
    else:
        print('Computing derivatives: {}'.format(deriv_fn))
        
        # get arrays
        fit_img = nb.load(fit_fn)
        fit_array = fit_img.get_fdata()
        data_array = nb.load(pp_avg_fn).get_fdata()
        pred_array = nb.load(pred_fn).get_fdata()
        
        # compute and save derivatives array
        deriv_array = fit2deriv(fit_array=fit_array, data_array=data_array, pred_array=pred_array)
        deriv_img = nb.Nifti1Image(dataobj=deriv_array, affine=fit_img.affine, header=fit_img.header)
        deriv_img.to_filename(deriv_fn)

# compute average loo derivatives
loo_deriv_avg_fn = "{}/{}_task-prf_fmriprep_dct_bold_loo_avg_prf-deriv.nii.gz".format(prf_fit_dir,subject)
print('Computing derivatives: {}'.format(loo_deriv_avg_fn))

loo_deriv_fns = glob.glob("{}/*loo*prf-deriv.nii.gz".format(prf_fit_dir))
loo_deriv_array = np.zeros_like(deriv_array)
for loo_deriv_fn in loo_deriv_fns:
    loo_deriv_array += nb.load(loo_deriv_fn).get_fdata()/len(loo_deriv_fns)
loo_deriv_img = nb.Nifti1Image(dataobj=loo_deriv_array, affine=fit_img.affine, header=fit_img.header)
loo_deriv_img.to_filename(loo_deriv_avg_fn)