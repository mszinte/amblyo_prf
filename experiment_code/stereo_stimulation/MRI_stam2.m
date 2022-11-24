function MRI_stam2(initialParam)
%------------------------------------------------------------------------
%  MRI_stam2 is a program to present stereoscopic stimuli in the scanner.
% It is part of :
% STaM Project [Stereo-Training and MRI]
% Sep 2014 - Berkeley
%-----------------------------------------------------------------------
%   It does: -  initialization
%            -  choose and start each different block
%            -  save and quit
%-----------------------------------------------------------------------
% Stimuli: dynamic RDS in 2 squares (one left of fixation, one right). We use sharp dots.
%
%
% Task: attentional
%
%------------------------------------------------------------------------
% Structure:
%   Displays the stimuli and get the response for attentional task
%   Many blocks (probably 16) give a run - all runs are identical, not all blocks
%   Each time the code is run so that one full run/EPI is finished, it 
%   saves data about the last finished run and that opens a session (at
%   the first run finished in that session). So if a unique run is done
%   and aborted before the end, it does not count as a run / session
%   but if 3 runs are finished, this is a session (>=1 run).
%------------------------------------------------------------------------
% Controls: 
% 
%------------------------------------------------------------------------
% Analysis: the correct file to analyse individual results is:
%
%------------------------------------------------------------------------
%
%           Version: v2
%
%------------------------------------------------------------------------
%   To Do:
%=======================================================================
try
    
    clc
    if ~exist('initialParam', 'var')
        Box=23;
    else
        Box=initialParam.Box;
    end
    
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
if ~exist('initialParam', 'var')
           %===================== INPUT MODE ==============================
            %1: User  ; 2: Robot 
            %The robot mode allows to test the experiment with no user awaitings
            %or long graphical outputs, just to test for obvious bugs
            inputMode=1; 
            %==================== QUICK MODE ==============================
            %1: ON  ; 2: OFF 
            %The quick mode allows to skip all the input part at the beginning of
            %the experiment to test faster for what the experiment is.
            quickMode=1; 
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
else
    disp('Use wrapper parameters');
    inputMode=initialParam.inputMode;
    quickMode=initialParam.quickMode;
    displayMode=initialParam.displayMode;
end


            %----- mode related stuff ---%
            if quickMode==2
                name=nameInput;
                nameDST=[input('Enter name given for DST: ','s'),'_DST'];
                language='en';
               % language=input('Language (fr for french; en for english):  ', 's');
                DE=str2double(input('Non-amblyopic Eye (1 for Left; 2 for Right):  ', 's'));
            else
                name='defaut';
                nameDST='defaut_DST'; %REMOVE
                language='en';
                DE=2;
            end
            
            %=============%=============
            % STEREO MODE - OPEN COM PORT
            %=============%=============
            if stereoMode==1
                %Closes any open COM port sessions to the Stereo Adapter
                    g = instrfind;   
                    if ~isempty(g); 
                        fclose(g);   
                    end

                %Set up the COM port for the Stereo Adapter
                    portCOM = serial('COM2','BaudRate',57600, 'DataBits', 8, 'FlowControl', 'none', 'Parity', 'none', 'StopBits', 1);
                    fopen(portCOM);
                    fwrite(portCOM,'2', 'char'); % set the 3D control to manual mode
            else
                portCOM = 0;
            end
    %=========  STARTERS =================================================== %
    %Initialize and load experiment settings (window and stimulus)
    file=[name,'_MRI'];
    sessionFile = [name,'_sessionFile.mat'];

    %first check is session file exists for that name
            alreadyStarted=exist([dataFilePath,sessionFile])==2;
            
        %=============   DEAL WITH PREVIOUS SESSIONS =================%
          if alreadyStarted==1 %already started - load current run number and session number from the session file
                load([dataFilePath,sessionFile]);
                sessionNb = sessionNb+1;
                runNb = runNb+1;
                disp('Loaded session file.');
          else
              sessionNb=1;
              runNb=1;
               disp('First session.');
          end
          
      fileForThatSession = [file,'_',num2str(sessionNb)];
      
       %     %if file exist but its default, delete and start afresh
        %    if quickMode==1 && alreadyStarted==1; delete([file,'.mat']); delete([file,'.txt']); alreadyStarted=0; end 
            
                
                %=============   LOAD ALL PARAMETERS =================%
                [expe,scr,stim,sounds]=globalParametersStam2(0,Box); 

                expe.DE = DE;
                expe.breakNb=0;
                expe.file=file;
                expe.feedback = 0;
                disp(expe.name)
                expe.startTime=GetSecs;
                %expe.lastBreakTime=GetSecs; %to calculate the time from the last break
                expe.date(end+1)={dateTime};    
                expe.language=language;
                runSaved=[];
                disp(['Current file for this session: ',fileForThatSession]);
                
      %----- ROBOT MODE ------%
        %when in robot mode, make all timings very short
        if inputMode==2
            stim.itemDuration                  = 0.0001;
            stim.interTrial                    = 0.0001;   
            stim.offTime                        = 0.0001;
            displayMode=2;
        end
        
    %--------------------------------------------------------------------------
    %       START THE RUN LOOP HERE
    %--------------------------------------------------------------------------
 %--------------------------------------------------------------------------
        %      Dummy frame in stereo mode
        %--------------------------------------------------------------------------
            if stereoMode==1
                disp('Dummy stereo frame')
                fwrite(portCOM,'b','char');
                Screen('FillRect', scr.w ,sc(scr.backgr,scr.box)) ; 
                flip(inputMode, scr.w);
            end
                    ShowCursor;
