function [response,t,item]=getResponseKb(keyboardNum,timeLimit,inputMode,allowedResponses,robotFn,robotprofil,speed,skipCheck,skipWaitForKeyRelease,oneTime)
%Usage: [response,t]=getResponseKb(keyboardNum,timeLimit,inputMode,allowedResponses);
%--------------------------------------------------------------------------
% A conventional function to get a keypress code
%--------------------------------------------------------------------------
%Features:  -works for all plateforms
%           -specific to a given keyboard (keyboardNum)
%           -stops after a time limit in SEC 
%           -selective (allow only specific keypresses: allowedResponses - if not specified, all responses are ok)
%           -can work in robot mode: robotFn is the answering fonction with
%
%           arg robotprofil given to it
%           -give back the time t of the keypress
%           -give back the response coded as below
% Parameters:
%           -timeLimit = 0 or [] => no time limit; any other number is the duration in sec (check)
%           -speed should not be used (kept for compatibility (set it to 1)
%           -skipCheck=1 avoids the series of checks at the beginning
%           (which is time consuming, but useful)
%           -skipWaitForKeyRelease=1; skips the step that makes sure no key
%           is currently pressed (%replace getResponseKbLive)
%           -oneTime=1 allows to check the keypress only one time (in the loop) and then
%           returns something (returns 0 if no key is pressed)=>
%           in that case skipWaitForKeyRelease will automatically be set to 1(replaces getResponseFast) 
%
% Response Code Table: (the one to give to allowedResponses) 
%               0: no keypress before time limit
%               1: left
%               2: right
%               3: space
%               4: escape
%               5: up
%               6: down
%               7: enter
%               8: backspace 
%               9: slash
%               10-19: 0, 1, 2, ... ,9 (numpad)
%               20-45: abcdefghijklmnopqrstuvwxyz
%               46-47: é and è (1 and 2 on american keyboard)
%               48-51: ( and ) and  + amd 
%               52: enter (pad) - please use 7 instead
%               53: left control
%               54: left shift
%               55-64: numbers (not numpad) 1-9 + 0

% speed variable allowd to choose for the used function. If speed is
% needed (speed=1), then uses KbCheck. Uses GetChar otherwise (speed=2).  
%--------------------------------------------------------------------------
% Function created in nov 2009 - adrien chopin 
%--------------------------------------------------------------------------

if exist('skipCheck','var')==0 ||isempty(skipCheck)||(skipCheck==0)
    if ~exist('timeLimit','var')||isempty(timeLimit);timeLimit=0;end
    if ~exist('inputMode','var')||isempty(inputMode);inputMode=1;end
    if ~exist('keyboardNum','var')||isempty(keyboardNum);keyboardNum=-1;end
    if ~exist('speed','var')||isempty(speed);speed=1;end 
    if ~exist('skipWaitForKeyRelease','var')||isempty(skipWaitForKeyRelease);skipWaitForKeyRelease=0;end
    if ~exist('oneTime','var')||isempty(oneTime);oneTime=0;end
    if ~exist('allowedResponses','var')||isempty(allowedResponses);allowedResponses=[0:64];end;
    %if ~exist('ignoreAlreadyPressedKeysOneTime','var')||isempty(ignoreAlreadyPressedKeysOneTime);ignoreAlreadyPressedKeysOneTime=0;end;
end
%ignoreAlreadyPressedKeysOneTime=0;
if oneTime==1 %&& ignoreAlreadyPressedKeysOneTime==0
    skipWaitForKeyRelease=1;
end

if inputMode==1
    %USER MODE
    %--------------------------------------------------------------------------
    % make sure no key is currently pressed
    if skipWaitForKeyRelease==0
%         if ignoreAlreadyPressedKeysOneTime==1 && oneTime==1
%             if KbCheck(keyboardNum)
%                 response=0;
%                 t=0;
%                 return %abort
%             end
%         else
            while KbCheck(keyboardNum); end
       % end
    end
    %DisableKeysForKbCheck(119);
        
    %Build the key code matrix:
    itemsMatrix=cell(64,1);
    %                    1       2       3      4       5    6       7      8     9     10  11  12   13 14  15  16   17 18  19                    
    itemsMatrix(1:19)={'left','right','space','escape','up','down','enter','back', '/', '0','1','2','3','4','5','6','7','8','9'};
    %add letters to keyMatrix
    for i=1:26
       itemsMatrix{19+i}=alphabet(i);
    end
    itemsMatrix(46:54)={'é','è','(',')','+','-','enterPad','leftCtr','leftShift'};
    itemsMatrix(55:64)={'num1','num2','num3','num4','num5','num6','num7','num8','num9','num0'};
    keyMatrix=key(itemsMatrix);

    if ~exist('allowedResponses','var')||isempty(allowedResponses);allowedResponses=1:numel(keyMatrix);end
    
    % get proper key
    if speed==1 %default one, using KbCheck
        timeStart=GetSecs;
        checkOneTimeFlag=1;
        while checkOneTimeFlag && ((GetSecs-timeStart)<=timeLimit || timeLimit==0)
                [keyIsDown,secs,keyCode] = KbCheck(keyboardNum);    
            if keyIsDown                            
                thisKey=find(keyCode);
                if length(thisKey)>1; thisKey=thisKey(1);end %avoid multiple response bug
                response = find(keyMatrix==thisKey);
                item=itemsMatrix(response);
                if length(response)>1; response=response(1);end %avoid multiple entry bug
                if isempty(response)==0
                    if sum(response==allowedResponses)>0 %allowed
                        t=secs-timeStart; %time keypress
                        return;
                    end
                end
            end
            if oneTime==1
                checkOneTimeFlag=0; 
            end
        end
    else %experimental one, using GetChar, forget about it
        FlushEvents('keyDown');
        timeStart=GetSecs;
        while (GetSecs-timeStart)<=timeLimit || timeLimit==0
            keyIsDown=0;
            [thisKey,secs] = GetChar;
            if isempty(thisKey)==0; keyIsDown=1;end
            if keyIsDown
                if length(thisKey)>1; thisKey=thisKey(1);end
                response = find(strcmp(itemsMatrix,thisKey));
                item=itemsMatrix(response);
                if isempty(response)==0
                    if sum(response==allowedResponses)>0 %allowed
                        t=secs.secs-timeStart; %time keypress
                        return;
                    end
                end
            end
        end
    end

        
   %should comes over here only if time is out
   t=timeLimit;
   response=0;
else
   %ROBOT MODE
   %-----------------------------------------------------------------------
 response=feval(robotFn,robotprofil);
%     noise1=norminv(rand(1),0,0.05);
%     noise2=norminv(rand(1),0,0.05);
%     diff=Lum2ContrSym(robotprofil(2),15)+noise1-(noise2+(Lum2ContrSym(robotprofil(3),15))*ratios(robotprofil(6)));
%     %diff=noise1+noise2;
%     if diff<0
%         balance=2;
%     elseif diff>0
%         balance=1;
%     else
%       balance= randsample([1,2],1);
%     end
%     %balance=1 if left eye seen and 2 otherwise
%     choice=[robotprofil(4),robotprofil(5)];

%    errorRate=5/100;% here is the % of error
%    if rand(1)<errorRate
%         responseKey=3-choice(balance); %error
%     else
%         responseKey=choice(balance);
%     end
   t=0.1;
end
