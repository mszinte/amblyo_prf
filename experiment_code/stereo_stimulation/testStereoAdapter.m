 function testStereoAdapter

scr.backgr=15;
scr.box=23;
screens=Screen('Screens')
scr.screenNumber=1
scr.res=Screen('Rect', scr.screenNumber)
scr.w=Screen('OpenWindow',scr.screenNumber, sc(scr.backgr,scr.box), [], 32, 2, [], 8);  
        scr.LE=Screen('OpenOffscreenWindow',scr.screenNumber ,sc(scr.backgr,scr.box), [], 32, [], 32);
        scr.RE=Screen('OpenOffscreenWindow',scr.screenNumber ,sc(scr.backgr,scr.box), [], 32, [], 32);
        mat = sc(scr.backgr.*ones(scr.res(4),scr.res(3)),scr.box);
        LEtxt=Screen('MakeTexture', scr.w,mat);
        REtxt=Screen('MakeTexture', scr.w,mat);
scr.centerX = scr.res(3)/2;
scr.centerY = scr.res(4)/2;
                    expe.portCOM = serial('COM2','BaudRate',57600, 'DataBits', 8, 'FlowControl', 'none', 'Parity', 'none', 'StopBits', 1);
                    fopen(expe.portCOM);
                    fwrite(expe.portCOM,'2', 'char'); % set the 3D control to manual mode
                disp('Dummy stereo frame')
                fwrite(expe.portCOM,'a','char');
                Screen('FillRect', scr.w ,sc(scr.backgr,scr.box)) ; 
                flip(1, scr.w);

disp('Flip test')
keepgoing=1;
 while keepgoing
    fwrite(expe.portCOM,'b','char'); %red in LE
    Screen('DrawLine', scr.w, sc([30, 0, 0],scr.box), 0, 20, scr.res(3), 20,3)
    Screen('DrawLine', scr.w, sc([30, 0, 0],scr.box), scr.centerX, 0, scr.centerX, scr.res(4),3)
    flip(1, scr.w);
     
    fwrite(expe.portCOM,'a','char'); %green in LE
    Screen('DrawLine', scr.w, sc([0, 30, 0],scr.box), 0, 40, scr.res(3), 40,3)
    Screen('DrawLine', scr.w, sc([0, 30, 0],scr.box), scr.centerX+20, 0, scr.centerX+20, scr.res(4),3)
    flip(1, scr.w);
    if KbCheck
        keepgoing=0;
    end
 end
    WaitSecs(1);
    
keepgoing=1;    
disp('Texture test')   
 while keepgoing
    fwrite(expe.portCOM,'b','char'); %red in LE
    Screen('DrawLine', LEtxt, sc([30, 0, 0],scr.box), 0, 20, scr.res(3), 20,3)
    Screen('DrawTexture',scr.w,LEtxt)
    Screen('DrawLine', LEtxt, sc([30, 0, 0],scr.box), scr.centerX, 0, scr.centerX, scr.res(4),3)
     Screen('DrawTexture',scr.w,LEtxt)
    flip(1, scr.w);
     
    fwrite(expe.portCOM,'a','char'); %green in LE
    Screen('DrawLine', REtxt, sc([0, 30, 0],scr.box), 0, 40, scr.res(3), 40,3)
    Screen('DrawTexture',scr.w,REtxt)
    Screen('DrawLine', REtxt, sc([0, 30, 0],scr.box), scr.centerX+20, 0, scr.centerX+20, scr.res(4),3)
     Screen('DrawTexture',scr.w,REtxt)
    flip(1, scr.w); 

    if KbCheck
        keepgoing=0;
    end
 end
    WaitSecs(1);
    
disp('Copy Window test')
keepgoing=1;
 while keepgoing
    fwrite(expe.portCOM,'b','char'); %red in LE
    Screen('DrawLine', scr.LE, sc([30, 0, 0],scr.box), 0, 20, scr.res(3), 20,3)
    Screen('CopyWindow',scr.LE,scr.w)
    Screen('DrawLine', scr.LE, sc([30, 0, 0],scr.box), scr.centerX, 0, scr.centerX, scr.res(4),3)
    Screen('CopyWindow',scr.LE,scr.w)
    flip(1, scr.w);
     
    fwrite(expe.portCOM,'a','char'); %green in LE
    Screen('DrawLine', scr.RE, sc([0, 30, 0],scr.box), 0, 40, scr.res(3), 40,3)
    Screen('CopyWindow',scr.RE,scr.w)
    Screen('DrawLine', scr.RE, sc([0, 30, 0],scr.box), scr.centerX+20, 0, scr.centerX+20, scr.res(4),3)
    Screen('CopyWindow',scr.RE,scr.w)
    flip(1, scr.w);
    if KbCheck
        keepgoing=0;
    end
 end
    WaitSecs(1);
    
    %CLOSE
    g = instrfind;   
    if ~isempty(g); 
         fclose(g);   
    end
    Screen('Close',LEtxt);
    Screen('Close',REtxt);
    sca
end

