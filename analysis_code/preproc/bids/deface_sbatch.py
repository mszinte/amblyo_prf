"""
-----------------------------------------------------------------------------------------
deface_sbatch.py
-----------------------------------------------------------------------------------------
Goal of the script:
Deface T1w images
-----------------------------------------------------------------------------------------
Input(s):
sys.argv[1]: main project directory
sys.argv[2]: project name (correspond to directory)
sys.argv[3]: subject (e.g. sub-001)
sys.argv[4]: overwrite images (0 = no, 1 = yes)
sys.argv[5]: server job or not (1 = server, 0 = terminal)
-----------------------------------------------------------------------------------------
Output(s):
Defaced images
-----------------------------------------------------------------------------------------
To run:
1. cd to function
>> cd /home/mszinte/projects/stereo_prf/mri_analysis/
2. run python command
python preproc/deface_sbatch.py [main directory] [project name] [subject num] [overwrite] 
-----------------------------------------------------------------------------------------
Exemple:
python analysis_code/preproc/deface_sbatch.py /scratch/mszinte/data stereo_prf sub-01 0 0
-----------------------------------------------------------------------------------------
Written by Martin Szinte (martin.szinte@gmail.com)
-----------------------------------------------------------------------------------------
"""

# imports modules
import sys
import os
import pdb
deb = pdb.set_trace

# inputs
main_dir = sys.argv[1]
project_dir = sys.argv[2]
subject = sys.argv[3]
ovewrite_in = int(sys.argv[4])
server_in = int(sys.argv[5])
hour_proc = 4
nb_procs = 8
log_dir = "{}/{}/derivatives/deface/logs".format(main_dir, project_dir, subject)
try: os.makedirs(log_dir)
except: pass

# define SLURM cmd
slurm_cmd = """\
#!/bin/bash
#SBATCH -p skylake
#SBATCH -A b161
#SBATCH --nodes=1
#SBATCH --cpus-per-task={nb_procs}
#SBATCH --time={hour_proc}:00:00
#SBATCH -e {log_dir}/{subject}_deface_%N_%j_%a.err
#SBATCH -o {log_dir}/{subject}_deface_%N_%j_%a.out
#SBATCH -J {subject}_deface\n\n""".format(nb_procs=nb_procs, hour_proc=hour_proc, subject=subject, log_dir=log_dir)

# get files
session = 'ses-02'
t1w_filename = "{}/{}/sourcedata/dcm2niix/{}/{}/anat/{}_{}_T1w.nii.gz".format(main_dir,project_dir,subject,session,subject,session)

# sh folder & file
sh_folder = "{}/{}/derivatives/deface/jobs".format(main_dir, project_dir, subject)
try: os.makedirs(sh_folder)
except: pass
sh_file = "{}/{}_deface.sh".format(sh_folder,subject)

of = open(sh_file, 'w')
if server_in: of.write(slurm_cmd)
if ovewrite_in == 1: deface_cmd = "pydeface {fn} --outfile {fn} --force --verbose\n".format(fn = t1w_filename)
else: deface_cmd = "pydeface {fn} --verbose\n".format(fn = t1w_filename)
of.write(deface_cmd)    
of.close()

print(sh_file)
# Run or submit jobs
if server_in:
    os.chdir(log_dir)
    print("Submitting {} to queue".format(sh_file))
    os.system("sbatch {}".format(sh_file))
else:
    os.system("sh {}".format(sh_file))