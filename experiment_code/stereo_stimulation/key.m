function code=key(name)


%==================================================
%GOAL is to automatize and generalize used keycodes 
%between plateforms
%
% Use findKey to test a specific key code
%==================================================
%Created in feb 2008 by Adrien Chopin
%
%==================================================
% IN GETRESPONSEKB, codes are:
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
%               46-47: é and è
%               48-51: ( and ) and  + amd -
%               52: enter (pad)
%               53: left control
%               54: left shift
%               61-70: numbers (not numpad) 1-9 + 0

    if iscell(name)==1
        n=numel(name);
        for i=1:n
            index=name{i};
            code(i)=getCode(index); 
        end
    else
        code=getCode(name);
    end

end

function k=getCode(index)
    errorCode=0;
    %=====WINDOWS KEYS===
    %====================
    if IsWindows  
        switch index
            case {'left','leftKeyN','leftA'} %left Arrow
               k=37;
            case {'right','rightKeyN','rightA'} %right Arrow
                k=39;
            case {'rightCtr','leftHemiKeyN', 'ctrl'}
                 k=163;
            case {'rightHemiKeyN', '0Num', '0Pad'}
                k=96;
            case {'escape','esc','escapeKey','escapeKeyN'} %echap
                k=27;
            case {'enter','enterKey','entree'}
                k=13;
            case {'spaceBar','space'}
                k=32;
            case {'leftShift'}
                k=160;
            case {'leftCtr'}
                k=162;
            case {'up'}
                k=38;
            case {'down'}
                k=40;
            case {'backspace','backSpace','back'}
                k=8;
                %numpad numbers
            case {'0'}; k=96;   case {'1'}; k=97; case {'2'}; k=98;   case {'3'}; k=99;   case {'4'}; k=100; case {'5'}; k=101; case {'6'}; k=102;   case {'7'}; k=103; case {'8'}; k=104; case {'9'}; k=105; 
          %french keyboard change stuff below
            case {'é'}; k=210; case {'è'}; k=210;
            case {'('}; k=210; case {')'}; k=219; case {'/'}; k=111; case {'+'}; k=107; case {'-'}; k=109;
            case {'enterPad'}; k=13;
           %american keyboard numbers 0 - 9 (not numpad)
            case {'num1'}; k = 49;  case {'num2'};  k = 50; case {'num3'};  k=51 ; case {'num4'};  k = 52;
            case {'num5'}; k = 53;  case {'num6'};  k = 54; case {'num7'};  k=55 ; case {'num8'};  k = 56;
            case {'num9'}; k = 57;  case {'num0'};  k = 48; 
            otherwise
                errorCode=1;
        end
        if numel(index)==1 %unitary character
            if sum(index=='abcdefghijklmnopqrstuvwxyz')>0 
                kk=65:90;
                k=kk(index=='abcdefghijklmnopqrstuvwxyz');
                errorCode=0;
            end
        end
    else 
    %=====MAC KEYS======
    %====================
        switch index
            case {'left','leftKeyN','leftA'} %left Arrow
                k=80;
            case {'right','rightKeyN','rightA'} %right Arrow
                k=79;
            case{'rightCtr','leftHemiKeyN', 'ctrl'}
                 k=228;
            case {'leftCtr'}
                k=224;
            case {'rightHemiKeyN', '0Num'}
                k=98;
            case {'escape','esc','escapeKey','escapeKeyN'} %echap
                k=41;
            case {'enter','enterKey','entree'}
                k=40;
            case {'spaceBar','space'}
                k=44;
            case {'up'}
                k=82;
            case {'down'}
                k=81;
            case {'backspace','backSpace','back'}
                k=42;
            case {'0'}; k=98;   case {'1'}; k=89; case {'2'}; k=90;   case {'3'}; k=91;   case {'4'}; k=92; case {'5'}; k=93; case {'6'}; k=94;   case {'7'}; k=95; case {'8'}; k=96; case {'9'}; k=97; 
            case {'é'}; k=31; case {'è'}; k=36;
            case {'('}; k=34; case {')'}; k=45; case {'/'}; k=84;  case {'+'}; k=87; case {'-'}; k=86; 
            case {'enterPad'}; k=88;  
            case {'leftCtr'}; k=224;  
            case {'leftShift'}; k=225;  
                case {'num1'}; k = 31;  case {'num2'};  k = 31; case {'num3'};  k=31 ; case {'num4'};  k = 31;
            case {'num5'}; k = 31;  case {'num6'};  k = 31; case {'num7'};  k=31 ; case {'num8'};  k = 31;
            case {'num9'}; k = 31;  case {'num0'};  k = 31; 
            otherwise
                 errorCode=1;
        end
        if numel(index)==1 %unitary character
            if sum(index=='abcdefghijklmnopqrstuvwxyz')>0 
                %french keyboard
                %kk=[20     5     6     7     8     9    10    11    12    13    14    15    51    17    18    19     4    21    22    23    24    25    29    27    28    26];
                %american keyboard
                kk=4:29;
                k=kk(index=='abcdefghijklmnopqrstuvwxyz');
                errorCode=0;
            end
        end
    end


    %==ERROR DEBUG===
    %=================
    if errorCode==1 %no keycode defined for this index
                error('Error 1: No defined keycode for the index: %s; use findKey.m to find it and enter it into key.m', index);
    end
    
end
