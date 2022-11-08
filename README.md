# STEREO_PRF
## Authors: 
Adrien CHOPIN, Uriel LASCOMBES, Margot CHEVILLARD, Jian DING, Michael SILVER, Yasha SHEYNIN, Denis LEVI, & Martin SZINTE

## Project description

We study the organization of the cortical visual system of a population of ambliopic patients.</br>
Here are listed all codes used to run and analyse this dataset.

## Data analysis

### Pre-processing

#### BIDS
- [x] convert dicom to niix [dcm2nii_bids_rename.py](analysis_code/preproc/bids/dcm2nii_bids_rename.py)
- [x] create events files [event_files_bidify.py](analysis_code/preproc/bids/event_files_bidify.py)
- [x] deface participants t1w image [deface_sbatch.py](analysis_code/preproc/bids/deface_sbatch.py)

#### Structural preprocessing
- [ ] manual edit of brain segmentation
- [ ] cut the brain and flatten it
- [ ] create pycortex dataset

#### Functional preprocessing
- [x] fMRIprep [fmriprep_sbatch.py](analysis_code/preproc/functional/fmriprep_sbatch.py)
- [x] slow drift correction and z-score [pybest_sbatch.py](analysis_code/preproc/functional/pybest_sbatch.py)
- [x] average and leave-one-out averaging of runs together [preproc_end.py](analysis_code/preproc/functional/preproc_end.py)

### Post-processing

### PRF analysis
- [ ] Fit pRF parameters (eccentricity, size, amplitude, baseline, rsquare)
  - pRF fitting code [prf_fit.py](analysis_code/postproc/prf/fit/prf_fit.py)
  - submit fit [submit_fit_jobs.py](analysis_code/postproc/prf/fit/submit_fit_jobs.py)
- [ ] Compute all pRF parameters (loo-rsquare, magnification, coverage) 
- [ ] make pycortex maps
- [ ] make webgl
- [ ] send index.py to webapp

### ROI analysis