# AMBLYO_PRF
## About
---
We study the organization of the cortical visual system of a population of amblyopic patients.</br>
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
- [ ] make logarithmic scale for colormap of cortical magnification
- [ ] run merge pdf and webgl
- [ ] copy sh runners in RetinoMaps and redo all there
- [ ] check and run 170k averaging codes and plots
- [ ] send data to Adrien
- [ ] Read back thesis and think of analysis to redo

## Data analysis
---

### BIDS
- [x] convert dicom to niix [dcm2nii_bids_rename.py](analysis_code/preproc/bids/dcm2nii_bids_rename.py) 
    </br>Note: each created .json file will miss a field "TaskName":"prf", to add manually for each functionnal scan, saved explicitly with encoding utf-8.
- [x] create events files [event_files_bidify.py](analysis_code/preproc/bids/event_files_bidify.py) 
    </br>Note: for missing event files, create a file with a column header line and an n/a line.
- [x] deface participants t1w image [deface_sbatch.py](analysis_code/preproc/bids/deface_sbatch.py) 
    </br>Note: run script for each subject separately.
- [x] validate bids format [https://bids-standard.github.io/bids-validator/] / alternately, use a docker [https://pypi.org/project/bids-validator/]
    </br>Note: for the webpage, use Chrome and wait for at least 30 min, even if nothing seems to happen.

### Individual analysis

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

#### Functional postprocessing

##### Inter-run correlations
<!-- - [x] Average inter-run correlations of each subject in 170k template [170k_corr_averaging.py](analysis_code/preproc/functional/170k_corr_averaging.py) -->
- [x] Make timeseries inter-run correlations flatmaps with pycortex [pycortex_maps_run_corr.py](analysis_code/preproc/functional/pycortex_maps_run_corr.py) or [pycortex_maps_run_corr.sh](analysis_code/preproc/functional/pycortex_maps_run_corr.sh)

##### PRF Gaussian fit
- [x] Create the visual matrix design [vdm_builder.py](analysis_code/postproc/prf/vdm_builder.py)
- [x] Run pRF gaussian grid fit [prf_submit_gridfit_jobs.py](analysis_code/postproc/prf/fit/prf_submit_gridfit_jobs.py)
- [x] Compute pRF gaussian grid fit derivatives [compute_gauss_gridfit_derivatives.py](analysis_code/postproc/prf/postfit/compute_gauss_gridfit_derivatives.py)
- [x] Make pRF maps with pycortex [pycortex_maps_gridfit.py](analysis_code/postproc/prf/postfit/pycortex_maps_gridfit.py) or [pycortex_maps_gridfit.sh](analysis_code/postproc/prf/postfit/pycortex_maps_gridfit.sh)

##### Rois
- [x] Draw ROIs on individual fsnative using Inkscape
- [x] Copy sub-170 containing MMP rois from [RetinoMaps](https://github.com/mszinte/RetinoMaps) project [compute_gauss_gridfit_derivatives.py](https://github.com/mszinte/RetinoMaps/blob/main/analysis_code/atlas/create_170k_mmp_rois_mask.ipynb) and mask areas in the overaly that are not covered by data's field of view.
- [x] Create 170k MMP rois masks [create_mmp_rois_atlas.py](analysis_code/atlas/create_mmp_rois_atlas.py)
- [x] Make ROIS files [make_rois_img.py](analysis_code/postproc/prf/postfit/make_rois_img.py)
- [x] Create flatmaps of ROIs [pycortex_maps_rois.py](analysis_code/postproc/prf/postfit/pycortex_maps_rois.py) or [pycortex_maps_rois.sh](analysis_code/postproc/prf/postfit/pycortex_maps_rois.sh)

##### CSS fit
- [x] CSS fit within the ROIs [prf_submit_css_jobs.py](analysis_code/postproc/prf/fit/prf_submit_css_jobs.py)
- [x] Compute CSS statistics [compute_css_stats.py](analysis_code/postproc/prf/postfit/compute_css_stats.py)
- [x] Compute CSS fit derivatives [compute_css_derivatives.py](analysis_code/postproc/prf/postfit/compute_css_derivatives.py)
- [x] Compute CSS population cortical magnification [css_pcm_sbatch.py](analysis_code/postproc/prf/postfit/css_pcm_sbatch.py)
- [x] Make CSS fit derivatives and pcm maps with pycortex [pycortex_maps_css.py](analysis_code/postproc/prf/postfit/pycortex_maps_css.py) or [pycortex_maps_css.sh](analysis_code/postproc/prf/postfit/pycortex_maps_css.sh)
- [ ] Make subject WEBGL with pycortex [pycortex_webgl_css.py](analysis_code/postproc/prf/webgl/pycortex_webgl_css.py) or [pycortex_webgl_css.sh](analysis_code/postproc/prf/webgl/pycortex_webgl_css.sh)
- [ ] Edit [index.html](disks/meso_H/projects/amblyo_prf/analysis_code/postproc/prf/webgl/index.html) and publish WEBGL on webapp [publish_webgl.py](analysis_code/postproc/prf/webgl/publish_webgl.py)
- [x] Make TSV with CSS fit derivatives, pcm and statistics [make_tsv_css.py](analysis_code/postproc/prf/postfit/make_tsv_css.py)
- [x] Make pRF derivatives and pcm main figures and figure TSV [make_rois_fig.py](analysis_code/postproc/prf/postfit/make_rois_fig.py) or [make_rois_fig.sh](analysis_code/postproc/prf/postfit/make_rois_fig.sh)
- [ ] Merge all css pycortex and pRF derivatives and pcm main figures [merge_fig_css.py](analysis_code/postproc/prf/postfit/merge_fig_css.py)

### Group analysis

#### Functional postprocessing
##### Inter-run correlations
- [ ] Inter-run correlation for **sub-170k** [compute_run_corr.py](analysis_code/preproc/functional/compute_run_corr.py)
- [ ] Make timeseries inter-run correlations flatmaps with pycortex **for sub-170k** [pycortex_maps_run_corr.py](analysis_code/preproc/functional/pycortex_maps_run_corr.py)

##### Gaussian fit
- [ ] Compute pRF gaussian grid fit derivatives **for sub-170k** [compute_gauss_gridfit_derivatives.py](analysis_code/postproc/prf/postfit/compute_gauss_gridfit_derivatives.py)
- [ ] Make pRF maps with pycortex **for sub-170k**  [pycortex_maps_gridfit.py](analysis_code/postproc/prf/postfit/pycortex_maps_gridfit.py)

##### Rois
- [ ] Make ROIS files **for sub-170k** [make_rois_img.py](analysis_code/postproc/prf/postfit/make_rois_img.py)
- [ ] Create flatmaps of ROIs **for sub-170k** [pycortex_maps_rois.py](analysis_code/postproc/prf/postfit/pycortex_maps_rois.py)

##### CSS fit
- [ ] Compute CSS statistics **for sub-170k** [compute_css_stats.py](analysis_code/postproc/prf/postfit/compute_css_stats.py)
- [ ] Compute CSS fit derivatives **for sub-170k** [compute_css_derivatives.py](analysis_code/postproc/prf/postfit/compute_css_derivatives.py)
- [ ] Compute CSS population cortical magnification **for sub-170k** [css_pcm_sbatch.py](analysis_code/postproc/prf/postfit/css_pcm_sbatch.py)
- [ ] Make CSS fit derivatives and pcm maps with pycortex **for sub-170k** [pycortex_maps_css.py](analysis_code/postproc/prf/postfit/pycortex_maps_css.py)
- [ ] Merge all css pycortex and pRF derivatives and pcm main figures **for sub-170k and group** [merge_fig_css.py](analysis_code/postproc/prf/postfit/merge_fig_css.py)
- [ ] Make subject WEBGL with pycortex **for sub-170k** [pycortex_webgl_css.py](analysis_code/postproc/prf/webgl/pycortex_webgl_css.py)
- [ ] Edit [index.html](disks/meso_H/projects/amblyo_prf/analysis_code/postproc/prf/webgl/index.html) and publish WEBGL on webapp [publish_webgl.py](analysis_code/postproc/prf/webgl/publish_webgl.py)
- [ ] Make TSV with CSS fit derivatives, pcm and statistics for **sub-170k and group** [make_tsv_css.py](analysis_code/postproc/prf/postfit/make_tsv_css.py)
- [ ] Make pRF derivatives and pcm main figures and figure TSV for **sub-170k and group** [make_rois_fig.py](analysis_code/postproc/prf/postfit/make_rois_fig.py)