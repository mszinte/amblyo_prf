function [grayscaleImageMatrix,actualFWHMpp]=ultimateGabor(VA2pxConstant,structure, widthVA, heightVA, averageL, contrast,...
    tilt, spatialFrequencyDeg, phase, FWHM, dontcut, gaussianTilt, opt, discrete)
% Rewriting of older function called GaborTemplate. Main updates are:
%   -can now draw Gabors with asymetric sizes
%   -all arguments are clearer
%   -phase and tilt are corrected
%   -replaced halfHeight with by FWHM (full width at half maximum, and a precise one - deviation from FWHM is less than 1%)
%   -correct the max luminance so that the Gaussian blur does not decrease contrast (the contrast you asked for is the one you get)
%   -can accept all arguments into a unique structure
%
%--------------    Mandatory arg      -------------------------------------
% VA2pxConstant, the conversion factor (pp By degVA)
% structure - you can pass all arguments into a structure here and all other arguments below will become optional. Set to 0 if not using that.
%   [if you use structure, all other following arguments will be ignored]
% heightVA and widthVA are in VA (min size is equivalent to 3px)
% averageL - the average background luminance in cd/m2
% contrast is btw 0 and 1
% 
%--------------    Optional arguments      -------------------------------------
% tilt in degrees (0 being the horizontal)
%                 135 90  45 
%                   \ | /
%                     . -- 0
%                       \  
%                        320
% spatialFrequencyDeg, the SF in cycles/degrees (careful: high frequencies creates aliasing changing the tilt)
% FWHM, the full width at half maximum in VA
% phase = 0 by default(in radians) - typical sinus profile, meaning that when tilt is 0, and phase 0, the center value is 0 and it's negative under it.
%   if tilt = 90, then negative phases go rightward and positive phase go leftward
% dontcut = 1 (by default 0) means that we don't cut the stimulus with a circular aperture of the size of the stimulus
% if gaussianTilt is provided, an oriented gaussian enveloppe with tilt in deg will replace the isotropic gaussian enveloppe - for the moment
% this only supports values 0 (enveloppe along horizontal) and 90 (enveloppe along vertical)
% opt decides if we use absolute value (0) or not when computing the luminance profile (if we do, we allow negative contrast as a trick for counterphasing, for example)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% Adapted to STaM project Apr 2014 % Adrien Chopin...
% Adapted to ZIR project Sept 2010 % Adrien Chopin, Pascal Mamassian, Randolphe Blake
% Adapted to BRE Project July 09   % Adrien Chopin, Madison Capps, Pascal Mamassian
%-----------------------------------------------------------------------
%------------------     Goal    -------------------------------------------
%
%  Create a Gabor matrix
%
%--------------------------------------------------------------------------
%   Warnings: more sanity checks are needed to validate the drawing when using oriented enveloppes
%--------------------------------------------------------------------------


%--------------------------------------------------------------------------
%       DEFAULT VALUES
%--------------------------------------------------------------------------

    if isnumeric(structure) && structure==0
    else
        widthVA=structure.widthVA;
        heightVA=structure.heightVA;
        averageL=structure.averageL;
        contrast=structure.contrast;
        if isfield(structure, 'tilt')==0; tilt=0; else tilt=structure.tilt; end
        if isfield(structure, 'spatialFrequencyDeg')==0; spatialFrequencyDeg=1; else spatialFrequencyDeg=structure.spatialFrequencyDeg; end
        if isfield(structure, 'phase')==0; phase=0; else phase=structure.phase; end
        if isfield(structure, 'FWHM')==0; FWHM=100; else FWHM=structure.FWHM; end   
        if isfield(structure, 'dontcut')==0; dontcut=0; else dontcut=structure.dontcut; end
        if isfield(structure, 'opt')==0; opt=1; else opt=structure.opt; end
        if isfield(structure, 'gaussianTilt')==0; gaussianTilt=[]; else gaussianTilt=structure.gaussianTilt; end
        if isfield(structure, 'discrete')==0; discrete=[]; else discrete=structure.discrete; end
    end
    
    if ~exist('discrete','var') || isempty('discrete')==1;  discrete=0; end
    if ~exist('tilt','var') || isempty('tilt')==1;  tilt=0; end
    if ~exist('spatialFrequencyDeg','var') || isempty('spatialFrequencyDeg')==1; spatialFrequencyDeg=1; end
    if ~exist('phase','var') || isempty('phase')==1;  phase=0; end
    if ~exist('FWHM','var') || isempty('FWHM')==1;FWHM=100;end
    if ~exist('dontcut','var') || isempty('dontcut')==1;dontcut=0;end
    if ~exist('opt','var') || isempty('opt')==1;opt=1;end
    if ~exist('gaussianTilt','var');gaussianTilt=[];end
    if contrast>1; disp('Your contrast in gaborDrawing is >1 !!! Do something!'); end

