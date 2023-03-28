"""-----------------------------------------------------------------------------------------pdf_maps.py-----------------------------------------------------------------------------------------Goal of the script:Create flatmap plots and dataset-----------------------------------------------------------------------------------------Input(s):sys.argv[1]: main project directorysys.argv[2]: project name (correspond to directory)sys.argv[3]: subject numbersys.argv[4]: group-----------------------------------------------------------------------------------------Output(s):pdf files with pycortex maps-----------------------------------------------------------------------------------------To run:0. To Run on meso (not on node)1. cd to function>> cd ~/projects/stereo_prf/analysis_code/postproc/prf/postfit2. run python command>> python pyxcortex_maps.py [main directory] [project name] [subject number] [group]-----------------------------------------------------------------------------------------Exemple:python pdf_maps.py /scratch/mszinte/data amblyo_prf 18 327-----------------------------------------------------------------------------------------Written by Martin Szinte (mail@martinszinte.net)-----------------------------------------------------------------------------------------"""# General importsimport sysfrom pypdf import PdfMergerimport os# Inputsmain_dir = sys.argv[1]project_dir = sys.argv[2]n_subjects = (int(sys.argv[3])+1)group = sys.argv[4]#ECC pdfmerger = PdfMerger()num = []for t in range(1, n_subjects):    num.append(str(t).zfill(2))pdf_list = ['sub-{n}_task-prf_ecc_avg.pdf'.format(n=n) for n in num]for p, pdf in zip(num, pdf_list):    directory = '{main_dir}/{project_dir}/derivatives/pp_data/sub-{num}/prf/pycortex/flatmaps'.format(main_dir=main_dir,project_dir=project_dir,num=p)     os.chdir(directory)    merger.append(pdf)os.chdir('{main_dir}/{project_dir}/derivatives/pp_data'.format(main_dir=main_dir,project_dir=project_dir))merger.write("ECC_all.pdf")merger.close()print('ECC pdf done')#polar pdfmerger = PdfMerger()num = []for t in range(1, n_subjects):    num.append(str(t).zfill(2))pdf_list = ['sub-{n}_task-prf_polar_255_avg.pdf'.format(n=n) for n in num]for p, pdf in zip(num, pdf_list):    directory = '{main_dir}/{project_dir}/derivatives/pp_data/sub-{num}/prf/pycortex/flatmaps'.format(main_dir=main_dir,project_dir=project_dir,num=p)     os.chdir(directory)    merger.append(pdf)os.chdir('{main_dir}/{project_dir}/derivatives/pp_data'.format(main_dir=main_dir,project_dir=project_dir))merger.write("polar_all.pdf")merger.close()print('polar pdf done')#rsq mapmerger = PdfMerger()num = []for t in range(1, n_subjects):    num.append(str(t).zfill(2))pdf_list = ['sub-{n}_task-prf_rsq_avg.pdf'.format(n=n) for n in num]for p, pdf in zip(num, pdf_list):    directory = '{main_dir}/{project_dir}/derivatives/pp_data/sub-{num}/prf/pycortex/flatmaps'.format(main_dir=main_dir,project_dir=project_dir,num=p)     os.chdir(directory)    merger.append(pdf)os.chdir('{main_dir}/{project_dir}/derivatives/pp_data'.format(main_dir=main_dir,project_dir=project_dir))merger.write("rsq_all.pdf")merger.close()print('rsq pdf done')#size mapmerger = PdfMerger()num = []for t in range(1, n_subjects):    num.append(str(t).zfill(2))pdf_list = ['sub-{n}_task-prf_size_avg.pdf'.format(n=n) for n in num]for p, pdf in zip(num, pdf_list):    directory = '{main_dir}/{project_dir}/derivatives/pp_data/sub-{num}/prf/pycortex/flatmaps'.format(main_dir=main_dir,project_dir=project_dir,num=p)     os.chdir(directory)    merger.append(pdf)os.chdir('{main_dir}/{project_dir}/derivatives/pp_data'.format(main_dir=main_dir,project_dir=project_dir))merger.write("size_all.pdf")merger.close()print('size pdf done')# Define permission cmdos.system("chmod -Rf 771 {main_dir}/{project_dir}".format(main_dir=main_dir, project_dir=project_dir))os.system("chgrp -Rf {group} {main_dir}/{project_dir}".format(main_dir=main_dir, project_dir=project_dir, group=group))