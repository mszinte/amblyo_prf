function STAM
% Wrapper starter file for Berkeley fMRI protocol, EPI main part
% STaM Project [Stereo-Training and MRI]
% Mar 2015 - Berkeley
%-----------------------------------------------------------------------
initialParam.Box=23;
            %===================== INPUT MODE ==============================
            %1: User  ; 2: Robot 
            %The robot mode allows to test the experiment with no user awaitings
            %or long graphical outputs, just to test for obvious bugs
            initialParam.inputMode = 1;
            %==================== QUICK MODE ==============================
            %1: ON  ; 2: OFF 
            %The quick mode allows to skip all the input part at the beginning of
            %the experiment to test faster for what the experiment is.
            initialParam.quickMode =2; 
            %==================== DISPLAY MODE ==============================
            %1: ON  ; 2: OFF 
            %In Display mode, some chosen variables are displayed on the screen
            initialParam.displayMode = 2;
            %==================== STEREO MODE ==============================
            %1: ON  ; 2: OFF 
            %In stereo mode, can work with 3D goggles by switching images through
            %a COM port command.
            initialParam.stereoMode=1; 
            %===============================================================
	
    initialParam.fixationDuration = 15701;
    MRI_stam3(initialParam)
    
end

