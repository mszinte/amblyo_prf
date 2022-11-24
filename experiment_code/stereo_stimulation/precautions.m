function precautions(w,switcher)
%==============================
%Generic function whose goal is to take some
%precautions during an experiment
%===============================
%Switcher can be on or off
%================================
%Created in feb 2008 by Adrien Chopin
%
%================================

%error managment, use warnings function to use this
global errorbook 

%Screen('BlendFunction',w, 'GL_ZERO', 'GL_ZERO')
switch switcher
    case {'on'}
        %KbName('UnifyKeyNames')
        FlushEvents;
        priorityLevel=MaxPriority(w);
        Priority(priorityLevel);
        HideCursor;
        echo off
        ListenChar(2);
        if IsWindows
            ShowHideWinTaskbarMex(0) 
        end
        %warning('off','MATLAB:dispatcher:InexactMatch') %disable match error warnings
        %Screen('Preference','Backgrounding',0);
    case{'off'}
        Priority(0);
        ShowCursor;
        ListenChar(0);
        if IsWindows
            ShowHideWinTaskbarMex(1) 
        end
        sca

        %clean the error managment
        if numel(errorbook)>0
            errorbook=cell(1);
            errorbook(1,1:2)={'Date and Time' '   Error Book'};
        end
end

end