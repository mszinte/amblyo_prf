function MRI_stam3(initialParam)
%------------------------------------------------------------------------
% MRI_stam3 is a program to present stereoscopic stimuli in the scanner.
% This is the EPI part to discover neural bases of stereopsis recovery 
% It is part of :
% STaM Project [Stereo-Training and MRI]
% Mar 2015 - Berkeley
%-----------------------------------------------------------------------
% Difference with MRI_stam2 - basically timing is correct by changing the
%   way trialStam works and many other stuff after that
%-----------------------------------------------------------------------
%   It does: -  initialization
%            -  choose and start each different block
%            -  save and quit
%-----------------------------------------------------------------------
% Stimuli: dynamic RDS in 2 squares (one left of fixation, one right). We use sharp dots.
%
% Task: attentional on fixation (light increment)
%
%------------------------------------------------------------------------
% Structure:
%   Displays the stimuli and get the response for attentional task
%   Many blocks (probably 16) give a run - all runs are identical (not for 
%   block order though), not all blocks are identical.
%   Each time the code is run so that one full run/EPI is finished, it 
%   saves data about the last finished run and that opens a session (at
%   the first run finished in that session). So if a unique run is done
%   and aborted before the end, it does not count as a run / session
%   but if 3 runs are finished, this is a session (>=1 run).
%------------------------------------------------------------------------
% Controls: 
% escape
% button 1 for the task, button 5 for TTL
%------------------------------------------------------------------------
% Analysis: the correct file to analyse individual results is:
%
%------------------------------------------------------------------------
%
%           Version: v3
%
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
    stereoMode = initialParam.stereoMode;
end

        %----- mode related stuff ---%
            if quickMode==2
                name=nameInput;
                nameDST=[input('Enter name given for DST: ','s'),'_DST'];
                DE=str2double(input('Non-amblyopic Eye (1 for Left; 2 for Right):  ', 's'));
            else
                name='defaut';
                nameDST='defaut_DST'; 
                DE=2;
            end
            
        %====================================
        % STEREO MODE - OPEN COM PORT
        %====================================
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
            
    %=========  STARTERS ====================================================
    %   Initialize and load experiment settings (window and stimulus)
    %========================================================================
    file=[name,'_MRI'];
    sessionFile = [name,'_sessionFile.mat'];

    %=============   DEAL WITH PREVIOUS SESSIONS =================%
        %first check is session file exists for that name
          alreadyStarted=exist([dataFilePath,sessionFile])==2;
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
      
  
        %=============   LOAD ALL PARAMETERS =================%
           [expe,scr,stim,sounds]=globalParametersStam2(0,Box); 
            expe.DE = DE;
            expe.breakNb=0;
            expe.file=file;
            expe.startTime=GetSecs;
            expe.date(end+1)={dateTime};    
            runSaved=[];
            disp(['Current file for this session: ',fileForThatSession]);
            disp('-------------------------------------------------------')    
            %Change some of the parameters depending on the mode (test mode on laptop or real expe in scanner)
            if exist('initialParam', 'var') %REAL MODE
                stim.fixationDuration  = initialParam.fixationDuration; %long fixation duration
                forceCorrelated=0; 
            else                    %LAPTOP DEBUG MODE
                disp('This is quick debug/test mode - not the real mode...')
                disp('Real mode can be started by running the STAM code.')
                disp('-------------------------------------------------------')  
                disp('If understood, press a key.')
                waitForKey(scr.keyboardNum,1);
                forceCorrelated=1; %that way, all trials are correlated and we can check if feeling of depth
                stim.dotSize = 10; %avoids a bug for dot size too large with drawdots
                expe.dispListpp = ([540]/3600).*scr.VA2pxConstant; %test with 2 large disparity values, uncrossed on left
            end
                
                
      %----- ROBOT MODE ------%
        %when in robot mode, make all timings very short
        if inputMode==2
            stim.itemDuration                  = 0.0001;
            stim.interTrial                    = 0.0001;   
            stim.offTime                        = 0.0001;
            displayMode=2;
        end
        
        %--------------------------------------------------------------------------
        %      Dummy frame in stereo mode
        %--------------------------------------------------------------------------
            if stereoMode==1
                disp('Dummy stereo frame')
                fwrite(portCOM,'a','char');
                Screen('FillRect', scr.w ,sc(scr.backgr,scr.box)) ; 
                flip(inputMode, scr.w);
            end
            ShowCursor;
            
       %--------------------------------------------------------------------------
       %   load contrast and position information from the DST calibration
       %--------------------------------------------------------------------------
           load([dataFilePath, nameDST],'leftContr','rightContr', 'leftUpShift', 'rightUpShift', 'leftLeftShift', 'rightLeftShift', 'flickering')
           expe.leftContr = leftContr; expe.rightContr =rightContr; expe.leftUpShift =leftUpShift; expe.rightUpShift =rightUpShift;
           expe.leftLeftShift=leftLeftShift; expe.rightLeftShift=rightLeftShift; expe.flickering=flickering;

        %--------------------------------------------------------------------------
        %   UPDATE LEFT AND RIGHT EYE COORDINATES AND CONTRAST FROM DST
        %--------------------------------------------------------------------------
            disp('Update eye''s image locations.');
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
            %POLARITY DEPENDENT (below equivalent to polarity 4 %Gray background, half of the dots blue light, half of the dots dark)
            scr.fontColor = stim.minLum;
            stim.fixL = stim.LminL;
            stim.fixR = stim.LminR;
    
    
