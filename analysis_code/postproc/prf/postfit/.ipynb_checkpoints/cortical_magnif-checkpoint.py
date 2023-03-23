"""
-----------------------------------------------------------------------------------------
cortical_magnif.py
-----------------------------------------------------------------------------------------
Goal of the script :
Calculate cortical magnification factor like in Harvey,Dumoulin (2011)
-----------------------------------------------------------------------------------------
Input(s):
sys.argv[1]: main project directory
sys.argv[2]: project name (correspond to directory)
sys.argv[3]: subject name (e.g. sub-01)
-----------------------------------------------------------------------------------------
Output(s):
None
-----------------------------------------------------------------------------------------
To run:
1. cd to function
>> cd ~/disks/meso_H/projects/stereo_prf/analysis_code/postproc/prf/postfit/
2. run python command
>> python cortical_magnif.py [main directory] [project name] [subject num]
-----------------------------------------------------------------------------------------
Exemple:
python cortical_magnif.py /scratch/mszinte/data amblyo_prf sub-01
-----------------------------------------------------------------------------------------
Written by Martin Szinte (mail@martinszinte.net)
-----------------------------------------------------------------------------------------
"""

# # General imports
# import numpy as np
# import os
# import json
# import sys
# import math

# # Define analysis parameters
# with open('../../../settings.json') as f:
#     json_s = f.read()
#     analysis_info = json.loads(json_s)
# screen_size_cm = analysis_info['screen_size_cm']
# screen_size_pix = analysis_info["screen_size_pix"]
# screen_distance_cm = analysis_info['screen_distance_cm']
# grid_nr = analysis_info['grid_nr']
# max_ecc_size = analysis_info['max_ecc_size']
# apperture_rad_dva = analysis_info["apperture_rad_dva"]

# #Create array of excentricity dependant of the grid
# ecc = np.linspace(0, max_ecc_size, grid_nr, endpoint=True)

# # Convert eccentricity range from degrees to cm
# ecc_cm = ecc / 57.3 * screen_distance_cm

# # Calculate relationship between the distance stimulus-fovea and the associated cortical size representation
# cmf = np.cos(np.deg2rad(ecc_deg)) / (ecc_cm * px_size_deg)


# # Define cortical magnification function
# def cortical_magnification(ecc_cm, screen_distance_cm, apperture_rad_dva):
#     # Calculate cortical magnification factor using equation 4
#     cmf = (a * np.exp(-((ecc_cm - b) / c)**2) + d) * ecc_cm**-0.57
    
#     return cmf


# # Calculate cortical magnification factor for each eccentricity using the function defined above
# cmf = cortical_magnification(ecc_cm, screen_distance_cm, apperture_rad_dva)

# # Calculate image size required for each eccentricity
# image_size_px = (2 * ecc_cm * cmf / apperture_rad_dva) * screen_size_pix[0] / screen_size_cm

# # Print the image size for each eccentricity
# for i in range(len(image_size_px)):
#     print(f"Eccentricity {i+1}: {image_size_px[i]} pixels")

    
    
# def cortical_magnification(screen_size_cm, screen_size_pix, screen_distance_cm, grid_nr, max_ecc_size, apperture_rad_dva, ecc):
#     # Convert eccentricity range from degrees to cm
#     ecc_cm = ecc / 57.3 * screen_distance_cm

#     # Calculate cortical magnification factor
#     cmf = 0.5 * (math.pi / 180) * max_ecc_size * screen_distance_cm / (apperture_rad_dva * grid_nr)

#     # Calculate image size required for this eccentricity
#     a = cmf
#     b = -1.5 * cmf * max_ecc_size
#     c = 0.5 * cmf * max_ecc_size ** 2
#     d = 0
#     size_px = (-b + math.sqrt(b ** 2 - 4 * a * (c - ecc_cm))) / (2 * a)

#     return size_px


# def cortical_magnification(screen_size_cm, screen_size_pix, screen_distance_cm, grid_nr, max_ecc_size, apperture_rad_dva):
#     # Convert eccentricity range from degrees to cm
#     ecc_cm = ecc / 57.3 * screen_distance_cm

#     # Calculate cortical magnification factor
#     cmf = (math.pi * apperture_rad_dva) / (res[0] * 2) / (ecc_cm * 2) * 10

