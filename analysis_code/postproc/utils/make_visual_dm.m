function make_visual_dm(in_dir,in_file,tr,trs,out_size,plot_vid)
% ----------------------------------------------------------------------
% make_visual_dm(in_dir, in_file tr,trs,out_size,plot_vid)
% ----------------------------------------------------------------------
% Goal of the function :
% Create visual design matrix for modeling
% ----------------------------------------------------------------------
% Input(s) :
% in_dir: stimulus video file directory (/your/path)
% in_file: stimulus video file name (AttendStim_vid)
% tr: tr duration in seconds
% trs: number of tr in total
% out_size: visual design matrix size (eg. [200, 200], or [240,135])
% plot_vid: draw the visual design (1) or not (0)
% ----------------------------------------------------------------------
% Output(s):
% none
% ----------------------------------------------------------------------
% Function created by Martin SZINTE (martin.szinte@gmail.com)
% Last update : 19 / 11 / 2020
% Project :     pRFexp
% Version :     1.0
% ----------------------------------------------------------------------
% example : 
% in_dir = '/Users/martinszinte/disks/meso_S/data/stereo_prf/derivatives/vdm/'
% in_file = 'VID_20221102_152644_trim_crop'
% tr = 1.8
% trs = 135
% out_size = [135,135]
% plot_vid = 1
% make_visual_dm(in_dir,in_file,tr,trs,out_size,plot_vid)
% ----------------------------------------------------------------------

close all
v = VideoReader(sprintf('%s/%s.mp4',in_dir,in_file));

frame_total = tr*trs*v.FrameRate;

frame_to_draw_tr_num = 0:1:trs-1;
frame_to_draw_tr_sec = frame_to_draw_tr_num * tr + tr/2;
frame_to_draw = round((frame_to_draw_tr_sec/v.Duration)*frame_total);
frame_tr = 0;
for frame_num = frame_to_draw                      
    frame_tr = frame_tr+1;
    mat_frame = read(v ,frame_num);                             
    mat_frame = mat_frame(:,:,1);
    mat_frame = mat_frame(:,(800-600)/2+1:(800-(800-600)/2));
    mat_frame = imresize(mat_frame,fliplr(out_size)); 
    
    if plot_vid
        imshow(mat_frame)
        pause(0.1)
    end
    
    stim(:,:,frame_tr) = mat_frame';
end

save(sprintf('%s/%s_vd.mat',in_dir,in_file),'stim')

end