%--------------------------------------------------------------------------
%       START THE RUN LOOP 
%--------------------------------------------------------------------------
keepgoing = 1;
    while keepgoing==1
        %=============   Do the BLOCK table =================%
            %the one that says what kind of blocks will be done in the run and in what order
            %this is all the blocks and the trials
            [fullTable, nbBlocks]=initializeExp(expe);
            
            %initialize run-specific values
            %expe.results = nan(size(fullTable,1),18);
            expe.nbBlocks = nbBlocks;
            expe.nn=size(fullTable,1);
            expe.goalCounter=expe.nn;
            
            %--------------------------------------------------------------------------
            %       START a DST-like FUSION SCREEN
            %--------------------------------------------------------------------------
                disp('Step 1: Fusion Screen - check for correct stereo displaying + correct fusion.');
                %SWAP FOR LEFT EYE
                   WaitSecs(0.5);
                   keepON=1;
                   while keepON %stereomode does not work if we don't constantly switch between images
                        if stereoMode==1
                            fwrite(portCOM,'b','char');
                        end
                        %----- Clean up
                            Screen('FillRect', scr.LEtxt ,sc(scr.backgr,scr.box)) ; 
                        %------ Big boxes (Outside frames)                      %REPLACE HASHED FRAMES WITH AN HOMOGENOUS ONE
                            Screen('FrameRect', scr.LEtxt, sc(stim.fixL,scr.box),[scr.LcenterXLine-stim.horiz.width/2,scr.LcenterYLine-stim.vert.height/2,scr.LcenterXLine+stim.horiz.width/2,scr.LcenterYLine+stim.vert.height/2], stim.horiz.height)
                        %-----fixation
                            drawDichFixation3(scr,stim,1,1,0);
                        %-----draw fusion lines ---> one horizontal top, one vertical left -RED IN LE
                            Screen('DrawLine', scr.LEtxt, sc([30, 0, 0],scr.box), 0, 100, scr.res(3), 100,3)
                            Screen('DrawLine', scr.LEtxt, sc([30, 0, 0],scr.box), 100, 0, 100, scr.res(4),3)
                        %-----SHOW    
                            Screen('DrawTexture',scr.w,scr.LEtxt)
                            flip(inputMode, scr.w);

                        %SWAP FOR RIGHT EYE
                        if stereoMode==1
                            fwrite(portCOM,'a','char');
                        end
                         %----- Clean up
                            Screen('FillRect', scr.REtxt ,sc(scr.backgr,scr.box)) ; 
                         % ------ Big boxes (Outside frames)                      %REPLACE HASHED FRAMES WITH AN HOMOGENOUS ONE
                            Screen('FrameRect', scr.REtxt, sc(stim.fixR,scr.box),[scr.RcenterXLine-stim.horiz.width/2,scr.RcenterYLine-stim.vert.height/2,scr.RcenterXLine+stim.horiz.width/2,scr.RcenterYLine+stim.vert.height/2], stim.horiz.height)
                         %-----fixation
                            drawDichFixation3(scr,stim,2,1,0);
                         %-----draw fusion lines ---> one horizontal top, one vertical left - GREEN IN RE
                            Screen('DrawLine', scr.REtxt, sc([0, 30, 0],scr.box), 0, 150, scr.res(3), 150,3)
                            Screen('DrawLine', scr.REtxt, sc([0, 30, 0],scr.box), 150, 0, 150, scr.res(4),3)
                         %-----SHOW   
                            Screen('DrawTexture',scr.w,scr.REtxt)
                            flip(inputMode, scr.w);
                            
                            % QUIT LOOP WHEN A KEY IS PRESSED
                            if KbCheck==1                 
                                keepON=0;
                            end
                   end

            %--------------------------------------------------------------------------
            %      WAIT SCREEN - wait for TTL pulse telling the EPI started
            %--------------------------------------------------------------------------
                disp('Step 2: Waiting for TTL pulse from scanner.');
                    %--show waiting screen
                        waitingScreen1 = ['Waiting Screen ... connecting with the scanner.'];
                        waitingScreen2 = ['Current Run is ',num2str(runNb),'.'];
                        
                    %SWAP FOR LEFT EYE 
                    if stereoMode==1
                        fwrite(portCOM,'b','char');
                    end
                        displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/6,scr.res(4)/2,scr.res(3),200],waitingScreen1);
                        displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/6,scr.res(4)/2+100,scr.res(3),200],waitingScreen2);
                        flip(inputMode, scr.w);

                    %SWAP FOR RIGHT EYE 
                    if stereoMode==1
                        fwrite(portCOM,'a','char');
                    end
                        displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/6,scr.res(4)/2,scr.res(3),200],waitingScreen1);
                        displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/6,scr.res(4)/2+100,scr.res(3),200],waitingScreen2);
                        flip(inputMode, scr.w);

                    %wait for TTL, coded 5 
                    getResponseKb(scr.keyboardNum,0,inputMode,[59],'',[],1,0,0,0); 
                    
            %-- can go below only if TTL is received or key 5 is pressed because only that key is allowed above

            %--------------------------------------------------------------------------
            %      FIXATION SCREEN (15.7 sec)
            %--------------------------------------------------------------------------
                startRunTime = GetSecs;
                disp('Step 3: Fixation screen');
                    %LEFT EYE SWAP STEREOADAPTER 
                    if stereoMode==1
                        fwrite(portCOM,'b','char');
                    end
                    %----- Clean up
                        Screen('FillRect', scr.LEtxt, sc(scr.backgr,scr.box));
                    %------ Big boxes (Outside frames)   %REPLACED HASHED FRAMES WITH AN HOMOGENOUS ONE
                        Screen('FrameRect', scr.LEtxt, sc(stim.fixL,scr.box),[scr.LcenterXLine-stim.horiz.width/2,scr.LcenterYLine-stim.vert.height/2,scr.LcenterXLine+stim.horiz.width/2,scr.LcenterYLine+stim.vert.height/2], stim.horiz.height)
                    %-----fixation
                        drawDichFixation3(scr,stim,1,1);
                    %----SHOW
                        Screen('DrawTexture',scr.w,scr.LEtxt)
                        [dummy, fixONLeft]=flip(inputMode, scr.w);


                    %RIGHT EYE SWAP STEREOADAPTER 
                    if stereoMode==1
                        fwrite(portCOM,'a','char');
                    end
                    %----- Clean up
                       Screen('FillRect', scr.REtxt, sc(scr.backgr,scr.box));
                    %------ Big boxes (Outside frames) %REPLACE HASHED FRAMES WITH AN HOMOGENOUS ONE
                        Screen('FrameRect', scr.REtxt, sc(stim.fixR,scr.box),[scr.RcenterXLine-stim.horiz.width/2,scr.RcenterYLine-stim.vert.height/2,scr.RcenterXLine+stim.horiz.width/2,scr.RcenterYLine+stim.vert.height/2], stim.horiz.height)
                    %-----fixation
                        drawDichFixation3(scr,stim,2,1);
                    %----SHOW
                        Screen('DrawTexture',scr.w,scr.REtxt)
                        [dummy, fixONRight]=flip(inputMode, scr.w);       

                    while (GetSecs - fixONRight)<stim.fixationDuration/1000  ; end

            %--------------------------------------------------------------------------
            %     RUN THE BLOCKS (block loop) 
            %--------------------------------------------------------------------------
                 disp('Step 4: Starting the blocks.');
                     for b=1:expe.nbBlocks
                        %extract the trials for that block and pass them to trialStam2
                            blockTable = fullTable(fullTable(:,12)==b,:);
                            expe.beginInterTrial=GetSecs;
                            [trials, expe, perf]=trialStam3(blockTable, stim,scr,expe, sounds, inputMode, displayMode,stereoMode, portCOM, runNb,forceCorrelated);
                            runSaved = [runSaved;trials];
                            performance(b,1:4,runNb) =[perf.hit,perf.FA,perf.miss,perf.CR];

                        %SAVE temp file below
                            save([dataFilePath,fileForThatSession,'_temp.mat'],'runSaved','runNb','sessionNb');

                     end

            %--------------------------------------------------------------------------
            %      FIXATION SCREEN (15.7 sec)
            %--------------------------------------------------------------------------
                disp('Step 5: Fixation screen');
                 %LEFT EYE SWAP STEREOADAPTER 
                    if stereoMode==1
                        fwrite(portCOM,'b','char');
                    end
                    %---Background
                        Screen('FillRect', scr.LEtxt, sc(scr.backgr,scr.box));
                    % ------ Big boxes (Outside frames)  %REPLACED HASHED FRAMES WITH AN HOMOGENOUS ONE
                        Screen('FrameRect', scr.LEtxt, sc(stim.fixL,scr.box),[scr.LcenterXLine-stim.horiz.width/2,scr.LcenterYLine-stim.vert.height/2,scr.LcenterXLine+stim.horiz.width/2,scr.LcenterYLine+stim.vert.height/2], stim.horiz.height)
                    %-----fixation
                        drawDichFixation3(scr,stim,1,1);
                    %----SHOW
                        Screen('DrawTexture',scr.w,scr.LEtxt)
                        [dummy, fixONLeft]=flip(inputMode, scr.w);
                        
                  %RIGHT EYE SWAP STEREOADAPTER 
                    if stereoMode==1
                        fwrite(portCOM,'a','char');
                    end
                    %---Background
                       Screen('FillRect', scr.REtxt, sc(scr.backgr,scr.box));
                    % ------ Big boxes (Outside frames)   %REPLACE HASHED FRAMES WITH AN HOMOGENOUS ONE
                        Screen('FrameRect', scr.REtxt, sc(stim.fixR,scr.box),[scr.RcenterXLine-stim.horiz.width/2,scr.RcenterYLine-stim.vert.height/2,scr.RcenterXLine+stim.horiz.width/2,scr.RcenterYLine+stim.vert.height/2], stim.horiz.height)
                    %-----fixation
                    drawDichFixation3(scr,stim,2,1);
                    %----SHOW
                        Screen('DrawTexture',scr.w,scr.REtxt)
                        [dummy, fixONRight]=flip(inputMode, scr.w);   
                        
                    while (GetSecs - fixONRight)<stim.fixationDuration/1000  ; end        

            %--------------------------------------------------------------------------
            %      SAVE THE SESSION 
            %--------------------------------------------------------------------------
                previousRunDuration = GetSecs - startRunTime;
                disp(['Step 6: End of run - measured run duration: ', num2str(previousRunDuration), ' sec']);
                disp('Step 7: Saving run data and session file.');
                save([dataFilePath,sessionFile],'runNb','sessionNb') %session file
                save([dataFilePath,fileForThatSession]) %everythinge else
                
            %--------------------------------------------------------------------------
            %      BREAK SCREEN + SCORE - ALLOWS TO ESCAPE NICELY OR TO 
            %       START A NEW RUN - and UPDATE RUN NB
            %---------------------------------------------------------------------------
                runperf=sum(performance(:,:,runNb));
                score(runNb) = 100.*(runperf(1)+runperf(4)-runperf(3)-runperf(2))./sum(runperf);
                disp('Break time (max 45 sec)');
                disp(['Score is: ', num2str(score(runNb)),'%'])
                disp('Before going on, press space and check for fusion.')
               
               %--show break screen
                    waitingScreen1 = 'Take a break but do not move :)';
                    waitingScreen3 = ['Your score is ', num2str(score(runNb)),'%'];
                    WaitSecs(1);   
                    keepON=1;
                    while keepON
                        %--SWAP FOR LEFT EYE 
                        if stereoMode==1
                            fwrite(portCOM,'b','char');
                        end
                        %---CLEAN UP
                            Screen('FillRect', scr.LEtxt ,sc(scr.backgr,scr.box)) ; 
                        %---write message
                            displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/6,scr.res(4)/4,scr.res(3),200],waitingScreen1);
                            displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/6,scr.res(4)/3,scr.res(3),200],waitingScreen3);
                        %---SHOW
                            Screen('DrawTexture',scr.w,scr.LEtxt)
                            flip(inputMode, scr.w);

                      %--SWAP FOR RIGHT EYE 
                        if stereoMode==1
                            fwrite(portCOM,'a','char');
                        end
                        %---CLEAN UP
                            Screen('FillRect', scr.REtxt ,sc(scr.backgr,scr.box)) ; 
                       %---write message
                            displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/6,scr.res(4)/4,scr.res(3),200],waitingScreen1);
                            displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/6,scr.res(4)/3,scr.res(3),200],waitingScreen3);
                       %---SHOW
                            Screen('DrawTexture',scr.w,scr.REtxt)
                            flip(inputMode, scr.w);
                       %--- Escape this whenever a key is pressed
                        keypress = getResponseKb(scr.keyboardNum,0,inputMode,3,'',[],1,0,0,1); 
                        if keypress == 3 %SPACE
                            keepON=0;
                        end
                    end
                    
               %-show fusion screen
                disp('Fusion Screen')
                disp(waitingScreen2);
                disp(['Next run is ', num2str(runNb+1),'.']);
                disp('Press space to start or escape to stop.')
                disp('-------------------------------------------------------') 
                WaitSecs(1);  
                keepON=1;
                while keepON
                  %--SWAP FOR LEFT EYE 
                    if stereoMode==1
                        fwrite(portCOM,'b','char');
                    end
                    %---CLEAN UP
                        Screen('FillRect', scr.LEtxt ,sc(scr.backgr,scr.box)) ; 
                    %------ Big boxes (Outside frames)  %REPLACED HASHED FRAMES WITH AN HOMOGENOUS ONE
                        Screen('FrameRect', scr.LEtxt, sc(stim.fixL,scr.box),[scr.LcenterXLine-stim.horiz.width/2,scr.LcenterYLine-stim.vert.height/2,scr.LcenterXLine+stim.horiz.width/2,scr.LcenterYLine+stim.vert.height/2], stim.horiz.height)
                    %-----fixation
                        drawDichFixation3(scr,stim,1,1);
                    %---write message
                        displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/6,scr.res(4)/4,scr.res(3),200],waitingScreen1);
                        displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/6,scr.res(4)/3,scr.res(3),200],waitingScreen3);
                    %-----draw fusion lines ---> one horizontal top, one vertical left -RED IN LE
                      %  Screen('DrawLine', scr.LEtxt, sc([30, 0, 0],scr.box), 0, 100, scr.res(3), 100,3)
                      %  Screen('DrawLine', scr.LEtxt, sc([30, 0, 0],scr.box), 100, 0, 100, scr.res(4),3)
                    %---SHOW
                        Screen('DrawTexture',scr.w,scr.LEtxt)
                        flip(inputMode, scr.w);

                  %--SWAP FOR RIGHT EYE 
                    if stereoMode==1
                        fwrite(portCOM,'a','char');
                    end
                    %---CLEAN UP
                        Screen('FillRect', scr.REtxt ,sc(scr.backgr,scr.box)) ; 
                    %------ Big boxes (Outside frames)  %REPLACED HASHED FRAMES WITH AN HOMOGENOUS ONE
                        Screen('FrameRect', scr.REtxt, sc(stim.fixR,scr.box),[scr.RcenterXLine-stim.horiz.width/2,scr.RcenterYLine-stim.vert.height/2,scr.RcenterXLine+stim.horiz.width/2,scr.RcenterYLine+stim.vert.height/2], stim.horiz.height)
                    %-----fixation
                        drawDichFixation3(scr,stim,2,1);
                    %---write message
                        displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/6,scr.res(4)/4,scr.res(3),200],waitingScreen1);
                        displayText(scr,sc(scr.fontColor,scr.box),[scr.res(3)/6,scr.res(4)/3,scr.res(3),200],waitingScreen3);
                    %-----draw fusion lines ---> one horizontal top, one vertical left - GREEN IN RE
                        %    Screen('DrawLine', scr.REtxt, sc([0, 30, 0],scr.box), 0, 150, scr.res(3), 150,3)
                        %    Screen('DrawLine', scr.REtxt, sc([0, 30, 0],scr.box), 150, 0, 150, scr.res(4),3)
                    %---SHOW
                        Screen('DrawTexture',scr.w,scr.REtxt)
                        flip(inputMode, scr.w);

                    %--- Escape this whenever a key is pressed
                        keypress = getResponseKb(scr.keyboardNum,0,inputMode,[3,4],'',[],1,0,0,1); 
                        if keypress == 4 %ESCAPE
                            keepgoing = 0;
                            keepON=0;
                            disp('End of session');
                        end
                        if keypress == 3 %SPACE
                            runNb = runNb+1;
                            disp('Next run starting...');
                            keepON=0;
                        end
                 end
                  
    end

        %--------------------------------------------------------------------------
        %   SAVE AND QUIT
        %--------------------------------------------------------------------------
              %===== SAVE ===%
                  save([dataFilePath,fileForThatSession])
                  saveAll([dataFilePath,fileForThatSession,'.mat'],[dataFilePath,fileForThatSession,'.txt'])

                %--------------------------------------------------------------------------
                % trials TABLE Summary: each row is a trial
                %    1:  trial #
                %    2:  always 1
                %    3:  pedestal - always 0
                %    4:  repetition in a block
                %    5:  nan
                %    6:  nan
                %    7:  config, where is  closest stimulus 1: left (-/+) - 2: right (+/-)
                %    8:  disparity of left stim in pp
                %    9:  disparity of right stim in pp
                %    10: disparity value in arcsec (of left stimulus)
                %    11: nan
                %    12: correlated (1: yes, 2: anti)
                %    13: block # -chrono order- (one block is either +/- configuration or -/+ configuration and one disp)
                %    14:  correct or not for that trial (attentional)
                %    15:  runNb
                %    16:  offTime
                %    17:  onTime
                %    18:  attentional task increment: 1 = yes, 2 = no
                %--------------------------------------------------------------------------  
                
            %--STEREO MODE - CLOSE COM PORT
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


%======================  DEBUGING =============================================
catch err   
    disp(err)
    rethrow(err);
    save([dataFilePath,expe.file,'-crashlog'])
    saveAll([dataFilePath,expe.file,'-crashlog.mat'],[dataFilePath,expe.file,'-crashlog.txt'])
    warnings
    if exist('scr','var'); precautions(scr.w, 'off'); end
        if eyeTrackerMode==1; Eyelink('ShutDown');end
end
end


function [fullTable, nbBlocks]=initializeExp(expe)
%============================================================================
%   do a matrix of all runs and whether it is correlated or not and then randomize
%============================================================================
   
        %for all blocks of that run, do a matrix of all blocks and randomize 
         %blockTable = [disp in arcsec, correlation (1 yes 2 anti), repeat, disp in pp]
         blockTable = [];
         for r = 1:expe.nbRepeatDisp
             for dind = 1:numel(expe.dispListpp)
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
