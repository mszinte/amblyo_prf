# AMBLYO_PRF
## About
---
We study the organization of the cortical visual system of a population of ambliopic patients.</br>
This repository contain all code allowing us to analyse our dataset [OpenNeuro:DSXXXXX](https://openneuro.org/datasets/dsXXXX).</br>

---
## Authors (alphabetic order): 
---
Adrien CHOPIN, Dennis LEVI, Uriel LASCOMBES, Jian DING, Yasha SHEYNIN, Michael SILVER, & Martin SZINTE

### Main dependencies
---
[dcm2niix](https://github.com/rordenlab/dcm2niix); 
[PyDeface](https://github.com/poldracklab/pydeface); 
[fMRIprep](https://fmriprep.org/en/stable/); 
[pRFpy](https://github.com/VU-Cog-Sci/prfpy); 
[FreeSurfer](https://surfer.nmr.mgh.harvard.edu/);
[FFmpeg](https://ffmpeg.org/);
[FSL](https://fsl.fmrib.ox.ac.uk);
[Inkscape](https://inkscape.org/)
[workbench](https://humanconnectome.org/software/connectome-workbench)
</br>


## To do
---
- [x] run and check preproc_end on all participants
- [x] work on pycortext correlation once we have a surface_pycortex loader (see uriel's code)
- [ ] fit data prf with gridfit
- [ ] get data in roi and fit css model

## Data analysis
---

### Pre-processing

#### BIDS
- [x] convert dicom to niix [dcm2nii_bids_rename.py](analysis_code/preproc/bids/dcm2nii_bids_rename.py) 
    </br>Note: each created .json file will miss a field "TaskName":"prf", to add manually for each functionnal scan, saved explicitly with encoding utf-8.
- [x] create events files [event_files_bidify.py](analysis_code/preproc/bids/event_files_bidify.py) 
    </br>Note: for missing event files, create a file with a column header line and an n/a line.
- [x] deface participants t1w image [deface_sbatch.py](analysis_code/preproc/bids/deface_sbatch.py) 
    </br>Note: run script for each subject separately.
- [x] validate bids format [https://bids-standard.github.io/bids-validator/] / alternately, use a docker [https://pypi.org/project/bids-validator/]
    </br>Note: for the webpage, use Chrome and wait for at least 30 min, even if nothing seems to happen.

#### Structural preprocessing
- [x] fMRIprep with anat-only option [fmriprep_sbatch.py](analysis_code/preproc/functional/fmriprep_sbatch.py)
- [x] create sagital view video before manual edit [sagital_view.py](analysis_code/preproc/anatomical/sagital_view.py)
- [x] manual edit of brain segmentation [pial_edits.sh](analysis_code/preproc/anatomical/pial_edits.sh)
- [x] FreeSurfer with new brainmask manually edited [freesurfer_pial.py](analysis_code/preproc/anatomical/freesurfer_pial.py)
- [x] create sagital view video before after edit [sagital_view.py](analysis_code/preproc/anatomical/sagital_view.py)
- [x] make cut in the brains for flattening [cortex_cuts.sh](analysis_code/preproc/anatomical/cortex_cuts.sh)
- [x] flatten the cut brains [flatten_sbatch.py](analysis_code/preproc/anatomical/flatten_sbatch.py)

#### Functional preprocessing
- [x] fMRIprep [fmriprep_sbatch.py](analysis_code/preproc/functional/fmriprep_sbatch.py)
- [x] supress bad run [bad_run.py](analysis_code/preproc/functional/bad_run.py)
- [x] Load freesurfer and import subject in pycortex db [freesurfer_import_pycortex.py](analysis_code/preproc/functional/freesurfer_import_pycortex.py)
- [x] High-pass, z-score, average and leave-one-out average and correlations [preproc_end_sbatch.py](analysis_code/preproc/functional/preproc_end_sbatch.py)
- [x] Make timeseries inter-run correlation maps with pycortex [pycortex_corr_maps.py](analysis_code/preproc/functional/pycortex_corr_maps.py)
 
### Post-processing

#### PRF analysis
- [x] create the visual matrix design [vdm_builder.py](analysis_code/postproc/prf/vdm_builder.py)

#### Gaussian fit
- [ ] Run pRF gaussian grid fit [prf_submit_gridfit_jobs.py](analysis_code/postproc/prf/fit/prf_submit_gridfit_jobs.py)
- [ ] Compute pRF gaussian grid fit derivatives [compute_gauss_gridfit_derivatives.py](analysis_code/postproc/prf/postfit/compute_gauss_gridfit_derivatives.py)
- [ ] Make pRF derivatives maps with pycortex [pycortex_maps_gridfit.py](analysis_code/postproc/prf/postfit/pycortex_maps_gridfit.py)

#### CSS fit
- [ ] get gaussian pRF parameters with simple GLM [submit_fit_jobs.py](analysis_code/postproc/prf/fit/submit_gridfit_jobs.py)
- [ ] compute gaussian pRF derivatives [compute_derivatives.py](analysis_code/postproc/prf/postfit/compute_derivatives.py)
- [ ] make pycortex maps [pycortex_maps.py](analysis_code/postproc/prf/postfit/pycortex_maps.py)
- [ ] draw ROIs using Inkscape
- [ ] extract ROIs masks [roi_masks.ipynb](analysis_code/postproc/prf/postfit/roi_masks.ipynb) 
- [ ] get css pRF derivatives in ROIs
- [ ] compute population cortical magnification [pcm_sbatch.py](analysis_code/postproc/prf/postfit/pcm_sbatch.py)
- [ ] make webgl with the pycortex dataset [pycortex_maps.py](analysis_code/postproc/prf/webgl/pycortex_webgl.py) 
- [ ] send the webgl files [send_data.sh](analysis_code/postproc/prf/webgl/send_data.sh)

### Main analysis
- [ ] extract all data as pickle files or tsv [make_tsv.ipynb](analysis_code/postproc/prf/postfit/make_tsv.ipynb)
- [ ] Figures and statistics [amblyo_analysis_and_figures.ipynb](analysis_code/postproc/result_analysis/amblyo_analysis_and_figures.ipynb)