%--------------------------------------------------------------------------
%       CREATE GABOR MATRIX
%--------------------------------------------------------------------------
    width=VA2pxConstant.*widthVA;
    height=VA2pxConstant.*heightVA;
    maxL=contrSym2Lum(contrast,averageL);
    phase=phase+pi;
    tilt=tilt+180;
    tiltInRadians = -(tilt+45) * pi / 180;
    gaussianSpaceConstantTarget = VA2pxConstant*FWHM/2.355; %in pixel/standard deviation (it's the size of std in pp);
    gaussianSpaceConstant=gaussianSpaceConstantTarget;
    halfWidth = round(width/2);
    halfHeight= round(height/2);
    if width<=3 || height<=3; disp('Warning, minimal size displayable for Gabor in gaborDrawing is 3 pixels.');end
    frequencyConstant=spatialFrequencyDeg*2*pi/VA2pxConstant;%en cycle par pixel
    [x y] = meshgrid(-halfWidth:halfWidth, -halfHeight:halfHeight);
    y=-y;
    
%--------------------------------------------------------------------------
%       ROTATE GABOR MATRIX
%--------------------------------------------------------------------------
    xrot=x.*cos(tiltInRadians)-y.*sin(tiltInRadians);
    yrot=x.*sin(tiltInRadians)+y.*cos(tiltInRadians);
    gratingMatrix =sin((xrot+yrot).*(frequencyConstant/sqrt(2))+phase);
    
    if discrete==1
        gratingMatrix(gratingMatrix<0)=-1;
        gratingMatrix(gratingMatrix>0)=1;
    end
    
    % for every value <0 == -1, every value >0 ==1
%--------------------------------------------------------------------------
%       APPLY GAUSSIAN ENVELOPPE
%--------------------------------------------------------------------------
    if isempty(gaussianTilt) == 0 %if this argument is provided, then the enveloppe is oriented with a given tilt
        if gaussianTilt == 0
            circularGaussianMatrix = exp(-(x.^2)./(2.*gaussianSpaceConstant.^2));
        elseif gaussianTilt == 90
            circularGaussianMatrix = exp(-(y.^2)./(2.*gaussianSpaceConstant.^2));
        end
    else %isotropic enveloppe
        circularGaussianMatrix = exp(-((x.^2) + (y.^2))./(2.*gaussianSpaceConstant.^2));   
    end
    
%--------------------------------------------------------------------------
%       APPLY or not AN APERTURE
%--------------------------------------------------------------------------
     if dontcut == 0
        radius=sqrt(x.^2+y.^2);
        circularGaussianMatrix = (radius<=(max(halfWidth,halfHeight))).*circularGaussianMatrix;
     end
    %plot(1:numel(circularGaussianMatrix(halfWidth,:)),circularGaussianMatrix(halfWidth,:))
    imageMatrix = gratingMatrix.* circularGaussianMatrix;

%--------------------------------------------------------------------------
%       SCALE LUMINANCE
%--------------------------------------------------------------------------
    if opt==0
        grayscaleImageMatrix = averageL + abs(maxL - averageL).* imageMatrix;
    else
        grayscaleImageMatrix = averageL + (maxL - averageL).* imageMatrix;
    end   

actualFWHMpp = [];
%measuring actual FWHM - only works if the half width falls before the end of the stimulus...and not in negative mode
%plot(1:numel(circularGaussianMatrix(halfWidth,:)),circularGaussianMatrix(halfWidth,:))
% [dummy,b]=min(abs(circularGaussianMatrix(halfWidth,:)-0.5)); %???because only 2 x 15.87% of the cumulated curse will be excluded of the FWHM area
%[dummy,d]=max(circularGaussianMatrix(halfWidth,:));
% actualFWHMpp=2*abs(b-d)

%test FHWM precision - run this in matlab command: for i=1:100;  [dum, g(i)]=ultimateGabor(100,0,1, 1, 10, 1, 0, 3, 0, i/100); end ; plot(1/100:1/100:1,g)
end

% 
% Old version
% rotMatrix=[cos(tiltInRadians),-sin(tiltInRadians);sin(tiltInRadians),cos(tiltInRadians)];
%VA2mmSize=10*VA2cm(1,scr.distFromScreen/10);%in mm/degreeVA (of Visual Angle)
%ppBydeg=scr.ppBymm*VA2mmSize;%in pixel by degree of visual angle
%for explamations, see http://en.wikipedia.org/wiki/Gaussian_blur and http://en.wikipedia.org/wiki/Full_width_at_half_maximum
%c2=a.*exp(-(((x+5).^ 2) + ((y+5).^ 2))/ (gaussianSpaceConstant ^ 2)).*(radius<=(stim.gaborSize/2));

% %--------------    mandatory arg      -------------------------------------
% % stim.gaborSize in pp
% % scr.distFromScreen in cm
% % averageL the background luminance in cd/m2
% % stim.contrast determines the amplitude of the Gabor
% %--------------------------------------------------------------------------
% % Adapted to ZIR project Sept 2010 % Adrien Chopin, Pascal Mamassian, Randolphe Blake
% % Adapted to BRE Project July 09   % Adrien Chopin, Madison Capps, Pascal Mamassian
% %-----------------------------------------------------------------------
% %--------------    optional arg      -------------------------------------
% % optional: tilt in degrees 
% %       WARNING: new reference tilt (opposite sense of previous one):
% %                135 90  45 
% %                  \ | /
% %                    . -- 0
% %                      \  
% %                       320
% % stim.spatialFrequencyDeg in cycles/degrees
% % stim.halfHeightVA, the half height of the gaussian enveloppe in visual angles
% % stim.steepness, a parameter that moves the Gabor from normal (=1) to square (around 10 but 2 is already big)
% % stim.asymetry, a parameter that creates alternancy of thin and thick
% % stripes instead of a regular Gabor (=0 if regular, until 1, if black thin thin stripes or -1 if white).
% % opt decides if we use absolute value or not for computing the luminance
% % (if we do, we allow negative contrast as a trick for counterphasing, for example)
% %--------------------------------------------------------------------------
% %
% %------------------     Goal    -------------------------------------------
% %
% % Creates a Gabor matrix
% %
% %--------------------------------------------------------------------------
% % Function created in july 2009 - adrien chopin 
% %--------------------------------------------------------------------------
% 
% if isfield(stim, 'tilt')==0;  tilt=0; end
% if isfield(stim, 'spatialFrequencyDeg')==0;  stim.spatialFrequencyDeg=2; end
% if isfield(stim, 'halfHeightVA')==0;  stim.halfHeightVA=0.45; end
% if isfield(stim, 'steepness')==0;  stim.steepness=1; end
% if isfield(stim, 'asymetry')==0;  stim.asymetry=0; end
% if isfield(stim, 'asymetry')==0;  stim.asymetry=0; end
% if ~exist('opt','var');opt=0;end
%  
% gray=averageL;
% white=contrSym2Lum(stim.contrast,averageL);
% 
% tiltInRadians = (360-tilt) * pi / 180;
% VA2mmSize=10*VA2cm(1,scr.distFromScreen/10);%in mm/degreeVA (of Visual Angle)
% ppBydeg=scr.ppBymm*VA2mmSize;%in pixel by degree of visual angle
% gaussianSpaceConstant = ppBydeg*stim.halfHeightVA*2.35;%in pixel/standard deviation
% 
% %to reduce the gabor size to the minimum
% half = stim.gaborSize/ 2;
% frequencyConstant=stim.spatialFrequencyDeg*2*pi/ppBydeg;%en cycle par pixel
% Array = (-half: half);
% [x y] = meshgrid(Array, Array);
% radius=sqrt(x.^2+y.^2);
% a1=sin(tiltInRadians)*frequencyConstant;
% a2=-cos(tiltInRadians)*frequencyConstant;
% gratingMatrix =sin(x*a1+y*a2);
% 
% %here, moves the grating down to creates asymetry
%     if stim.asymetry==0; 
%         stim.asymetryFactor=1;
%     else
%         stim.asymetryFactor=abs(1/stim.asymetry);
%     end
%     gratingMatrix=(gratingMatrix+stim.asymetry).*stim.asymetryFactor;
%     
% %here the steepness occurs (we multiply the amplitude of the sin and cut at
% %the limits to make it square
%     gratingMatrix=stim.steepness.*gratingMatrix;
%     gratingMatrix(gratingMatrix<-1)=-1; gratingMatrix(gratingMatrix>1)=1;
% 
% circularGaussianMatrix = exp(-((x.^ 2) + (y.^ 2))/ (gaussianSpaceConstant ^ 2)).*(radius<=(stim.gaborSize/2));
% %c2=a.*exp(-(((x+5).^ 2) + ((y+5).^ 2))/ (gaussianSpaceConstant ^ 2)).*(radius<=(stim.gaborSize/2));
% imageMatrix = gratingMatrix.* circularGaussianMatrix;
% 
% if opt==0
% 	grayscaleImageMatrix = gray + abs(white - gray).* imageMatrix;
% else
%     grayscaleImageMatrix = gray + (white - gray).* imageMatrix;
% end
% end
% 
% 


