"""-----------------------------------------------------------------------------------------merge_pycortex_maps.py-----------------------------------------------------------------------------------------Goal of the script:Concat all pycortex maps and prf figures of one subject in one pdf-----------------------------------------------------------------------------------------Input(s):sys.argv[1]: main project directorysys.argv[2]: project name (correspond to directory)sys.argv[3]: number of subjectssys.argv[4]: group-----------------------------------------------------------------------------------------Output(s):one pdf file with pycortex maps and one pdf file with prf figures-----------------------------------------------------------------------------------------To run:0. To Run on meso (not on node)1. cd to function>>  cd ~/projects/[PROJECT]/analysis_code/postproc/prf/postfit2. run python command>> python pdf_maps.py [main directory] [project name] [subject num] [group]-----------------------------------------------------------------------------------------Exemple:python merge_pycortex_maps.py /scratch/mszinte/data amblyo_prf sub-01 327-----------------------------------------------------------------------------------------Written by Uriel Lascombes (uriel.lascombes@laposte.net)Edited by Martin Szinte (mail@martinszinte.net)-----------------------------------------------------------------------------------------"""# General importsimport osimport sysimport jsonimport globfrom pypdf import PdfWriterfrom pypdf.annotations import FreeText# Debugimport ipdbdeb = ipdb.set_trace# Inputsmain_dir = sys.argv[1]project_dir = sys.argv[2]subject = sys.argv[3]group = sys.argv[4]# load settingswith open('../../../settings.json') as f:    json_s = f.read()    analysis_info = json.loads(json_s)formats = analysis_info['formats']extensions = analysis_info['extensions']prf_task_name = analysis_info['prf_task_name']# Merge Pycortex Mapsfor format_, extension in zip(formats, extensions):       # Defind output directory and file    pycortex_merge_dir = '{}/{}/derivatives/pp_data/{}/{}/figures/pycortex/'.format(        main_dir, project_dir, subject, format_)    os.makedirs(pycortex_merge_dir, exist_ok = True)    pycortex_merge_fn = '{}_prf-all_maps.pdf'.format(subject)        # Find all pycortex maps     pycortex_roi_dir = '{}/{}/derivatives/pp_data/{}/{}/rois/pycortex/flatmaps_rois/*'.format(        main_dir, project_dir, subject, format_)    pycortex_corr_dir = '{}/{}/derivatives/pp_data/{}/{}/corr/pycortex/flatmaps_inter-run-corr/*{}*'.format(        main_dir, project_dir, subject, format_, prf_task_name)    pycortex_gauss_dir = '{}/{}/derivatives/pp_data/{}/{}/prf/pycortex/flatmaps_avg_gauss_gridfit/*'.format(        main_dir, project_dir, subject, format_)    pycortex_css_dir = '{}/{}/derivatives/pp_data/{}/{}/prf/pycortex/flatmaps_loo-avg_css/*'.format(        main_dir, project_dir, subject, format_)        pycortex_all = glob.glob(pycortex_roi_dir) \        + glob.glob(pycortex_corr_dir) \            + glob.glob(pycortex_gauss_dir) \                + glob.glob(pycortex_css_dir)        # Merge pdf and export final pdf     pycortex_merger = PdfWriter()    for n_page, pycortex_map in enumerate(pycortex_all):         # merge        pycortex_merger.append(pycortex_map)            # Export the pdf     pycortex_merger.write('{}/{}'.format(pycortex_merge_dir, pycortex_merge_fn))    pycortex_merger.close()# Merge prf figuresfor format_, extension in zip(formats, extensions):     # Defind output directory and file    prf_fig_merge_dir = '{}/{}/derivatives/pp_data/{}/{}/figures/prf_figures/'.format(        main_dir, project_dir, subject, format_)    os.makedirs(prf_fig_merge_dir, exist_ok = True)    prf_fig_merge_fn = '{}_prf-all_fig.pdf'.format(subject)    # Find all prf figures      prf_fig_dir = '{}/{}/derivatives/pp_data/{}/{}/prf/figures/*'.format(        main_dir, project_dir, subject, format_)    prf_fig_dir_fns = glob.glob(prf_fig_dir)    # Merge pdf and export final pdf     figures_merger = PdfWriter()    for n_page, figure_fn in enumerate(prf_fig_dir_fns):         # merge        figures_merger.append(figure_fn)            # Export the pdf       figures_merger.write('{}/{}'.format(prf_fig_merge_dir, prf_fig_merge_fn))    figures_merger.close()    # Define permission cmdprint('Changing files permissions in {}/{}'.format(main_dir, project_dir))os.system("chmod -Rf 771 {main_dir}/{project_dir}".format(main_dir=main_dir, project_dir=project_dir))os.system("chgrp -Rf {group} {main_dir}/{project_dir}".format(main_dir=main_dir, project_dir=project_dir, group=group))