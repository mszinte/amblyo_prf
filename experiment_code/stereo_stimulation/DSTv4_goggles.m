function DSTv4_goggles(initialParam)
%
% GOGGLES version of DST (alternating screen for LE/RE)
%
%----------------------------------------------------------------------------------------------------
% Running comments: run this function to:
%       -check stereoscopic device display
%       -calibrate screen contrast / position 
%       -check the resulting fusion
%----------------------------------------------------------------------------------------------------
% STaM - DST Project [Stereo-Training and MRI]
% Apr 2014 - Berkeley
%-----------------------------------------------------------------------
%
%================== Fusion Training v3 ====================================
%   Amblyopic participants have to go through a fusion training to be sure that:
%       -participants can fuse coarsly (anti-suppression)
%       -participants can fuse finely (absence of diplopia)
%
%   This function does:
%           - initialization of a manual calibration adjusting each eye contrast, and frame position and the alternating flicker (defaut: none)
%           - check anti-suppression and absence of diplopia (fusions) with a simple quick test (approx. 30 trials)
%
%=======================================================================
% Stimuli: First, a 23deg x 17deg frame and a binocular fixation cross. Then binocular dots moving, to check diplopia.
%   Then monocular moving dots (or small Gabors) in small binocular moving circles. Final version: all randomized
%   All dots/Gabors stimuli can all be presented in two areas:
%       -a 8deg x 16deg square 1deg left or right from fixation (for dots-circles only and like fMRI/stereotest stimuli)
%       -a 3deg x 3deg square 10 arcmin above or below fixation (for Gabors-circles only and like in training stimuli)
%
% Task: First fuse frame and cross. If the cross/frame are in diplopia, the subject presses space and the manual calibration is redone.
%       For the dots, how many are presented? If diplopia occurs, the double number of dots will be reported (10 trials).
%       For the dots / Gabors in circles, how many are presented? If suppression occurs, no dot, or less dots will be reported (10 trials).
%
% Specials:
% Warnings:
%------------------------------------------------------------------------

try
    clc
    Box=23;
    if Box==19
        cd([paths(Box),'fMRI - stimulation',filesep]);
    elseif Box==23
        cd(paths(Box));    
    end
    paths(Box)
    dataFilePath = ['dataFiles',filesep];
    
%==========================================================================
%                           QUICK PARAMETERS
%==========================================================================
  
    %===================== INPUT MODE ==============================
    %1: User  ; 2: Robot
    %The robot mode allows to test the experiment with no user awaitings
    %or long graphical outputs, just to test for obvious bugs
    inputMode=1;
    %==================== QUICK MODE ==============================
    %1: ON  ; 2: OFF
    %The quick mode allows to skip all the input part at the beginning of
    %the experiment to test faster for what the experiment is.
    quickMode=2;
    %==================== DISPLAY MODE ==============================
    %1: ON  ; 2: OFF
    %In Display mode, some chosen variables are displayed on the screen
    displayMode=2;
    %==================== STEREO MODE ==============================
    %1: ON  ; 2: OFF
    %In stereo mode, can work with 3D goggles by switching images through
    %a COM port command.
    stereoMode=1;
    %===============================================================
    %----- mode related stuff ---%
    if quickMode==2
        name=[nameInput,'_DST'];
        DE=str2double(input('Non-amblyopic Eye (1 for Left; 2 for Right):  ', 's'));
       % language=input('Language (fr for french; en for english):  ', 's');
    else
        name='defaut_DST';
        DE = 2;
    end
    
    