#     # Calculate image size required for this eccentricity
#     size_cm = cmf * ecc_cm * 2
#     size_deg = size_cm / screen_distance_cm * 57.3

#     # Convert image size from degrees to pixels
#     size_px = size_deg / apperture_rad_dva * res[0]

#     return size_px


# def cortical_magnification(eccentricity):
#     # Constants from Harvey and Dumoulin (2011)
#     c1 = 0.5
#     c2 = 0.35
#     c3 = 0.18
#     c4 = 0.1

#     # Equation 1 from Harvey and Dumoulin (2011)
#     cmf = c1 * np.exp(-c2*eccentricity) + c3*np.exp(-c4*eccentricity)

#     return cmf


# # Define the eccentricity of the point in degrees
# eccentricity = 5.0

# # Calculate the cortical magnification factor using the cortical_magnification function
# cmf = cortical_magnification(eccentricity)

# print(f"Cortical magnification factor at {eccentricity} degrees: {cmf}")




# ########### Librairies to calculate CMF ###################

# #########1st library

# import numpy as np
# import matplotlib.pyplot as plt
# from pycmf import cortical_magnification_factor

# # Define analysis parameters
# screen_distance_cm = 60  # distance between screen and eye in cm
# px_size_deg = 0.0267  # size of one pixel on screen in visual degrees

# # Define eccentricity range
# max_ecc_size = 15  # maximum eccentricity to consider in visual degrees
# grid_nr = 100  # number of grid points to use
# ecc = np.linspace(0, max_ecc_size, grid_nr, endpoint=True)

# # Calculate CMF using PyCMF
# cmf = cortical_magnification_factor(ecc, screen_distance_cm, px_size_deg)

# # Define pRF size as a function of eccentricity
# prf_size = 1 + ecc/2  # in degrees of visual angle

# # Apply CMF to pRF size
# prf_size_adjusted = prf_size / cmf

# # Plot results
# fig, ax = plt.subplots()
# ax.plot(ecc, prf_size, label='pRF size')
# ax.plot(ecc, prf_size_adjusted, label='Adjusted pRF size')
# ax.set_xlabel('Eccentricity (degrees of visual angle)')
# ax.set_ylabel('Size (degrees of visual angle)')
# ax.legend()
# plt.show()




# ######### 2nd library

# import numpy as np
# from prfpy import visual

# # Define stimulus and screen parameters
# screen_distance = 60  # distance between the subject and the screen in cm
# screen_width = 40  # width of the screen in cm
# screen_resolution = (1920, 1080)  # screen resolution in pixels
# viewing_distance = 100  # viewing distance in cm

# # Calculate the visual angle corresponding to the screen width
# screen_width_deg = visual.get_width_deg(screen_distance, screen_width)

# # Calculate the eccentricity values
# eccentricity_deg = np.linspace(0, screen_width_deg/2, num=100)

# # Calculate the cortical magnification factor
# cmf = visual.get_cortical_magnification_factor(
#     eccentricity_deg,
#     screen_distance,
#     screen_resolution,
#     viewing_distance
# )



######### 3rd library

import neuropythy as ny
import numpy as np
import json
import sys
import nibabel as nb

# Inputs
main_dir = sys.argv[1]
project_dir = sys.argv[2]
subject = sys.argv[3]

# Define analysis parameters
with open('../../../settings.json') as f:
    json_s = f.read()
    analysis_info = json.loads(json_s)
screen_size_cm = analysis_info['screen_size_cm']
screen_distance_cm = analysis_info['screen_distance_cm']
grid_nr = analysis_info['grid_nr']
max_ecc_size = analysis_info['max_ecc_size']
mesh = ny.load("{}/{}/derivatives/fmriprep/freesurfer/{}/surf/lh.inflated".format(main_dir, project_dir, subject))
coords, faces, meta_data = nb.freesurfer.io.read_geometry(mesh)

# Convert to Nifti image
img = ny.make_image(coords, faces)

# Create array of eccentricity dependent of the grid
ecc = np.linspace(0, max_ecc_size, grid_nr, endpoint=True)

# Convert eccentricity range from degrees to cm
ecc_cm = ecc / 57.3 * screen_distance_cm

# Calculate cortical magnification factor using the neuropythy library
cmf = ny.neighborhood_cortical_magnification(mesh, ecc_cm)

print(cmf)


