"""
-----------------------------------------------------------------------------------------
bad_run.py
-----------------------------------------------------------------------------------------
Goal of the script:
Exclude bad run
-----------------------------------------------------------------------------------------
Input(s):
sys.argv[1]: main project directory
sys.argv[2]: project name (correspond to directory)
sys.argv[3]: subject (e.g. sub-001)
----------------------------------------------------
Output(s):
rewrrite the bad run names with _exluded extention. 
Supposed to have change the 'setting.json'.
-----------------------------------------------------------------------------------------
To run:
1. cd to function
>> cd ~/projects/amblyo_prf/analysis_code/preproc/functional
2. run python command
python bad_run.py [main directory] [project name] [subject num]
-----------------------------------------------------------------------------------------
Exemple:
python bad_run.py /scratch/mszinte/data/ amblyo_prf
-----------------------------------------------------------------------------------------
Written by Martin Szinte (mail@martinszinte.net)
-----------------------------------------------------------------------------------------
"""
# General imports
import json
import os
import sys
import glob
import ipdb
deb = ipdb.set_trace

# Inputs
main_dir = sys.argv[1]
project_name = sys.argv[2]

# load settings
with open('../../settings.json') as f:
    json_s = f.read()
    analysis_info = json.loads(json_s)
subjects_excluded = analysis_info['subjects_excluded']
tasks_excluded = analysis_info['tasks_excluded']
runs_excluded = analysis_info['runs_excluded']
sessions_excluded = analysis_info['sessions_excluded']

# add the _excluded extention to the bad_run 
for subjects_excluded_num, subject_excluded in enumerate(subjects_excluded):
    for task_excluded in tasks_excluded[subjects_excluded_num]:
        for session_excluded in sessions_excluded[subjects_excluded_num]:
            for run_excluded in runs_excluded[subjects_excluded_num]:
                prefix = "{}/{}/derivatives/fmriprep/fmriprep/{}/{}/func/*{}*{}_*".format(
                    main_dir, project_name, subject_excluded, session_excluded, task_excluded, run_excluded)
                fns = glob.glob(prefix)
                
                for fn in fns:
                    excluded_dir = "{}/{}/derivatives/fmriprep/fmriprep/{}/{}/excluded".format(
                        main_dir, project_name, subject_excluded, session_excluded)
                    os.makedirs(excluded_dir, exist_ok=True)
                    os.rename(fn, "{}/{}".format(excluded_dir, os.path.basename(fn)))