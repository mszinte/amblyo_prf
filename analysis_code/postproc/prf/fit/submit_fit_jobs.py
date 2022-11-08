"""
-----------------------------------------------------------------------------------------
submit_fit_jobs.py
-----------------------------------------------------------------------------------------
Goal of the script:
Create jobscript to fit pRF
-----------------------------------------------------------------------------------------
Input(s):
sys.argv[1]: main project directory
sys.argv[2]: project name (correspond to directory)
sys.argv[3]: subject name (e.g. sub-01)
-----------------------------------------------------------------------------------------
Output(s):
.sh file to execute in server
-----------------------------------------------------------------------------------------
To run:
>> cd to function
>> python fit/submit_fit_jobs.py [pp directory] [subject]
-----------------------------------------------------------------------------------------
Exemple:
1. cd to function
>> cd ~/projects/stereo_prf/analysis_code/postproc/fit/
2. run python command
python submit_fit_jobs.py [main directory] [project name] [subject num]
-----------------------------------------------------------------------------------------
Executions:
python submit_fit_jobs.py /scratch/mszinte/data stereo_prf sub-01
python submit_fit_jobs.py /scratch/mszinte/data stereo_prf sub-02
python submit_fit_jobs.py /scratch/mszinte/data stereo_prf sub-03
-----------------------------------------------------------------------------------------
Written by Martin Szinte (martin.szinte@gmail.com)
-----------------------------------------------------------------------------------------
"""

# Stop warnings
import warnings
warnings.filterwarnings("ignore")

# General imports
import numpy as np
import os
import json
import sys
import glob
import nibabel as nb
import datetime
import ipdb
deb = ipdb.set_trace

# Inputs
main_dir = sys.argv[1]
project_dir = sys.argv[2]
subject = sys.argv[3]

# Cluster settings
fit_per_hour = 15000.0
nb_procs = 8

print("Fit analysis")

# Define folders
ppdir = "{}/{}/derivatives/pp_data/".format(main_dir, project_dir)
prf_folder = "{}/{}/prf/".format(pp_dir, subject)
os.makedirs(prf_folder, exist_ok=True)
prf_fit_folder = "{}/{}/prf/fit".format(pp_dir, subject)
os.makedirs(prf_fit_folder, exist_ok=True)
prf_jobs_folder = "{}/{}/prf/jobs".format(pp_dir, subject)
os.makedirs(prf_jobs_folder, exist_ok=True)
prf_logs_folder = "{}/{}/prf/log_outpits".format(pp_dir, subject)
os.makedirs(prf_logs_folder, exist_ok=True)

# Fefine fns (filenames)
vdm_fn = "{}/vdm/prf_vdm.mat".format(pp_dir, subject)
pp_avg_fns = glob.glob("{}/{}/func/fmriprep_dct_avg/*avg*.nii.gz".format(pp_dir,subject))
for fit_num, pp_avg_fn in enumerate(pp_avg_fns):
    
    input_fn = pp_avg_fn
    fit_fn = "{}/{}_prf-deriv.nii.gz".format(prf_fit_folder, os.path.basename(pp_avg_fn))
    pred_fn = "{}/{}_prf-pred.nii.gz".format(prf_fit_folder, os.path.basename(pp_avg_fn))

    if os.path.isfile(fit_fn):
        if os.path.getsize(fit_fn) != 0:
            print("output file {} already exists and is non-empty: aborting analysis".format(fit_fn))
            exit()
    
    data = nb.load(input_fn).get_fdata()

    data_var = np.var(data,axis=-1)
    mask = data_var!=0.0    
    num_vox = mask[...].sum()
    job_dur_obj = datetime.timedelta(hours=np.ceil(num_vox/fit_per_hour))
    job_dur = "{:1d}-{:02d}:00:00".format(job_dur_obj.days,divmod(job_dur_obj.seconds,3600)[0])

    # create job shell
    slurm_cmd = """\
    #!/bin/bash
    #SBATCH -p skylake
    #SBATCH -A b161
    #SBATCH --nodes=1
    #SBATCH --cpus-per-task={nb_procs}
    #SBATCH --time={job_dur}
    #SBATCH -e {log_dir}/{sub}_fit_{fit_num}_%N_%j_%a.err
    #SBATCH -o {log_dir}/{sub}_fit_{fit_num}_%N_%j_%a.out
    #SBATCH -J {sub}_fit_{fit_num}\n\n""".format(
    nb_procs=nb_procs, log_dir=log_dir, job_dur=job_dur, sub=subject, fit_num=fit_num)

    # define fit cmd
    fit_cmd = "python analysis_code/postproc/prf/fit/prf_fit.py {} {} {} {} {} {}".format(
        subject, input_fn, vdm_fn, fit_fn, pred_fn, nb_procs)

    # create sh folder and file
    sh_dir = "{}/jobs/{}_prf_fit-{}.sh".format(prf_folder,subject,fit_num)

    of = open(sh_dir, 'w')
    of.write("{slurm_cmd}{fit_cmd}".format(slurm_cmd=slurm_cmd, fit_cmd=fit_cmd))
    of.close()

    # Submit jobs
    print("Submitting {sh_dir} to queue".format(sh_dir=sh_dir))
    os.system("sbatch {sh_dir}".format(sub_command=sub_command, sh_dir=sh_dir))
