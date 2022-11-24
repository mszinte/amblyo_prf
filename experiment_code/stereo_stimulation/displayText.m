function [finalX,finalY]=displayText(window,color,rect,strings)
%--------------------------------------------------------------------------
%Usage: displayText(window,color,rect,string)
%DONT FORGET TO PUT A SPACE AFTER EACH WORD
%--------------------------------------------------------------------------
%Features: -doesnt cut the words when return to the line
%          -draw them in rect
%          -adapt itself to the size of the font
%______________________________________________________________
%
%Goal: Display the text in rect
%
%--------------------------------------------------------------------------
%Param: 
%window.w: an onscreen
%window.res: onscreen resolution
%window.W: width of the screen in mm
%window.frameSep: the deviation between the center of the screen and the
%centers of the half screens, in mm
%color: your text color
%rect: [top left x, top left y, width, height]
%strings: your text
%mode: 1: mirror ; 2: stereo
%--------------------------------------------------------------------------
%Adapted from displaystereotext2 in nov 09
%Adapted by Adrien Chopin in August 2007
%From displaystereotex
%written 18/06/07 by Adrien Chopin
%To contact me: adrien.chopin@gmail.com
%--------------------------------------------------------------------------

if ~isfield(window,'fontSize');window.fontSize=20;end

Screen('TextFont',window.w,'Arial');
Screen('TextSize',window.w,window.fontSize);
%Screen('FrameRect',window.w,0,[rect(1),rect(2),rect(1)+rect(3),rect(2)+rect(4)]);

%split the string parameter in words (looks for space after adding one at the end)
strings=sprintf('%s ',strings);
indEnd=regexp(strings, '\s', 'end');
indDeb=[1, indEnd(1:end-1)+1];


side=rect(1); top=rect(2);
panelWidth=rect(3);
panelHeight=rect(4);
x=side;
y=top;
ppbychar(1)=window.fontSize;
for i=1:numel(indEnd)
    word=strings(indDeb(i):indEnd(i));
    if x+((numel(word)+1)*mean(ppbychar))>side+panelWidth %estimate final position
        %go to the next line if word too long except if word is longer
        %than a line
        if ((numel(word)+1)*mean(ppbychar))<=panelWidth
            x=side;
            y=y+2.5*mean(ppbychar);
        end
    end
    
    %if comes over, stop
    if y>top+panelHeight;
        break
    end
    [nx,y]=Screen('DrawText',window.w,word ,x,y,color);
    %fill a temporary database to estimate the nb of pp by char
    ppbychar(i)=abs(x-nx)/numel(word);
    x=nx;
end
finalX=x;
finalY=y;
end
