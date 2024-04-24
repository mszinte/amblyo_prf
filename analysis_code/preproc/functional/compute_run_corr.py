"""
-----------------------------------------------------------------------------------------
compute_run_corr.py
-----------------------------------------------------------------------------------------
Goal of the script:
Computer inter-run correlations
-----------------------------------------------------------------------------------------
Input(s):
sys.argv[1]: main project directory
sys.argv[2]: project name (correspond to directory)
sys.argv[3]: subject name
sys.argv[4]: group of shared data (e.g. 327)
-----------------------------------------------------------------------------------------
Output(s):
# Inter-run correlation files
-----------------------------------------------------------------------------------------
To run:
1. cd to function
>> cd ~/projects/[PROJECT]/analysis_code/preproc/functional/
2. run python command
python compute_run_corr.py [main directory] [project name] [subject name] [group]
-----------------------------------------------------------------------------------------
Exemple:
python compute_run_corr.py /scratch/mszinte/data amblyo_prf sub-01 327
-----------------------------------------------------------------------------------------
Written by Martin Szinte (mail@martinszinte.net)
Edited by Uriel Lascombes (uriel.lascombes@laposte.net)
-----------------------------------------------------------------------------------------
"""

# Stop warnings
import warnings
warnings.filterwarnings("ignore")

# General imports
import json
import sys
import os
import glob
import ipdb
deb = ipdb.set_trace
import numpy as np
import nibabel as nb
import itertools as it
from scipy import stats
import shutil
import datetime

# Personal imports
sys.path.append("{}/../../utils".format(os.getcwd()))
from surface_utils import load_surface , make_surface_image
from maths_utils import linear_regression_surf, multipletests_surface

# Time
start_time = datetime.datetime.now()

# Inputs
main_dir = sys.argv[1]
project_dir = sys.argv[2]
subject = sys.argv[3]
group = sys.argv[4]

# Load settings
with open('../../settings.json') as f:
    json_s = f.read()
    analysis_info = json.loads(json_s)
tasks = analysis_info['task_names']
sessions = analysis_info['sessions']
formats = analysis_info['formats']
extensions = analysis_info['extensions']
fdr_alpha = analysis_info['fdr_alpha']
maps_names = analysis_info['maps_names_corr']

# make extension folders
corr_temp_dir = "{}/{}/derivatives/temp_data/{}_corr".format(main_dir, project_dir, subject)
os.makedirs(corr_temp_dir, exist_ok=True)

# Find all the filtered files 
preproc_fns = []
for format_, extension in zip(formats, extensions):
    list_ = glob.glob("{}/{}/derivatives/pp_data/{}/{}/func/fmriprep_dct/*_*.{}".format(
            main_dir, project_dir, subject, format_, extension))
    preproc_fns.extend(list_)

# Split filtered files  depending of their nature
preproc_fsnative_hemi_L, preproc_fsnative_hemi_R, preproc_170k = [], [], []
for subtype in preproc_fns:
    if "hemi-L" in subtype:
        preproc_fsnative_hemi_L.append(subtype)
    elif "hemi-R" in subtype:
        preproc_fsnative_hemi_R.append(subtype)
    elif "170k" in subtype:
        preproc_170k.append(subtype)
        
preproc_files_list = [preproc_fsnative_hemi_L,
                      preproc_fsnative_hemi_R,
                      preproc_170k]

# Inter-run correlations
slope_idx, intercept_idx, rvalue_idx, pvalue_idx, stderr_idx, \
    trs_idx, corr_pvalue_5pt_idx, corr_pvalue_1pt_idx = 0, 1, 2, 3, 4, 5, 6, 7

