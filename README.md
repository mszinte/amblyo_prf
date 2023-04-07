# STEREO_PRF
## About
---
We study the organization of the cortical visual system of a population of ambliopic patients.</br>
In this repository is kept all code allowing us to analyse our dataset [OpenNeuro:DSXXXXX](https://openneuro.org/datasets/dsXXXX).</br>

---
## Authors: 
---
Adrien CHOPIN, Dennis LEVI, Uriel LASCOMBES, Jian DING, Yasha SHEYNIN, Margot CHEVILLARD, Michael SILVER, & Martin SZINTE

### Main dependencies
---
[dcm2niix](https://github.com/rordenlab/dcm2niix); 
[PyDeface](https://github.com/poldracklab/pydeface); 
[fMRIprep](https://fmriprep.org/en/stable/); 
[pRFpy](https://github.com/VU-Cog-Sci/prfpy); 
[FreeSurfer](https://surfer.nmr.mgh.harvard.edu/);
[FFmpeg](https://ffmpeg.org/)
[FSL](https://fsl.fmrib.ox.ac.uk)
</br>


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
- [x] high-pass, z-score, average and leave-one-out average [preproc_end.py](analysis_code/preproc/functional/preproc_end.py)
- [x] Load freesurfer and execute [pycortex_import.py](analysis_code/preproc/functional/pycortex_import.py): run only [freesurfer_import_pycortex.py](analysis_code/preproc/functional/freesurfer_import_pycortex.py)

### Post-processing

#### PRF analysis
- [x] create the visual matrix design [vdm_builder.py](analysis_code/postproc/prf/vdm_builder.py)
- [x] Execute [prf_fit.py](analysis_code/postproc/prf/fit/prf_fit.py) to fit pRF parameters (eccentricity, size, amplitude, baseline, rsquare): run only [submit_fit_jobs.py](analysis_code/postproc/prf/fit/submit_fit_jobs.py)
- [x] Compute pRF derivatives [compute_derivatives.py](analysis_code/postproc/prf/postfit/compute_derivatives.py)
    - [ ] add Dumoulin magnification factor
    - [ ] add pRF coverage
- [x] make pycortex maps [pycortex_maps.py](analysis_code/postproc/prf/postfit/pycortex_maps.py)
- [X] make pdf files with the maps [pdf_maps.py](analysis_code/postproc/prf/postfit/pdf_maps.py)
- [ ] make webgl
- [ ] send index.py to webapp
### ROI analysis

- [x] extract ROIs masks [roi_masks.ipynb](analysis_code/ROIs/roi_masks.ipynb)