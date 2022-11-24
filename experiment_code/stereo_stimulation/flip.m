function [VBLTimestamp StimulusOnsetTime FlipTimestamp Missed Beampos] =flip(inputMode, varargin)
%alias de Screen('Flip',...)
%Use:
%[VBLTimestamp StimulusOnsetTime FlipTimestamp Missed Beampos] = flip(inputMode, windowPtr [, when] [, dontclear] [, dontsync] [, multiflip])
%Add input mode at the beginning (1: user; 2, robot)
%if ~exist('opt','inputMode');inputMode=1;end

    if inputMode==1
        commandPart1='[VBLTimestamp StimulusOnsetTime FlipTimestamp Missed Beampos] = Screen(''Flip''';
        commandPart2='';
        for i=1:numel(varargin)
           commandPart2=sprintf('%s,varargin{%d}',commandPart2,i);
        end
        commandPart3=');';
        command=strcat(commandPart1,commandPart2,commandPart3);
        eval(command);
    else
        VBLTimestamp=GetSecs;
        StimulusOnsetTime =VBLTimestamp;
        FlipTimestamp =VBLTimestamp;
        Missed =0;
    end

end