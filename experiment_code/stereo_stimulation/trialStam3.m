function [trials, expe, perf]=trialStam3(blockTable,stim,scr,expe, sounds,inputMode, displayMode,stereoMode,portCOM,runNb,forceCorrelated)
%------------------------------------------------------------------------
% It is part of : 
% STaM Project [Stereo-Training and MRI]
% June 2014 - Berkeley
%-----------------------------------------------------------------------
%
%================== Trial function is showing a block of ON OFF stim ====================================
%   Many blocks (probably 14) give a run - all runs are identical, not all blocks
%   Called by MRI_stam3 main experiment function
%   This function does:
%           - display stimuli, get response for attentional task
%=======================================================================

try

    % -----  (block) TABLE --------------------------------
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
    
    %--------------------------------------------------------------------------------------------------
    %   SELECT CURRENT BLOCK FEATURES (assuming it will be identical for all trials
    %--------------------------------------------------------------------------------------------------
        thisTrial = blockTable(1,:);
        pedestal = thisTrial(2); disparityLeft = thisTrial(7); disparityRight = thisTrial(8); closestStim = thisTrial(6);
        correlated = thisTrial(11);
        if forceCorrelated==1
             correlated = 1;
        end
        n = size(blockTable,1)-1; %nb of trials -1 because we start with an additional OFF and end with another ON

    %--------------------------------------------------------------------------------------------------
    %   DEFINE LUMINANCE OF CORRELATED AND UNCORRELATED DOTS
    %--------------------------------------------------------------------------------------------------
         if correlated==1
            stim.dotColor1L = stim.minLum; stim.dotColor2L = stim.maxLum;
            stim.dotColor1R = stim.minLum; stim.dotColor2R = stim.maxLum;
        else
            stim.dotColor1L = stim.minLum; stim.dotColor2L = stim.maxLum;
            stim.dotColor1R = stim.maxLum; stim.dotColor2R = stim.minLum;
         end
        
         stim.LmaxL = 2*scr.backgr;
         stim.LmaxR = 2*scr.backgr;
    %--------------------------------------------------------------------------------------------------
    %   Initialize attentional task and other parameters
    %--------------------------------------------------------------------------------------------------
        lastCheck = GetSecs; %last time the task has been checked and the timers updated
        beginTime = lastCheck; %starting time stamp for that block
        incrementTimeList = []; %list of all previous increment times (used to know whether is detected or not in time)
        correctFlag = 1; %correct by default, =0 when missed or FA
        uncorrectTimer = 0; %initialize uncorrect timer
        correctTimer = 0; %initialize correct timer
        randomStart = rand(1).*360; %random start for perfAngle to avoid bias in attention
        perfMax = correctTimer/(n+1); %ratio time correct / time total at end of block
        perfAngle = (360*perfMax); %performance converted into a feedback circle arc angle to display
        circleColor= sc([scr.backgr 0 scr.backgr],scr.box); %standard color for feedback circle is purple
        trials = []; %list of answers and stimulus that are displayed
        perf.hit = 0; %hit counter (performance)
        perf.miss = 0; %miss counter
        perf.FA = 0; %FA counter
        lastOneWasIncrement=0; %flag =1 whenever last ON was an increment (to avoid two in a row)

    %--------------------------------------------------------------------------------------------------
    %   Initialize feedback color for the little square around fixation
    %--------------------------------------------------------------------------------------------------
        if correctFlag == 1 % feedback correct is green
            feedback = sc([0 scr.backgr 0],scr.box);
        else %red otherwise
            feedback = sc([scr.backgr 0 0],scr.box);
        end

        %whenever performance reaches the max, feedback circle color changes to green
        if perfMax>=1
            circleColor = sc([0 scr.backgr 0],scr.box);
        end
    
    % ------------- ALLOWED RESPONSES as a function of TIME (allows escape in the first 10 min)-----%
    %       Response Code Table:
    %               0: no keypress before time limit
    %               1: left
    %               2: right
    %               3: space
    %               4: escape           <- escape from keyboard only
    %               5: up
    %               6: down
    %              52: enter (numpad)
    %              55: num 1            <- answer button 1 when you see an dot increment (on fixation)
    %              56: num 2
     allowRS=[4,55];  %allowed response: PRESS 1 WHEN YOU SEE THE INCREMENT  
    
    %--------------------------------------------------------------------------
    %   PRELOADING OF COORDINATES
    %--------------------------------------------------------------------------
    
        %--------------------------------------------------------------------------
        %defines peripheric boxes rect (to be drawn inside with dots)
        %without outline (just inside)
        maxi=round(stim.fixationLength+2*stim.fixationOffset+stim.fixationLineWidth/2);

        %defines peripheric rect (to be drawn inside with dots)          
            %left
                centerRectLeftL = centerSizedAreaOnPx(scr.LcenterXLine-stim.RDSecc, scr.LcenterYLine, stim.RDSwidth, stim.RDSheight);
                centerRectLeftR = centerSizedAreaOnPx(scr.RcenterXLine-stim.RDSecc, scr.RcenterYLine, stim.RDSwidth, stim.RDSheight);
            %right 
                centerRectRightL = centerSizedAreaOnPx(scr.LcenterXLine+stim.RDSecc, scr.LcenterYLine, stim.RDSwidth, stim.RDSheight);
                centerRectRightR = centerSizedAreaOnPx(scr.RcenterXLine+stim.RDSecc, scr.RcenterYLine,stim.RDSwidth, stim.RDSheight);
            %background left of meridian (with a hole where the stimuli are)   
                bgRectLELeft = centerSizedAreaOnPx(scr.LcenterXLine-stim.backgrWidth/4, scr.LcenterYLine, stim.backgrWidth/2+1, stim.backgrHeight);
                bgRectRELeft = centerSizedAreaOnPx(scr.RcenterXLine-stim.backgrWidth/4, scr.RcenterYLine, stim.backgrWidth/2+1, stim.backgrHeight);
            %background right of meridian (with a hole where the stimuli are)    
                bgRectLERight = centerSizedAreaOnPx(scr.LcenterXLine+stim.backgrWidth/4, scr.LcenterYLine, stim.backgrWidth/2+1, stim.backgrHeight);
                bgRectRERight = centerSizedAreaOnPx(scr.RcenterXLine+stim.backgrWidth/4, scr.RcenterYLine, stim.backgrWidth/2+1, stim.backgrHeight);
            %big box rect left
                boxRectL= [scr.LcenterXLine-stim.horiz.width/2,scr.LcenterYLine-stim.vert.height/2,scr.LcenterXLine+stim.horiz.width/2,scr.LcenterYLine+stim.vert.height/2];
                boxRectR= [scr.RcenterXLine-stim.horiz.width/2,scr.RcenterYLine-stim.vert.height/2,scr.RcenterXLine+stim.horiz.width/2,scr.RcenterYLine+stim.vert.height/2];

        %generates every frames
           nbFrames = n;
           % LEFT target
            [coordLeftLTmp, coordLeftRTmp, expe.nbDotsLeft ]=generateRDSStereoCoord(1, centerRectLeftL(4)-centerRectLeftL(2)+1, centerRectLeftL(3)-centerRectLeftL(1)+1, stim.dotDensity, stim.dotSize, stim.coherence, stim.speed, disparityLeft);
            coordLeftL = nan(2,expe.nbDotsLeft,nbFrames);
            coordLeftR = nan(2,expe.nbDotsLeft,nbFrames);
            coordLeftL(:,:,1) = coordLeftLTmp;
            coordLeftR(:,:,1) = coordLeftRTmp;
                for fram=2:nbFrames
                    [coordLeftLTmp, coordLeftRTmp, expe.nbDotsLeft ]=generateRDSStereoCoord(1, centerRectLeftL(4)-centerRectLeftL(2)+1, centerRectLeftL(3)-centerRectLeftL(1)+1, stim.dotDensity, stim.dotSize, stim.coherence, stim.speed, disparityLeft);
                    coordLeftL(:,:,fram) = coordLeftLTmp;
                    coordLeftR(:,:,fram) = coordLeftRTmp;
                end
                 coordLeftL(1,:,:)=coordLeftL(1,:,:)+ repmat(centerRectLeftL(1)-1,[1,expe.nbDotsLeft,nbFrames]);
                 coordLeftL(2,:,:)=coordLeftL(2,:,:)+ repmat(centerRectLeftL(2)-1,[1,expe.nbDotsLeft,nbFrames]);
                 coordLeftR(1,:,:)=coordLeftR(1,:,:)+ repmat(centerRectLeftR(1)-1,[1,expe.nbDotsLeft,nbFrames]);
                 coordLeftR(2,:,:)=coordLeftR(2,:,:)+ repmat(centerRectLeftR(2)-1,[1,expe.nbDotsLeft,nbFrames]);
          % RIGHT target
           [coordRightLTmp, coordRightRTmp, expe.nbDotsRight ]=generateRDSStereoCoord(1, centerRectRightR(4)-centerRectRightR(2)+1, centerRectRightR(3)-centerRectRightR(1)+1, stim.dotDensity, stim.dotSize, stim.coherence, stim.speed, disparityRight);
            coordRightL = nan(2,expe.nbDotsRight,nbFrames);
            coordRightR = nan(2,expe.nbDotsRight,nbFrames);
            coordRightL(:,:,1) = coordRightLTmp;
            coordRightR(:,:,1) = coordRightRTmp;
                for fram=2:nbFrames
                    [coordRightLTmp, coordRightRTmp, expe.nbDotsRight ]=generateRDSStereoCoord(1, centerRectRightR(4)-centerRectRightR(2)+1, centerRectRightR(3)-centerRectRightR(1)+1, stim.dotDensity, stim.dotSize, stim.coherence, stim.speed, disparityRight);
                    coordRightL(:,:,fram) = coordRightLTmp;
                    coordRightR(:,:,fram) = coordRightRTmp;
                end
            coordRightL(1,:,:)=coordRightL(1,:,:)+ repmat(centerRectRightL(1)-1,[1,expe.nbDotsRight,nbFrames]);
            coordRightL(2,:,:)=coordRightL(2,:,:)+ repmat(centerRectRightL(2)-1,[1,expe.nbDotsRight,nbFrames]);
            coordRightR(1,:,:)=coordRightR(1,:,:)+ repmat(centerRectRightR(1)-1,[1,expe.nbDotsRight,nbFrames]);
            coordRightR(2,:,:)=coordRightR(2,:,:)+ repmat(centerRectRightR(2)-1,[1,expe.nbDotsRight,nbFrames]);

      %--BACKGROUND
          %LEFT SIDE of meridian for background (for each eye)
           relativeRect = [centerRectLeftL(1)-bgRectLELeft(1)+1, centerRectLeftL(2)-bgRectLELeft(2)+1, centerRectLeftL(3)-bgRectLELeft(1)+1, centerRectLeftL(4)-bgRectLELeft(2)+1];
            [coordBackgrLTmp, coordBackgrRTmp, expe.nbDotsBackL ]=generateRDSStereoCoord(1, bgRectLELeft(4)-bgRectLELeft(2)+1, bgRectLELeft(3)-bgRectLELeft(1)+1, stim.dotDensity, stim.dotSize, stim.coherence, stim.speed, 0, [], relativeRect);
            coordBackgrLELeft = nan(2,expe.nbDotsBackL,nbFrames);
            coordBackgrRELeft = nan(2,expe.nbDotsBackL,nbFrames);
            coordBackgrLELeft(:,:,1) = coordBackgrLTmp;
            coordBackgrRELeft(:,:,1) = coordBackgrRTmp;
                for fram=2:nbFrames
                    [coordBackgrLTmp, coordBackgrRTmp, expe.nbDotsBackL ]=generateRDSStereoCoord(1, bgRectLELeft(4)-bgRectLELeft(2)+1, bgRectLELeft(3)-bgRectLELeft(1)+1, stim.dotDensity, stim.dotSize, stim.coherence, stim.speed, 0, [], relativeRect);
                    coordBackgrLELeft(:,:,fram) = coordBackgrLTmp;
                    coordBackgrRELeft(:,:,fram) = coordBackgrRTmp;
                end
            coordBackgrLELeft(1,:,:)=coordBackgrLELeft(1,:,:)+ repmat(bgRectLELeft(1)-1,[1,expe.nbDotsBackL,nbFrames]);
            coordBackgrLELeft(2,:,:)=coordBackgrLELeft(2,:,:)+ repmat(bgRectLELeft(2)-1,[1,expe.nbDotsBackL,nbFrames]);
            coordBackgrRELeft(1,:,:)=coordBackgrRELeft(1,:,:)+ repmat(bgRectRELeft(1)-1,[1,expe.nbDotsBackL,nbFrames]);
            coordBackgrRELeft(2,:,:)=coordBackgrRELeft(2,:,:)+ repmat(bgRectRELeft(2)-1,[1,expe.nbDotsBackL,nbFrames]);

           %RIGHT SIDE of meridian for background (for each eye)
            relativeRect = [centerRectRightL(1)-bgRectLERight(1)+1, centerRectRightL(2)-bgRectLERight(2)+1, centerRectRightL(3)-bgRectLERight(1)+1, centerRectRightL(4)-bgRectLERight(2)+1];
            [coordBackgrLTmp, coordBackgrRTmp, expe.nbDotsBackR ]=generateRDSStereoCoord(1, bgRectLERight(4)-bgRectLERight(2)+1, bgRectLERight(3)-bgRectLERight(1)+1, stim.dotDensity, stim.dotSize, stim.coherence, stim.speed, 0, [], relativeRect);
            coordBackgrLERight = nan(2,expe.nbDotsBackR,nbFrames);
            coordBackgrRERight = nan(2,expe.nbDotsBackR,nbFrames);
            coordBackgrLERight(:,:,1) = coordBackgrLTmp;
            coordBackgrRERight(:,:,1) = coordBackgrRTmp;
                for fram=2:nbFrames
                    [coordBackgrLTmp, coordBackgrRTmp, expe.nbDotsBackR ]=generateRDSStereoCoord(1, bgRectLERight(4)-bgRectLERight(2)+1, bgRectLERight(3)-bgRectLERight(1)+1, stim.dotDensity, stim.dotSize, stim.coherence, stim.speed, 0, [], relativeRect);
                    coordBackgrLERight(:,:,fram) = coordBackgrLTmp;
                    coordBackgrRERight(:,:,fram) = coordBackgrRTmp;
                end
            coordBackgrLERight(1,:,:)=coordBackgrLERight(1,:,:)+ repmat(bgRectLERight(1)-1,[1,expe.nbDotsBackR,nbFrames]);
            coordBackgrLERight(2,:,:)=coordBackgrLERight(2,:,:)+ repmat(bgRectLERight(2)-1,[1,expe.nbDotsBackR,nbFrames]);
            coordBackgrRERight(1,:,:)=coordBackgrRERight(1,:,:)+ repmat(bgRectRERight(1)-1,[1,expe.nbDotsBackR,nbFrames]);
            coordBackgrRERight(2,:,:)=coordBackgrRERight(2,:,:)+ repmat(bgRectRERight(2)-1,[1,expe.nbDotsBackR,nbFrames]);

    %--------------------------------------------------------------------------
    %   START WITH A DUMMY OFF STIMULUS WHICH IS BASICALLY FIXATION
    %--------------------------------------------------------------------------
        %-- LEFT EYE SWAP STEREOADAPTER 
            if stereoMode==1
               fwrite(portCOM,'b','char');
            end
            %--- Background
                Screen('FillRect', scr.LEtxt, sc(scr.backgr,scr.box));
            %------ Big boxes (Outside frames)                        %REPLACED HASHED FRAMES WITH AN HOMOGENOUS ONE
                Screen('FrameRect', scr.LEtxt, sc(stim.fixL,scr.box),boxRectL, stim.horiz.height)
            %----- fixation
                drawDichFixation3(scr,stim,1,1);
            %--- Arc showing time spent in a correct answer configuration
                Screen('FrameArc', scr.LEtxt ,circleColor ,[scr.LcenterXLine-maxi scr.LcenterYLine-maxi scr.LcenterXLine+maxi scr.LcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
            %--- DIRECT FEEDBACK
                Screen('FrameRect', scr.LEtxt ,feedback , [scr.LcenterXDot-stim.feedbackSizePp,scr.LcenterYDot-stim.feedbackSizePp,scr.LcenterXDot+stim.feedbackSizePp,scr.LcenterYDot+stim.feedbackSizePp] ,1) ;  
            %---- SHOW
                Screen('DrawTexture',scr.w,scr.LEtxt)
                [dummy, firstOFFLeft]=flip(inputMode, scr.w);

        %--- RIGHT EYE SWAP STEREOADAPTER 
            if stereoMode==1
               fwrite(portCOM,'a','char');
            end
                %--- Background
                   Screen('FillRect', scr.REtxt, sc(scr.backgr,scr.box));
               % ------ Big boxes (Outside frames)                      %REPLACE HASHED FRAMES WITH AN HOMOGENOUS ONE
                    Screen('FrameRect', scr.REtxt, sc(stim.fixR,scr.box),boxRectR, stim.horiz.height)
                %-----fixation
                    drawDichFixation3(scr,stim,2,1);
                %---- Arc showing time spent in a correct answer configuration
                    Screen('FrameArc', scr.REtxt ,circleColor ,[scr.RcenterXLine-maxi scr.RcenterYLine-maxi scr.RcenterXLine+maxi scr.RcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                %----DIRECT FEEDBACK
                     Screen('FrameRect', scr.REtxt, feedback , [scr.RcenterXDot-stim.feedbackSizePp,scr.RcenterYDot-stim.feedbackSizePp,scr.RcenterXDot+stim.feedbackSizePp,scr.RcenterYDot+stim.feedbackSizePp] ,1) ;
               %---- SHOW
                    Screen('DrawTexture',scr.w,scr.REtxt)
                    [dummy, firstOFFRight]=flip(inputMode, scr.w);
 %--------------------------------------------------------------------------
 %       Get answer and update feedback
 %--------------------------------------------------------------------------
    detectFlag = 0;
    alreadyResponded = 0; %1 if already responded on that 500ms
    while (GetSecs - beginTime) < stim.itemDuration/1000 
            %--------------------------------------------------------------------------
            % UPDATE TIMERS aND DISPLAY THEM
            %--------------------------------------------------------------------------
               %-- update it
                nowT=GetSecs;
                update=nowT-lastCheck;
                lastCheck = nowT;
                if correctFlag==1
                    correctTimer = correctTimer+update;
                else
                    uncorrectTimer = uncorrectTimer+update;
                end
              %-- display
                perfMax = correctTimer/(n+1);
                perfAngle = (360*perfMax); %performance converted into a feedback circle arc angle to display
                if perfMax>=1
                    circleColor = sc([0 scr.backgr 0],scr.box);
                end  
                
                 %--SWITCH ON LEFT EYE
                    if stereoMode==1
                        fwrite(portCOM,'b','char');
                    end
                    %---Arc showing time spent in a correct answer configuration
                        Screen('FrameArc', scr.LEtxt ,circleColor ,[scr.LcenterXLine-maxi scr.LcenterYLine-maxi scr.LcenterXLine+maxi scr.LcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                    %--- SHOW
                        Screen('DrawTexture',scr.w,scr.LEtxt)
                        flip(inputMode, scr.w);   

                 %-- SWITCH ON RIGHT EYE
                    if stereoMode==1
                        fwrite(portCOM,'a','char');
                    end    
                    %--- Arc showing time spent in a correct answer configuration
                        Screen('FrameArc', scr.REtxt ,circleColor ,[scr.RcenterXLine-maxi scr.RcenterYLine-maxi scr.RcenterXLine+maxi scr.RcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                    %--- SHOW     
                        Screen('DrawTexture',scr.w,scr.REtxt)
                        flip(inputMode, scr.w); 
                                  
            %TO AVOID ERRORS - I DONT CHECK FOR RESPONSES during first dummy OFF time
    end
    offTime = GetSecs-beginTime;
    
    %--------------------------------------------------------------------------
    %   START THE TRIAL LOOP WITH MOrE ON-OFF STIM
    %--------------------------------------------------------------------------
     for trial = 1:n    
         startON= GetSecs;
         % changing frame:
         RDSnb = trial; %or =1  (rds frame nb)
         
        %--------------------------------------------------------------------------
        %  POTENTIAL INCREMENT
        %--------------------------------------------------------------------------
            increment = randsample([0 1], 1, 'true', [1-stim.attentionalP, stim.attentionalP]); %1: yes, 0: no increment
            if lastOneWasIncrement==1 %no increment one after the other
                increment=0;
                lastOneWasIncrement=0;
            end
            if increment == 1 %temporarily increase white luminance for fixation
                stim.LmaxL = stim.LmaxL * expe.multiplier;
                stim.LmaxR = stim.LmaxR * expe.multiplier;
                incrementTimeList=[incrementTimeList, GetSecs];
            end
    
        %--------------------------------------------------------------------------
        %   ON LOOP - SHOW STIMULI
        %--------------------------------------------------------------------------
          %LEFT EYE SWAP STEREOADAPTER 
                if stereoMode==1
                    fwrite(portCOM,'b','char');
                end
                
                %--delete the drawing areas
                    Screen('FillRect', scr.LEtxt ,sc(scr.backgr,scr.box),boxRectL ) ;%boxRectL
                %--DRAW THE DOTS FULL CONTRAST
                  %--RDS LE - left and right side
                    %-draw half of the dots with dotColor1
                       Screen('DrawDots', scr.LEtxt, coordLeftL(:,1:round(expe.nbDotsLeft/2),RDSnb), stim.dotSize, sc(stim.dotColor1L,scr.box),[0,0], 2);
                       Screen('DrawDots', scr.LEtxt, coordRightL(:,1:round(expe.nbDotsRight/2),RDSnb), stim.dotSize, sc(stim.dotColor1L,scr.box),[0, 0], 2);
                     %-draw the other half with dotColor2
                        Screen('DrawDots', scr.LEtxt, coordLeftL(:,(round(expe.nbDotsLeft/2)+1):end,RDSnb), stim.dotSize, sc(stim.dotColor2L,scr.box),[0, 0], 2);
                        Screen('DrawDots', scr.LEtxt, coordRightL(:,(round(expe.nbDotsRight/2)+1):end,RDSnb), stim.dotSize, sc(stim.dotColor2L,scr.box),[0, 0], 2);
                  %--LE BACKGR RDS left and right side
                    %-draw half of the dots with dotColor1
                        Screen('DrawDots', scr.LEtxt, coordBackgrLELeft(:,1:round(expe.nbDotsBackL/2),RDSnb), stim.dotSize, sc(stim.dotColor1L,scr.box),[0,0], 2);
                        Screen('DrawDots', scr.LEtxt, coordBackgrLERight(:,1:round(expe.nbDotsBackL/2),RDSnb), stim.dotSize, sc(stim.dotColor1L,scr.box),[0, 0], 2);
                     %-draw the other half with dotColor2
                        Screen('DrawDots', scr.LEtxt, coordBackgrLELeft(:,(round(expe.nbDotsBackL/2)+1):end,RDSnb), stim.dotSize, sc(stim.dotColor2L,scr.box),[0, 0], 2);
                        Screen('DrawDots', scr.LEtxt, coordBackgrLERight(:,(round(expe.nbDotsBackL/2)+1):end,RDSnb), stim.dotSize, sc(stim.dotColor2L,scr.box),[0, 0], 2);
                %------ Big boxes (Outside frames)                        %REPLACED HASHED FRAMES WITH AN HOMOGENOUS ONE
                    Screen('FrameRect', scr.LEtxt, sc(stim.fixL,scr.box),[scr.LcenterXLine-stim.horiz.width/2,scr.LcenterYLine-stim.vert.height/2,scr.LcenterXLine+stim.horiz.width/2,scr.LcenterYLine+stim.vert.height/2], stim.horiz.height)   
                %-----fixation
                    drawDichFixation3(scr,stim,1,1,0);
                %----Arc showing time spent in a correct answer configuration
                    Screen('FrameArc', scr.LEtxt ,circleColor ,[scr.LcenterXLine-maxi scr.LcenterYLine-maxi scr.LcenterXLine+maxi scr.LcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                %----DIRECT FEEDBACK
                    Screen('FrameRect', scr.LEtxt ,feedback , [scr.LcenterXDot-stim.feedbackSizePp,scr.LcenterYDot-stim.feedbackSizePp,scr.LcenterXDot+stim.feedbackSizePp,scr.LcenterYDot+stim.feedbackSizePp] ,1) ;
                %----SHOW
                    Screen('DrawTexture',scr.w,scr.LEtxt)
                    [dummy, frameONLeft]=flip(inputMode, scr.w);
                
            %RIGHT EYE SWAP STEREOADAPTER 
                if stereoMode==1
                    fwrite(portCOM,'a','char');
                end
                %---delete the inner drawing areas
                    Screen('FillRect', scr.REtxt ,sc(scr.backgr,scr.box),boxRectR);%boxRectR
                %---DRAW THE DOTS FULL CONTRAST
                  %--RDS RE - left and right side
                    %-draw half of the dots with dotColor1
                       Screen('DrawDots', scr.REtxt, coordLeftR(:,1:round(expe.nbDotsLeft/2),RDSnb), stim.dotSize, sc(stim.dotColor1R,scr.box),[0,0], 2);
                       Screen('DrawDots', scr.REtxt, coordRightR(:,1:round(expe.nbDotsRight/2),RDSnb), stim.dotSize, sc(stim.dotColor1R,scr.box),[0, 0], 2);   
                    %-draw the other half with dotColor2
                        Screen('DrawDots', scr.REtxt, coordLeftR(:,(round(expe.nbDotsLeft/2)+1):end,RDSnb), stim.dotSize, sc(stim.dotColor2R,scr.box),[0, 0], 2);
                        Screen('DrawDots', scr.REtxt, coordRightR(:,(round(expe.nbDotsRight/2)+1):end,RDSnb), stim.dotSize,sc(stim.dotColor2R,scr.box),[0, 0], 2);
                  %--BACKGR RDS RE left and right side
                    %-draw half of the dots with dotColor1
                        Screen('DrawDots', scr.REtxt, coordBackgrRELeft(:,1:round(expe.nbDotsBackR/2),RDSnb), stim.dotSize, sc(stim.dotColor1R,scr.box),[0,0], 2);
                        Screen('DrawDots', scr.REtxt, coordBackgrRERight(:,1:round(expe.nbDotsBackR/2),RDSnb), stim.dotSize, sc(stim.dotColor1R,scr.box),[0, 0], 2);
                     %-draw the other half with dotColor2
                        Screen('DrawDots', scr.REtxt, coordBackgrRELeft(:,(round(expe.nbDotsBackR/2)+1):end,RDSnb), stim.dotSize, sc(stim.dotColor2R,scr.box),[0, 0], 2);
                        Screen('DrawDots', scr.REtxt, coordBackgrRERight(:,(round(expe.nbDotsBackR/2)+1):end,RDSnb), stim.dotSize, sc(stim.dotColor2R,scr.box),[0, 0], 2);
                %------ Big boxes (Outside frames)                      %REPLACE HASHED FRAMES WITH AN HOMOGENOUS ONE
                    Screen('FrameRect', scr.REtxt, sc(stim.fixR,scr.box),[scr.RcenterXLine-stim.horiz.width/2,scr.RcenterYLine-stim.vert.height/2,scr.RcenterXLine+stim.horiz.width/2,scr.RcenterYLine+stim.vert.height/2], stim.horiz.height)
                %-----fixation
                    drawDichFixation3(scr,stim,2,1,0);
                %-----Arc showing time spent in a correct answer configuration
                    Screen('FrameArc', scr.REtxt ,circleColor ,[scr.RcenterXLine-maxi scr.RcenterYLine-maxi scr.RcenterXLine+maxi scr.RcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                %-----DIRECT FEEDBACK
                    Screen('FrameRect', scr.REtxt ,feedback , [scr.RcenterXDot-stim.feedbackSizePp,scr.RcenterYDot-stim.feedbackSizePp,scr.RcenterXDot+stim.feedbackSizePp,scr.RcenterYDot+stim.feedbackSizePp] ,1) ;          
                %----SHOW
                    Screen('DrawTexture',scr.w,scr.REtxt)
                    [dummy, frameONRight]=flip(inputMode, scr.w); %-max(0,Missed)

           %--------------------------------------------------------------------------
           %   DISPLAY MODE STUFF
           %--------------------------------------------------------------------------
            if displayMode==1
               Screen('DrawLines',scr.LEtxt, [scr.LcenterXLine,scr.LcenterXLine,scr.LcenterXLine-6,scr.LcenterXLine-6,...
                   scr.LcenterXLine+6,scr.LcenterXLine+6,scr.LcenterXLine+12,scr.LcenterXLine+12;0,scr.res(4),0,scr.res(4),...
                   0,scr.res(4),0,scr.res(4)],  1, sc([15,15,15],scr.box));
               Screen('DrawLines',scr.LEtxt, [scr.RcenterXLine,scr.RcenterXLine,scr.RcenterXLine-6,scr.RcenterXLine-6,...
                   scr.RcenterXLine+6,scr.RcenterXLine+6,scr.RcenterXLine+12,scr.RcenterXLine+12;0,scr.res(4),...
                   0,scr.res(4),0,scr.res(4),0,scr.res(4)],  1, sc([15,15,15],scr.box));
              Screen('DrawDots', scr.LEtxt, [scr.LcenterXLine;scr.LcenterYLine], 1, 0,[],2); 
               Screen('DrawTexture',scr.w,scr.LEtxt)
               flip(inputMode, scr.w);
               waitForKey(scr.keyboardNum,inputMode);   
            end
           
        while (GetSecs - startON) < stim.itemDuration/1000 
            %--------------------------------------------------------------------------
            % UPDATE TIMERS aND DISPLAY THEM
            %--------------------------------------------------------------------------
               %--update
                nowT=GetSecs;
                update=nowT-lastCheck;
                lastCheck = nowT;
                if correctFlag==1
                    correctTimer = correctTimer+update;
                else
                    uncorrectTimer = uncorrectTimer+update;
                end
               %--display
                   perfMax = correctTimer/(n+1);
                   perfAngle = (360*perfMax); %performance converted into a feedback circle arc angle to display
                    if perfMax>=1
                        circleColor = sc([0 scr.backgr 0],scr.box);
                    end  

                    %SWITCH ON LEFT EYE
                    if stereoMode==1
                        fwrite(portCOM,'b','char');
                    end
                    %---Arc showing time spent in a correct answer configuration
                        Screen('FrameArc', scr.LEtxt ,circleColor ,[scr.LcenterXLine-maxi scr.LcenterYLine-maxi scr.LcenterXLine+maxi scr.LcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                    %----SHOW
                        Screen('DrawTexture',scr.w,scr.LEtxt)
                        flip(inputMode, scr.w);   
                       
                    %SWITCH ON RIGHT EYE
                    if stereoMode==1
                        fwrite(portCOM,'a','char');
                    end    
                    %-----Arc showing time spent in a correct answer configuration
                        Screen('FrameArc', scr.REtxt ,circleColor ,[scr.RcenterXLine-maxi scr.RcenterYLine-maxi scr.RcenterXLine+maxi scr.RcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                    %----SHOW 
                        Screen('DrawTexture',scr.w,scr.REtxt)
                        flip(inputMode, scr.w); 
                    
            %--------------------------------------------------------------------------
            %   GET RESPONSE (dont wait)
            %--------------------------------------------------------------------------
               [responseKey]=getResponseKb(scr.keyboardNum,0,inputMode,allowRS,[],[],1,0,0,1);
                if responseKey==0
                    alreadyResponded = 0;
                    detectFlag=0;
                end
                if alreadyResponded == 0; %1 if already responded on that 500ms
                    if responseKey==55 && detectFlag==0 %detected stg
                       detectFlag=1;
                    elseif responseKey==4
                        %ESCAPE
                        quickQuit(scr)
                    end
                    %--------------------------------------------------------------------------
                    %  CHECK DETECTION
                    %--------------------------------------------------------------------------
                    if detectFlag==1
                        idxD=((GetSecs-incrementTimeList)<expe.detectTime);
                        if any(idxD) %check whether increment in the last second
                           %CORRECT DETECTION
                            correctFlag = 1;
                            feedback = sc([0 scr.backgr 0],scr.box);
                            incrementTimeList(idxD)=[]; %remove oldest increment
                            alreadyResponded = 1;
                            perf.hit =  perf.hit+1;
                        else
                            %FALSE ALARM
                            correctFlag = 0;
                            %incorrect == red
                            feedback = sc([scr.backgr 0 0],scr.box);
                            perf.FA= perf.FA+1;
                        end
                    end

                    %--------------------------------------------------------------------------
                    %  CHECK MISS
                    %--------------------------------------------------------------------------   
                    if detectFlag==0
                        idxM=((GetSecs-incrementTimeList)>expe.detectTime);
                        if any(idxM) %check whether increment older than the last second
                            correctFlag = 0;
                            feedback = sc([scr.backgr 0 0],scr.box);
                            incrementTimeList(idxM)=[];
                            perf.miss = perf.miss+1;
                        end
                    end
                end      
        end
            onTime = GetSecs - startON;     
        %--------------------------------------------------------------------------
        %   End of an OFF ON trial - save the trial in trials
        %--------------------------------------------------------------------------
            trials=[trials;trial,thisTrial,correctFlag, runNb, offTime, onTime, increment];
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
        
        %--------------------------------------------------------------------------
        %   OFF LOOP - REMOVE STIMULI
        %--------------------------------------------------------------------------
        startOff = GetSecs;
            %------------------------------------------------------------------------------
            %   INCREMENT   -Put white luminance back to normal (to materialize increment)
            %------------------------------------------------------------------------------
                if increment == 1
                    stim.LmaxL = stim.LmaxL / expe.multiplier;
                    stim.LmaxR = stim.LmaxR / expe.multiplier;
                    increment = 0;
                    lastOneWasIncrement=1;
                end
        
              %--LEFT EYE SWAP STEREOADAPTER 
                if stereoMode==1
                    fwrite(portCOM,'b','char');
                end
                    %---delete the inner drawing areas
                        Screen('FillRect', scr.LEtxt ,sc(scr.backgr,scr.box),boxRectL) ;
                    %------ Big boxes (Outside frames)                      %REPLACE HASHED FRAMES WITH AN HOMOGENOUS ONE
                        Screen('FrameRect', scr.LEtxt, sc(stim.fixL,scr.box),boxRectL, stim.horiz.height)
                    %-----fixation
                        drawDichFixation3(scr,stim,1,1,0);
                    %----Arc showing time spent in a correct answer configuration
                        Screen('FrameArc', scr.LEtxt ,circleColor ,[scr.LcenterXLine-maxi scr.LcenterYLine-maxi scr.LcenterXLine+maxi scr.LcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                    %----DIRECT FEEDBACK
                        Screen('FrameRect', scr.LEtxt ,feedback , [scr.LcenterXDot-stim.feedbackSizePp,scr.LcenterYDot-stim.feedbackSizePp,scr.LcenterXDot+stim.feedbackSizePp,scr.LcenterYDot+stim.feedbackSizePp] ,1) ; 
                    %-----SHOW 
                        Screen('DrawTexture',scr.w,scr.LEtxt)
                        [dummy, frameOFFLeft]=flip(inputMode, scr.w); %-max(0,Missed)

               %----RIGHT EYE SWAP STEREOADAPTER 
                if stereoMode==1
                    fwrite(portCOM,'a','char');
                end
                    %---delete the inner drawing areas
                        Screen('FillRect', scr.REtxt ,sc(scr.backgr,scr.box),boxRectR);
                    % ------ Big boxes (Outside frames)                      %REPLACE HASHED FRAMES WITH AN HOMOGENOUS ONE
                        Screen('FrameRect', scr.REtxt, sc(stim.fixR,scr.box),boxRectR, stim.horiz.height)
                    %-----fixation
                        drawDichFixation3(scr,stim,2,1,0);
                    %-----Arc showing time spent in a correct answer configuration
                        Screen('FrameArc', scr.REtxt ,circleColor ,[scr.RcenterXLine-maxi scr.RcenterYLine-maxi scr.RcenterXLine+maxi scr.RcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                    %-----DIRECT FEEDBACK
                        Screen('FrameRect', scr.REtxt ,feedback , [scr.RcenterXDot-stim.feedbackSizePp,scr.RcenterYDot-stim.feedbackSizePp,scr.RcenterXDot+stim.feedbackSizePp,scr.RcenterYDot+stim.feedbackSizePp] ,1) ;
                    %-----SHOW 
                        Screen('DrawTexture',scr.w,scr.REtxt)
                        [dummy, frameOFFRight]=flip(inputMode, scr.w); %-max(0,Missed)

        while (GetSecs - startOff) < stim.itemDuration/1000
            %--------------------------------------------------------------------------
            % UPDATE TIMERS aND DISPLAY THEM
            %--------------------------------------------------------------------------
               %--update
                nowT=GetSecs;
                update=nowT-lastCheck;
                lastCheck = nowT;
                if correctFlag==1
                    correctTimer = correctTimer+update;
                else
                    uncorrectTimer = uncorrectTimer+update;
                end
               %--display
                    perfMax = correctTimer/(n+1);
                    perfAngle = (360*perfMax); %performance converted into a feedback circle arc angle to display
                    if perfMax>=1
                        circleColor = sc([0 scr.backgr 0],scr.box);
                    end  

                  %-SWITCH ON LEFT EYE
                    if stereoMode==1
                        fwrite(portCOM,'b','char');
                    end
                    %---Arc showing time spent in a correct answer configuration
                        Screen('FrameArc', scr.LEtxt ,circleColor ,[scr.LcenterXLine-maxi scr.LcenterYLine-maxi scr.LcenterXLine+maxi scr.LcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                    %-----SHOW 
                        Screen('DrawTexture',scr.w,scr.LEtxt)
                        flip(inputMode, scr.w);   
                  
                 %-SWITCH ON RIGHT EYE
                    if stereoMode==1
                        fwrite(portCOM,'a','char');
                    end    
                    %---Arc showing time spent in a correct answer configuration
                        Screen('FrameArc', scr.REtxt ,circleColor ,[scr.RcenterXLine-maxi scr.RcenterYLine-maxi scr.RcenterXLine+maxi scr.RcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                    %-----SHOW 
                        Screen('DrawTexture',scr.w,scr.REtxt)
                        flip(inputMode, scr.w); 

            %--------------------------------------------------------------------------
            %   GET RESPONSE (dont wait)
            %--------------------------------------------------------------------------
                [responseKey]=getResponseKb(scr.keyboardNum,0,inputMode,allowRS,[],[],1,0,0,1);
                if responseKey==0
                    alreadyResponded = 0;
                    detectFlag=0;
                end
                if alreadyResponded == 0; %1 if already responded on that 500ms
                    if responseKey==55 && detectFlag==0 %detected stg
                       detectFlag=1;
                    elseif responseKey==4
                        %ESCAPE
                        quickQuit(scr)
                    end
                    %--------------------------------------------------------------------------
                    %  CHECK DETECTION
                    %--------------------------------------------------------------------------
                        if detectFlag==1
                            idxD=((GetSecs-incrementTimeList)<expe.detectTime);
                            if any(idxD) %check whether increment in the last second
                               %CORRECT DETECTION
                                correctFlag = 1;
                                feedback = sc([0 scr.backgr 0],scr.box);
                                incrementTimeList(idxD)=[]; %remove oldest increment
                                alreadyResponded = 1;
                                perf.hit = perf.hit+1;
                            else
                                %FALSE ALARM
                                correctFlag = 0;
                                %incorrect == red
                                feedback = sc([scr.backgr 0 0],scr.box);
                                perf.FA = perf.FA+1;
                            end
                        end

                    %--------------------------------------------------------------------------
                    %  CHECK MISS
                    %--------------------------------------------------------------------------   
                        if detectFlag==0
                            idxM=((GetSecs-incrementTimeList)>expe.detectTime);
                            if any(idxM) %check whether increment older than the last second
                                correctFlag = 0;
                                feedback = sc([scr.backgr 0 0],scr.box);
                                incrementTimeList(idxM)=[];
                                perf.miss = perf.miss+1;
                            end
                        end
                end    
        end
        offTime = (GetSecs - startOff);
            

            %         %--------------------------------------------------------------------------
            %         %   SCREEN CAPTURE
            %         %--------------------------------------------------------------------------
            %             theFrame=belowRrect(:,1,frame);
            %             Screen('FrameRect', scr.w, 255, theFrame)
            %             flip(inputMode, scr.w, [], 1);
            %             WaitSecs(1)
            %             im=150-Screen('GetImage', scr.w, theFrame);
            %
            %             %[a,bb]=min(im(25,:,1))
            %             %save('im2.mat','im')
            %             plot(1:size(im,2),im(25,:,1), 'Color', [jjj/12, 1-jjj/12, 0])
            %             hold on
            %             zz=22:28;
            %            x=sum(sum(double(squeeze(im(zz,zz,1))).* repmat(double(zz),[numel(zz),1])))/sum(sum(im(zz,zz,1)))
            %            y=sum(sum(double(squeeze(im(zz,zz,1))).* repmat(double(zz)',[1,numel(zz)])))/sum(sum(im(zz,zz,1)))
            %
            %             zz=24:26;
            %            x=sum(sum(double(squeeze(im(zz,zz,1))).* repmat(double(zz),[numel(zz),1])))/sum(sum(im(zz,zz,1)))
            %            y=sum(sum(double(squeeze(im(zz,zz,1))).* repmat(double(zz)',[1,numel(zz)])))/sum(sum(im(zz,zz,1)))
            %             stimulationFlag = 0;
            %              WaitSecs(1)


    end
   startOnLast= GetSecs;
    %--------------------------------------------------------------------------
    %   FINISH WITH AN ADDITIONAL ON STIMULUS 
    %--------------------------------------------------------------------------
        %--------------------------------------------------------------------------
        %   ON LOOP - SHOW STIMULI
        %--------------------------------------------------------------------------
          %--LEFT EYE SWAP STEREOADAPTER 
           if stereoMode==1
                fwrite(portCOM,'b','char');
           end
              %--delete the inner drawing areas
                    Screen('FillRect', scr.LEtxt ,sc(scr.backgr,scr.box),boxRectL) ; %boxRectL
              %--DRAW THE DOTS FULL CONTRAST
               %-RDS LE - left and right side
                %-draw half of the dots with dotColor1
                    Screen('DrawDots', scr.LEtxt, coordLeftL(:,1:round(expe.nbDotsLeft/2),RDSnb), stim.dotSize, sc(stim.dotColor1L,scr.box),[0,0], 2);
                    Screen('DrawDots', scr.LEtxt, coordRightL(:,1:round(expe.nbDotsRight/2),RDSnb), stim.dotSize, sc(stim.dotColor1L,scr.box),[0, 0], 2);
                %-draw the other half with dotColor2
                    Screen('DrawDots', scr.LEtxt, coordLeftL(:,(round(expe.nbDotsLeft/2)+1):end,RDSnb), stim.dotSize, sc(stim.dotColor2L,scr.box),[0, 0], 2);
                    Screen('DrawDots', scr.LEtxt, coordRightL(:,(round(expe.nbDotsRight/2)+1):end,RDSnb), stim.dotSize, sc(stim.dotColor2L,scr.box),[0, 0], 2);
               %--LE BACKGR RDS left and right side
                %-draw half of the dots with dotColor1
                    Screen('DrawDots', scr.LEtxt, coordBackgrLELeft(:,1:round(expe.nbDotsBackL/2),RDSnb), stim.dotSize, sc(stim.dotColor1L,scr.box),[0,0], 2);
                    Screen('DrawDots', scr.LEtxt, coordBackgrLERight(:,1:round(expe.nbDotsBackL/2),RDSnb), stim.dotSize, sc(stim.dotColor1L,scr.box),[0, 0], 2);
                %-draw the other half with dotColor2
                    Screen('DrawDots', scr.LEtxt, coordBackgrLELeft(:,(round(expe.nbDotsBackL/2)+1):end,RDSnb), stim.dotSize, sc(stim.dotColor2L,scr.box),[0, 0], 2);
                    Screen('DrawDots', scr.LEtxt, coordBackgrLERight(:,(round(expe.nbDotsBackL/2)+1):end,RDSnb), stim.dotSize, sc(stim.dotColor2L,scr.box),[0, 0], 2);
               %------ Big boxes (Outside frames)                        %REPLACED HASHED FRAMES WITH AN HOMOGENOUS ONE
                    Screen('FrameRect', scr.LEtxt, sc(stim.fixL,scr.box),[scr.LcenterXLine-stim.horiz.width/2,scr.LcenterYLine-stim.vert.height/2,scr.LcenterXLine+stim.horiz.width/2,scr.LcenterYLine+stim.vert.height/2], stim.horiz.height)   
               %-----fixation
                    drawDichFixation3(scr,stim,1,1,0);
               %----Arc showing time spent in a correct answer configuration
                    Screen('FrameArc', scr.LEtxt ,circleColor ,[scr.LcenterXLine-maxi scr.LcenterYLine-maxi scr.LcenterXLine+maxi scr.LcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
               %----DIRECT FEEDBACK
                    Screen('FrameRect', scr.LEtxt ,feedback , [scr.LcenterXDot-stim.feedbackSizePp,scr.LcenterYDot-stim.feedbackSizePp,scr.LcenterXDot+stim.feedbackSizePp,scr.LcenterYDot+stim.feedbackSizePp] ,1) ;
               %-----SHOW 
                    Screen('DrawTexture',scr.w,scr.LEtxt)
                    [dummy, frameONLeft]=flip(inputMode, scr.w); %-max(0,Missed)

            %RIGHT EYE SWAP STEREOADAPTER 
                if stereoMode==1
                    fwrite(portCOM,'a','char');
                end
                   %---delete the inner drawing areas
                        Screen('FillRect', scr.REtxt ,sc(scr.backgr,scr.box),boxRectR);
                  %---DRAW THE DOTS FULL CONTRAST
                   %-RDS RE - left and right side
                    %-draw half of the dots with dotColor1
                        Screen('DrawDots', scr.REtxt, coordLeftR(:,1:round(expe.nbDotsLeft/2),RDSnb), stim.dotSize, sc(stim.dotColor1R,scr.box),[0,0], 2);
                        Screen('DrawDots', scr.REtxt, coordRightR(:,1:round(expe.nbDotsRight/2),RDSnb), stim.dotSize, sc(stim.dotColor1R,scr.box),[0, 0], 2);   
                    %-draw the other half with dotColor2
                        Screen('DrawDots', scr.REtxt, coordLeftR(:,(round(expe.nbDotsLeft/2)+1):end,RDSnb), stim.dotSize, sc(stim.dotColor2R,scr.box),[0, 0], 2);
                        Screen('DrawDots', scr.REtxt, coordRightR(:,(round(expe.nbDotsRight/2)+1):end,RDSnb), stim.dotSize, sc(stim.dotColor2R,scr.box),[0, 0], 2);
                   %--BACKGR RDS RE left and right side
                    %-draw half of the dots with dotColor1
                        Screen('DrawDots', scr.REtxt, coordBackgrRELeft(:,1:round(expe.nbDotsBackR/2),RDSnb), stim.dotSize, sc(stim.dotColor1R,scr.box),[0,0], 2);
                        Screen('DrawDots', scr.REtxt, coordBackgrRERight(:,1:round(expe.nbDotsBackR/2),RDSnb), stim.dotSize, sc(stim.dotColor1R,scr.box),[0, 0], 2);
                    %-draw the other half with dotColor2
                        Screen('DrawDots', scr.REtxt, coordBackgrRELeft(:,(round(expe.nbDotsBackR/2)+1):end,RDSnb), stim.dotSize, sc(stim.dotColor2R,scr.box),[0, 0], 2);
                        Screen('DrawDots', scr.REtxt, coordBackgrRERight(:,(round(expe.nbDotsBackR/2)+1):end,RDSnb), stim.dotSize, sc(stim.dotColor2R,scr.box),[0, 0], 2);
                   %------ Big boxes (Outside frames)                      %REPLACE HASHED FRAMES WITH AN HOMOGENOUS ONE
                        Screen('FrameRect', scr.REtxt, sc(stim.fixR,scr.box),[scr.RcenterXLine-stim.horiz.width/2,scr.RcenterYLine-stim.vert.height/2,scr.RcenterXLine+stim.horiz.width/2,scr.RcenterYLine+stim.vert.height/2], stim.horiz.height)
                   %-----fixation
                        drawDichFixation3(scr,stim,2,1,0);
                   %-----Arc showing time spent in a correct answer configuration
                        Screen('FrameArc', scr.REtxt ,circleColor ,[scr.RcenterXLine-maxi scr.RcenterYLine-maxi scr.RcenterXLine+maxi scr.RcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                   %----DIRECT FEEDBACK
                        Screen('FrameRect', scr.REtxt ,feedback , [scr.RcenterXDot-stim.feedbackSizePp,scr.RcenterYDot-stim.feedbackSizePp,scr.RcenterXDot+stim.feedbackSizePp,scr.RcenterYDot+stim.feedbackSizePp] ,1) ; 
                   %-----SHOW      
                        Screen('DrawTexture',scr.w,scr.REtxt)
                        [dummy, frameONRight]=flip(inputMode, scr.w); %-max(0,Missed)

        while (GetSecs - startOnLast) < (stim.itemDuration/1000 - 150)%remove 150ms to catch up any delay in the sequence (feuRouge at the end)
            %--------------------------------------------------------------------------
            % UPDATE TIMERS aND DISPLAY THEM
            %--------------------------------------------------------------------------
               %--update
                    nowT=GetSecs;
                    update=nowT-lastCheck;
                    lastCheck = nowT;
                    if correctFlag==1
                        correctTimer = correctTimer+update;
                    else
                        uncorrectTimer = uncorrectTimer+update;
                    end
               %--display
                    perfMax = correctTimer/(n+1);
                    perfAngle = (360*perfMax); %performance converted into a feedback circle arc angle to display
                    if perfMax>=1
                        circleColor = sc([0 scr.backgr 0],scr.box);
                    end     
                    
                  %--SWITCH ON LEFT EYE
                    if stereoMode==1
                        fwrite(portCOM,'b','char');
                    end
                    %--Arc showing time spent in a correct answer configuration
                        Screen('FrameArc', scr.LEtxt ,circleColor ,[scr.LcenterXLine-maxi scr.LcenterYLine-maxi scr.LcenterXLine+maxi scr.LcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                    %-----SHOW     
                        Screen('DrawTexture',scr.w,scr.LEtxt)
                        flip(inputMode, scr.w); 
                        
                 %--SWITCH ON RIGHT EYE
                    if stereoMode==1
                        fwrite(portCOM,'a','char');
                    end    
                      %---Arc showing time spent in a correct answer configuration
                        Screen('FrameArc', scr.REtxt ,circleColor ,[scr.RcenterXLine-maxi scr.RcenterYLine-maxi scr.RcenterXLine+maxi scr.RcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                      %-----SHOW   
                        Screen('DrawTexture',scr.w,scr.REtxt)
                        flip(inputMode, scr.w); 
            %--------------------------------------------------------------------------
            %   GET RESPONSE (dont wait)
            %--------------------------------------------------------------------------
            [responseKey]=getResponseKb(scr.keyboardNum,0,inputMode,allowRS,[],[],1,0,0,1);
            if responseKey==0
                alreadyResponded = 0;
                detectFlag=0;
            end
            if alreadyResponded == 0; %1 if already responded on that 500ms
                if responseKey==55 && detectFlag==0 %detected stg
                   detectFlag=1;
                elseif responseKey==4
                    %ESCAPE
                    quickQuit(scr)
                end
                %--------------------------------------------------------------------------
                %  CHECK DETECTION
                %--------------------------------------------------------------------------
                if detectFlag==1
                    idxD=((GetSecs-incrementTimeList)<expe.detectTime);
                    if any(idxD) %check whether increment in the last second
                       %CORRECT DETECTION
                        correctFlag = 1;
                        feedback = sc([0 scr.backgr 0],scr.box);
                        incrementTimeList(idxD)=[]; %remove oldest increment
                        alreadyResponded = 1;
                        perf.hit = perf.hit+1;
                    else
                        %FALSE ALARM
                        correctFlag = 0;
                        %incorrect == red
                        feedback = sc([scr.backgr 0 0],scr.box);
                        perf.FA = perf.FA+1;
                    end
                end
            
                %--------------------------------------------------------------------------
                %  CHECK MISS
                %--------------------------------------------------------------------------   
                if detectFlag==0
                    idxM=((GetSecs-incrementTimeList)>expe.detectTime);
                    if any(idxM) %check whether increment older than the last second
                        correctFlag = 0;
                        feedback = sc([scr.backgr 0 0],scr.box);
                        incrementTimeList(idxM)=[];
                        perf.miss=perf.miss+1;
                    end
                end
            end
        end

%==================================================
%   ERASE ON STIMULUS
%==================================================
  %--SWAP FOR LEFT EYE 
    if stereoMode==1
        fwrite(portCOM,'b','char');
    end
    %--background
        Screen('FillRect', scr.LEtxt ,sc(scr.backgr,scr.box), boxRectL);
    %-----fixation
        drawDichFixation3(scr,stim,1,1);
    %------ Big boxes (Outside frames)                        %REPLACED HASHED FRAMES WITH AN HOMOGENOUS ONE
        Screen('FrameRect', scr.LEtxt, sc(stim.fixL,scr.box),boxRectL, stim.horiz.height)
    %-----SHOW 
        Screen('DrawTexture',scr.w,scr.LEtxt)
        [dummy, offsetStim]=flip(inputMode, scr.w);
    
  %--SWAP FOR RIGHT EYE 
    if stereoMode==1
        fwrite(portCOM,'a','char');
    end
    %--background
        Screen('FillRect', scr.REtxt ,sc(scr.backgr,scr.box),boxRectR)
    %-----fixation
        drawDichFixation3(scr,stim,2,1);
    %------ Big boxes (Outside frames)                        %REPLACED HASHED FRAMES WITH AN HOMOGENOUS ONE
        Screen('FrameRect', scr.REtxt, sc(stim.fixL,scr.box),boxRectR, stim.horiz.height)
    %-----SHOW 
        Screen('DrawTexture',scr.w,scr.REtxt)
        [dummy, offsetStim]=flip(inputMode, scr.w);
        
  expe.stimTime= offsetStim-firstOFFRight;
    
 %--------------------------------------------------------------------------
 %   End of OFF ON trial - save the trial in trials
 %--------------------------------------------------------------------------
     trial=trial+1;
     trials=[trials;trial,thisTrial,correctFlag, runNb, offTime, onTime, increment];
     perf.CR=(n+1)-perf.hit-perf.miss-perf.FA ; %if not a miss, hit or FA, then it is a CR
     feuRouge(beginTime+2*stim.itemDuration*(n+1)/1000, inputMode)
     %disp(['Block duration: ', num2str(GetSecs-beginTime),' sec']);
    
catch err   %===== DEBUGING =====%
    warnings
    if exist('scr','var'); precautions(scr.w, 'off'); end
    disp(err)
    rethrow(err);
end

end

function quickQuit(scr)
        precautions(scr.w,'off')
        disp('ESCAPE Press : Crashing the experiment - data will not be saved')
        disp('--------------------------------------------------------------')
        xxx
end