%       %--------------------------------------------------------------------------
%       %   load contrast and position information from the DST calibration
%       %--------------------------------------------------------------------------
 load([dataFilePath, nameDST],'leftContr','rightContr', 'leftUpShift', 'rightUpShift', 'leftLeftShift', 'rightLeftShift', 'flickering')
           expe.leftContr = leftContr; expe.rightContr =rightContr; expe.leftUpShift =leftUpShift; expe.rightUpShift =rightUpShift;
           expe.leftLeftShift=leftLeftShift; expe.rightLeftShift=rightLeftShift; expe.flickering=flickering;

%        %--------------------------------------------------------------------------
%        %   UPDATE LEFT AND RIGHT EYE COORDINATES AND CONTRAST FROM DST
%        %--------------------------------------------------------------------------
        disp('Update eye locations');
                        scr.LcenterXLine= scr.LcenterXLine - expe.leftLeftShift;
                        scr.LcenterXDot = scr.LcenterXDot - expe.leftLeftShift;
                        scr.RcenterXLine= scr.RcenterXLine - expe.rightLeftShift;
                        scr.RcenterXDot = scr.RcenterXDot - expe.rightLeftShift;
                        scr.LcenterYLine = scr.centerYLine - expe.leftUpShift;
                        scr.RcenterYLine = scr.centerYLine - expe.rightUpShift;
                        scr.LcenterYDot = scr.centerYDot - expe.leftUpShift;
                        scr.RcenterYDot = scr.centerYDot - expe.rightUpShift;
                        [stim.LmaxL,stim.LminL]=contrSym2Lum(expe.leftContr,scr.backgr); %white and black, left eye
                        [stim.LmaxR,stim.LminR]=contrSym2Lum(expe.rightContr,scr.backgr); %white and black, right eye
                        %POLARITY DEPENDENT (here equivalent to polarity 4 %Gray background, half of the dots blue light, half of the dots dark) 
                        scr.fontColor = stim.minLum;
                        stim.fixL = stim.LminL;
                        stim.fixR = stim.LminR;
    
    keepgoing = 1;
    
