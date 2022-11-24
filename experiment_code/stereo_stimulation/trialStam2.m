function [trials, expe]=trialStam2(blockTable,stim,scr,expe, sounds,inputMode, displayMode,stereoMode,portCOM)
%------------------------------------------------------------------------
% It is part of :
% STaM Project [Stereo-Training and MRI]
% June 2014 - Berkeley
%-----------------------------------------------------------------------
%
%================== Trial function is showing a block of ON OFF stim ====================================
%   Many blocks (probably 16) give a run - all runs are identical, not all blocks
%   Called by MRI_stam2 main experiment function
%   This function does:
%           - display stimuli, get response for attentional task
%=======================================================================

try
     
    
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
    %         [breakNb, trial, expe, lastBreakTime, responseKey, RT,beginInterTrial,stimTime,jitter1,jitter2]=stimAndRegistrateDist(ShuffledTable(t,:), breakNb, trial, lastBreakTime, scr, stim, expe, sounds, startTime, inputMode,...
    %             displayMode, goalCounter, destRectL1, destRectL2,destRectR1,destRectR2, language, block,beginInterTrial);
    %for jjj=1:11
    % --------------------------------------------------------------------------------------------------
    %   SELECT CURRENT BLOCK FEATURES (assuming it will be identical for all trials
    % --------------------------------------------------------------------------------------------------
    thisTrial = blockTable(1,:);
    pedestal = thisTrial(2); disparityLeft = thisTrial(7); disparityRight = thisTrial(8); closestStim = thisTrial(6);
    correlated = thisTrial(11);
    %correlated = 2; %HERE
    n = size(blockTable,1)-1; %nb of trials -1 because we start with an additional OFF and end with another ON

    if correlated==1
        stim.dotColor1L = stim.minLum; stim.dotColor2L = stim.maxLum;
        stim.dotColor1R = stim.minLum; stim.dotColor2R = stim.maxLum;
    else
        stim.dotColor1L = stim.minLum; stim.dotColor2L = stim.maxLum;
        stim.dotColor1R = stim.maxLum; stim.dotColor2R = stim.minLum;
    end
    % --------------------------------------------------------------------------------------------------
    %   Initialize attentional task (COMMENT THAT)
    % --------------------------------------------------------------------------------------------------
    lastCheck = GetSecs; %last time the task has been checked and the timers updated
    incrementTimeList = []; %list of all previous increment times (used to know whether is detected or not in time)
    correctFlag = 1; %correct by default
    uncorrectTimer = 0; %initialize correct timer
    correctTimer = 0; %initialize correct timer
    randomStart = rand(1).*360; %random start for perfAngle to avoid bias in attention
    perf = correctTimer/(n+1); %ratio time correct / time total at end of block
    perfAngle = (360*perf); %performance converted into a feedback circle arc angle to display
    circleColor= sc([scr.backgr 0 scr.backgr],scr.box); %standard color for feedback circle is purple
    trials = [];
    
    % --------------------------------------------------------------------------------------------------
    %   Initialize feedback color for the little square around fixation
    if correctFlag == 1
        % feedback correct is green
        feedback = sc([0 scr.backgr 0],scr.box);
    else %red otherwise
        feedback = sc([scr.backgr 0 0],scr.box);
    end
    
    %whenever performance reaches the max, feedback circle color changes to green
    if perf>=1
        circleColor = sc([0 scr.backgr 0],scr.box);
    end  
    
    % ------------- ALLOWED RESPONSES as a function of TIME (allows escape in the first 10 min)-----%
    %       Response Code Table:
    %               0: no keypress before time limit
    %               1: left
    %               2: right
    %               3: space
    %               4: escape
    %               5: up
    %               6: down
    %              52: enter (numpad)
    %              55: num 1            <- answer this when you see an dot increment (on fixation)
    %              56: num 2
    
     allowRS=[4,55];  %allowed response: PRESS 1 WHEN YOU SEE THE INCREMENT
    
    
    %--------------------------------------------------------------------------
    %   PRELOADING OF COORDINATES DURING INTERTRIAL
    %--------------------------------------------------------------------------
    
    %--------------------------------------------------------------------------
    %defines peripheric boxes rect (to be drawn inside with dots)
    %without outline (just inside)
    maxi=round(stim.fixationLength+2*stim.fixationOffset+stim.fixationLineWidth/2);
    
%     if stim.lateral == 0 %above below
%         aboveLRectOut = [scr.LcenterXLine-stim.RDSwidth/2+stim.fixationLineWidth, scr.LcenterYLine-stim.RDSheight-stim.RDSecc+stim.fixationLineWidth, scr.LcenterXLine+stim.RDSwidth/2-stim.fixationLineWidth+1, scr.LcenterYLine-stim.RDSecc-stim.fixationLineWidth+1];
%         aboveRRectOut = [scr.RcenterXLine-stim.RDSwidth/2+stim.fixationLineWidth, scr.RcenterYLine-stim.RDSheight-stim.RDSecc+stim.fixationLineWidth, scr.RcenterXLine+stim.RDSwidth/2-stim.fixationLineWidth+1, scr.RcenterYLine-stim.RDSecc-stim.fixationLineWidth+1];
%         belowLRectOut = [scr.LcenterXLine-stim.RDSwidth/2+stim.fixationLineWidth, scr.LcenterYLine+stim.RDSecc+stim.fixationLineWidth, scr.LcenterXLine+stim.RDSwidth/2-stim.fixationLineWidth+1, scr.LcenterYLine+stim.RDSheight+stim.RDSecc-stim.fixationLineWidth+1];
%         belowRRectOut = [scr.RcenterXLine-stim.RDSwidth/2+stim.fixationLineWidth, scr.RcenterYLine+stim.RDSecc+stim.fixationLineWidth, scr.RcenterXLine+stim.RDSwidth/2-stim.fixationLineWidth+1, scr.RcenterYLine+stim.RDSheight+stim.RDSecc-stim.fixationLineWidth+1];
%     else %left right
%         %left
%         aboveLRectOut = [scr.LcenterXLine-stim.RDSwidth+stim.fixationLineWidth-stim.RDSecc, scr.LcenterYLine-stim.RDSheight/2+stim.fixationLineWidth, scr.LcenterXLine-stim.RDSecc-stim.fixationLineWidth+1, scr.LcenterYLine+stim.fixationLineWidth/2+1+stim.RDSheight/2];
%         aboveRRectOut = [scr.RcenterXLine-stim.RDSwidth+stim.fixationLineWidth-stim.RDSecc, scr.RcenterYLine-stim.RDSheight/2+stim.fixationLineWidth, scr.RcenterXLine-stim.RDSecc-stim.fixationLineWidth+1, scr.RcenterYLine+stim.fixationLineWidth/2+1+stim.RDSheight/2];
%         %right
%         belowLRectOut = [scr.LcenterXLine+stim.RDSecc+stim.fixationLineWidth, scr.LcenterYLine-stim.RDSheight/2+stim.fixationLineWidth, scr.LcenterXLine+stim.RDSecc+stim.RDSwidth-stim.fixationLineWidth+1, scr.LcenterYLine+stim.fixationLineWidth/2+1+stim.RDSheight/2];
%         belowRRectOut = [scr.RcenterXLine+stim.RDSecc+stim.fixationLineWidth, scr.RcenterYLine-stim.RDSheight/2+stim.fixationLineWidth, scr.RcenterXLine+stim.RDSecc+stim.RDSwidth-stim.fixationLineWidth+1, scr.RcenterYLine+stim.fixationLineWidth/2+1+stim.RDSheight/2];
%         %background (left and right of meridian, with a hole where the stimuli are
%         bgRectLELeft = [scr.LcenterXLine-stim.backgrWidth/2, scr.LcenterYLine-stim.backgrHeight/2, scr.LcenterXLine, scr.LcenterYLine+stim.backgrHeight/2]; %left side
%         bgRectLERight = [scr.LcenterXLine, scr.LcenterYLine-stim.backgrHeight/2, scr.LcenterXLine+stim.backgrWidth/2, scr.LcenterYLine+stim.backgrHeight/2]; %right side
%         bgRectRELeft = [scr.RcenterXLine-stim.backgrWidth/2, scr.RcenterYLine-stim.backgrHeight/2, scr.RcenterXLine, scr.RcenterYLine+stim.backgrHeight/2] ;  
%         bgRectRERight = [scr.RcenterXLine, scr.RcenterYLine-stim.backgrHeight/2, scr.RcenterXLine+stim.backgrWidth/2, scr.RcenterYLine+stim.backgrHeight/2] ;  
    
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
%BE
        %big box rect left
        boxRectL= [scr.LcenterXLine-stim.horiz.width/2,scr.LcenterYLine-stim.vert.height/2,scr.LcenterXLine+stim.horiz.width/2,scr.LcenterYLine+stim.vert.height/2];
        boxRectR= [scr.RcenterXLine-stim.horiz.width/2,scr.RcenterYLine-stim.vert.height/2,scr.RcenterXLine+stim.horiz.width/2,scr.RcenterYLine+stim.vert.height/2];

        %left
            %cRectLeftL = [scr.LcenterXLine-stim.RDSwidth-stim.RDSecc, scr.LcenterYLine-stim.RDSheight/2, scr.LcenterXLine-stim.RDSecc, scr.LcenterYLine+stim.RDSheight/2];
             %centerRectLeftR = [scr.RcenterXLine-stim.RDSwidth-stim.RDSecc, scr.RcenterYLine-stim.RDSheight/2, scr.RcenterXLine-stim.RDSecc, scr.RcenterYLine+stim.RDSheight/2];
        %right
           % centerRectRightL = [scr.LcenterXLine+stim.RDSecc, scr.LcenterYLine-stim.RDSheight/2, scr.LcenterXLine+stim.RDSecc+stim.RDSwidth, scr.LcenterYLine+stim.RDSheight/2];
            %centerRectRightR = [scr.RcenterXLine+stim.RDSecc, scr.RcenterYLine-stim.RDSheight/2, scr.RcenterXLine+stim.RDSecc+stim.RDSwidth, scr.RcenterYLine+stim.RDSheight/2];
        %background (left and right of meridian, with a hole where the stimuli are
           % bgRectLELeft = [scr.LcenterXLine-stim.backgrWidth/2, scr.LcenterYLine-stim.backgrHeight/2, scr.LcenterXLine, scr.LcenterYLine+stim.backgrHeight/2]; %left side
           % bgRectLERight = [scr.LcenterXLine, scr.LcenterYLine-stim.backgrHeight/2, scr.LcenterXLine+stim.backgrWidth/2, scr.LcenterYLine+stim.backgrHeight/2]; %right side
           % bgRectRELeft = [scr.RcenterXLine-stim.backgrWidth/2, scr.RcenterYLine-stim.backgrHeight/2, scr.RcenterXLine, scr.RcenterYLine+stim.backgrHeight/2] ;  
           % bgRectRERight = [scr.RcenterXLine, scr.RcenterYLine-stim.backgrHeight/2, scr.RcenterXLine+stim.backgrWidth/2, scr.RcenterYLine+stim.backgrHeight/2] ;  
 %   end
    
    %                centerRectLeftL = [scr.LcenterXLine-stim.RDSwidth/2+stim.fixationLineWidth, scr.LcenterYLine-stim.RDSheight-stim.RDSecc+stim.fixationLineWidth, scr.LcenterXLine+stim.RDSwidth/2-stim.fixationLineWidth+1, scr.LcenterYLine-stim.RDSecc-stim.fixationLineWidth+1];
    %                centerRectLeftR = [scr.RcenterXLine-stim.RDSwidth/2+stim.fixationLineWidth, scr.RcenterYLine-stim.RDSheight-stim.RDSecc+stim.fixationLineWidth, scr.RcenterXLine+stim.RDSwidth/2-stim.fixationLineWidth+1, scr.RcenterYLine-stim.RDSecc-stim.fixationLineWidth+1];
    %                centerRectRightL = [scr.LcenterXLine-stim.RDSwidth/2+stim.fixationLineWidth, scr.LcenterYLine+stim.RDSecc+stim.fixationLineWidth, scr.LcenterXLine+stim.RDSwidth/2-stim.fixationLineWidth+1, scr.LcenterYLine+stim.RDSheight+stim.RDSecc-stim.fixationLineWidth+1];
    %                centerRectRightR = [scr.RcenterXLine-stim.RDSwidth/2+stim.fixationLineWidth, scr.RcenterYLine+stim.RDSecc+stim.fixationLineWidth, scr.RcenterXLine+stim.RDSwidth/2-stim.fixationLineWidth+1, scr.RcenterYLine+stim.RDSheight+stim.RDSecc-stim.fixationLineWidth+1];
    
    %with outline
    %box1L = [scr.LcenterXLine-stim.RDSwidth/2, scr.LcenterYLine-stim.RDSheight-stim.RDSecc, scr.LcenterXLine+stim.RDSwidth/2+1, scr.LcenterYLine-stim.RDSecc+1];
    %box1R = [scr.RcenterXLine-stim.RDSwidth/2, scr.RcenterYLine-stim.RDSheight-stim.RDSecc, scr.RcenterXLine+stim.RDSwidth/2+1, scr.RcenterYLine-stim.RDSecc+1];
    %box2L = [scr.LcenterXLine-stim.RDSwidth/2, scr.LcenterYLine+stim.RDSecc, scr.LcenterXLine+stim.RDSwidth/2+1, scr.LcenterYLine+stim.RDSheight+stim.RDSecc+1];
    %box2R = [scr.RcenterXLine-stim.RDSwidth/2, scr.RcenterYLine+stim.RDSecc, scr.RcenterXLine+stim.RDSwidth/2+1, scr.RcenterYLine+stim.RDSheight+stim.RDSecc+1];
    
    %generates every frames
        %nbFrames =  round (stim.itemDuration / ( 1000 * stim.frameTime))+20;
        nbFrames = n;
       % LEFT
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
      % RIGHT
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

    %BACKGROUND
       %LEFT SIDE of meridian for background (for each eye)
       %START HERE BY CORRECTING THAT
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
%     %transform all coordinates (that are rect centers) into rect windows coordinates
%     belowLrect = (cat(1,coordRightL-floor(stim.dotSize/2),coordRightL+floor(stim.dotSize/2)+1));
%     belowRrect = (cat(1,coordRightR-floor(stim.dotSize/2),coordRightR+floor(stim.dotSize/2)+1));
%     aboveLrect = cat(1,coordLeftL-floor(stim.dotSize/2),coordLeftL+floor(stim.dotSize/2)+1);
%     aboveRrect = cat(1,coordLeftR-floor(stim.dotSize/2),coordLeftR+floor(stim.dotSize/2)+1);
%     backgrLELeftrect = cat(1,coordBackgrLELeft-floor(stim.dotSize/2),coordBackgrLELeft+floor(stim.dotSize/2)+1);
%     backgrRELeftrect = cat(1,coordBackgrRELeft-floor(stim.dotSize/2),coordBackgrRELeft+floor(stim.dotSize/2)+1);
%     backgrLERightrect = cat(1,coordBackgrLERight-floor(stim.dotSize/2),coordBackgrLERight+floor(stim.dotSize/2)+1);
%     backgrRERightrect = cat(1,coordBackgrRERight-floor(stim.dotSize/2),coordBackgrRERight+floor(stim.dotSize/2)+1);
                                    
%--------------------------------------------------------------------------
%   DISPLAY FRAMES + FIXATION
%--------------------------------------------------------------------------

    %--------------------------------------------------------------------------
    %   START WITH AN OFF STIMULUS WHICH IS BASICALLY FIXATION
    %--------------------------------------------------------------------------
        %LEFT EYE SWAP STEREOADAPTER HERE
        if stereoMode==1
                fwrite(portCOM,'a','char');
        end
            %--- Background
                Screen('FillRect', scr.LEtxt, sc(scr.backgr,scr.box));
            % ------ Big boxes (Outside frames)                        %REPLACED HASHED FRAMES WITH AN HOMOGENOUS ONE
                Screen('FrameRect', scr.LEtxt, sc(stim.fixL,scr.box),boxRectL, stim.horiz.height)
            %-----fixation
                drawDichFixation3(scr,stim,1,1);
            %Arc showing time spent in a correct answer configuration
                Screen('FrameArc', scr.LEtxt ,circleColor ,[scr.LcenterXLine-maxi scr.LcenterYLine-maxi scr.LcenterXLine+maxi scr.LcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
            %DIRECT FEEDBACK
                Screen('FrameRect', scr.LEtxt ,feedback , [scr.LcenterXDot-stim.feedbackSizePp,scr.LcenterYDot-stim.feedbackSizePp,scr.LcenterXDot+stim.feedbackSizePp,scr.LcenterYDot+stim.feedbackSizePp] ,1) ;  
         %   if stereoMode==1
                Screen('DrawTexture',scr.w,scr.LEtxt)
                [dummy, firstOFFLeft]=flip(inputMode, scr.w);
           % end

        %RIGHT EYE SWAP STEREOADAPTER HERE
        if stereoMode==1
                fwrite(portCOM,'b','char');
        end
            %--- Background
               Screen('FillRect', scr.REtxt, sc(scr.backgr,scr.box));
       % end
           % ------ Big boxes (Outside frames)                      %REPLACE HASHED FRAMES WITH AN HOMOGENOUS ONE
                Screen('FrameRect', scr.REtxt, sc(stim.fixR,scr.box),boxRectR, stim.horiz.height)
            %-----fixation
                drawDichFixation3(scr,stim,2,1);
            %Arc showing time spent in a correct answer configuration
                Screen('FrameArc', scr.REtxt ,circleColor ,[scr.RcenterXLine-maxi scr.RcenterYLine-maxi scr.RcenterXLine+maxi scr.RcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
            %DIRECT FEEDBACK
                 Screen('FrameRect', scr.REtxt, feedback , [scr.RcenterXDot-stim.feedbackSizePp,scr.RcenterYDot-stim.feedbackSizePp,scr.RcenterXDot+stim.feedbackSizePp,scr.RcenterYDot+stim.feedbackSizePp] ,1) ;
           Screen('DrawTexture',scr.w,scr.REtxt)
           [dummy, firstOFFRight]=flip(inputMode, scr.w);
        
    feuRouge(expe.beginInterTrial+stim.interTrial/1000,inputMode);

    detectFlag = 0;
    alreadyResponded = 0; %1 if already responded on that 500ms
    while (GetSecs - firstOFFRight) < stim.itemDuration/1000 
            %--------------------------------------------------------------------------
            % UPDATE TIMERS aND DISPLAY THEM
            %--------------------------------------------------------------------------
               %update
                nowT=GetSecs;
                update=nowT-lastCheck;
                lastCheck = nowT;
                if correctFlag==1
                    correctTimer = correctTimer+update;
                else
                    uncorrectTimer = uncorrectTimer+update;
                end
               %display
                perf = correctTimer/(n+1);
                perfAngle = (360*perf); %performance converted into a feedback circle arc angle to display
                if perf>=1
                    circleColor = sc([0 scr.backgr 0],scr.box);
                end  
                %SWITCH ON LEFT EYE
                if stereoMode==1
                    fwrite(portCOM,'a','char');
                end
                %Arc showing time spent in a correct answer configuration
                    Screen('FrameArc', scr.LEtxt ,circleColor ,[scr.LcenterXLine-maxi scr.LcenterYLine-maxi scr.LcenterXLine+maxi scr.LcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                  %  if stereoMode==1
                  Screen('DrawTexture',scr.w,scr.LEtxt)
                        flip(inputMode, scr.w);   
                   % end
                %SWITCH ON RIGHT EYE
                if stereoMode==1
                    fwrite(portCOM,'b','char');
                end    
                   %Arc showing time spent in a correct answer configuration
                    Screen('FrameArc', scr.REtxt ,circleColor ,[scr.RcenterXLine-maxi scr.RcenterYLine-maxi scr.RcenterXLine+maxi scr.RcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
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
            
            %TO AVOID FALSE ERRORS - I DONT CHECK FOR RESPONSES HERE
%             if alreadyResponded == 0; %1 if already responded on that 500ms
%                 if responseKey==55  %detected stg
%                    detectFlag=1;
%                 elseif responseKey==4
%                     %ESCAPE
%                     quickQuit(scr)
%                 end
%                 %--------------------------------------------------------------------------
%                 %  CHECK DETECTION
%                 %--------------------------------------------------------------------------
%                 if detectFlag==1
%                     idxD=((GetSecs-incrementTimeList)<expe.detectTime);
%                     if any(idxD) %check whether increment in the last second
%                        %CORRECT DETECTION
%                         correctFlag = 1;
%                         feedback = sc([0 scr.backgr 0],scr.box);
%                         incrementTimeList(idxD)=[]; %remove oldest increment
%                         alreadyResponded = 1;
%                     else
%                         %FALSE ALARM
%                         correctFlag = 0;
%                         %incorrect == red
%                         feedback = sc([scr.backgr 0 0],scr.box);
%                     end
%                 end
%             
%                 %--------------------------------------------------------------------------
%                 %  CHECK MISS
%                 %--------------------------------------------------------------------------   
%                 if detectFlag==0
%                     idxM=((GetSecs-incrementTimeList)>expe.detectTime);
%                     if any(idxM) %check whether increment older than the last second
%                         correctFlag = 0;
%                         feedback = sc([scr.backgr 0 0],scr.box);
%                         incrementTimeList(idxM)=[];
%                     end
%                 end
%             end
            
    end
    
    % ---- TIMING CHECKS ---%
    %Missed = 0;  timetable=nan(size(belowLrect,3),1);
    
    %--------------------------------------------------------------------------
    %   START THE TRIAL LOOP WITH MOrE ON-OFF STIM
    %--------------------------------------------------------------------------
     for trial = 1:n      
        %--------------------------------------------------------------------------
        %  POTENTIAL INCREMENT
        %--------------------------------------------------------------------------
            increment = randsample([0 1], 1, 'true', [1-stim.attentionalP, stim.attentionalP]); %1: yes, 0: no increment
            if increment == 1 %temporarily increase white luminance for fixation
                stim.LmaxL = stim.LmaxL * expe.multiplier;
                stim.LmaxR = stim.LmaxR * expe.multiplier;
                incrementTimeList=[incrementTimeList, GetSecs];
            end
    
        %--------------------------------------------------------------------------
        %   ON LOOP - SHOW STIMULI
        %--------------------------------------------------------------------------
          %LEFT EYE SWAP STEREOADAPTER HERE
                if stereoMode==1
                    fwrite(portCOM,'a','char');
                end
                
                %delete the drawing areas
                    Screen('FillRect', scr.LEtxt ,sc(scr.backgr,scr.box),boxRectL ) ;%boxRectL
                %DRAW THE DOTS FULL CONTRAST
                %    Screen('DrawTextures', scr.w, textureIndex,  [], belowLrect(:,:,trial),[])
                %    Screen('DrawTextures', scr.w, textureIndex,  [], aboveLrect(:,:,trial),[])
                %RDS LE - left and right side
                %draw half of the dots with dotColor1
                    Screen('DrawDots', scr.LEtxt, coordLeftL(:,1:round(expe.nbDotsLeft/2),trial), stim.dotSize, sc(stim.dotColor1L,scr.box),[0,0], 2);
                   Screen('DrawDots', scr.LEtxt, coordRightL(:,1:round(expe.nbDotsRight/2),trial), stim.dotSize, sc(stim.dotColor1L,scr.box),[0, 0], 2);
                 %draw the other half with dotColor2
                    Screen('DrawDots', scr.LEtxt, coordLeftL(:,(round(expe.nbDotsLeft/2)+1):end,trial), stim.dotSize, [0 0 sc(stim.dotColor2L,scr.box)],[0, 0], 2);
                    Screen('DrawDots', scr.LEtxt, coordRightL(:,(round(expe.nbDotsRight/2)+1):end,trial), stim.dotSize, [0 0 sc(stim.dotColor2L,scr.box)],[0, 0], 2);
                %LE BACKGR RDS left and right side
                %draw half of the dots with dotColor1
                    Screen('DrawDots', scr.LEtxt, coordBackgrLELeft(:,1:round(expe.nbDotsBackL/2),trial), stim.dotSize, sc(stim.dotColor1L,scr.box),[0,0], 2);
                    Screen('DrawDots', scr.LEtxt, coordBackgrLERight(:,1:round(expe.nbDotsBackL/2),trial), stim.dotSize, sc(stim.dotColor1L,scr.box),[0, 0], 2);
                 %draw the other half with dotColor2
                    Screen('DrawDots', scr.LEtxt, coordBackgrLELeft(:,(round(expe.nbDotsBackL/2)+1):end,trial), stim.dotSize, sc(stim.dotColor2L,scr.box),[0, 0], 2);
                    Screen('DrawDots', scr.LEtxt, coordBackgrLERight(:,(round(expe.nbDotsBackL/2)+1):end,trial), stim.dotSize, sc(stim.dotColor2L,scr.box),[0, 0], 2);
                 % ------ Big boxes (Outside frames)                        %REPLACED HASHED FRAMES WITH AN HOMOGENOUS ONE
                    Screen('FrameRect', scr.LEtxt, sc(stim.fixL,scr.box),[scr.LcenterXLine-stim.horiz.width/2,scr.LcenterYLine-stim.vert.height/2,scr.LcenterXLine+stim.horiz.width/2,scr.LcenterYLine+stim.vert.height/2], stim.horiz.height)   
                %-----fixation
                    drawDichFixation3(scr,stim,1,1,0);
                %Arc showing time spent in a correct answer configuration
                    Screen('FrameArc', scr.LEtxt ,circleColor ,[scr.LcenterXLine-maxi scr.LcenterYLine-maxi scr.LcenterXLine+maxi scr.LcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                %DIRECT FEEDBACK
                    Screen('FrameRect', scr.LEtxt ,feedback , [scr.LcenterXDot-stim.feedbackSizePp,scr.LcenterYDot-stim.feedbackSizePp,scr.LcenterXDot+stim.feedbackSizePp,scr.LcenterYDot+stim.feedbackSizePp] ,1) ;
               % if stereoMode==1
                    Screen('DrawTexture',scr.w,scr.LEtxt)
                    [dummy, frameONLeft]=flip(inputMode, scr.w); %-max(0,Missed)
               % end
                
            %RIGHT EYE SWAP STEREOADAPTER HERE
                if stereoMode==1
                    fwrite(portCOM,'b','char');
                end
                    %delete the inner drawing areas
                   % Screen('FillRect', scr.REtxt ,sc(scr.backgr,scr.box),boxRectR);%boxRectR
               % end 
                %DRAW THE DOTS FULL CONTRAST
                  %  Screen('DrawTextures', scr.w, textureIndex,  [], belowRrect(:,:,trial),[])
                  %  Screen('DrawTextures', scr.w, textureIndex,  [], aboveRrect(:,:,trial),[])
                %RDS RE - left and right side
                %draw half of the dots with dotColor1
%                quickQuit(scr) %CHANGE scr.LEtxt back to scr.REtxt - use test3 %HERE HERE HERE
                    Screen('DrawDots', scr.REtxt, coordLeftR(:,1:round(expe.nbDotsLeft/2),trial), stim.dotSize, sc(stim.dotColor1R,scr.box),[0,0], 2);
                   Screen('DrawDots', scr.REtxt, coordRightR(:,1:round(expe.nbDotsRight/2),trial), stim.dotSize, sc(stim.dotColor1R,scr.box),[0, 0], 2);   
                %draw the other half with dotColor2
                    Screen('DrawDots', scr.REtxt, coordLeftR(:,(round(expe.nbDotsLeft/2)+1):end,trial), stim.dotSize, [0 0 sc(stim.dotColor2R,scr.box)],[0, 0], 2);
                    Screen('DrawDots', scr.REtxt, coordRightR(:,(round(expe.nbDotsRight/2)+1):end,trial), stim.dotSize,[0 0 sc(stim.dotColor2R,scr.box)],[0, 0], 2);
                %BACKGR RDS RE left and right side
                %draw half of the dots with dotColor1
                    Screen('DrawDots', scr.REtxt, coordBackgrRELeft(:,1:round(expe.nbDotsBackR/2),trial), stim.dotSize, sc(stim.dotColor1R,scr.box),[0,0], 2);
                    Screen('DrawDots', scr.REtxt, coordBackgrRERight(:,1:round(expe.nbDotsBackR/2),trial), stim.dotSize, sc(stim.dotColor1R,scr.box),[0, 0], 2);
                 %draw the other half with dotColor2
                    Screen('DrawDots', scr.REtxt, coordBackgrRELeft(:,(round(expe.nbDotsBackR/2)+1):end,trial), stim.dotSize, sc(stim.dotColor2R,scr.box),[0, 0], 2);
                    Screen('DrawDots', scr.REtxt, coordBackgrRERight(:,(round(expe.nbDotsBackR/2)+1):end,trial), stim.dotSize, sc(stim.dotColor2R,scr.box),[0, 0], 2);
                % ------ Big boxes (Outside frames)                      %REPLACE HASHED FRAMES WITH AN HOMOGENOUS ONE
                    Screen('FrameRect', scr.REtxt, sc(stim.fixR,scr.box),[scr.RcenterXLine-stim.horiz.width/2,scr.RcenterYLine-stim.vert.height/2,scr.RcenterXLine+stim.horiz.width/2,scr.RcenterYLine+stim.vert.height/2], stim.horiz.height)
                %-----fixation
                    drawDichFixation3(scr,stim,2,1,0);
                %Arc showing time spent in a correct answer configuration
                    Screen('FrameArc', scr.REtxt ,circleColor ,[scr.RcenterXLine-maxi scr.RcenterYLine-maxi scr.RcenterXLine+maxi scr.RcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                %DIRECT FEEDBACK
                    Screen('FrameRect', scr.REtxt ,feedback , [scr.RcenterXDot-stim.feedbackSizePp,scr.RcenterYDot-stim.feedbackSizePp,scr.RcenterXDot+stim.feedbackSizePp,scr.RcenterYDot+stim.feedbackSizePp] ,1) ;          
                    Screen('DrawTexture',scr.w,scr.REtxt)
                    [dummy, frameONRight]=flip(inputMode, scr.w); %-max(0,Missed)

           %--------------------------------------------------------------------------
           %   DISPLAY MODE STUFF
           %--------------------------------------------------------------------------
            if displayMode==1
        %    texts2Disp=sprintf('%+5.3f %+5.3f %+5.3f %+5.0f %+5.1f %+5.2f %+5.1f %+5.2f %+5.3f', [dispCenter, dispBg, targCloser, disparitySec]);

%                Screen('DrawLines',scr.w, [scr.LcenterXLine,scr.LcenterXLine,scr.LcenterXLine+1,scr.LcenterXLine+1,scr.LcenterXLine+2,scr.LcenterXLine+2,...
%                    scr.LcenterXLine+6,scr.LcenterXLine+6,scr.LcenterXLine+12,scr.LcenterXLine+12;0,scr.res(4),0,scr.res(4),...
%                    0,scr.res(4),0,scr.res(4),0,scr.res(4)],  1, sc([15,15,15],scr.box));
%                Screen('DrawLines',scr.w, [scr.RcenterXLine,scr.RcenterXLine,scr.RcenterXLine+1,scr.RcenterXLine+1,scr.RcenterXLine+2,scr.RcenterXLine+2,...
%                    scr.RcenterXLine+6,scr.RcenterXLine+6,scr.RcenterXLine+12,scr.RcenterXLine+12;0,scr.res(4),0,scr.res(4),...
%                    0,scr.res(4),0,scr.res(4),0,scr.res(4)],  1, sc([15,15,15],scr.box));

               Screen('DrawLines',scr.LEtxt, [scr.LcenterXLine,scr.LcenterXLine,scr.LcenterXLine-6,scr.LcenterXLine-6,...
                   scr.LcenterXLine+6,scr.LcenterXLine+6,scr.LcenterXLine+12,scr.LcenterXLine+12;0,scr.res(4),0,scr.res(4),...
                   0,scr.res(4),0,scr.res(4)],  1, sc([15,15,15],scr.box));
               Screen('DrawLines',scr.LEtxt, [scr.RcenterXLine,scr.RcenterXLine,scr.RcenterXLine-6,scr.RcenterXLine-6,...
                   scr.RcenterXLine+6,scr.RcenterXLine+6,scr.RcenterXLine+12,scr.RcenterXLine+12;0,scr.res(4),...
                   0,scr.res(4),0,scr.res(4),0,scr.res(4)],  1, sc([15,15,15],scr.box));
              Screen('DrawDots', scr.LEtxt, [scr.LcenterXLine;scr.LcenterYLine], 1, 0,[],2); 
%                for iii=-200:10:200
%                     Screen('DrawLine', scr.w, sc(stim.LminL,scr.box), scr.LcenterXLine+iii, scr.LcenterYLine+1000 ,  scr.LcenterXLine+iii, scr.LcenterYLine-1000 , 1);   %Left eye up line
%                     Screen('DrawLine', scr.w, sc(stim.LminL,scr.box), scr.RcenterXLine+iii, scr.RcenterYLine+1000 ,  scr.RcenterXLine+iii, scr.RcenterYLine-1000 , 1);   %Left eye up line
%                end
          %     displayText(scr,sc(stim.LminL,scr.box),[scr.LcenterXLine-75,scr.LcenterYLine+100-2.*scr.fontSize,scr.res(3),200],texts2Disp);
          %     displayText(scr,sc(stim.LminR,scr.box),[scr.RcenterXLine-75,scr.RcenterYLine+100-2.*scr.fontSize,scr.res(3),200],texts2Disp);
               Screen('DrawTexture',scr.w,scr.LEtxt)
               flip(inputMode, scr.w);
               waitForKey(scr.keyboardNum,inputMode);
               
           end
        while (GetSecs - frameONRight) < stim.itemDuration/1000 
            %--------------------------------------------------------------------------
            % UPDATE TIMERS aND DISPLAY THEM
            %--------------------------------------------------------------------------
               %update
                nowT=GetSecs;
                update=nowT-lastCheck;
                lastCheck = nowT;
                if correctFlag==1
                    correctTimer = correctTimer+update;
                else
                    uncorrectTimer = uncorrectTimer+update;
                end
               %display
               perf = correctTimer/(n+1);
               perfAngle = (360*perf); %performance converted into a feedback circle arc angle to display
                if perf>=1
                    circleColor = sc([0 scr.backgr 0],scr.box);
                end  
                
                %SWITCH ON LEFT EYE
                if stereoMode==1
                    fwrite(portCOM,'a','char');
                end
                %Arc showing time spent in a correct answer configuration
                    Screen('FrameArc', scr.LEtxt ,circleColor ,[scr.LcenterXLine-maxi scr.LcenterYLine-maxi scr.LcenterXLine+maxi scr.LcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                   % if stereoMode==1
                   Screen('DrawTexture',scr.w,scr.LEtxt)
                        flip(inputMode, scr.w);   
                   % end
                %SWITCH ON RIGHT EYE
                if stereoMode==1
                    fwrite(portCOM,'b','char');
                end    
                   %Arc showing time spent in a correct answer configuration
                    Screen('FrameArc', scr.REtxt ,circleColor ,[scr.RcenterXLine-maxi scr.RcenterYLine-maxi scr.RcenterXLine+maxi scr.RcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
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
                    else
                        %FALSE ALARM
                        correctFlag = 0;
                        %incorrect == red
                        feedback = sc([scr.backgr 0 0],scr.box);
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
                    end
                end
            end
        end
             
        %--------------------------------------------------------------------------
        %   End of OFF ON trial - save the trial in trials
        %--------------------------------------------------------------------------
            trials=[trials;trial,thisTrial,correctFlag, nan, nan, nan, increment];
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
    
        %--------------------------------------------------------------------------
        %   OFF LOOP - REMOVE STIMULI
        %--------------------------------------------------------------------------
            %--------------------------------------------------------------------------
            % INCREMENT
            %Put white luminance back to normal (to materialize increment)
            if increment == 1
                stim.LmaxL = stim.LmaxL / expe.multiplier;
                stim.LmaxR = stim.LmaxR / expe.multiplier;
                increment = 0;
            end
        
            %LEFT EYE SWAP STEREOADAPTER HERE
            if stereoMode==1
                fwrite(portCOM,'a','char');
            end
                %delete the inner drawing areas
                        Screen('FillRect', scr.LEtxt ,sc(scr.backgr,scr.box),boxRectL) ;
                % ------ Big boxes (Outside frames)                      %REPLACE HASHED FRAMES WITH AN HOMOGENOUS ONE
                     Screen('FrameRect', scr.LEtxt, sc(stim.fixL,scr.box),boxRectL, stim.horiz.height)
                %-----fixation
                    drawDichFixation3(scr,stim,1,1,0);
                %Arc showing time spent in a correct answer configuration
                    Screen('FrameArc', scr.LEtxt ,circleColor ,[scr.LcenterXLine-maxi scr.LcenterYLine-maxi scr.LcenterXLine+maxi scr.LcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                %DIRECT FEEDBACK
                    Screen('FrameRect', scr.LEtxt ,feedback , [scr.LcenterXDot-stim.feedbackSizePp,scr.LcenterYDot-stim.feedbackSizePp,scr.LcenterXDot+stim.feedbackSizePp,scr.LcenterYDot+stim.feedbackSizePp] ,1) ;
          %  if stereoMode==1    
                    Screen('DrawTexture',scr.w,scr.LEtxt)
                    [dummy, frameOFFLeft]=flip(inputMode, scr.w); %-max(0,Missed)
          %  end
            
            %RIGHT EYE SWAP STEREOADAPTER HERE
            if stereoMode==1
                fwrite(portCOM,'b','char');
            end
                %delete the inner drawing areas
                     Screen('FillRect', scr.REtxt ,sc(scr.backgr,scr.box),boxRectR);
           % end
                % ------ Big boxes (Outside frames)                      %REPLACE HASHED FRAMES WITH AN HOMOGENOUS ONE
                     Screen('FrameRect', scr.REtxt, sc(stim.fixR,scr.box),boxRectR, stim.horiz.height)
                %-----fixation
                    drawDichFixation3(scr,stim,2,1,0);
                %Arc showing time spent in a correct answer configuration
                    Screen('FrameArc', scr.REtxt ,circleColor ,[scr.RcenterXLine-maxi scr.RcenterYLine-maxi scr.RcenterXLine+maxi scr.RcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                %DIRECT FEEDBACK
                    Screen('FrameRect', scr.REtxt ,feedback , [scr.RcenterXDot-stim.feedbackSizePp,scr.RcenterYDot-stim.feedbackSizePp,scr.RcenterXDot+stim.feedbackSizePp,scr.RcenterYDot+stim.feedbackSizePp] ,1) ;
                    Screen('DrawTexture',scr.w,scr.REtxt)
                    [dummy, frameOFFRight]=flip(inputMode, scr.w); %-max(0,Missed)
              
        while (GetSecs - frameOFFRight) < stim.itemDuration/1000
            %--------------------------------------------------------------------------
            % UPDATE TIMERS aND DISPLAY THEM
            %--------------------------------------------------------------------------
               %update
                nowT=GetSecs;
                update=nowT-lastCheck;
                lastCheck = nowT;
                if correctFlag==1
                    correctTimer = correctTimer+update;
                else
                    uncorrectTimer = uncorrectTimer+update;
                end
               %display
                perf = correctTimer/(n+1);
                perfAngle = (360*perf); %performance converted into a feedback circle arc angle to display
                if perf>=1
                    circleColor = sc([0 scr.backgr 0],scr.box);
                end  
                
                %SWITCH ON LEFT EYE
                if stereoMode==1
                    fwrite(portCOM,'a','char');
                end
                %Arc showing time spent in a correct answer configuration
                    Screen('FrameArc', scr.LEtxt ,circleColor ,[scr.LcenterXLine-maxi scr.LcenterYLine-maxi scr.LcenterXLine+maxi scr.LcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                 %   if stereoMode==1
                        Screen('DrawTexture',scr.w,scr.LEtxt)
                        flip(inputMode, scr.w);   
                 %   end
                %SWITCH ON RIGHT EYE
                if stereoMode==1
                    fwrite(portCOM,'b','char');
                end    
                   %Arc showing time spent in a correct answer configuration
                    Screen('FrameArc', scr.REtxt ,circleColor ,[scr.RcenterXLine-maxi scr.RcenterYLine-maxi scr.RcenterXLine+maxi scr.RcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
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
                    else
                        %FALSE ALARM
                        correctFlag = 0;
                        %incorrect == red
                        feedback = sc([scr.backgr 0 0],scr.box);
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
                    end
                end
            end
        end
       
            %frameOff =frameOnset;
            % feuRouge(frameOnset+stim.frameTime-max(0,Missed),inputMode);
            %                 [dummy, frameOnset]=flip(inputMode, scr.w,frameOnset+stim.frameTime,1); %-max(0,Missed)

            % ---- TIMING CHECKS ---%
            %                  frameOnset = GetSecs;
            %                 % [dummy frameOnset FlipTimestamp]=flip(inputMode, scr.w,[],1);
            %                  Missed=frameOnset-(frameOff+stim.frameTime);
            %                  timetable(frame)=Missed;


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
   
    %--------------------------------------------------------------------------
    %   FINISH WITH AN ADDITIONAL ON STIMULUS 
    %--------------------------------------------------------------------------
        %--------------------------------------------------------------------------
        %   ON LOOP - SHOW STIMULI
        %--------------------------------------------------------------------------
          %LEFT EYE SWAP STEREOADAPTER HERE
           if stereoMode==1
                fwrite(portCOM,'a','char');
           end
                %delete the inner drawing areas
                    Screen('FillRect', scr.LEtxt ,sc(scr.backgr,scr.box),boxRectL) ; %boxRectL
                %DRAW THE DOTS FULL CONTRAST
%                     Screen('DrawTextures', scr.w, textureIndex,  [], belowLrect(:,:,trial),[])
%                     Screen('DrawTextures', scr.w, textureIndex,  [], aboveLrect(:,:,trial),[])
                %RDS LE - left and right side
                %draw half of the dots with dotColor1
                    Screen('DrawDots', scr.LEtxt, coordLeftL(:,1:round(expe.nbDotsLeft/2),trial), stim.dotSize, sc(stim.dotColor1L,scr.box),[0,0], 2);
                    Screen('DrawDots', scr.LEtxt, coordRightL(:,1:round(expe.nbDotsRight/2),trial), stim.dotSize, sc(stim.dotColor1L,scr.box),[0, 0], 2);
                 %draw the other half with dotColor2
                    Screen('DrawDots', scr.LEtxt, coordLeftL(:,(round(expe.nbDotsLeft/2)+1):end,trial), stim.dotSize, [0 0 sc(stim.dotColor2L,scr.box)],[0, 0], 2);
                    Screen('DrawDots', scr.LEtxt, coordRightL(:,(round(expe.nbDotsRight/2)+1):end,trial), stim.dotSize, [0 0 sc(stim.dotColor2L,scr.box)],[0, 0], 2);
                %LE BACKGR RDS left and right side
                %draw half of the dots with dotColor1
                    Screen('DrawDots', scr.LEtxt, coordBackgrLELeft(:,1:round(expe.nbDotsBackL/2),trial), stim.dotSize, sc(stim.dotColor1L,scr.box),[0,0], 2);
                    Screen('DrawDots', scr.LEtxt, coordBackgrLERight(:,1:round(expe.nbDotsBackL/2),trial), stim.dotSize, sc(stim.dotColor1L,scr.box),[0, 0], 2);
                 %draw the other half with dotColor2
                    Screen('DrawDots', scr.LEtxt, coordBackgrLELeft(:,(round(expe.nbDotsBackL/2)+1):end,trial), stim.dotSize, sc(stim.dotColor2L,scr.box),[0, 0], 2);
                    Screen('DrawDots', scr.LEtxt, coordBackgrLERight(:,(round(expe.nbDotsBackL/2)+1):end,trial), stim.dotSize, sc(stim.dotColor2L,scr.box),[0, 0], 2);
               % ------ Big boxes (Outside frames)                        %REPLACED HASHED FRAMES WITH AN HOMOGENOUS ONE
                    Screen('FrameRect', scr.LEtxt, sc(stim.fixL,scr.box),[scr.LcenterXLine-stim.horiz.width/2,scr.LcenterYLine-stim.vert.height/2,scr.LcenterXLine+stim.horiz.width/2,scr.LcenterYLine+stim.vert.height/2], stim.horiz.height)   
                %-----fixation
                    drawDichFixation3(scr,stim,1,1,0);
                %Arc showing time spent in a correct answer configuration
                    Screen('FrameArc', scr.LEtxt ,circleColor ,[scr.LcenterXLine-maxi scr.LcenterYLine-maxi scr.LcenterXLine+maxi scr.LcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                %DIRECT FEEDBACK
                    Screen('FrameRect', scr.LEtxt ,feedback , [scr.LcenterXDot-stim.feedbackSizePp,scr.LcenterYDot-stim.feedbackSizePp,scr.LcenterXDot+stim.feedbackSizePp,scr.LcenterYDot+stim.feedbackSizePp] ,1) ;
           %   if stereoMode==1  
                    Screen('DrawTexture',scr.w,scr.LEtxt)
                    [dummy, frameONLeft]=flip(inputMode, scr.w); %-max(0,Missed)
            %  end
            %RIGHT EYE SWAP STEREOADAPTER HERE
            if stereoMode==1
                fwrite(portCOM,'b','char');
            end
                %delete the inner drawing areas
                    Screen('FillRect', scr.REtxt ,sc(scr.backgr,scr.box),boxRectR);
       %    end
                %DRAW THE DOTS FULL CONTRAST
%                     Screen('DrawTextures', scr.w, textureIndex,  [], belowRrect(:,:,trial),[])
%                     Screen('DrawTextures', scr.w, textureIndex,  [], aboveRrect(:,:,trial),[])
            %RDS RE - left and right side
                %draw half of the dots with dotColor1
                    Screen('DrawDots', scr.REtxt, coordLeftR(:,1:round(expe.nbDotsLeft/2),trial), stim.dotSize, sc(stim.dotColor1R,scr.box),[0,0], 2);
                    Screen('DrawDots', scr.REtxt, coordRightR(:,1:round(expe.nbDotsRight/2),trial), stim.dotSize, sc(stim.dotColor1R,scr.box),[0, 0], 2);   
                %draw the other half with dotColor2
                    Screen('DrawDots', scr.REtxt, coordLeftR(:,(round(expe.nbDotsLeft/2)+1):end,trial), stim.dotSize, [0 0 sc(stim.dotColor2R,scr.box)],[0, 0], 2);
                    Screen('DrawDots', scr.REtxt, coordRightR(:,(round(expe.nbDotsRight/2)+1):end,trial), stim.dotSize, [0 0 sc(stim.dotColor2R,scr.box)],[0, 0], 2);
                %BACKGR RDS RE left and right side
                %draw half of the dots with dotColor1
                    Screen('DrawDots', scr.REtxt, coordBackgrRELeft(:,1:round(expe.nbDotsBackR/2),trial), stim.dotSize, sc(stim.dotColor1R,scr.box),[0,0], 2);
                    Screen('DrawDots', scr.REtxt, coordBackgrRERight(:,1:round(expe.nbDotsBackR/2),trial), stim.dotSize, sc(stim.dotColor1R,scr.box),[0, 0], 2);
                 %draw the other half with dotColor2
                    Screen('DrawDots', scr.REtxt, coordBackgrRELeft(:,(round(expe.nbDotsBackR/2)+1):end,trial), stim.dotSize, sc(stim.dotColor2R,scr.box),[0, 0], 2);
                    Screen('DrawDots', scr.REtxt, coordBackgrRERight(:,(round(expe.nbDotsBackR/2)+1):end,trial), stim.dotSize, sc(stim.dotColor2R,scr.box),[0, 0], 2);
               % ------ Big boxes (Outside frames)                      %REPLACE HASHED FRAMES WITH AN HOMOGENOUS ONE
                    Screen('FrameRect', scr.REtxt, sc(stim.fixR,scr.box),[scr.RcenterXLine-stim.horiz.width/2,scr.RcenterYLine-stim.vert.height/2,scr.RcenterXLine+stim.horiz.width/2,scr.RcenterYLine+stim.vert.height/2], stim.horiz.height)
                %-----fixation
                     drawDichFixation3(scr,stim,2,1,0);
                %Arc showing time spent in a correct answer configuration
                    Screen('FrameArc', scr.REtxt ,circleColor ,[scr.RcenterXLine-maxi scr.RcenterYLine-maxi scr.RcenterXLine+maxi scr.RcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                %DIRECT FEEDBACK
                    Screen('FrameRect', scr.REtxt ,feedback , [scr.RcenterXDot-stim.feedbackSizePp,scr.RcenterYDot-stim.feedbackSizePp,scr.RcenterXDot+stim.feedbackSizePp,scr.RcenterYDot+stim.feedbackSizePp] ,1) ; 
                    Screen('DrawTexture',scr.w,scr.REtxt)
                    [dummy, frameONRight]=flip(inputMode, scr.w); %-max(0,Missed)
            
        while (GetSecs - frameONRight) < stim.itemDuration/1000 
            %--------------------------------------------------------------------------
            % UPDATE TIMERS aND DISPLAY THEM
            %--------------------------------------------------------------------------
               %update
                nowT=GetSecs;
                update=nowT-lastCheck;
                lastCheck = nowT;
                if correctFlag==1
                    correctTimer = correctTimer+update;
                else
                    uncorrectTimer = uncorrectTimer+update;
                end
               %display
                perf = correctTimer/(n+1);
                perfAngle = (360*perf); %performance converted into a feedback circle arc angle to display
                if perf>=1
                    circleColor = sc([0 scr.backgr 0],scr.box);
                end                     
                      %SWITCH ON LEFT EYE
                if stereoMode==1
                    fwrite(portCOM,'a','char');
                end
                %Arc showing time spent in a correct answer configuration
                    Screen('FrameArc', scr.LEtxt ,circleColor ,[scr.LcenterXLine-maxi scr.LcenterYLine-maxi scr.LcenterXLine+maxi scr.LcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
                   % if stereoMode==1
                    Screen('DrawTexture',scr.w,scr.LEtxt)
                    flip(inputMode, scr.w);   
                  %  end
                %SWITCH ON RIGHT EYE
                if stereoMode==1
                    fwrite(portCOM,'b','char');
                end    
                   %Arc showing time spent in a correct answer configuration
                    Screen('FrameArc', scr.REtxt ,circleColor ,[scr.RcenterXLine-maxi scr.RcenterYLine-maxi scr.RcenterXLine+maxi scr.RcenterYLine+maxi],randomStart,perfAngle,stim.fixationLineWidth) ;
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
                    else
                        %FALSE ALARM
                        correctFlag = 0;
                        %incorrect == red
                        feedback = sc([scr.backgr 0 0],scr.box);
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
                    end
                end
            end
        end

    %         % ---- TIMING CHECKS ---%
    %                 nanmean(timetable)
    %                     nanstd(timetable)
    %                     sca
    %                     xx
    
    
%==================================================
%   ERASE ON STIMULUS
%==================================================
    %SWAP FOR LEFT EYE HERE
    if stereoMode==1
        fwrite(portCOM,'a','char');
    end
    %--background
        Screen('FillRect', scr.LEtxt ,sc(scr.backgr,scr.box), boxRectL);
    %-----fixation
        drawDichFixation3(scr,stim,1,1);
    % ------ Big boxes (Outside frames)                        %REPLACED HASHED FRAMES WITH AN HOMOGENOUS ONE
        Screen('FrameRect', scr.LEtxt, sc(stim.fixL,scr.box),boxRectL, stim.horiz.height)
  %  if stereoMode==1
        Screen('DrawTexture',scr.w,scr.LEtxt)
        [dummy, offsetStim]=flip(inputMode, scr.w);
  %  end
    
    %SWAP FOR RIGHT EYE HERE
    if stereoMode==1
        fwrite(portCOM,'b','char');
    end
        Screen('FillRect', scr.REtxt ,sc(scr.backgr,scr.box),boxRectR)
   % end
    %-----fixation
        drawDichFixation3(scr,stim,2,1);
    % ------ Big boxes (Outside frames)                        %REPLACED HASHED FRAMES WITH AN HOMOGENOUS ONE
        Screen('FrameRect', scr.REtxt, sc(stim.fixL,scr.box),boxRectR, stim.horiz.height)
         Screen('DrawTexture',scr.w,scr.REtxt)
         [dummy, offsetStim]=flip(inputMode, scr.w);
    expe.stimTime= offsetStim-firstOFFRight;
    
        %--------------------------------------------------------------------------
        %   End of OFF ON trial - save the trial in trials
        %--------------------------------------------------------------------------
            trial=trial+1;
            trials=[trials;trial,thisTrial,correctFlag, nan, nan, nan, increment];
            
 %     %------ Progression bar for robotMode ----%
%     if inputMode==2
%         Screen('FillRect',scr.w, sc([scr.fontColor,0,0],scr.box),[0 0 scr.res(3)*trial/expe.goalCounter 10]);
%         Screen('Flip',scr.w);
%     end
    
    
    
catch err   %===== DEBUGING =====%
    warnings
    if exist('scr','var'); precautions(scr.w, 'off'); end
    disp(err)
    rethrow(err);
    %save([cd,filesep,expe.file,'-crashlog'])
    %saveAll([cd,filesep,expe.file,'-crashlog.mat'],[cd,filesep,expe.file,'-crashlog.txt'])
end

end

function quickQuit(scr)
        precautions(scr.w,'off')
        disp('ESCAPE Press : Crashing the experiment - data will not be saved')
        disp('--------------------------------------------------------------')
              xxx
end
