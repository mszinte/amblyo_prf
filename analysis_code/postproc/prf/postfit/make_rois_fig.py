"""
-----------------------------------------------------------------------------------------
make_rois_fig.py
-----------------------------------------------------------------------------------------
Goal of the script:
Make ROIs-based CSS figures
-----------------------------------------------------------------------------------------
Input(s):
sys.argv[1]: main project directory
sys.argv[2]: project name (correspond to directory)
sys.argv[3]: subject name (e.g. sub-01)
sys.argv[4]: server group (e.g. 327)
-----------------------------------------------------------------------------------------
Output(s):
CSS analysis figures
-----------------------------------------------------------------------------------------
To run:
1. cd to function
>> cd ~/projects/[PROJECT]/analysis_code/postproc/prf/postfit/
2. run python command
python make_rois_fig.py [main directory] [project name] [subject] [group]
-----------------------------------------------------------------------------------------
Exemple:
python make_rois_fig.py /scratch/mszinte/data amblyo_prf sub-01 327
-----------------------------------------------------------------------------------------
Written by Uriel Lascombes (uriel.lascombes@laposte.net)
Edited by Martin Szinte (mail@martinszinte.net)
-----------------------------------------------------------------------------------------
"""

# Stop warnings
import warnings
warnings.filterwarnings("ignore")

# General imports
import os
import sys
import json
import pandas as pd
import ipdb
deb = ipdb.set_trace

# Personal import
sys.path.append("{}/../../../utils".format(os.getcwd()))
from plot_utils import *

# Inputs
main_dir = sys.argv[1]
project_dir = sys.argv[2]
subject = sys.argv[3]
group = sys.argv[4]

# Load settings
with open('../../../settings.json') as f:
    json_s = f.read()
    analysis_info = json.loads(json_s)
formats = analysis_info['formats']
extensions = analysis_info['extensions']
rois = analysis_info['rois']

# Colors
colormap_dict = {'V1': (243, 231, 155),
                 'V2': (250, 196, 132),
                 'V3': (248, 160, 126),
                 'V3AB': (235, 127, 134),
                 'LO': (150, 0, 90), 
                 'VO': (0, 0, 200),
                 'hMT+': (0, 25, 255),
                 'iIPS': (0, 152, 255),
                 'sIPS': (44, 255, 150)}
roi_colors = ['rgb({},{},{})'.format(*rgb) for rgb in colormap_dict.values()]

# Threshold settings
ecc_th = analysis_info['ecc_th']
size_th = analysis_info['size_th']
rsqr_th = analysis_info['rsqr_th']
pcm_th = analysis_info['pcm_th']
amplitude_th = analysis_info['amplitude_th']
stats_th = analysis_info['stats_th']
if stats_th == 0.05: stats_col = 'corr_pvalue_5pt'
elif stats_th == 0.01: stats_col = 'corr_pvalue_1pt'

# Format loop
for format_, extension in zip(formats, extensions):
    
    # Create folders and fns
    tsv_dir = '{}/{}/derivatives/pp_data/{}/{}/prf/tsv'.format(
        main_dir, project_dir, subject, format_)
    fig_dir = '{}/{}/derivatives/pp_data/{}/{}/prf/figures'.format(
        main_dir, project_dir, subject, format_)
    os.makedirs(fig_dir, exist_ok=True)

    # Load data
    tsv_fn = '{}/{}_css-all_derivatives.tsv'.format(tsv_dir, subject)
    data = pd.read_table(tsv_fn, sep="\t")
    
    # Threshold data (replace by nan)
    data.loc[(data.amplitude < amplitude_th) |                                    # amplitude 
             (data.prf_ecc < ecc_th[0]) | (data.prf_ecc > ecc_th[1]) |            # eccentricity 
             (data.prf_size < size_th[0]) | (data.prf_size > size_th[1]) |        # size
             (data.pcm < pcm_th[0]) | (data.pcm > pcm_th[1]) |                    # pcm
             (data.prf_loo_r2 < rsqr_th) |                                        # loo rsqr
             (data[stats_col] > stats_th)                                         # stats
              ] = np.nan
    data = data.dropna()

    # Violins plots
    fig_fn = "{}/{}_prf_violins.pdf".format(fig_dir, subject)
    print('Saving {}'.format(fig_fn))
    fig = prf_violins_plot(data=data, fig_width=1920, fig_height=1080, rois=rois, roi_colors=roi_colors)
    fig.write_image(fig_fn)

    # Ecc.size plots
    plot_groups = [['V1', 'V2', 'V3'],
                   ['V3AB', 'LO', 'VO'],
                   ['hMT+', 'iIPS', 'sIPS']]
    ecc_bins = np.linspace(0.1, 1, 6)**2 * 15
    fig_fn = "{}/{}_prf_ecc_size.pdf".format(fig_dir, subject)
    print('Saving {}'.format(fig_fn))
    fig = prf_ecc_size_plot(data=data, fig_width=1000, fig_height=400, rois=rois, roi_colors=roi_colors,
                            plot_groups=plot_groups, ecc_bins=ecc_bins)
    fig.write_image(fig_fn)

    # Ecc.pCM plot
    fig_fn = "{}/{}_prf_ecc_pcm.pdf".format(fig_dir, subject)
    fig = prf_ecc_pcm_plot(data, fig_width=1000, fig_height=400, rois=rois, roi_colors=roi_colors,
                           plot_groups=plot_groups, ecc_bins=ecc_bins)
    print('Saving {}'.format(fig_fn))
    fig.write_image(fig_fn)
    
    # # Polar angle distributions
    # figures, hemis = prf_polar_plot(data, subject, fig_height=300, fig_width=1920, 
    #                                 ecc_th=ecc_th, size_th=size_th, rsq_th=rsq_th)
    # for i, (figure, hemi) in enumerate(zip(figures, hemis), start=1):
    #     figure.write_image("{}/{}_subplot_polar_{}.pdf".format(fig_dir, subject, hemi))
        
    # # Contralaterality plots
    # fig3 = prf_contralaterality_plot(data, subject, fig_height=300, fig_width=1920, 
    #                                  ecc_th=ecc_th, size_th=size_th, rsq_th=rsq_th)
    # fig3.write_image("{}/{}_contralaterality.pdf".format(fig_dir, subject))
    
    
    
    # # ??
    # fig5 = surface_rois_all_categories_plot(data, subject, fig_height=1080, fig_width=1920)
    # fig5.write_image("{}/{}_surface_rois_all_categories.pdf".format(fig_dir, subject)) 
    
    # # ??
    # fig6 = surface_rois_categories_plot(data, subject, fig_height=1080, fig_width=1920)
    # fig6.write_image("{}/{}_surface_rois_categories.pdf".format(fig_dir, subject)) 

    # # ??
    # fig7 = categories_proportions_roi_plot(data, subject, fig_height=300, fig_width=1920)
    # fig7.write_image("{}/{}_categories_proportions_roi.pdf".format(fig_dir, subject)) 

# Define permission cmd
# print('Changing files permissions in {}/{}'.format(main_dir, project_dir))
# os.system("chmod -Rf 771 {}/{}".format(main_dir, project_dir))
# os.system("chgrp -Rf {} {}/{}".format(group, main_dir, project_dir))