function waitForKey(KbNb,inputMode)
%Special KbWait:
%KbNb = number of the keyboard input
%inputMode: 1 = user ; 2 = robot

if ~exist('inputMode','var'); inputMode=1;  end

if inputMode==1
    while KbCheck(KbNb); end;
    
        KbWait(KbNb,3);
end
