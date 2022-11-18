"""
-----------------------------------------------------------------------------------------
freesurfer_pial.py
-----------------------------------------------------------------------------------------
Goal of the script:
Run freesurfer with new brainmask manually edited
-----------------------------------------------------------------------------------------
Input(s):
sys.argv[1]: main project directory
sys.argv[2]: project name (correspond to directory)
sys.argv[3]: subject (e.g. sub-01)
sys.argv[4]: server nb of hour to request (e.g 10)
-----------------------------------------------------------------------------------------
Output(s):
new freesurfer segmentation files
-----------------------------------------------------------------------------------------
To run:
1. cd to function
>> cd ~/disks/meso_H/projects/stereo_prf/analysis_code/preproc/anatomical/
2. run python command
python freesurfer_pial.py [main directory] [project name] [subject]
-----------------------------------------------------------------------------------------
Exemple:
python preproc/freesurfer_pial.py /scratch/mszinte/data/ PredictEye sub-01 20 martin.szinte
-----------------------------------------------------------------------------------------
Written by Martin Szinte (mail@martinszinte.net)
-----------------------------------------------------------------------------------------
"""

# imports modules
import os
import sys
import json
opj = os.path.join

# inputs
main_dir = sys.argv[1]
project_dir = sys.argv[2]
subject = sys.argv[3]

# Define cluster/server specific parameters
cluster_name = 'skylake'
hour_proc = 20
nb_procs = 8
memory_val = 48
proj_name = 'b161'

# define directory and freesurfer licence
os.makedirs(log_dir, exist_ok=True)
os.makedirs(job_dir, exist_ok=True)
log_dir = "{}/{}/derivatives/freesurfer_pial/log_outputs".format(main_dir,project_dir)
job_dir = "{}/{}/derivatives/freesurfer_pial/jobs".format(main_dir,project_dir)
fs_dir = "{}{}/derivatives/fmriprep/freesurfer/".format(main_dir, project_dir)
fs_licence = '/scratch/mszinte/freesurfer/license.txt'

# define SLURM cmd
slurm_cmd = """\
#!/bin/bash
#SBATCH --mail-type=ALL
#SBATCH -p skylake
#SBATCH -A {proj_name}
#SBATCH --nodes=1
#SBATCH --mem={memory_val}gb
#SBATCH --cpus-per-task={nb_procs}
#SBATCH --time={hour_proc}:00:00
#SBATCH -e {log_dir}/{subject}_freesurfer-pial_%N_%j_%a.err
#SBATCH -o {log_dir}/{subject}_freesurfer-pial_%N_%j_%a.out
#SBATCH -J {subject}_freesurfer-pial\n\n""".format( nb_procs=nb_procs, subject=subject, memory_val = memory_val, 
													log_dir=log_dir, proj_name=proj_name)

# define freesurfer command
freesurfer_cmd = """\
export SUBJECTS_DIR={}\n\
export FS_LICENSE={}\n\
recon-all -autorecon-pial -subjid {}""".format(fs_dir, fs_licence, subject)

# create sh folder and file
sh_dir = "{}/{}_freesurfer-pial.sh".format(job_dir, subject)

of = open(sh_dir, 'w')
of.write("{}{}".format(slurm_cmd,freesurfer_cmd))
of.close()

# submit jobs
print("Submitting {} to queue".format(sh_dir))
os.chdir(log_dir)
os.system("sbatch {}".format(sh_dir))