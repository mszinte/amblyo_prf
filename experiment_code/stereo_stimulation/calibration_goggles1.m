function [calib]=calibration_goggles1(expe,scr,stim,sounds, inputMode, displayMode,calib,stereoMode)
%--------------------------------------------------------------------------
%   CALIBRATION FOR VERTICAL EYE POSITION AND CONTRAST
%--------------------------------------------------------------------------

% ------------- ALLOWED RESPONSES (find the codes in getResponseKb) -----%
%               3:  space
%               4:  escape
%               55-59 - numbers 1 to 5
    allowR=[3:4,55:58]; %space, escape, 1 to 4
%--------------------------------------------------------------------------

    calib.leftContrNum=log(calib.leftContr/(1-calib.leftContr)); %a number that we vary between -inf and inf and that we map betw 0 and 1 with a sigmoid
    calib.rightContrNum=log(calib.rightContr/(1-calib.rightContr));

    scr.LcenterXLineIni= scr.LcenterXLine ;
    scr.LcenterXDotIni = scr.LcenterXDot  ;
    scr.RcenterXLineIni= scr.RcenterXLine  ;
    scr.RcenterXDotIni = scr.RcenterXDot  ;

%--------------------------------------------------------------------------
%       FUSION SCREEN TO CHECK DISPLAY ----------%
%--------------------------------------------------------------------------
     disp('Step 1: Stereo Display Check - ask SS whether red lines are in LE and whether lines cross in top left corner.')
     disp('Press space when done...')
     WaitSecs(1);

     %temporary values for screen position and contrast
        scr.LcenterXLine= scr.LcenterXLineIni - calib.leftLeftShift;
        scr.LcenterXDot = scr.LcenterXDotIni - calib.leftLeftShift;
        scr.RcenterXLine= scr.RcenterXLineIni - calib.rightLeftShift;
        scr.RcenterXDot = scr.RcenterXDotIni - calib.rightLeftShift;
        scr.LcenterYLine = scr.centerYLine - calib.leftUpShift;
        scr.RcenterYLine = scr.centerYLine - calib.rightUpShift;
        scr.LcenterYDot = scr.centerYDot - calib.leftUpShift;
        scr.RcenterYDot = scr.centerYDot - calib.rightUpShift;
        calib.leftContr=1./(1+exp(-calib.leftContrNum));
        calib.rightContr=1./(1+exp(-calib.rightContrNum));
        [stim.LmaxL,stim.LminL]=contrSym2Lum(calib.leftContr,scr.backgr); %white and black, left eye
        [stim.LmaxR,stim.LminR]=contrSym2Lum(calib.rightContr,scr.backgr); %white and black, right eye
 
     keepON = 1;
     while keepON
        %LEFT EYE
        if stereoMode==1
            fwrite(expe.portCOM,'b','char');
        end
            Screen('FillRect', scr.LEtxt, sc(scr.backgr,scr.box))
            %-----draw fusion lines ---> one horizontal top, one vertical left -RED IN LE
            Screen('DrawLine', scr.LEtxt, sc([30, 0, 0],scr.box), 0, 100, scr.res(3), 100,3)
            Screen('DrawLine', scr.LEtxt, sc([30, 0, 0],scr.box), 100, 0, 100, scr.res(4),3)
            %-----left fixation
            drawDichFixation3(scr,stim,1);
            %---- SHOW
            Screen('DrawTexture',scr.w,scr.LEtxt)
            flip(inputMode, scr.w);

        %RIGHT EYE
        if stereoMode==1
            fwrite(expe.portCOM,'a','char');
        end
             Screen('FillRect', scr.REtxt, sc(scr.backgr,scr.box))
             %-----draw fusion lines ---> one horizontal top, one vertical left - GREEN IN RE
            Screen('DrawLine', scr.REtxt, sc([0, 30, 0],scr.box), 0, 150, scr.res(3), 150,3)
            Screen('DrawLine', scr.REtxt, sc([0, 30, 0],scr.box), 150, 0, 150, scr.res(4),3)
             %-----right fixation
            drawDichFixation3(scr,stim,2);    
            %---- SHOW
            Screen('DrawTexture',scr.w,scr.REtxt)
            flip(inputMode, scr.w);
            
            % RESPONSE INTAKE TO ESCAPE LOOP
            if KbCheck
                keepON=0;
            end
     end
 
