# STEREO_PRF
## About
---
We study the organization of the cortical visual system of a population of ambliopic patients.</br>
In this repository is kept all code allowing us to analyse our dataset [OpenNeuro:DSXXXXX](https://openneuro.org/datasets/dsXXXX).</br>

---
## Authors: 
---
Adrien CHOPIN, Uriel LASCOMBES, Margot CHEVILLARD, Jian DING, Michael SILVER, Yasha SHEYNIN, Denis LEVI, & Martin SZINTE

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
- [x] create events files [event_files_bidify.py](analysis_code/preproc/bids/event_files_bidify.py)
- [x] deface participants t1w image [deface_sbatch.py](analysis_code/preproc/bids/deface_sbatch.py)

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
- [x] high-pass, z-score, average and leave-one-out average [preproc_end.py](analysis_code/preproc/functional/preproc_end.py)
- [x] create pycortex dataset [pycortex_import.py](analysis_code/preproc/functional/pycortex_import.py)

### Post-processing

#### PRF analysis
- [x] create the visual matrix design [vdm_builder.ipynb](analysis_code/postproc/prf/fit/vdm_builder.ipynb)
- [x] Fit pRF parameters (eccentricity, size, amplitude, baseline, rsquare)
  - pRF fitting code [prf_fit.py](analysis_code/postproc/prf/fit/prf_fit.py)
  - submit fit [submit_fit_jobs.py](analysis_code/postproc/prf/fit/submit_fit_jobs.py)
- [x] Compute pRF derivatives [compute_derivatives.py](analysis_code/postproc/prf/post_fit/compute_derivatives.py)
    - [ ] add Dumoulin magnification factor
    - [ ] add pRF coverage
- [ ] make pycortex maps
- [ ] make webgl
- [ ] send index.py to webapp

### ROI analysis