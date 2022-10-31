"""
-----------------------------------------------------------------------------------------
mriqc_sbatch.py
-----------------------------------------------------------------------------------------
Goal of the script:
Run frmiqc on mesocentre using job mode
-----------------------------------------------------------------------------------------
Input(s):
sys.argv[1]: main project directory
sys.argv[2]: project name (correspond to directory)
sys.argv[3]: bids subject name (e.g. sub-01)
sys.argv[4]: server nb of processor to use (e.g 32)
sys.argv[5]: server nb of hour to request (e.g 10)
-----------------------------------------------------------------------------------------
Output(s):
QC html files
-----------------------------------------------------------------------------------------
To run:
1. cd to function
>> cd ~/projects/stereo_prf/analysis_code/preproc/
2. run python command
python mriqc_sbatch.py [main directory] [project name] [subject name] [nb proc.] [hour proc.]
-----------------------------------------------------------------------------------------
Exemple:
python mriqc_sbatch.py /scratch/mszinte/data stereo_prf sub-01 8 4
python mriqc_sbatch.py /scratch/mszinte/data stereo_prf sub-02 8 4
-----------------------------------------------------------------------------------------
Written by Martin Szinte (martin.szinte@gmail.com)
-----------------------------------------------------------------------------------------
"""

# imports modules
import sys
import os
import time
opj = os.path.join

# inputs
singularity_dir = '/scratch/mszinte/softwares/mriqc-0.15.1.simg'
main_dir = sys.argv[1]
project_dir = sys.argv[2]
subject = sys.argv[3]
sub_num = subject[-2:]
nb_procs = int(sys.argv[4])
job_dur = int(sys.argv[5])
cluster_name = 'skylake'
proj_name = 'b161'
memory_val = 100

# create sh folder and file
jobs_dir = opj(main_dir,project_dir,'derivatives','mriqc','jobs') 
log_dir = opj(main_dir,project_dir,'derivatives','mriqc','log_outputs')
try:
    os.makedirs(jobs_dir)
    os.makedirs(log_dir)
except:
    pass

slurm_cmd = """\
#!/bin/bash
#SBATCH -p {cluster_name}
#SBATCH -A {proj_name}
#SBATCH --nodes=1
#SBATCH --mem={memory_val}gb
#SBATCH --cpus-per-task={nb_procs}
#SBATCH --time={job_dur}:00:00
#SBATCH -e {log_dir}/{subject}_mriqc_%N_%j_%a.err
#SBATCH -o {log_dir}/{subject}_mriqc_%N_%j_%a.out
#SBATCH -J {subject}_mriqc\n\n""".format(
                    cluster_name=cluster_name, proj_name=proj_name,
                    nb_procs=nb_procs, log_dir=log_dir,
                    job_dur=job_dur, subject=subject, memory_val=memory_val)

# define singularity cmd
singularity_cmd = "singularity run --bind {main_dir}:/work_dir {simg} /work_dir/{project_dir}/ /work_dir/{project_dir}/derivatives/mriqc/ participant --participant_label {sub_num} -w /work_dir/temp_data/ --verbose-reports --mem_gb {memory_val} -m bold T1w --no-sub".format(main_dir=main_dir, project_dir=project_dir, simg=singularity_dir, sub_num=sub_num, memory_val=memory_val)

sh_dir = "{main_dir}/{project_dir}/derivatives/mriqc/jobs/sub-{sub_num}_mriqc.sh".format(main_dir=main_dir, project_dir=project_dir, sub_num=sub_num)
of = open(sh_dir, 'w')
of.write("{slurm_cmd}{singularity_cmd}".format(slurm_cmd=slurm_cmd, singularity_cmd=singularity_cmd))
of.close()

# Submit jobs
print("Submitting {sh_dir} to queue".format(sh_dir=sh_dir))
os.chdir(log_dir)
os.system("sbatch {sh_dir}".format(sh_dir=sh_dir))
