function drawDichFixation3(scr,stim,eye,fixationColor,missingDot)
%This version 3 uses textures window to be compatible with stereo mode

if ~exist('eye','var') || isempty(eye); eye=0;end % eye = 0 is binocular, eye = 1 is LE, eye = 2 is RE
if ~exist('fixationColor','var') || isempty(fixationColor); fixationColor=0;end % fixationColor = 0 is black dot, fixationColor = 1 is white dot
if ~exist('missingDot','var') || isempty(missingDot); missingDot=0;end % missingDot = 0 -draws central dot, 1 dont
if ~isfield(stim,'fixL') ; stim.fixL= stim.LminL;end 
if ~isfield(stim,'fixR') ; stim.fixR= stim.LminR;end 

maxi=round(stim.fixationLength+2*stim.fixationOffset+stim.fixationLineWidth/2);
        
if eye==0 || eye==1 %LEFT EYE
    %-- no go zone (with no dots, just fixation)
        Screen('FillOval', scr.LEtxt ,sc(scr.backgr,scr.box) ,[scr.LcenterXLine-maxi scr.LcenterYLine-maxi scr.LcenterXLine+maxi scr.LcenterYLine+maxi]) ;

    %-- Vertical lines (binocular)
        rectVL1 = [scr.LcenterXLine-stim.fixationLineWidth/2, scr.LcenterYLine-stim.fixationLength-stim.fixationOffset,  scr.LcenterXLine+stim.fixationLineWidth/2,...
            scr.LcenterYLine-stim.fixationOffset];
        rectVL2 = [scr.LcenterXLine-stim.fixationLineWidth/2, scr.LcenterYLine+stim.fixationOffset ,  scr.LcenterXLine+stim.fixationLineWidth/2,...
            scr.LcenterYLine+stim.fixationLength+stim.fixationOffset];
       Screen('FillRect', scr.LEtxt, sc(stim.fixL,scr.box), rectVL1); 
       Screen('FillRect', scr.LEtxt, sc(stim.fixL,scr.box), rectVL2); 
        
    %-- Horizontal triangles (binocular)
        polyCoord1L = [scr.LcenterXLine-stim.fixationOffset, scr.LcenterYLine; ...
            scr.LcenterXLine-stim.fixationOffset-round(stim.fixationLength), scr.LcenterYLine+stim.fixationLineWidth;...
            scr.LcenterXLine-stim.fixationOffset-round(stim.fixationLength), scr.LcenterYLine-stim.fixationLineWidth];     
        polyCoord2L = [scr.LcenterXLine+stim.fixationOffset, scr.LcenterYLine; ...
            scr.LcenterXLine+stim.fixationOffset+round(stim.fixationLength), scr.LcenterYLine+stim.fixationLineWidth;...
            scr.LcenterXLine+stim.fixationOffset+round(stim.fixationLength), scr.LcenterYLine-stim.fixationLineWidth];
        Screen('FillPoly', scr.LEtxt ,sc(stim.fixL,scr.box), polyCoord1L, 1);
        Screen('FillPoly', scr.LEtxt ,sc(stim.fixL,scr.box), polyCoord2L, 1);
        
     %-- centre fixation zone (binocular circle)
        Screen('FrameOval', scr.LEtxt ,sc(stim.fixL,scr.box) ,[scr.LcenterXLine-maxi scr.LcenterYLine-maxi scr.LcenterXLine+maxi scr.LcenterYLine+maxi] ,stim.fixationLineWidth) ;

     %-- Middle fixation dot (binocular)
        if missingDot == 0
            if fixationColor == 0 %black 
                Screen('DrawDots', scr.LEtxt, [scr.LcenterXDot;scr.LcenterYDot], stim.fixationDotSize,sc(stim.fixL,scr.box));
            else %white
                Screen('DrawDots', scr.LEtxt, [scr.LcenterXDot;scr.LcenterYDot], stim.fixationDotSize,sc(stim.LmaxL,scr.box));
            end
        end
end

if eye==0 || eye==2 %RIGHT EYE
    %-- no go zone (with no dots, just fixation)
        Screen('FillOval', scr.REtxt ,sc(scr.backgr,scr.box) ,[scr.RcenterXLine-maxi scr.RcenterYLine-maxi scr.RcenterXLine+maxi scr.RcenterYLine+maxi]);

    %-- vertical lines (binocular)
        rectVR1 = [scr.RcenterXLine-stim.fixationLineWidth/2, scr.RcenterYLine+stim.fixationOffset,...
            scr.RcenterXLine+stim.fixationLineWidth/2, scr.RcenterYLine+stim.fixationOffset+stim.fixationLength];
        rectVR2 = [scr.RcenterXLine-stim.fixationLineWidth/2, scr.RcenterYLine-stim.fixationOffset-stim.fixationLength ,...
            scr.RcenterXLine+stim.fixationLineWidth/2, scr.RcenterYLine-stim.fixationOffset];
        Screen('FillRect', scr.REtxt, sc(stim.fixR,scr.box), rectVR1);
        Screen('FillRect', scr.REtxt, sc(stim.fixR,scr.box), rectVR2); 
        
     %-- horizontal triangles (binocular)
        polyCoord1R = [scr.RcenterXLine-stim.fixationOffset, scr.RcenterYLine; ...
            scr.RcenterXLine-stim.fixationOffset-round(stim.fixationLength), scr.RcenterYLine+stim.fixationLineWidth;...
            scr.RcenterXLine-stim.fixationOffset-round(stim.fixationLength), scr.RcenterYLine-stim.fixationLineWidth];
        polyCoord2R = [scr.RcenterXLine+stim.fixationOffset, scr.RcenterYLine; ...
            scr.RcenterXLine+stim.fixationOffset+round(stim.fixationLength), scr.RcenterYLine+stim.fixationLineWidth;...
            scr.RcenterXLine+stim.fixationOffset+round(stim.fixationLength), scr.RcenterYLine-stim.fixationLineWidth];
        Screen('FillPoly', scr.REtxt ,sc(stim.fixR,scr.box), polyCoord1R, 1);
        Screen('FillPoly', scr.REtxt ,sc(stim.fixR,scr.box), polyCoord2R, 1);
        
     %-- centre fixation zone (binocular circle)
            Screen('FrameOval', scr.REtxt ,sc(stim.fixR,scr.box) ,[scr.RcenterXLine-maxi scr.RcenterYLine-maxi scr.RcenterXLine+maxi scr.RcenterYLine+maxi] ,stim.fixationLineWidth);

     %-- Middle fixation dot (binocular)
        if missingDot == 0
            if fixationColor == 0 %black 
                Screen('DrawDots', scr.REtxt, [scr.RcenterXDot;scr.RcenterYDot], stim.fixationDotSize,sc(stim.fixR,scr.box));
            else %white
                Screen('DrawDots', scr.REtxt, [scr.RcenterXDot;scr.RcenterYDot], stim.fixationDotSize,sc(stim.LmaxR,scr.box));
            end
        end
end

        
        
       
        
    
    
        
    
       
       
        
    
        
            

