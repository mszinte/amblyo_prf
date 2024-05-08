#!/bin/bash

# Define the path to the settings.json file
settings_file="/home/mszinte/projects/amblyo_prf/analysis_code/settings.json"

# Define current directory
cd /home/mszinte/projects/amblyo_prf/analysis_code/postproc/prf/postfit/

# Read the subjects from settings.json using Python
subjects=$(python -c "import json; data = json.load(open('$settings_file')); print('\n'.join(data['subjects']))")

# Loop through each subject and run the Python code
for subject in $subjects
do
    echo "Processing make_rois_fig.py for: $subject"
    python make_rois_fig.py /scratch/mszinte/data amblyo_prf "$subject" 327
done