"""
-----------------------------------------------------------------------------------------
prf_gridfit.py
-----------------------------------------------------------------------------------------
Goal of the script:
Prf fit computing gaussian grid fit
-----------------------------------------------------------------------------------------
Input(s):
sys.argv[1]: main project directory
sys.argv[2]: project name (correspond to directory)
sys.argv[3]: subject name
sys.argv[4]: input file name (path to the data to fit)
sys.argv[5]: number of processors to compute in parrallel
-----------------------------------------------------------------------------------------
Output(s):
fit tester numpy arrays
-----------------------------------------------------------------------------------------
To run:
1. cd to function
>> cd ~/projects/amblyo_prf/analysis_code/postproc/prf/fit
2. run python command
python prf_gridfit.py [main directory] [project name] [subject] [fn_path] [processors]
-----------------------------------------------------------------------------------------
Exemple:
python prf_gridfit.py /scratch/mszinte/data amblyo_prf sub-01 [file_path] 32
-----------------------------------------------------------------------------------------
Written by Martin Szinte (mail@martinszinte.net)
Edited by Uriel Lascombes (uriel.lascombes@laposte.net)
-----------------------------------------------------------------------------------------
"""

# stop warnings
import warnings
warnings.filterwarnings("ignore")

# general imports
import os
import sys
import json
import ipdb
import datetime
import numpy as np
deb = ipdb.set_trace

# MRI analysis imports
from prfpy.stimulus import PRFStimulus2D
from prfpy.model import Iso2DGaussianModel 
from prfpy.fit import Iso2DGaussianFitter 
import nibabel as nb

# personal imports
sys.path.append("{}/../../../utils".format(os.getcwd()))
from surface_utils import make_surface_image , load_surface

# get inputs
start_time = datetime.datetime.now()

# inputs and settings
main_dir = sys.argv[1]
project_dir = sys.argv[2]
subject = sys.argv[3]
input_fn = sys.argv[4]
procs = int(sys.argv[5])

# analysis parameters
with open('../../../settings.json') as f:
    json_s = f.read()
    analysis_info = json.loads(json_s)
screen_size_cm = analysis_info['screen_size_cm']
screen_distance_cm = analysis_info['screen_distance_cm']
TR = analysis_info['TR']
vdm_width = analysis_info['vdm_size_pix'][0] 
vdm_height = analysis_info['vdm_size_pix'][1]
gauss_grid_nr = analysis_info['gauss_grid_nr']
max_ecc_size = analysis_info['max_ecc_size']

# define directories
if input_fn.endswith('.nii'):
    prf_fit_dir = "{}/{}/derivatives/pp_data/{}/170k/prf/fit".format(
        main_dir, project_dir, subject)
    os.makedirs(prf_fit_dir, exist_ok=True)

elif input_fn.endswith('.gii'):
    prf_fit_dir = "{}/{}/derivatives/pp_data/{}/fsnative/prf/fit".format(
        main_dir, project_dir, subject)
    os.makedirs(prf_fit_dir, exist_ok=True)

fit_fn_gauss_gridfit = input_fn.split('/')[-1]
fit_fn_gauss_gridfit = fit_fn_gauss_gridfit.replace('bold', 'prf-fit_gauss_gridfit')
pred_fn_gauss_gridfit = input_fn.split('/')[-1]
pred_fn_gauss_gridfit = pred_fn_gauss_gridfit.replace('bold', 'prf-pred_gauss_gridfit')

# define visual design
vdm_fn = "{}/{}/derivatives/vdm/vdm_prf_{}_{}.npy".format(
    main_dir, project_dir, vdm_width, vdm_height)
vdm = np.load(vdm_fn)

# defind model parameter grid range
gauss_params_num = 8
fit_verbose = True
sizes = max_ecc_size * np.linspace(0.1,1,gauss_grid_nr)**2
eccs = max_ecc_size * np.linspace(0.1,1,gauss_grid_nr)**2
polars = np.linspace(0, 2*np.pi, gauss_grid_nr)


# load data
img, raw_data = load_surface(fn=input_fn)

# exclude nan voxel from the analysis 
valid_vertices = ~np.isnan(raw_data).any(axis=0)
valid_vertices_idx = np.where(valid_vertices)[0]
data = raw_data[:,valid_vertices]

# determine stimulus
stimulus = PRFStimulus2D(screen_size_cm=screen_size_cm[1], 
                         screen_distance_cm=screen_distance_cm,
                         design_matrix=vdm, 
                         TR=TR)

# determine gaussian model
gauss_model = Iso2DGaussianModel(stimulus=stimulus)

# grid fit gauss model
gauss_fitter = Iso2DGaussianFitter(data=data.T, 
                                   model=gauss_model, 
                                   n_jobs=procs)

gauss_fitter.grid_fit(ecc_grid=eccs, 
                      polar_grid=polars, 
                      size_grid=sizes, 
                      verbose=fit_verbose, 
                      n_batches=procs)

# Rearange result
gauss_fit = gauss_fitter.gridsearch_params
gauss_fit_mat = np.zeros((raw_data.shape[1],gauss_params_num))
gauss_pred_mat = np.zeros_like(raw_data) 

for est,vert in enumerate(valid_vertices_idx):
    gauss_fit_mat[vert] = gauss_fit[est]
    gauss_pred_mat[:,vert] = gauss_model.return_prediction(mu_x=gauss_fit[est][0], 
                                                          mu_y=gauss_fit[est][1], 
                                                          size=gauss_fit[est][2], 
                                                          beta=gauss_fit[est][3], 
                                                          baseline=gauss_fit[est][4],
                                                          hrf_1=gauss_fit[est][5],
                                                          hrf_2=gauss_fit[est][6])

gauss_fit_mat = np.where(gauss_fit_mat == 0, np.nan, gauss_fit_mat)
gauss_pred_mat = np.where(gauss_pred_mat == 0, np.nan, gauss_pred_mat)

#export data from gauss model fit
maps_names = ['mu_x', 'mu_y', 'prf_size', 'prf_amplitude', 'bold_baseline', 
              'hrf_1','hrf_2', 'r_squared']

# export fit
img_gauss_gridfit_fit_mat = make_surface_image(data=gauss_fit_mat.T, 
                                               source_img=img, 
                                               maps_names=maps_names)
nb.save(img_gauss_gridfit_fit_mat,'{}/{}'.format(prf_fit_dir, fit_fn_gauss_gridfit)) 

# export pred
img_gauss_gridfit_pred_mat = make_surface_image(data=gauss_pred_mat, 
                                                source_img=img)
nb.save(img_gauss_gridfit_pred_mat,'{}/{}'.format(prf_fit_dir, pred_fn_gauss_gridfit)) 

# print duration
end_time = datetime.datetime.now()
print("\nStart time:\t{start_time}\nEnd time:\t{end_time}\nDuration:\t{dur}".format(
    start_time=start_time, 
    end_time=end_time, 
    dur=end_time - start_time))