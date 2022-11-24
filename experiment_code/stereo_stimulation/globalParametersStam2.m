function [expe,scr,stim,sounds]=globalParametersStam2(skipFlag,Box)
%------------------------------------------------------------------------
% global parameters for MRI_Stam2 and 3, which is a program to present stereoscopic stimuli in the scanner.
% It is part of :
% STaM Project [Stereo-Training and MRI]
% Sep 2014 - Berkeley
%-----------------------------------------------------------------------
    
    %set the randomness random
    %rng('default'); %does not work in box 21
    rand('twister', sum(100*clock));
    
    if ~exist('skipFlag','var');skipFlag=0;end
    AssertOpenGL;
    Screen('Preference', 'VisualDebugLevel', 0); %decrease the level of initial debug commenting from 3 to 1
    
    %======================================================================
    %              WINDOW-SCREEN PARAMETERS 
    %====================================================================== 
   % screens=Screen('Screens');
    if Box == 19
        scr.screenNumber=2; 
    else
        scr.screenNumber=1;
    end
    scr.screenNumber
    try
        scr.res=Screen('rect', scr.screenNumber); %screen size in pixel, format: [0 0 maxHoriz maxVert]
    catch
        error('Probably that the display is not in extended mode but in mirror. Restart Matlab after changing mode.')
    end
    if scr.res(3)~=800
        error('Resolution should absolutely be 800x600!! Current resolution is:')
        disp(scr.res)
    end
    scr.box=Box;
     switch Box
         case {19}         %Standard values for laptop Latitude E3660 Argent
                scr.W=290;           scr.H=170; %mm  
                scr.distFromScreen=78; %in cm
                scr.frameSep = 0; %in mm
                scr.FOV = 30;
         case {20} %Standard values for SONY screen in Levi Lab (Triniton Multiscan G500 - room 487)
             scr.W=360;           scr.H=290; %mm  
                scr.frameSep = 84; %in mm
                scr.distFromScreen=150; %in cm
         case {21} %Standard values for NEC SuperBright Diamondtron MultiSync FP2141SB screen in Levi Lab (room 487 -eye tracker spot)      
             scr.W=390;           scr.H=295; %mm  
                      scr.frameSep = 100; %in mm
                scr.distFromScreen=150; %in cm
         case {23} %Scanner goggles NeuroNordicLab VisualSystem
        scr.W=43.4;           scr.H=29.6; %mm
        scr.frameSep = 0; %in mm
        scr.distFromScreen=10; %in cm
        scr.FOV = 30; %field of view in deg VA in the goggles
     end
      
        %check if vertical and horizontal pixel sizes are the same
        scr.ppBymm= scr.res(3)/scr.W;
        %if scr.res(3)/scr.W~=scr.res(4)/scr.H; warnings('Change the screen resolution to have equal pixel sizes.',1);end
        %scr.VA2pxConstant=scr.ppBymm *10*VA2cm(1,scr.distFromScreen); %constant by which we multiply a value in VA to get a value in px
        scr.VA2pxConstant = scr.res(3)./scr.FOV;
        scr.backgr=5; %in cd/m2
        scr.fontColor=0;
        %scr.keyboardNum=findKeyboardNumber(skipFlag);
        scr.keyboardNum=-1; %alll keyboards
        %scr.keyboardNum=scr.keyboardNum(2);
        %scr.keyboardNum=max(PsychHID('NumDevices'))
        scr.w=Screen('OpenWindow',scr.screenNumber, sc(scr.backgr,scr.box), [], 32, 2, [], 8);  
        %scr.LE=Screen('OpenOffscreenWindow',scr.screenNumber ,sc(scr.backgr,scr.box), [], 32, [], 32);
        %scr.RE=Screen('OpenOffscreenWindow',scr.screenNumber ,sc(scr.backgr,scr.box), [], 32, [], 32);
        mat = sc(scr.backgr.*ones(scr.res(4),scr.res(3)),scr.box);
        scr.LEtxt=Screen('MakeTexture', scr.w,mat);
        scr.REtxt=Screen('MakeTexture', scr.w,mat);
        scr.fontSize  = 30;
        Screen('BlendFunction', scr.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('Preference', 'ConserveVRAM', 4096);
%          Tell PTB to always use the workaround for broken beamposition queries in
%           VBL on MS-Windows, even if the automatic startup test does not detect any
%           problems. This for rare cases where the test fails to detect broken
%           setups.
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
            
         %scr.frameTime =Screen('GetFlipInterval', scr.w, 1); HERE
         scr.frameRate = Screen('NominalFrameRate', scr.w);
         scr.frameTime = 1/scr.frameRate;  %CHANGE HERE     
    %     scr.monitorRefreshRate=1/scr.frameTime;
    %--------------------------------------------------------------------------
    
    %======================================================================
    %              STIMULUS PARAMETERS 
    %======================================================================        
        %--Fixation nonius cross / circle + fixation dot
            stim.fixationLengthMin= 30; % half size in arcmin
            stim.fixationLineWidthMin=15; %in arcmin 8
            stim.fixationOffsetMin= 15; %offset between central fixation and nonius in arcmin
            stim.fixationDotSizeMin=15; %in arcmin
            
        %--Big boxes properties (fusion box)
            stim.frameLineWidthVA=0.3; %line width of the frames in VA
          if Box == 19
            stim.frameWidthVA=14; %witdth of the outside frame in deg 23
            stim.frameHeightVA=10; %in deg 17
          else
             stim.frameWidthVA=20; %witdth of the outside frame in deg 23
            stim.frameHeightVA=18; %in deg 17 
          end
            stim.frameContrast=0.96;
            stim.framePhase=pi;
            
           %-hashed big box (fusion box in DST)
            stim.horiz.widthVA=stim.frameWidthVA; stim.horiz.heightVA=stim.frameLineWidthVA; stim.horiz.averageL=scr.backgr;
            stim.horiz.contrast=stim.frameContrast; stim.horiz.tilt=90;  stim.horiz.spatialFrequencyDeg=0.4; 
            stim.horiz.phase=stim.framePhase; stim.horiz.FWHM = 100;
            stim.horiz.discrete=1; % set to make horiz frames with stripes, not gabor. JS 8/1/14
            
            stim.vert.widthVA=stim.frameLineWidthVA; stim.vert.heightVA=stim.frameHeightVA; stim.vert.averageL=scr.backgr;
            stim.vert.contrast=stim.frameContrast; stim.vert.tilt=0;  stim.vert.spatialFrequencyDeg=0.4; 
            stim.vert.phase=stim.framePhase; stim.vert.FWHM = 100;
            stim.vert.discrete=1;% set to make horiz frames with stripes, not gabor. JS 8/1/14
            
         %--Main stimuli for stereo task: left and right RDS panels in depth (not the background) 
           %-target RDS
            stim.RDSwidthVA=stim.frameWidthVA/2.*0.8; %8 %width of RDS panels (each)
            stim.RDSheightVA=stim.frameHeightVA.*0.55556; %11 %heigth of  RDS panel
            stim.RDS_edge_eccVA = 0 ; %in VA, eccentricity of the closer edge of the RDS panel relative to fixation
            stim.RDSeccVA=stim.RDS_edge_eccVA+stim.RDSwidthVA/2; %eccentricty of the center of the central RDS
            
           %-background RDS - size of the background in VA
            stim.backgrWidthVA = 0.95*stim.frameWidthVA ; %should be the same that the big box frame (95% of it) 
            stim.backgrHeightVA = 0.95*stim.frameHeightVA;
            stim.backgrWidthVA = 0.95*stim.frameWidthVA ; %should be the same that the big box frame (95% of it) 
            stim.backgrHeightVA = 0.95*stim.frameHeightVA;
            
        %--Dots in stereo test   
            stim.dotDensity= 25; % in %
            stim.coherence = 0; %in % - valid only when using moving dots
            stim.apparentSizeVA = 0.3; % = gaussian dot FWHM in va 
            stim.apparentSize = stim.apparentSizeVA.*scr.VA2pxConstant; % = gaussian dot FWHM in pp - we use transparency - 16 on laptop, 24 on v2 resolution
            stim.gaussianD = 0; %1 yes, 0: no (sharp dots)
               if stim.gaussianD == 1
                   stim.dotSize = round(3*stim.apparentSize); %in pp (defines the dot drawing area)
               else
                   stim.dotSize = round(stim.apparentSize);
               end 
               stim.speed = 1; % in pp by frame 0.5 on laptop, valid only when using moving dots
               stim.dotContrast = 0.96;
           
            stim.polarity = 4; %1 : standard with grey background, 2: white on black background, 3: black on white background, 4: half/half
            if mod(stim.dotSize,2)~=1; disp('Careful! dotsize should be odd: adding 1 to it');  stim.dotSize=stim.dotSize+1; end
            if stim.dotSize<3; disp('dotsize should be greater than 3');  sca; xx; end
            stim.maxLum = 60; %maximum white to display
            stim.minLum = 0;    %maximum dark to display
            
    %--------------------------------------------------------------------------
    % TIMING (All times are in MILLISECONDS)
    %--------------------------------------------------------------------------
         stim.itemDuration                  = 560.75; 
         stim.interTrial                    = 0;   
         stim.fixationDuration               = 1000; %ms 15701 when using wrapper code  
         stim.frameTime                      = scr.frameTime  ; %to get time for all drawings, only draw one every 3 frames
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
        %general
        expe.name='Stam v1 Goggles - Scanner version';
        expe.time=[]; %durations of the sessions in min
        expe.date={}; %dates of the sessions
        expe.instrPosition=[0,scr.centerY,300,1000];
        %expe.escapeTimeLimit=10; %(min) nb of min after which escape key is deactivated
        %expe.driftCorrectionFlag=0;
        %expe.feedback = 0; %if 1, give an auditory feedback according to success
        expe.multiplier = 3; %for luminance increment 
        expe.detectTime = 1.5; %time in sec before which it is correct to detect an increment
        stim.attentionalP = 0.3; %probability of an increment in the attentional task
        stim.feedbackSizeMin = 1.5*stim.fixationLineWidthMin/2; %nb of pixels used for half height frame around fixation
 
        %paradigm
        expe.pedestalMin = 0; % pedestal values in min %FIRST ONE HAS TO BE ZERO (or change the way range is chosen later)
        expe.nbPedestal = numel(expe.pedestalMin);  %nb of condition, each corresponding to a different pedestal %
        expe.nbRepeatDisp = 2; %nb of times each specific disparity magnitude/config/correlation is repeated in a run
        expe.dispList = [270,540,-270,-540];
        expe.nbValues = 1; %nb of different disparities presented in a block
        expe.nbOfPresentation = 14; %nb of ON OFF cycles of presentation in a block HERE 14
           
           %  expe.dispList = [270] %HERE
            % expe.nbOfPresentation = 2
% ============================================
%           Conversions in pixels
% ============================================
            stim.fixationLength=round(convertVA2px(stim.fixationLengthMin/60)); 
            stim.fixationLineWidth=round(convertVA2px(stim.fixationLineWidthMin/60));
            stim.fixationOffset=round(convertVA2px(stim.fixationOffsetMin/60));
            stim.fixationDotSize=round(convertVA2px(stim.fixationDotSizeMin/60));
            stim.horiz.width=round(convertVA2px(stim.horiz.widthVA));
            stim.horiz.height=round(convertVA2px(stim.horiz.heightVA));
            stim.vert.width= round(convertVA2px(stim.vert.widthVA));
            stim.vert.height= round(convertVA2px(stim.vert.heightVA));
            stim.frameLineWidth = round(convertVA2px(stim.frameLineWidthVA));
            stim.RDSwidth=round(convertVA2px(stim.RDSwidthVA)); 
            stim.RDSheight=round(convertVA2px(stim.RDSheightVA)); 
            stim.RDSecc=round(convertVA2px(stim.RDSeccVA));
            expe.pedestal= convertVA2px(expe.pedestalMin/60);
            expe.dispListpp = convertVA2px(expe.dispList/3600);
            stim.backgrWidth=round(convertVA2px(stim.backgrWidthVA)); 
            stim.backgrHeight=round(convertVA2px(stim.backgrHeightVA));
            stim.feedbackSizePp=round(convertVA2px(stim.feedbackSizeMin/60));            
        if mod(stim.RDSwidth,2)~=1; disp('Correcting: stim.RDSwidth should be odd - removing 1pp');  stim.RDSwidth = stim.RDSwidth-1; end
        if mod(stim.RDSheight,2)~=1; disp('Correcting: stim.RDSheight should be odd - removing 1pp');  stim.RDSheight=stim.RDSheight-1; end
        if mod(stim.backgrHeight,2)~=1; disp('Correcting: stim.backgrHeight should be odd - removing 1pp');  stim.backgrHeight=stim.backgrHeight-1; end
        if mod(stim.backgrWidth,4)~=0; disp('Correcting: stim.backgrWidth should be a multiple of 4 - removing pp');  stim.backgrWidth=stim.backgrWidth-mod(stim.backgrWidth,4); end
                
        %expe.breakInstructions.fr=strcat('Vous pouvez prendre une pause plus longue. Appuyez sur une touche pour continuer.');
        %expe.breakInstructions.en=strcat('You can have a longer break if you wish. Press a key to continue.');
        %expe.thx.fr='====  MERCI  =====';
        %expe.thx.en='=====  THANK YOU  =====';
%         disp(expe)
%         disp(scr)
%         disp(stim)
%         disp(sounds)
    %--------------------------------------------------------------------------
    precautions(scr.w, 'on');
    
    function px=convertVA2px(VA)
       % px=scr.ppBymm *10*VA2cm(VA,scr.distFromScreen); 
         px= VA.*scr.VA2pxConstant;
%         %correct for when subpixel value is obtained
%         if px==0
%             px=ceil(scr.ppBymm *10*VA2cm(VA,scr.distFromScreen));
%         end
    end
end