for preproc_files in preproc_files_list:
    for task in tasks:
        # Defind output files names 
        preproc_files_task = [file for file in preproc_files if task in file]

        if not preproc_files_task:
            print('No files for {}'.format(task))
            continue
        
        if preproc_files_task[0].find('hemi-L') != -1: hemi = 'hemi-L'
        elif preproc_files_task[0].find('hemi-R') != -1: hemi = 'hemi-R'
        else: hemi = None

        # Load preproc files to have meta and header
        preproc_img, preproc_data = load_surface(fn=preproc_files_task[0])
        
        # Compute the combination 
        combis = list(it.combinations(preproc_files_task, 2))

        # Load data and compute the correlations
        corr_stats_fns = []
        for combi_num, combi in enumerate(combis):
            a_img, a_data = load_surface(fn=combi[0])
            b_img, b_data = load_surface(fn=combi[1])
            combi_task_corr = linear_regression_surf(bold_signal=a_data, 
                                                     model_prediction=b_data,
                                                     correction='fdr_tsbh',
                                                     alpha=fdr_alpha)
            
            # Save combi files in temp_data
            if hemi: combi_corr_fn = "{}/{}_task-{}_{}_fmriprep_dct_corr_bold_combi-{}.func.gii".format(
                corr_temp_dir, subject, task, hemi, combi_num)
            else: combi_corr_fn = "{}/{}_task-{}_fmriprep_dct_corr_bold_combi-{}.dtseries.nii".format(
                corr_temp_dir, subject, task, combi_num)

            print("combi corr save: {}".format(combi_corr_fn))
            corr_stats_fns.append(combi_corr_fn)
            combi_corr_img = make_surface_image(data=combi_task_corr,
                                          source_img=preproc_img, 
                                          maps_names=maps_names)
            nb.save(combi_corr_img, combi_corr_fn)
            
        # Averaging
        corr_stats_img, corr_stats_data = load_surface(fn=corr_stats_fns[0])
        corr_stats_data_avg = np.zeros(corr_stats_data.shape)
        
        for n_run, corr_stats_fn in enumerate(corr_stats_fns):
            # Load data 
            corr_stats_img, corr_stats_data = load_surface(fn=corr_stats_fn)
    
            # Averaging
            if n_run == 0: corr_stats_data_avg = np.copy(corr_stats_data)
            else: corr_stats_data_avg = np.nanmean(np.array([corr_stats_data_avg, corr_stats_data]), axis=0)

        
        # Compute two sided corrected p-values
        t_statistic = corr_stats_data_avg[slope_idx, :] / corr_stats_data_avg[stderr_idx, :]
        degrees_of_freedom = corr_stats_data_avg[trs_idx, 0] - 2 
        p_values = 2 * (1 - stats.t.cdf(abs(t_statistic), df=degrees_of_freedom)) 
        corrected_p_values = multipletests_surface(pvals=p_values, 
                                                   correction='fdr_tsbh', 
                                                   alpha=fdr_alpha)
        corr_stats_data_avg[pvalue_idx, :] = p_values
        corr_stats_data_avg[corr_pvalue_5pt_idx, :] = corrected_p_values[0,:]
        corr_stats_data_avg[corr_pvalue_1pt_idx, :] = corrected_p_values[1,:]

        # Average across combinations
        if hemi:
            cor_fn = "{}/{}/derivatives/pp_data/{}/fsnative/corr/fmriprep_dct_corr/{}_task-{}_{}_fmriprep_dct_corr_bold.func.gii".format(
                    main_dir, project_dir, subject, subject, task, hemi)
        else:
            cor_fn = "{}/{}/derivatives/pp_data/{}/170k/corr/fmriprep_dct_corr/{}_task-{}_fmriprep_dct_corr_bold.dtseries.nii".format(
                    main_dir, project_dir, subject, subject, task)

        print("corr save: {}".format(cor_fn))
        corr_img = make_surface_image(data=corr_stats_data_avg,
                                      source_img=preproc_img, 
                                      maps_names=maps_names)
        nb.save(corr_img, cor_fn)

print('Deleting temp directory: {}'.format(corr_temp_dir))
os.system("rm -Rfd {}".format(corr_temp_dir))

# Time
end_time = datetime.datetime.now()
print("\nStart time:\t{start_time}\nEnd time:\t{end_time}\nDuration:\t{dur}".format(
        start_time=start_time,
        end_time=end_time,
        dur=end_time - start_time))