%=========  STARTERS =================================================== %
%   Initialize and load experiment settings (window and stimulus)
%--------------------------------------------------------------------------        
    %first check is file exists for that name
    alreadyStarted=exist([dataFilePath,name,'.mat'],'file')==2;
    
    %if file exist but its default, delete and start afresh
    if quickMode==1 && alreadyStarted>0; delete([dataFilePath,name,'.mat']); delete([dataFilePath,name,'.txt']); alreadyStarted=0; end 

    if alreadyStarted==0 %intialize
        %--------------------------------------------------------------------------
        %   LOAD EXPERIMENTAL PARAMETERS FROM A SEPARATE FILE
        %--------------------------------------------------------------------------
        [expe,scr,stim,sounds]=globalParametersDSTv4_goggles(0,Box);
        if exist('parameters','var')
            %special parameters to change after loading
            disp parameters
        end
        file=name;      
    else
        %if the file exists and its not defaut, just load it - actually that should never happen, so crash it
        disp('The file exists! Be sure of what you are doing before removing this (crashing) checkpoint')
        xxx
        disp('Name exists: load previous data and parameters')
        load([dataFilePath,name,'.mat'])
        scr.w=Screen('OpenWindow',scr.screenNumber, sc(scr.backgr,scr.box), [], 32, 2);
        precautions(scr.w, 'on');
    end

    %----- ROBOT MODE ------%
    %when in robot mode, make all timings very short
    if inputMode==2
        stim.duration                  = 0.001;
    end
    
    %==========================
    %   STEREO MODE - OPEN COM PORT
    %==========================
        if stereoMode==1
            %Closes any open COM port sessions to the Stereo Adapter
            g = instrfind;
            if ~isempty(g);
                fclose(g);
            end
            disp('Connect with COM2-stereoAdapter...')
            %Set up the COM port for the Stereo Adapter
            expe.portCOM = serial('COM2','BaudRate',57600, 'DataBits', 8, 'FlowControl', 'none', 'Parity', 'none', 'StopBits', 1);
            fopen(expe.portCOM);
            fwrite(expe.portCOM,'2', 'char'); % set the 3D control to manual mode
        else
            expe.portCOM = 0;
        end
    %--------------------------------------------------------------------------
    %      Dummy frame in stereo mode
    %--------------------------------------------------------------------------
            if stereoMode==1
                disp('Dummy stereo frame')
                fwrite(expe.portCOM,'a','char');
                Screen('FillRect', scr.w ,sc(scr.backgr,scr.box)) ; 
                flip(inputMode, scr.w);
            end
            disp('-------------------------------------------------------')  
    % Initialisation of variables
        expe.DE = DE;
        calib.leftContr=stim.frameContrast;
        calib.rightContr=stim.frameContrast;
        calib.leftUpShift=0;
        calib.rightUpShift=0;
        calib.leftLeftShift=0;
        calib.rightLeftShift=0;
        calib.flickering=0;
            
    expe.startTime=GetSecs;
    calib1=0; calib2=0; %flags to move on next step
    while calib1 == 0 || calib2 ==0 
        
        % ===  MANUAL CALIBRATIONS FOR CONTRAST AND POSITION   === %
        if inputMode==1 
            if calib1 == 0;
                [calib]=calibration_goggles1(expe,scr,stim,sounds, inputMode, displayMode,calib,stereoMode);
                calib1=1;
            end
        else %except when robot mode
            calib.leftContr=0.96;   calib.rightContr=0.96;  calib.leftUpShift=0;  calib.rightUpShift=0;  calib.leftLeftShift=0;  calib.rightLeftShift=0;  calib.flickering=0;
        end
        
        if calib2 == 0 %enter horizontal calibration
            [calib]=calibration_goggles2(expe,scr,stim,sounds, inputMode, displayMode,calib,stereoMode);
            calib2=1;
        end
        

    end
    

%later, most codes will load directly the following variables 
    leftContr = calib.leftContr;   rightContr = calib.rightContr;  leftUpShift = calib.leftUpShift;
    rightUpShift = calib.rightUpShift;  leftLeftShift = calib.leftLeftShift;  rightLeftShift = calib.rightLeftShift;  
    flickering = calib.flickering;

    
    %--------------------------------------------------------------------------
    %   SAVE AND QUIT
    %--------------------------------------------------------------------------
    %===== SAVE ===%
    disp('Saving...')
    disp('-------------------------------------------------------')  
    if inputMode==2 || quickMode==1 %if robot or quickmode, do all blocks
        %dont save
         clear quickMode inputMode displayMode stereoMode
         save([dataFilePath,file])
        saveAll([dataFilePath,file,'.mat'],[dataFilePath,file,'.txt'])
    else
        clear quickMode inputMode displayMode stereoMode
        save([dataFilePath,file])
        saveAll([dataFilePath,file,'.mat'],[dataFilePath,file,'.txt'])
    end
    
    
    %===== QUIT =====%
    precautions(scr.w, 'off');
    warnings

    
catch err   %===== DEBUGING =====%
    disp(err)
    rethrow(err);
    save([dataFilePath,name,'-crashlog'])
    saveAll([dataFilePath,name,'-crashlog.mat'],[dataFilePath,name,'-crashlog.txt'])
    warnings
    if exist('scr','var'); 
        precautions(scr.w, 'off'); 
        Screen('Close',scr.LEtxt);
        Screen('Close',scr.REtxt);
    end
    
    

end
end





