"""
-----------------------------------------------------------------------------------------
pycortex_webgl_css.py
-----------------------------------------------------------------------------------------
Goal of the script:
Create combined webgl per participants
-----------------------------------------------------------------------------------------
Input(s):
sys.argv[1]: main project directory
sys.argv[2]: project name (correspond to directory)
sys.argv[3]: subject name (e.g. sub-01)
sys.argv[4]: server group (e.g. 327)
-----------------------------------------------------------------------------------------
Output(s):
Pycortex webgl
-----------------------------------------------------------------------------------------
To run:
0. TO RUN ON INVIBE SERVER (with Inkscape)
1. cd to function
>> cd ~/disks/meso_H/projects/[PROJECT]/analysis_code/postproc/prf/webgl/
2. run python command
>> python pycortex_webgl_css.py [main directory] [project] [subject] [group]
-----------------------------------------------------------------------------------------
Exemple:
python pycortex_webgl_css.py ~/disks/meso_S/data amblyo_prf sub-01 327
-----------------------------------------------------------------------------------------
Written by Martin Szinte (mail@martinszinte.net)
Edited by Uriel Lascombes (uriel.lascombes@laposte.net)
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
import cortex
import numpy as np
import matplotlib.pyplot as plt

# Personal import
sys.path.append("{}/../../../utils".format(os.getcwd()))
from pycortex_utils import draw_cortex, set_pycortex_config_file, load_surface_pycortex, create_colormap

# Inputs
main_dir = sys.argv[1]
project_dir = sys.argv[2]
subject = sys.argv[3]
# recache = True
# webapp = True

# Define analysis parameters
with open('../../../settings.json') as f:
    json_s = f.read()
    analysis_info = json.loads(json_s)
formats = analysis_info['formats']
prf_task_name = analysis_info['prf_task_name']
tasks = analysis_info['task_names']

# Set pycortex db and colormaps
cortex_dir = "{}/{}/derivatives/pp_data/cortex".format(main_dir, project_dir)
set_pycortex_config_file(cortex_dir)

for format_, pycortex_subject in zip(formats, [subject, 'sub-170k']):

    # Define directory
    pp_dir = "{}/{}/derivatives/pp_data/{}".format(main_dir, project_dir, subject, format_)
    cor_datasets_dir = '{}/corr/pycortex/datasets_corr'.format(pp_dir)
    gridfit_datasets_dir = '{}/prf/pycortex/datasets_avg_gauss_gridfit'.format(pp_dir)
    rois_datasets_dir = '{}/rois/pycortex/datasets_rois'.format(pp_dir)
    css_dataset_dir = "{}/pycortex/datasets_loo-avg_css".format(pp_dir)

    # Define filenames
    cor_datasets_fn = []
    cor_datasets_fn.append("{}/{}_task-{}.hdf".format(cor_datasets_dir, subject, task)) for task in tasks
    gridfit_datasets_fn = "{}/{}_task-{}_avg-gridfit.hdf".format(gridfit_datasets_dir, subject, prf_task_name)
    rois_datasets_fn = "{}/{}_task-{}_rois.hdf".format(rois_datasets_dir, subject, prf_task_name)
    css_datasets_fn = "{}/{}_task-{}_css.hdf".format(css_dataset_dir, subject, prf_task_name)

    # Concatenate filenames
    dateset_fns = []
    dateset_fns.append(cor_datasets_fn)
    dateset_fns.append(gridfit_datasets_fn)
    dateset_fns.append(rois_datasets_fn)
    dateset_fns.append(css_datasets_fn)
    deb()

    # Load datasets and combine them

    # Create webgl folder
    # Make webgl
    
    # avg_dataset = cortex.load(avg_dataset_fn)
    # loo_avg_dataset_fn = "{}/{}_task-{}_loo_avg.hdf".format(datasets_dir, subject, task)
    # loo_avg_dataset = cortex.load(loo_avg_dataset_fn)
    # new_dataset = cortex.Dataset(avg_dataset=avg_dataset, loo_avg_dataset=loo_avg_dataset)
    # cortex.webgl.make_static(outpath=webgl_dir, data=new_dataset, recache=recache)

# # Send to webapp
# # --------------
# if webapp == True:
#     webapp_dir = '{}{}_{}/'.format(analysis_info['webapp_dir'], subject, preproc)
#     os.system('rsync -avuz --progress {local_dir} {webapp_dir}'.format(local_dir=webgl_dir, webapp_dir=webapp_dir))
#     print('go to : https://invibe.nohost.me/amblyo_prf/{}_{}'.format(subject, preproc))