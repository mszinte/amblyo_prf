function feuRouge(goalTime, inputMode)
%------------------------------------------------------------------------
% Basic function waiting that current time is superior or equal to goalTime
% in sec, except if in robotMode
% Adrien Chopin, November 2013 - Geneva
%------------------------------------------------------------------------

if inputMode==1
    while GetSecs<goalTime;    end;   
end