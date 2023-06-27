"""
-----------------------------------------------------------------------------------------
pcm_sbatch..py
-----------------------------------------------------------------------------------------
Goal of the script:
Run computation of population cortical magnification
-----------------------------------------------------------------------------------------
Input(s):
sys.argv[1]: main project directory
sys.argv[2]: project name (correspond to directory)
sys.argv[3]: subject name (e.g. sub-01)
sys.argv[4]: group (e.g. 327)
-----------------------------------------------------------------------------------------
Output(s):
sh file for running batch command
-----------------------------------------------------------------------------------------
To run:
1. cd to function
>> cd ~/projects/amblyo_prf/analysis_code/postproc/prf/postfit/
2. run python command
>> python pcm_sbatch.py [main directory] [project name] [subject num] [group]
-----------------------------------------------------------------------------------------
Exemple:
python pcm_sbatch.py /scratch/mszinte/data amblyo_prf sub-01 327
-----------------------------------------------------------------------------------------
Written by Martin Szinte (martin.szinte@gmail.com)
-----------------------------------------------------------------------------------------
"""

# stop warnings
import warnings
warnings.filterwarnings("ignore")

# general imports
import json
import os
import sys
import ipdb
deb = ipdb.set_trace

# define analysis parameters
with open('../../../settings.json') as f:
    json_s = f.read()
    analysis_info = json.loads(json_s)

# inputs
main_dir = sys.argv[1]
project_dir = sys.argv[2]
subject = sys.argv[3]
group = sys.argv[4]

# Define cluster/server specific parameters
cluster_name  = analysis_info['cluster_name']
proj_name = analysis_info['proj_name']
nb_procs = 8
memory_val = 48
hour_proc = 4

# set folders
log_dir = "{}/{}/derivatives/pp_data/{}/prf/pcm/log_outputs".format(main_dir, project_dir, subject)
job_dir = "{}/{}/derivatives/pp_data/{}/prf/pcm/jobs".format(main_dir, project_dir, subject)
os.makedirs(log_dir, exist_ok=True)
os.makedirs(job_dir, exist_ok=True)

slurm_cmd = """\
#!/bin/bash
#SBATCH -p {cluster_name}
#SBATCH -A {proj_name}
#SBATCH --nodes=1
#SBATCH --mem={memory_val}gb
#SBATCH --cpus-per-task={nb_procs}
#SBATCH --time={hour_proc}:00:00
#SBATCH -e {log_dir}/{subject}_pcm_%N_%j_%a.err
#SBATCH -o {log_dir}/{subject}_pcm_%N_%j_%a.out
#SBATCH -J {subject}_pcm
""".format(proj_name=proj_name, cluster_name=cluster_name,
           nb_procs=nb_procs, hour_proc=hour_proc, 
           subject=subject, memory_val=memory_val, log_dir=log_dir)
compute_pcm_cmd = "python compute_pcm.py {} {} {} {}".format(main_dir, project_dir, subject, group)

# create sh fn
sh_fn = "{}/{}_pcm.sh".format(job_dir, subject)

of = open(sh_fn, 'w')
of.write("{}".format(slurm_cmd))
of.write("{}".format(compute_pcm_cmd))
of.close()

# Submit jobs
print("Submitting {} to queue".format(sh_fn))
os.system("sbatch {}".format(sh_fn))