function [expe,scr,stim,sounds]=globalParametersDSTv4_goggles(skipFlag,Box)
%======================================================================
%  Goal: control panel for the expriment parameters of DSTv4_goggles
%======================================================================
% STaM Project [Stereo-Training and MRI]
% Apr 2014 - Berkeley
%-----------------------------------------------------------------------

%BOX HAS TO BE 23 FOR THE SCANNER and screenNumber is 1

%set the randomness random
%rng('default') %does not work on experimetn computer
rand('twister', sum(100*clock)); %rng('shuffle');
if ~exist('skipFlag','var');skipFlag=0;end

%======================================================================
%              WINDOW-SCREEN PARAMETERS
%======================================================================

Screen('Preference', 'VisualDebugLevel', 1); %decrease the level of initial debug commenting from 3 to 1
%screens=Screen('Screens');
scr.screenNumber=1; 
scr.res=Screen('Rect', scr.screenNumber); %screen size in pixel, format: [0 0 maxHoriz maxVert]
scr.box=Box;
switch Box
    case {19}         %Standard values for laptop Latitude E3660 Argent
        scr.W=290;           scr.H=170; %mm
        scr.frameSep = 0; %in mm
        scr.distFromScreen=78; %in cm
        scr.FOV = 30; %field of view in deg VA in the goggles
    case {23} %Scanner
        scr.W=43.4;           scr.H=29.6; %mm
        scr.frameSep = 0; %in mm
        scr.distFromScreen=10; %in cm
        scr.FOV = 30; %field of view in deg VA in the goggles
end