disp('Step 2: Vertical and contrast Calibration: ask SS to use 1-4 to align circles vertically and ')
disp('to try to adjust contrast to get similar images (force a lower contrast in DE).')
disp('Press space when done...')
WaitSecs(1);
goFlag=1;
%--------------------------------------------------------------------------
%   LOOP TO ALLOW CALIBRATION
%--------------------------------------------------------------------------
while goFlag==1
    %--------------------------------------------------------------------------
    %   UPDATE LEFT AND RIGHT EYE COORDINATES AND CONTRAST
    %--------------------------------------------------------------------------      
        scr.LcenterXLine= scr.LcenterXLineIni - calib.leftLeftShift;
        scr.LcenterXDot = scr.LcenterXDotIni - calib.leftLeftShift;
        scr.RcenterXLine= scr.RcenterXLineIni - calib.rightLeftShift;
        scr.RcenterXDot = scr.RcenterXDotIni - calib.rightLeftShift;
        scr.LcenterYLine = scr.centerYLine - calib.leftUpShift;
        scr.RcenterYLine = scr.centerYLine - calib.rightUpShift;
        scr.LcenterYDot = scr.centerYDot - calib.leftUpShift;
        scr.RcenterYDot = scr.centerYDot - calib.rightUpShift;
        calib.leftContr=1./(1+exp(-calib.leftContrNum));
        calib.rightContr=1./(1+exp(-calib.rightContrNum));
        [stim.LmaxL,stim.LminL]=contrSym2Lum(calib.leftContr,scr.backgr); %white and black, left eye
        [stim.LmaxR,stim.LminR]=contrSym2Lum(calib.rightContr,scr.backgr); %white and black, right eye

    %--------------------------------------------------------------------------
    %   DISPLAY FRAMES + FIXATION
    %--------------------------------------------------------------------------
        %---- frames
        stim.horiz.contrast=calib.leftContr;
        stim.vert.contrast=calib.leftContr;
        horizframeMatL=ultimateGabor(scr.VA2pxConstant, stim.horiz);
        vertframeMatL=ultimateGabor(scr.VA2pxConstant, stim.vert);
        stim.horiz.contrast=calib.rightContr;
        stim.vert.contrast=calib.rightContr;
        horizframeMatR=ultimateGabor(scr.VA2pxConstant, stim.horiz);
        vertframeMatR=ultimateGabor(scr.VA2pxConstant, stim.vert);

        topFrameCoordL=[scr.LcenterXLine-stim.horiz.width/2,scr.LcenterYLine-stim.horiz.height/2-stim.vert.height/2,scr.LcenterXLine+stim.horiz.width/2,scr.LcenterYLine+stim.horiz.height/2-stim.vert.height/2];
        topFrameCoordR=[scr.RcenterXLine-stim.horiz.width/2,scr.RcenterYLine-stim.horiz.height/2-stim.vert.height/2,scr.RcenterXLine+stim.horiz.width/2,scr.RcenterYLine+stim.horiz.height/2-stim.vert.height/2];
        bottomFrameCoordL=[scr.LcenterXLine-stim.horiz.width/2,scr.LcenterYLine-stim.horiz.height/2+stim.vert.height/2,scr.LcenterXLine+stim.horiz.width/2,scr.LcenterYLine+stim.horiz.height/2+stim.vert.height/2];
        bottomFrameCoordR=[scr.RcenterXLine-stim.horiz.width/2,scr.RcenterYLine-stim.horiz.height/2+stim.vert.height/2,scr.RcenterXLine+stim.horiz.width/2,scr.RcenterYLine+stim.horiz.height/2+stim.vert.height/2];
        leftFrameL=[scr.LcenterXLine-stim.vert.width/2-stim.horiz.width/2,scr.LcenterYLine-stim.vert.height/2-stim.horiz.height/2,scr.LcenterXLine-stim.horiz.width/2+stim.vert.width/2,scr.LcenterYLine+stim.vert.height/2+stim.horiz.height/2];
        leftFrameR=[scr.RcenterXLine-stim.vert.width/2-stim.horiz.width/2,scr.RcenterYLine-stim.vert.height/2-stim.horiz.height/2,scr.RcenterXLine-stim.horiz.width/2+stim.vert.width/2,scr.RcenterYLine+stim.vert.height/2+stim.horiz.height/2];
        rightFrameL=[scr.LcenterXLine-stim.vert.width/2+stim.horiz.width/2,scr.LcenterYLine-stim.vert.height/2-stim.horiz.height/2,scr.LcenterXLine+stim.horiz.width/2+stim.vert.width/2,scr.LcenterYLine+stim.vert.height/2+stim.horiz.height/2];
        rightFrameR=[scr.RcenterXLine-stim.vert.width/2+stim.horiz.width/2,scr.RcenterYLine-stim.vert.height/2-stim.horiz.height/2,scr.RcenterXLine+stim.horiz.width/2+stim.vert.width/2,scr.RcenterYLine+stim.vert.height/2+stim.horiz.height/2];

        horizframeL=Screen('MakeTexture',scr.w,sc(horizframeMatL,scr.box));
        vertframeL=Screen('MakeTexture',scr.w,sc(vertframeMatL,scr.box));
        horizframeR=Screen('MakeTexture',scr.w,sc(horizframeMatR,scr.box));
        vertframeR=Screen('MakeTexture',scr.w,sc(vertframeMatR,scr.box));
   
        maxi=round(stim.fixationLength+2.*stim.fixationOffset+stim.fixationLineWidth);
        centerRectMaskCoordL=[scr.LcenterXLine,  scr.LcenterYLine-maxi, scr.LcenterXLine+maxi,scr.LcenterYLine+maxi];
        centerRectMaskCoordR=[scr.RcenterXLine-maxi,  scr.RcenterYLine-maxi, scr.RcenterXLine,scr.RcenterYLine+maxi ];
    
    %-------------------------   FUSION SCREEN TO CALIBRATE VERTICAL ----------%
      %--LEFT EYE
        if stereoMode==1
            fwrite(expe.portCOM,'b','char');
        end
            Screen('FillRect', scr.LEtxt, sc(scr.backgr,scr.box))
            %----left image frame
            Screen('DrawTextures',scr.LEtxt,[horizframeL,horizframeL,vertframeL,vertframeL],[],[topFrameCoordL',bottomFrameCoordL',...
                leftFrameL',rightFrameL'])
            %-----left fixation
            drawDichFixation3(scr,stim,1);    
            %----left mask %DRAW A MASK ON HALF THE CROSS TO CHECK COMPLEMENTARITY
            Screen('FillRect', scr.LEtxt, sc(scr.backgr,scr.box), centerRectMaskCoordL)
            %---- SHOW
            Screen('DrawTexture',scr.w,scr.LEtxt)
            flip(inputMode, scr.w);

      %--RIGHT EYE
        if stereoMode==1
            fwrite(expe.portCOM,'a','char');
        end
            Screen('FillRect', scr.REtxt, sc(scr.backgr,scr.box))
            %----right image frame
            Screen('DrawTextures',scr.REtxt,[horizframeR,horizframeR,vertframeR,vertframeR],[],[topFrameCoordR',bottomFrameCoordR',...
                leftFrameR',rightFrameR'])
            %-----right fixation
            drawDichFixation3(scr,stim,2);    
            %----right mask
            Screen('FillRect', scr.REtxt, sc(scr.backgr,scr.box), centerRectMaskCoordR)
            %---- SHOW
            Screen('DrawTexture',scr.w,scr.REtxt)
            flip(inputMode, scr.w);
    
    %---Close texture to avoid lag
        Screen('Close',horizframeL);
        Screen('Close',vertframeL);
        Screen('Close',horizframeR);
        Screen('Close',vertframeR);
    
    %         %--------------------------------------------------------------------------
    %         %   SCREEN CAPTURE
    %         %--------------------------------------------------------------------------
    %             theFrame=[150 0 650 500];
    %             Screen('FrameRect', scr.w, 255, theFrame)
    %             flip(inputMode, scr.w, [], 1);
    %             %WaitSecs(1)
    %             %im=Screen('GetImage', scr.w, theFrame);
    %             %save('im2.mat','im')
    %
       
    %--------------------------------------------------------------------------
    %   GET RESPONSE
    %--------------------------------------------------------------------------
        [responseKey, RT]=getResponseKb(scr.keyboardNum,0,inputMode,allowR,'robotModeDSTv1',0,1,1,1,1);
    
        if responseKey>0     
            %--------------------------------------------------------------------------
            %  Keys
            %--------------------------------------------------------------------------
            % 1 and 2 controls up-down axis
            % 3 and 4 controls contrast
            % Space validates the setting
            % Esc quits without saving
               
            % --- ESCAPE PRESS : escape the whole program ----%
            if responseKey==4
                disp('Voluntary Interruption')
                warnings
                precautions(scr.w, 'off');
                return
            end

            % --- SPACE BAR PRESS : escape the calibration with parameters ----%
            if responseKey==3
                goFlag=0;
            end
        
            
            % --- MODIFICATION OF LEFT AND RIGHT EYE POSITION  ----%
                if responseKey==55 %LE goes up, right goes down
                     calib.leftUpShift= calib.leftUpShift+1;
                     calib.rightUpShift= calib.rightUpShift-1;
                end

                if responseKey==56 %LE goes down, right goes up
                     calib.leftUpShift= calib.leftUpShift-1;
                     calib.rightUpShift= calib.rightUpShift+1;
                end

            % --- MODIFICATION OF DOMINANT EYE CONTRAST ----%
                if expe.DE == 1 %LE dominant
                    if responseKey==57
                         calib.leftContrNum= calib.leftContrNum-0.1;
                    end

                    if responseKey==58
                         calib.leftContrNum= calib.leftContrNum+0.1;
                    end

                else %RE dominant
                    if responseKey==57
                         calib.rightContrNum= calib.rightContrNum-0.1;
                    end

                    if responseKey==58
                         calib.rightContrNum= calib.rightContrNum+0.1;
                    end
                end
        end

    % ---------------------------------------------------------
    %    set calibration coordinate limits 
    % ---------------------------------------------------------            
        if (scr.LcenterXLineIni - stim.horiz.width/2 + calib.leftLeftShift)<0   % left OUTER boundary limit
            calib.leftLeftShift=calib.leftLeftShift-1;
        end
        
        if (scr.LcenterXLineIni + calib.leftLeftShift)>scr.res(3)% left inner
            calib.leftLeftShift=calib.leftLeftShift+1;
        end
        
        if (scr.RcenterXLineIni + calib.rightLeftShift)<0 % right inner
            calib.rightLeftShift=calib.rightLeftShift-1;
        end
        
        if (scr.RcenterXLineIni - calib.rightLeftShift)>scr.res(3) % right outer
            calib.rightLeftShift=calib.rightLeftShift+1;
        end
                
        if (scr.LcenterYLine-calib.leftUpShift)<0  % left upper
            calib.leftUpShift=calib.leftUpShift-1;
        end
        
        if (scr.RcenterYLine-calib.rightUpShift)<0 % right upper
            calib.rightUpShift=calib.rightUpShift-1;
        end
        
        if  (scr.LcenterYLine -calib.leftUpShift)>scr.res(4)
            calib.leftUpShift=calib.leftUpShift+1;% Left lower
        end
        if (scr.RcenterYLine -calib.rightUpShift)>scr.res(4) % right lower
            calib.rightUpShift=calib.rightUpShift+1;
        end

    
    %--------------------------------------------------------------------------
    %   DISPLAY MODE STUFF
    %--------------------------------------------------------------------------
    texts2Disp=sprintf('%5.0f %5.0f %5.0f %5.0f %5.1f %5.2f %5.1f %5.2f %5.3f', [calib.leftLeftShift,calib.leftUpShift,calib.rightLeftShift,calib.rightUpShift,calib.leftContrNum,calib.leftContr,calib.rightContrNum,calib.rightContr,calib.leftContr./calib.rightContr]);
    if displayMode==1
        displayText(scr,sc(stim.LminL,scr.box),[scr.LcenterXLine-75-maxi,scr.LcenterYLine-1-maxi-2.*scr.fontSize,scr.res(3),200],texts2Disp);
        displayText(scr,sc(stim.LminR,scr.box),[scr.RcenterXLine-75-maxi,scr.RcenterYLine-1-maxi-2.*scr.fontSize,scr.res(3),200],texts2Disp);
    end
end
end