while keepgoing==1
        %=============   Do the BLOCK table =================%
                    %the one that says what kind of blocks will be done in the run and in what order
                    %DO HERE - this is all the blocks and the trials
                    [fullTable, nbBlocks]=initializeExp(expe);
                         
                    %initialize run-specific values
                    expe.results = nan(size(fullTable,1),18);
                    expe.nbBlocks = nbBlocks;
                    expe.nn=size(fullTable,1);
                    expe.goalCounter=expe.nn; 
                 
        %--------------------------------------------------------------------------
        %       START THE DST-like with a FUSION SCREEN
        %--------------------------------------------------------------------------
            disp('Fusion Screen');
                %fusion screen 
                %to be replaced by DST-like
            %SWAP FOR LEFT EYE
           % fusionScreen = 'Fusion Screen';  
           WaitSecs(0.5);
           keepON=1;
           while keepON
            if stereoMode==1
                fwrite(portCOM,'a','char');
            end
            Screen('FillRect', scr.LEtxt ,sc(scr.backgr,scr.box)) ; 
            Screen('DrawLine', scr.LEtxt, sc([30, 0, 0],scr.box), 0, 20, scr.res(3), 20,3)
             % ------ Big boxes (Outside frames)                      %REPLACE HASHED FRAMES WITH AN HOMOGENOUS ONE
                    Screen('FrameRect', scr.LEtxt, sc(stim.fixL,scr.box),[scr.LcenterXLine-stim.horiz.width/2,scr.LcenterYLine-stim.vert.height/2,scr.LcenterXLine+stim.horiz.width/2,scr.LcenterYLine+stim.vert.height/2], stim.horiz.height)
            %-----fixation
                    drawDichFixation3(scr,stim,1,1,0);
                    %displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/2,scr.res(4)/2,scr.res(3),200],fusionScreen);
            Screen('DrawTexture',scr.w,scr.LEtxt)
            flip(inputMode, scr.w);
            
            %SWAP FOR RIGHT EYE
            if stereoMode==1
                fwrite(portCOM,'b','char');
            end
            Screen('FillRect', scr.REtxt ,sc(scr.backgr,scr.box)) ; 
             Screen('DrawLine', scr.REtxt, sc([0, 30, 0],scr.box), 0, 40, scr.res(3), 40,3)
              % ------ Big boxes (Outside frames)                      %REPLACE HASHED FRAMES WITH AN HOMOGENOUS ONE
                    Screen('FrameRect', scr.REtxt, sc(stim.fixR,scr.box),[scr.RcenterXLine-stim.horiz.width/2,scr.RcenterYLine-stim.vert.height/2,scr.RcenterXLine+stim.horiz.width/2,scr.RcenterYLine+stim.vert.height/2], stim.horiz.height)
             %-----fixation
                     drawDichFixation3(scr,stim,2,1,0);
                     %displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/2,scr.res(4)/2,scr.res(3),200],fusionScreen);
            Screen('DrawTexture',scr.w,scr.REtxt)
            flip(inputMode, scr.w);
                if KbCheck==1                 
                    keepON=0;
                end
           end
                %Adapted DST here
                
        %--------------------------------------------------------------------------
        %      WAIT SCREEN - wait for TTL pulse telling the EPI started
        %--------------------------------------------------------------------------
        disp('Waiting for TTL');
            %show waiting screen
            waitingScreen1 = ['Waiting Screen ... connecting with the scanner.'];
            waitingScreen2 = ['Current Run is ',num2str(runNb),'.'];
            %SWAP FOR LEFT EYE 
            if stereoMode==1
                fwrite(portCOM,'a','char');
            end
            %Screen('FillRect', scr.w ,sc(scr.backgr,scr.box)) ; 
            displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/6,scr.res(4)/2,scr.res(3),200],waitingScreen1);
            displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/6,scr.res(4)/2+100,scr.res(3),200],waitingScreen2);
            % if stereoMode==1
                flip(inputMode, scr.w);
           %  end
            
            %SWAP FOR RIGHT EYE 
            if stereoMode==1
                fwrite(portCOM,'b','char');
            end
           %     Screen('FillRect', scr.w ,sc(scr.backgr,scr.box)) ; 
          %  end
            displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/6,scr.res(4)/2,scr.res(3),200],waitingScreen1);
            displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/6,scr.res(4)/2+100,scr.res(3),200],waitingScreen2);
            flip(inputMode, scr.w);
            
            %wait for TTL, coded 5 (check)
            getResponseKb(scr.keyboardNum,0,inputMode,[55,59],'',[],1,0,0,0); 
            %can go here only if TTL is received or key 5 is pressed because only that key is allowed above
            
        %--------------------------------------------------------------------------
        %      FIXATION SCREEN (15 sec)
        %--------------------------------------------------------------------------
        disp('Fixation screen');
            %LEFT EYE SWAP STEREOADAPTER 
            if stereoMode==1
                fwrite(portCOM,'a','char');
            end
            %--- Background
                Screen('FillRect', scr.LEtxt, sc(scr.backgr,scr.box));
            % ------ Big boxes (Outside frames)   %REPLACED HASHED FRAMES WITH AN HOMOGENOUS ONE
                Screen('FrameRect', scr.LEtxt, sc(stim.fixL,scr.box),[scr.LcenterXLine-stim.horiz.width/2,scr.LcenterYLine-stim.vert.height/2,scr.LcenterXLine+stim.horiz.width/2,scr.LcenterYLine+stim.vert.height/2], stim.horiz.height)
            %-----fixation
            drawDichFixation3(scr,stim,1,1);
            Screen('DrawTexture',scr.w,scr.LEtxt)
                [dummy, fixONLeft]=flip(inputMode, scr.w);

            
            %RIGHT EYE SWAP STEREOADAPTER 
            if stereoMode==1
                fwrite(portCOM,'b','char');
                %--- Background
            end
               Screen('FillRect', scr.REtxt, sc(scr.backgr,scr.box));
           % ------ Big boxes (Outside frames) %REPLACE HASHED FRAMES WITH AN HOMOGENOUS ONE
                Screen('FrameRect', scr.REtxt, sc(stim.fixR,scr.box),[scr.RcenterXLine-stim.horiz.width/2,scr.RcenterYLine-stim.vert.height/2,scr.RcenterXLine+stim.horiz.width/2,scr.RcenterYLine+stim.vert.height/2], stim.horiz.height)
            %-----fixation
            drawDichFixation3(scr,stim,2,1);
            Screen('DrawTexture',scr.w,scr.REtxt)
            [dummy, fixONRight]=flip(inputMode, scr.w);       
            
            while (GetSecs - fixONRight)<stim.fixationDuration/1000  ; end
                
        %--------------------------------------------------------------------------
        %     RUN THE BLOCKS 
        %--------------------------------------------------------------------------
         disp('Starting the blocks');
         startRunTime = GetSecs;
             for b=1:expe.nbBlocks
                %extract the trials for that block and pass them to trialStam2
                    blockTable = fullTable(fullTable(:,12)==b,:);
                    expe.beginInterTrial=GetSecs;%?
                    [trials, expe]=trialStam2(blockTable, stim,scr,expe, sounds, inputMode, displayMode,stereoMode, portCOM);
                    runSaved = [runSaved;trials];

                %SAVE temp AROUND HERE
                    save([dataFilePath,fileForThatSession,'_temp.mat'],'runSaved','runNb','sessionNb');
                    
             end
        previousRunDuration = GetSecs - startRunTime;
        disp(['Measured run duration: ', num2str(previousRunDuration), ' sec']);

        %--------------------------------------------------------------------------
        %      FIXATION SCREEN (15 sec)
        %--------------------------------------------------------------------------
        disp('Fixation');
            %LEFT EYE SWAP STEREOADAPTER 
            if stereoMode==1
                fwrite(portCOM,'a','char');
            end
            %--- Background
                Screen('FillRect', scr.LEtxt, sc(scr.backgr,scr.box));
            % ------ Big boxes (Outside frames)  %REPLACED HASHED FRAMES WITH AN HOMOGENOUS ONE
                Screen('FrameRect', scr.LEtxt, sc(stim.fixL,scr.box),[scr.LcenterXLine-stim.horiz.width/2,scr.LcenterYLine-stim.vert.height/2,scr.LcenterXLine+stim.horiz.width/2,scr.LcenterYLine+stim.vert.height/2], stim.horiz.height)
            %-----fixation
            drawDichFixation3(scr,stim,1,1);
            Screen('DrawTexture',scr.w,scr.LEtxt)
                [dummy, fixONLeft]=flip(inputMode, scr.w);
            %RIGHT EYE SWAP STEREOADAPTER HERE
            if stereoMode==1
                fwrite(portCOM,'b','char');
            end
                %--- Background
               Screen('FillRect', scr.REtxt, sc(scr.backgr,scr.box));
            % ------ Big boxes (Outside frames)   %REPLACE HASHED FRAMES WITH AN HOMOGENOUS ONE
                Screen('FrameRect', scr.REtxt, sc(stim.fixR,scr.box),[scr.RcenterXLine-stim.horiz.width/2,scr.RcenterYLine-stim.vert.height/2,scr.RcenterXLine+stim.horiz.width/2,scr.RcenterYLine+stim.vert.height/2], stim.horiz.height)
            %-----fixation
            drawDichFixation3(scr,stim,2,1);
            Screen('DrawTexture',scr.w,scr.REtxt)
            [dummy, fixONRight]=flip(inputMode, scr.w);        
            while (GetSecs - fixONRight)<stim.fixationDuration/1000  ; end        
            
        %--------------------------------------------------------------------------
        %      SAVE THE SESSION FILE
        %--------------------------------------------------------------------------
            disp('Saving session file...');
            save([dataFilePath,sessionFile],'runNb','sessionNb')

        %--------------------------------------------------------------------------
        %      BREAK SCREEN + SCORE - unlimited - ALLOWS TO ESCAPE NICELY OR TO 
        %       START A NEW RUN - and UPDATE RUN NB
        %---------------------------------------------------------------------------
            disp('Break');
            disp(['Next run is ', num2str(runNb+1),'.']);
            
            %show waiting screen
            waitingScreen1 = 'Take a break.';
            waitingScreen2 = 'Press space to start or escape to stop.';
            disp(waitingScreen2);
            WaitSecs(2);
         keepON=1;
         while keepON
            %SWAP FOR LEFT EYE HERE
            if stereoMode==1
                fwrite(portCOM,'a','char');
            end
            Screen('FillRect', scr.LEtxt ,sc(scr.backgr,scr.box)) ; 
            Screen('DrawLine', scr.LEtxt, sc([30, 0, 0],scr.box), 0, 20, scr.res(3), 20,3)
             % ------ Big boxes (Outside frames)  %REPLACED HASHED FRAMES WITH AN HOMOGENOUS ONE
                Screen('FrameRect', scr.LEtxt, sc(stim.fixL,scr.box),[scr.LcenterXLine-stim.horiz.width/2,scr.LcenterYLine-stim.vert.height/2,scr.LcenterXLine+stim.horiz.width/2,scr.LcenterYLine+stim.vert.height/2], stim.horiz.height)
            %-----fixation
            drawDichFixation3(scr,stim,1,1);
          %  displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/6,scr.res(4)/2+100,scr.res(3),200],waitingScreen2);
         %   if stereoMode==1
           %     Screen('CopyWindow',scr.REtxt,scr.w)
           Screen('DrawTexture',scr.w,scr.LEtxt)
           displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/6,scr.res(4)/4,scr.res(3),200],waitingScreen1);
                flip(inputMode, scr.w);
          %  end
            
            %SWAP FOR RIGHT EYE HERE
            if stereoMode==1
                fwrite(portCOM,'b','char');
            end
                Screen('FillRect', scr.REtxt ,sc(scr.backgr,scr.box)) ; 
                Screen('DrawLine', scr.REtxt, sc([0, 30, 0],scr.box), 0, 40, scr.res(3), 40,3)
            % ------ Big boxes (Outside frames)  %REPLACED HASHED FRAMES WITH AN HOMOGENOUS ONE
                 Screen('FrameRect', scr.REtxt, sc(stim.fixR,scr.box),[scr.RcenterXLine-stim.horiz.width/2,scr.RcenterYLine-stim.vert.height/2,scr.RcenterXLine+stim.horiz.width/2,scr.RcenterYLine+stim.vert.height/2], stim.horiz.height)
            %-----fixation
            drawDichFixation3(scr,stim,2,1);
           % displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/6,scr.res(4)/2+100,scr.res(3),200],waitingScreen2);
            Screen('DrawTexture',scr.w,scr.REtxt)
            displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/6,scr.res(4)/4,scr.res(3),200],waitingScreen1);
            flip(inputMode, scr.w);
         
            keypress = getResponseKb(scr.keyboardNum,0,inputMode,[3,4],'',[],1,0,0,1); 
            if keypress == 4 %ESCAPE
                keepgoing = 0;
                keepON=0;
                disp('End of session');
            end
            if keypress == 3 %SPACE
                runNb = runNb+1;
                disp('Next run');
                keepON=0;
            end
         end
    %--------------------------------------------------------------------------
    % trialLine TABLE Summary:
    %    1:  trial #
    %    2:  pedestal condition # (always 1)
    %    3:  pedestal value in pp (always 0)
    %    4:  repetition in a block
    %    5:  value (disparity) #
    %    6:  value in pp
    %    7:  config, where is  closest stimulus 1: left (+/-) - 2: right (-/+)
    %    8:  disparity of left stim in pp
    %    9:  disparity of right stim in pp
    %    10:  disparity value in arcsec
    %    11: run # (one run is correlated or anti-correlated)
    %    12: correlated (1: yes, 2: anti)
    %    13: block # -chrono order- (one block is either +/- configuration or -/+ configuration)
    %    14:  responseKey - 55 = increment report
    %    15:  fixation duration
    %    16:  RT = stimulus duration
    %    17:  Gaze outside of area or not? (1 yes, 0 no)
    %    18:  attentional task increment: 1 = yes, 2 = no
    %--------------------------------------------------------------------------     
