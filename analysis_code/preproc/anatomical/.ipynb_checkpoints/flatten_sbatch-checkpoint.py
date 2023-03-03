"""
-----------------------------------------------------------------------------------------
flatten_sbatch.py
-----------------------------------------------------------------------------------------
Goal of the script:
Run mris_flatten on mesocentre using job mode
-----------------------------------------------------------------------------------------
Input(s):
sys.argv[1]: main project directory
sys.argv[2]: project name (correspond to directory)
sys.argv[3]: subject (e.g. sub-01)
sys.argv[4]: group (e.g. 327)
-----------------------------------------------------------------------------------------
Output(s):
preprocessed files
-----------------------------------------------------------------------------------------
To run:
1. cd to function
>> cd ~/projects/stereo_prf/analysis_code/preproc/anatomical/
2. run python command
python flatten_sbatch.py [main directory] [project name] [subject] [group]
-----------------------------------------------------------------------------------------
Example:
python flatten_sbatch.py /scratch/mszinte/data amblyo_prf sub-01 327
-----------------------------------------------------------------------------------------
Written by Martin Szinte (mail@martinszinte.net)
-----------------------------------------------------------------------------------------
"""

# imports modules
import sys
import os
import time
import json
opj = os.path.join

# inputs
main_dir = sys.argv[1]
project_dir = sys.argv[2]
subject = sys.argv[3]
group = sys.argv[4]
sub_num = subject[-2:]
hemis = ['lh', 'rh']

# Define cluster/server specific parameters
cluster_name  = 'skylake'
proj_name = 'b161'
nb_procs = 32
memory_val = 48
hour_proc = 20

# define directory and freesurfer licence
log_dir = "{}/{}/derivatives/flatten/log_outputs".format(main_dir,project_dir)
fs_dir = "{}/{}/derivatives/fmriprep/freesurfer".format(main_dir, project_dir)
job_dir = "{}/{}/derivatives/flatten/jobs".format(main_dir,project_dir)
os.makedirs(log_dir, exist_ok=True)
os.makedirs(job_dir, exist_ok=True)

# define SLURM cmd
for hemi in hemis:
    slurm_cmd = """\
#!/bin/bash
#SBATCH -p skylake
#SBATCH -A {proj_name}
#SBATCH --nodes=1
#SBATCH --mem={memory_val}gb
#SBATCH --cpus-per-task={nb_procs}
#SBATCH --time={hour_proc}:00:00
#SBATCH -e {log_dir}/{subject}_{hemi}_flatten_%N_%j_%a.err
#SBATCH -o {log_dir}/{subject}_{hemi}_flatten_%N_%j_%a.out
#SBATCH -J {subject}_{hemi}_flatten
export SUBJECTS_DIR='{fs_dir}'
cd '{fs_dir}/{subject}/surf/'\n\n""".format(proj_name=proj_name, nb_procs=nb_procs, hour_proc=hour_proc, 
                                            subject=subject, memory_val=memory_val, log_dir=log_dir, 
                                            fs_dir=fs_dir, hemi=hemi)

# define permission cmd
chmod_cmd = "\nchmod -Rf 771 {main_dir}/{project_dir}".format(main_dir=main_dir, project_dir=project_dir)
chgrp_cmd = "\nchgrp -Rf {group} {main_dir}/{project_dir}".format(main_dir=main_dir, project_dir=project_dir, group=group)    
    
# define flatten cmd
flatten_cmd = "mris_flatten {}.full.patch.3d {}.full.flat.patch.3d".format(hemi, hemi)

# create sh fn
sh_fn = "{}/{}_{}_flatten.sh".format(job_dir, subject, hemi)

of = open(sh_fn, 'w')
of.write("{}".format(slurm_cmd))
of.write("{}".format(flatten_cmd))
of.close()

# Submit jobs
print("Submitting {} to queue".format(sh_fn))
os.chdir(log_dir)
os.system("sbatch {}".format(sh_fn))