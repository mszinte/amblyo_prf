"""
-----------------------------------------------------------------------------------------
dcm2nii_sbatch.py
-----------------------------------------------------------------------------------------
Goal of the script:
Run pybest on mesocentre using job mode
-----------------------------------------------------------------------------------------
Input(s):
sys.argv[1]: main project directory
sys.argv[2]: project name (correspond to directory)
sys.argv[3]: subject (e.g. sub-01)
sys.argv[4]: registration type (e.g. T1w)
sys.argv[5]: server nb of hour to request (e.g 10)
sys.argv[6]: pca noise processing (0 =no, 1 = yes)
sys.argv[7]: email account
-----------------------------------------------------------------------------------------
Output(s):
Convert dicom to niix
-----------------------------------------------------------------------------------------
To run:
1. cd to function
>> cd /home/mszinte/projects/stereo_prf/preproc/
2. run python command
python dcm2nii.py ...
-----------------------------------------------------------------------------------------
Exemple:

-----------------------------------------------------------------------------------------
Written by Martin Szinte (martin.szinte@gmail.com)
Edit by ...
-----------------------------------------------------------------------------------------
"""