end

        %--------------------------------------------------------------------------
        %   SAVE AND QUIT
        %--------------------------------------------------------------------------
%              %===== SAVE ===%
%                  disp(['Duration:',num2str((GetSecs-expe.startTime)/60)]);
%                  expe.time(end+1)=(GetSecs-expe.startTime)/60;
%                  tmp=inputMode; 
                  save([dataFilePath,fileForThatSession])
                  saveAll([dataFilePath,fileForThatSession,'.mat'],[dataFilePath,fileForThatSession,'.txt'])
            %--------------------------------------------------------------------------
            % trials TABLE Summary: each row is a trial
            %    1:  trial #
            %    2:  place in the cycle of presentation of a block
            %    3:  pedestal - always 0
            %    4:  repetition in a block
            %    5:  nan
            %    6:  nan
            %    7:  config, where is  closest stimulus 1: left (-/+) - 2: right (+/-)
            %    8:  disparity of left stim in pp
            %    9:  disparity of right stim in pp
            %    10: disparity value in arcsec (of left stimulus)
            %    11: run #
            %    12: correlated (1: yes, 2: anti)
            %    13: block # -chrono order- (one block is either +/- configuration or -/+ configuration and one disp)
            %    14:  correct or not for that trial (attentional)
            %    15:  fixation duration? nan
            %    16:  RT = stimulus duration? nan
            %    17:  nan
            %    18:  attentional task increment: 1 = yes, 2 = no
            %--------------------------------------------------------------------------
            
