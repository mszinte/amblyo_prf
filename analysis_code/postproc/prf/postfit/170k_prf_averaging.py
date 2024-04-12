"""
-----------------------------------------------------------------------------------------
170k_prf_averaging.py
-----------------------------------------------------------------------------------------
Goal of the script:
Average all subjects of pRF derivatives on the 170k format.
-----------------------------------------------------------------------------------------
Input(s):
sys.argv[1]: main project directory
sys.argv[2]: project name (correspond to directory)
sys.argv[3]: group (e.g. 327)
sys.argv[4]: model (e.g. css, gauss)
-----------------------------------------------------------------------------------------
Output(s):
sh file for running batch command
-----------------------------------------------------------------------------------------
To run:
1. cd to function
>> cd ~/projects/[PROJECT]/analysis_code/postproc/prf/postfit/
2. run python command
>> python 170k_prf_averaging.py [main directory] [project name] [group] [model]
-----------------------------------------------------------------------------------------
Exemple:
python 170k_prf_averaging.py /scratch/mszinte/data amblyo_prf 327 gauss
python 170k_prf_averaging.py /scratch/mszinte/data amblyo_prf 327 css
-----------------------------------------------------------------------------------------
Written by Uriel Lascombes (uriel.lascombes@laposte.net)
Edited by Martin Szinte (martin.szinte@gmail.com)
-----------------------------------------------------------------------------------------
"""
# Stop warnings
import warnings
warnings.filterwarnings("ignore")

# Debug 
import ipdb
deb = ipdb.set_trace

# General imports
import os
import sys
import json
import pandas as pd
import numpy as np
import nibabel as nb

# Personal imports
sys.path.append("{}/../../../utils".format(os.getcwd()))
from pycortex_utils import get_rois
from surface_utils import make_surface_image, load_surface

# Inputs
main_dir = sys.argv[1]
project_dir = sys.argv[2]
group = sys.argv[3]
model = sys.argv[4]

with open('../../../settings.json') as f:
    json_s = f.read()
    analysis_info = json.loads(json_s)
subjects = analysis_info['subjects']
formats = analysis_info['formats']
extensions = analysis_info['extensions']
prf_task_name = analysis_info['prf_task_name']

prf_dir = '{}/{}/derivatives/pp_data/sub-170k/170k/prf'.format(main_dir, project_dir)
avg_170k_dir = '{}/prf_derivatives'.format(prf_dir)
os.makedirs(avg_170k_dir, exist_ok=True)
    
for n_subject, subject in enumerate(subjects) :
    print('adding {}...'.format(subject))
    
    deriv_dir = '{}/{}/derivatives/pp_data/{}/170k/prf/prf_derivatives'.format(main_dir, 
                                                                               project_dir, 
                                                                               subject)
    
    if model == 'gauss' :
        deriv_fn = '{}_task-{}_fmriprep_dct_avg_prf-deriv_gauss_gridfit.dtseries.nii'.format(
            subject, prf_task_name)
    elif model == 'css':
        deriv_fn = '{}_task-{}_fmriprep_dct_prf-deriv_pcm-loo-avg_css.dtseries.nii'.format(
            subject, prf_task_name)
    
    img, data = load_surface(fn='{}/{}'.format(deriv_dir, deriv_fn))

    # Average without considering nan 
    if n_subject == 0:
        data_avg = np.copy(data)
    else:
        data_avg = np.nanmean(np.array([data_avg, data]), axis=0)

# Export results 
if model == 'gauss' :
    avg_170k_fn = 'sub-170k_task-{}_fmriprep_dct_avg_prf-deriv_gauss_gridfit.dtseries.nii'.format(
        prf_task_name)
    maps_names = ['rsq', 'ecc', 'polar_real', 'polar_imag', 'size',
                  'amplitude','baseline', 'x','y','hrf_1','hrf_2']
elif model == 'css':
    avg_170k_fn = 'sub-170k_task-{}_fmriprep_dct_prf-deriv_pcm-loo-avg_css.dtseries.nii'.format(
        prf_task_name)
    maps_names = ['prf_rsq', 'prf_ecc', 'polar_real', 'polar_imag', 
                  'prf_size', 'amplitude', 'baseline', 'prf_x','prf_y',
                  ' hrf_1', 'hrf_2','prf_n', 'prf_loo_r2', 'pcm']

print('saving {}/{}'.format(avg_170k_dir, avg_170k_fn))
avg_img = make_surface_image(data=data_avg, source_img=img, maps_names=maps_names)
nb.save(avg_img,'{}/{}'.format(avg_170k_dir, avg_170k_fn))

# Make TSV
if model == 'css':
    prf_tsv_dir = "{}/tsv".format(prf_dir)
    os.makedirs(prf_tsv_dir, exist_ok=True)
    
    concat_rois_list = [analysis_info['mmp_rois'], analysis_info['rois']]
    for n_list, rois_list in enumerate(concat_rois_list):
        rois = rois_list
        surf_size = '170k'
        if 'LO' in rois_list:
            atlas_name = 'mmp_group'
        else:
            atlas_name = 'mmp'
    
        roi_verts_L, roi_verts_R = get_rois(subject, 
                                            return_concat_hemis=False, 
                                            return_hemi=None, 
                                            rois=rois, 
                                            mask=True, 
                                            atlas_name=atlas_name, 
                                            surf_size=surf_size)
        
        df_rois_brain = pd.DataFrame()
        for hemi in ['hemi-L', 'hemi-R']:
            if hemi == 'hemi-L':
                roi_verts = roi_verts_L
            elif hemi == 'hemi-R':
                roi_verts = roi_verts_R
                
            for roi in roi_verts.keys():
                # make a dict with data for each rois 
                data_dict = {col: data_avg[col_idx, roi_verts[roi]] for col_idx, col in enumerate(maps_names)}
                data_dict['rois'] = [roi] * data_avg[:, roi_verts[roi]].shape[1]
                data_dict['subject'] = ['sub-170k'] * data_avg[:, roi_verts[roi]].shape[1]
                data_dict['hemi'] = [hemi] * data_avg[:, roi_verts[roi]].shape[1]
                df_rois_hemi = pd.DataFrame(data_dict)
                df_rois_brain = pd.concat([df_rois_brain, df_rois_hemi], ignore_index=True)
    
            # export tsv for mmp rois and mmp group rois 
            if atlas_name == 'mmp':
                df_rois_brain.to_csv('{}/sub-170k_css-prf_derivatives.tsv'.format(prf_tsv_dir), 
                                     sep="\t", na_rep='NaN',index=False)
            elif atlas_name == 'mmp_group':
                df_rois_brain.to_csv('{}/sub-170k_css-prf_derivatives_group.tsv'.format(prf_tsv_dir), 
                                     sep="\t", na_rep='NaN',index=False)

# Define permission cmd
os.system("chmod -Rf 771 {}/{}".format(main_dir, project_dir))
os.system("chgrp -Rf {} {}/{}".format(group, main_dir, project_dir))