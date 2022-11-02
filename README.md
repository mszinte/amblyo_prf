# Project name stereo_prf
#### Authors: 
Adrien CHOPIN, Uriel LASCOMBES, Margot CHEVILLARD, Jian DING, Michael SILVER, Yasha SHEYNIN, Denis LEVI, & Martin SZINTE

## Project description

Project in which we study the organization of the cortical visual system of a population of ambliopic patients.

## Data analysis

### Pre-processing

#### BIDS
- [x] convert dicom to niix [dcm2nii_bids_rename.py](analysis_code/preproc/dcm2nii_bids_rename.py)
- [x] create events files [event_files_bidify.py](analysis_code/preproc/event_files_bidify.py)
- [x] deface participants t1w image [deface_sbatch.py](analysis_code/preproc/deface_sbatch.py)

#### Structural preprocessing
- [ ] manual edit of brain segmentation
- [ ] cut the brain and flatten it
- [ ] create pycortex dataset

#### Functional preprocessing
- [x] fMRIprep [fmriprep_sbatch.py](analysis_code/preproc/fmriprep_sbatch.py)
- [x] slow drift correction and z-score [pybest_sbatch.py](analysis_code/preproc/pybest_sbatch.py)
- [x] average and leave-one-out averaging of runs together [preproc_end.py](analysis_code/preproc/preproc_end.py)

### Post-processing

### pRF
- [ ] prf fit 
- [ ] compute pRF parameters 
- [ ] make pycortex maps
- [ ] make webgl
- [ ] send index.py to webapp