%              %===== THANKS ===%
%                 Screen('FillRect',scr.w, sc(scr.backgr,scr.box));
%                 displaystereotext3(scr,sc(scr.fontColor,scr.box),[0,500,500,400],expe.thx.(language),1);
%                 %displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/2-250,500,500,400],thx.(expe.language))
%                 flip(tmp, scr.w);   
%                 waitForKey(scr.keyboardNum,tmp); 

            %STEREO MODE - OPEN COM PORT
            if stereoMode==1
                %Closes any open COM port sessions to the Stereo Adapter
                    g = instrfind;   
                    if ~isempty(g); 
                        fclose(g);   
                    end
             end
            
             %===== QUIT =====%
                 warnings 
                 precautions(scr.w, 'off');


catch err   %===== DEBUGING =====%
    disp(err)
    rethrow(err);
    save([dataFilePath,expe.file,'-crashlog'])
    saveAll([dataFilePath,expe.file,'-crashlog.mat'],[dataFilePath,expe.file,'-crashlog.txt'])
    warnings
    if exist('scr','var'); precautions(scr.w, 'off'); end
        if eyeTrackerMode==1; Eyelink('ShutDown');end
end
%============================================================================
end


function [fullTable, nbBlocks]=initializeExp(expe)

%do a matrix of all runs and whether it is correlated or not and then randomize
%     runList = [ones(1,expe.nbRuns), 2*ones(1,expe.nbRuns)]; %runs for correlated RDS (1) then runs for anticorrelated (2)
%     nn=2*expe.nbRuns;        idx=randsample(nn,nn,0);
%     ShuffledList=runList(idx);
    
        %for all blocks of that run, do a matrix of all blocks and randomize 
         %blockTable = [disp in arcsec, correlation (1 yes 2 anti), repeat, disp in pp]
         blockTable = [];
         for r = 1:expe.nbRepeatDisp
             for dind = 1:numel(expe.dispList)
                 d = expe.dispList(dind);
                 p=expe.dispListpp(dind);
                 for c = 1:2 %1: correlated / 2: anti correlated
                         blockTable = [blockTable; d, c, r,p];
                 end
             end
         end

         nbBlocks=size(blockTable,1);
         idx=randsample(nbBlocks,nbBlocks,0);
         ShuffledList=blockTable(idx,:);
         
        table = [];
        for block = 1:nbBlocks    %go through each block and build the trials
                  disparity = ShuffledList(block, 1);
                  correlation = ShuffledList(block, 2);
                  repeat = ShuffledList(block, 3);
                  dispPP = ShuffledList(block, 4);
                  
                 % for v=1:expe.nbValues
                 dispLeft = dispPP ; %disparity in pp for the left stimulus (positive disp are uncrossed here)
                 dispRight = -dispPP;
                 % config, where is  closest stimulus 1: left (-/+) - 2: right (+/-)
                 [dummy, config] = min([dispLeft,dispRight]);
                 for stimulus = 1:expe.nbOfPresentation
                      table=[table;stimulus,0,repeat,nan,nan,config,dispLeft, dispRight, disparity,nan,correlation, block];        
                 end 
                
%                 idx=randsample(nn,nn,0);
%                 ShuffledTable=table(idx,:);
%                 fullTable=[fullTable;ShuffledTable];
                                   % -----  TABLE --------------------------------
                                   %    1:  place in the cycle of presentation of a block
                                   %    2:  pedestal - always 0
                                   %    3:  repetition in a block
                                   %    4:  nan
                                   %    5:  nan
                                   %    6:  config, where is  closest stimulus 1: left (-/+) - 2: right (+/-)
                                   %    7:  disparity of left stim in pp
                                   %    8:  disparity of right stim in pp
                                   %    9:  disparity value in arcsec (of left stimulus)
                                   %    10: run # 
                                   %    11: correlated (1: yes, 2: anti)
                                   %    12: block # -chrono order- (one block is either +/- configuration or -/+ configuration and one disp)
                                   % ---------------------------------------------            
         
        end
        fullTable = table;

end

function quickQuit(scr)
        precautions(scr.w,'off')
              xxx
end