%check if vertical and horizontal pixel sizes are the same
scr.ppBymm= scr.res(3)/scr.W;
%if scr.res(3)/scr.W~=scr.res(4)/scr.H; warning('Change the screen resolution to have equal pixel sizes.',1);end
%scr.VA2pxConstant=scr.ppBymm *10*VA2cm(1,scr.distFromScreen); %constant by which we multiply a value in VA to get a value in px
scr.VA2pxConstant = scr.res(3)./scr.FOV;
scr.backgr=5; %in cd/m2
scr.fontColor=0;
%scr.keyboardNum=findKeyboardNumber(skipFlag);
scr.keyboardNum=-1;
%scr.keyboardNum=scr.keyboardNum(2);
% Keyboard in the experimental room is keyboardNum = 4
%scr.keyboardNum=max(PsychHID('NumDevices'))
scr.w=Screen('OpenWindow',scr.screenNumber, sc(scr.backgr,scr.box), [], 32, 2);
%scr.LE=Screen('OpenOffscreenWindow',scr.screenNumber ,sc(scr.backgr,scr.box), [], 32, [], 32);
%scr.RE=Screen('OpenOffscreenWindow',scr.screenNumber ,sc(scr.backgr,scr.box), [], 32, [], 32);
mat = sc(scr.backgr.*ones(scr.res(4),scr.res(3)),scr.box);
scr.LEtxt=Screen('MakeTexture', scr.w,mat);
scr.REtxt=Screen('MakeTexture', scr.w,mat);
scr.fontSize  = 10;
Screen('BlendFunction', scr.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

%now defines centers of screen and centers of stereo screens
%Caution has to be taken because the screen origin for DrawLine and
%DrawDots are different, and are also dependent on the screen
%On a viewPixx, screen originates at [1,0] for DrawLine and [0,1]
%for DrawDots
scr.centerX = scr.res(3)/2;
scr.centerY = scr.res(4)/2;
scr.stereoDeviation = scr.ppBymm.*scr.frameSep; %nb of px necessary to add from screen center in order to put a stim a zero disp

scr.LcenterX=round(scr.centerX-scr.stereoDeviation);
scr.RcenterX=round(scr.centerX+scr.stereoDeviation);
scr.centerY=round(scr.centerY);
scr.midPt=scr.centerX;

%            scr.LcenterXLine=         round(scr.centerX-scr.stereoDeviation);
%            scr.RcenterXLine=         round(scr.centerX+scr.stereoDeviation);
%            scr.centerYLine=          round(scr.centerY);
%            scr.LcenterXDot=         round(scr.centerX-scr.stereoDeviation);
%            scr.RcenterXDot=         round(scr.centerX+scr.stereoDeviation);
%            scr.centerYDot=          round(scr.centerY);

%Centers for Drawline
scr.LcenterXLine=round(scr.centerX-scr.stereoDeviation); %stereo position of left eye center
scr.RcenterXLine=round(scr.centerX+scr.stereoDeviation); %stereo position of right eye center
scr.centerYLine=round(scr.centerY); %stereo position of left eye center
%Centers for Drawdots
scr.LcenterXDot=round(scr.centerX-scr.stereoDeviation)-1; %stereo position of left eye center
scr.RcenterXDot=round(scr.centerX+scr.stereoDeviation)-1; %stereo position of right eye center
scr.centerYDot=round(scr.centerY)+1; %stereo position of left eye center

if Box==19
    %Centers for Drawline
    scr.LcenterXLine=round(scr.centerX-scr.stereoDeviation); %stereo position of left eye center
    scr.RcenterXLine=round(scr.centerX+scr.stereoDeviation); %stereo position of right eye center
    scr.centerYLine=round(scr.centerY); %stereo position of left eye center
    %Centers for Drawdots
    scr.LcenterXDot=round(scr.centerX-scr.stereoDeviation); %stereo position of left eye center
    scr.RcenterXDot=round(scr.centerX+scr.stereoDeviation); %stereo position of right eye center
    scr.centerYDot=round(scr.centerY); %stereo position of left eye center
end
%scr.frameTime =Screen('GetFlipInterval', scr.w, 3,[],2);
%     scr.monitorRefreshRate=1/scr.frameTime;
%--------------------------------------------------------------------------

%======================================================================
%              STIMULUS PARAMETERS
%======================================================================

%Fixation
    stim.fixationLengthMin= 30; % half size in arcmin
    stim.fixationLineWidthMin=15; %in arcmin  
    stim.fixationOffsetMin= 15; %offset between central fixation and nonius in arcmin
    stim.fixationDotSizeMin=15; %in arcmin

%Big boxes in fusion task (frames)
        if Box == 19
            stim.frameWidthVA=14; %witdth of the outside frame in deg 23
            stim.frameHeightVA=10; %in deg 17
          else
             stim.frameWidthVA=20; %witdth of the outside frame in deg 23
            stim.frameHeightVA=18; %in deg 17 
        end
        stim.frameLineWidthVA=0.2; %line width of the frames in VA
        stim.frameContrast=0.96;
        stim.framePhase=pi;

    stim.horiz.widthVA=stim.frameWidthVA; stim.horiz.heightVA=stim.frameLineWidthVA; stim.horiz.averageL=scr.backgr;
    stim.horiz.contrast=stim.frameContrast; stim.horiz.tilt=90;  stim.horiz.spatialFrequencyDeg=0.4;
    stim.horiz.phase=stim.framePhase; stim.horiz.FWHM = 100;
    stim.horiz.discrete=1; % set to make horiz frames with stripes, not gabor. JS 8/1/14

    stim.vert.widthVA=stim.frameLineWidthVA; stim.vert.heightVA=stim.frameHeightVA; stim.vert.averageL=scr.backgr;
    stim.vert.contrast=stim.frameContrast; stim.vert.tilt=0;  stim.vert.spatialFrequencyDeg=0.4;
    stim.vert.phase=stim.framePhase; stim.vert.FWHM = 100;
    stim.vert.discrete=1;% set to make horiz frames with stripes, not gabor. JS 8/1/14

%--------------------------------------------------------------------------
% TIMING (All times are in MILLISECONDS)
%--------------------------------------------------------------------------
    stim.duration                  = 200;
    stim.itemDuration                  = 5000; 
    stim.interTrial                    = 200;   
    %  stim.frameTime                      = scr.frameTime  ; %to get time for all drawings, only draw one every 3 frames
    stim.minimalDuration                = 200; 

%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%         sounds PARAMETERS
%--------------------------------------------------------------------------
    duration=0.2;
    freq1=1000;
    freq2=500;
    freq3 = 2000;
    sounds.success=soundDefine(duration,freq1);
    sounds.fail=soundDefine(duration,freq2);
    sounds.outFixation = soundDefine(duration,freq3);
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
%         EXPERIENCE PARAMETERS
%--------------------------------------------------------------------------
expe.name='STaM-DST-Goggles: Stereopsis Training and MRI';
expe.instrPosition=[0,300,400,1100];


% ============================================
%           Conversions in pixels
% ============================================
%Conversions in pixels
    stim.fixationLength=round(convertVA2px(stim.fixationLengthMin/60));
    stim.fixationLineWidth=round(convertVA2px(stim.fixationLineWidthMin/60));
    stim.fixationOffset=round(convertVA2px(stim.fixationOffsetMin/60));
    stim.fixationDotSize=round(convertVA2px(stim.fixationDotSizeMin/60));
    stim.horiz.width=round(convertVA2px(stim.horiz.widthVA));
    stim.horiz.height=round(convertVA2px(stim.horiz.heightVA));
    stim.vert.width= round(convertVA2px(stim.vert.widthVA));
    stim.vert.height= round(convertVA2px(stim.vert.heightVA));
    stim.frameLineWidth = round(convertVA2px(stim.frameLineWidthVA));

%--------------------------------------------------------------------------
precautions(scr.w, 'on');

    function px=convertVA2px(VA)
%         px=round(scr.ppBymm *10*VA2cm(VA,scr.distFromScreen));
%         %correct for when subpixel value is obtained
%         if px==0
%             px=ceil(scr.ppBymm *10*VA2cm(VA,scr.distFromScreen));
%         end
         px= VA.*scr.VA2pxConstant;
    end
end
