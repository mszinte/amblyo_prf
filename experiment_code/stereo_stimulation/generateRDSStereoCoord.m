function [coordL, coordR, nbDots] = generateRDSStereoCoord(nbFrames, heightpp, widthpp, dotDensity, apparentDotSize, coherence, speed, disparity, direction, exclusionArea)
%------------------------------------------------------------------------
% Goal : generate coordinates for dynamic random dot stereograms
% - generates a set of coords for each eye coordL and coordR
% -sequence:
% -generate random dots
% -insert disparity
% -remove MONOCULARLY the dots in the exclusion area and outside of the area
% -> the process let no monocular cues, but non-corresponding dots on all edges
%   (the outside edge and the inner edge with the exclusion area) 
%------------------------------------------------------------------------
%
%   nbFrames specifies the nb of frames for which coordinates will be generated
%   heightpp and widthpp defines a rect window whose left up corner pixel is 0,0
%   dotDensity in % defines the nb of dots drawed according to their apparentDotSize (FWHM) and the rect area
%   coherence in % - 0 means all dots are going in random direction
%   speed is in pp by frame
%   disparity is in pp (positive disparity is uncrossed)
%   direction is optional and decide the coherent motion direction in rad (0 is rigthward horizontal, pi/2 is upward vertical)
%   exclusionArea is a rect in which no dots will be picked
%
%   coordL and coordR dimensions are:
%       1:  x, y
%       2:  dot
%       3:  frame
if ~exist('direction','var') || isempty('direction')==1;direction=rand(1).*2*pi;end
if ~exist('exclusionArea','var') || isempty('exclusionArea')==1;exclusionArea=[0 0 0 0];end

halfDotSize=floor(apparentDotSize/2);
%first extend exclusion area, if it exists, to exclude dots that are crossing over, but whose center is not
if sum(exclusionArea)>0
    exclusionArea(1:2)=exclusionArea(1:2)-halfDotSize;
    exclusionArea(3:4)=exclusionArea(3:4)+halfDotSize;
end

%defines the nb of dots
areaSizepp = heightpp * widthpp;
nbDots = round((dotDensity/100) * (areaSizepp - (exclusionArea(3)-exclusionArea(1)+1).*(exclusionArea(4) - exclusionArea(2)+1))  /  (pi*(apparentDotSize/2)^2));
%+1 checked
coordL = nan(2,nbDots,nbFrames);

% [xArea, yArea] = meshgrid(0:apparentDotSize:widthpp, 0:apparentDotSize:heightpp);
 [xArea, yArea] = meshgrid(1:widthpp, 1:heightpp);
 xAreaLine=xArea(:); yAreaLine = yArea(:);
 sizeXY = numel(xAreaLine);

%choose the first dots randomly
chosenDots = randsample(sizeXY,nbDots, 0) ;
coordL(:, :, 1) = [xAreaLine(chosenDots)'; yAreaLine(chosenDots)'];
coordR = coordL;

%choose a random direction for the not coherent dot
anglesRad = rand(1,nbDots).*2*pi;

%and also one for the coherent dot
anglesRad(1,1:round(nbDots*coherence/100)) = direction;

%apply the direction to the frame step to get motion vectors
rotationMatrix=nan(2,nbDots);
for ii=1:nbDots %We first move all dots a step to the 0 deg direction (speed related) and then rotate around the initial position coordinates
    rotationMatrix(:,ii) =[speed,0]*[cos(anglesRad(ii)), -sin(anglesRad(ii));sin(anglesRad(ii)),cos(anglesRad(ii))];
end

%introduce disparity into left eye by translating everything with a given disparity shift (leftward) and copy pasting what is out of frame on the other side
coordL(1,:, 1) = coordL(1,:, 1) - disparity/2;
coordR(1,:, 1) = coordR(1,:, 1) + disparity/2; %opposite in RE

minLimit = 1+halfDotSize;
maxLimitWidth = widthpp-halfDotSize;
maxLimitHeight = heightpp-halfDotSize;
trueWidth = maxLimitWidth - minLimit +1;
trueHeight = maxLimitHeight - minLimit +1;
i=1;
% dot =0;
% dots2replaceN = 0;   
counter = 0;
   while counter < 3
      counter = 0;
        %===============================================================================================================
        %   if a dot reaches exclusion area, first, look whether it is outside in both eyes and if yes, replace it
             badDotsL = (coordL(1, :, i)>=exclusionArea(1) & coordL(2, :, i)>=exclusionArea(2) & coordL(1, :, i)<=exclusionArea(3) & coordL(2, :, i)<=exclusionArea(4));
             badDotsR = (coordR(1, :, i)>=exclusionArea(1) & coordR(2, :, i)>=exclusionArea(2) & coordR(1, :, i)<=exclusionArea(3) & coordR(2, :, i)<=exclusionArea(4));
          if any((badDotsL & badDotsR))==1
              dots2replace = (badDotsL & badDotsR);
              chosenDots = randsample(sizeXY,sum(dots2replace(:)), 0) ;
              temp1 = coordL(:,:, i); 
              temp2 = coordR(:,:, i);
              temp1(:,dots2replace) = [xAreaLine(chosenDots)'- disparity/2; yAreaLine(chosenDots)'];
              temp2(:,dots2replace) = [xAreaLine(chosenDots)'+ disparity/2; yAreaLine(chosenDots)'];
              coordL(:,:, i) = temp1;
              coordR(:,:, i) = temp2;
             % dots2replaceN = dots2replaceN + sum(dots2replace);
          else
              counter= counter +1;
          end
  
        %===============================================================================================================
        %   if a dot reaches exclusion area, but is only in one eye, redraw a new monocular dot but let the other mononcular one to avoid
        %   monocular cues
             badDotsL = (coordL(1, :, i)>=exclusionArea(1) & coordL(2, :, i)>=exclusionArea(2) & coordL(1, :, i)<=exclusionArea(3) & coordL(2, :, i)<=exclusionArea(4));
             badDotsR = (coordR(1, :, i)>=exclusionArea(1) & coordR(2, :, i)>=exclusionArea(2) & coordR(1, :, i)<=exclusionArea(3) & coordR(2, :, i)<=exclusionArea(4));
             monocularBadL = (badDotsL==1 & badDotsR==0);
             monocularBadR = (badDotsL==0 & badDotsR==1);
             if any(monocularBadL)
                 chosenDots = randsample(sizeXY,sum(monocularBadL(:)), 0) ;
                 temp1 = coordL(:,:, i); 
                 %temp2 = coordR(:,:, i);
                 %saveDotsR = coordR(:,badDotsL, i); 
                 temp1(:,monocularBadL) = [xAreaLine(chosenDots)'- disparity/2; yAreaLine(chosenDots)'];
                 %temp2(:,badDotsL) = [xAreaLine(chosenDots)'+ disparity/2; yAreaLine(chosenDots)'];
                 coordL(:,:, i) = temp1;
                 %coordR(:,:, i) = temp2;
                % dot= dot+sum(monocularBadL(:));
             else
                 counter = counter + 1;
             end
             if any(monocularBadR)
                 chosenDots = randsample(sizeXY,sum(monocularBadR(:)), 0) ;
                 %temp1 = coordL(:,:, i); 
                 temp2 = coordR(:,:, i);
                 %saveDotsL = coordL(:,badDotsR, i); 
                 %temp1(:,badDotsR) = [xAreaLine(chosenDots)'- disparity/2; yAreaLine(chosenDots)'];
                 temp2(:,monocularBadR) = [xAreaLine(chosenDots)'+ disparity/2; yAreaLine(chosenDots)'];
                 %coordL(:,:, i) = temp1;
                 coordR(:,:, i) = temp2;
               %  dot= dot+sum(monocularBadR(:));
             else
                 counter = counter + 1;
             end 
   end
   %===========================================================================
   % Finally, if coordinates are outside of frame, make it jump on the other side
     if any(coordL(1, :, i)<minLimit) ; coordL(1, coordL(1, :, i)<minLimit, i) = coordL(1, coordL(1, :, i)<minLimit, i) + trueWidth; end
     if any(coordR(1, :, i)<minLimit) ; coordR(1, coordR(1, :, i)<minLimit, i) = coordR(1, coordR(1, :, i)<minLimit, i) + trueWidth; end
     if any(coordL(2, :, i)<minLimit) ;  coordL(2, coordL(2, :, i)<minLimit, i) = coordL(2, coordL(2, :, i)<minLimit, i) + trueHeight;end
     if any(coordR(2, :, i)<minLimit) ;  coordR(2, coordR(2, :, i)<minLimit, i) = coordR(2, coordR(2, :, i)<minLimit, i) + trueHeight;end
     if any(coordL(1, :, i)>maxLimitWidth) ;  coordL(1, coordL(1, :, i)>maxLimitWidth, i) = coordL(1, coordL(1, :, i)>maxLimitWidth, i)- trueWidth;end
     if any(coordR(1, :, i)>maxLimitWidth) ;  coordR(1, coordR(1, :, i)>maxLimitWidth, i) = coordR(1, coordR(1, :, i)>maxLimitWidth, i) - trueWidth;end
     if any(coordL(2, :, i)>maxLimitHeight) ;  coordL(2, coordL(2, :, i)>maxLimitHeight, i) = coordL(2, coordL(2, :, i)>maxLimitHeight, i)- trueHeight;end
     if any(coordR(2, :, i)>maxLimitHeight) ;  coordR(2, coordR(2, :, i)>maxLimitHeight, i) = coordR(2, coordR(2, :, i)>maxLimitHeight, i) - trueHeight;end

   %  badDotsPerc1 = dot*100/sizeXY
   %  badDotsPerc2 = dots2replaceN*100/sizeXY

     %ADAPT BELOW FROM ABOVE WHENEVER ONE NEEDS TO MOVE THE DOTS
%move the dots across each frames
% if nbFrames>1
%     for i=2:nbFrames
%          % add the motion vectors 
%             coordsL = coordL(:, :, i-1);
%             coordL(:, :, i)=coordsL+rotationMatrix;
%             coordsR = coordR(:, :, i-1);
%             coordR(:, :, i)=coordsR+rotationMatrix;
% 
%       %if a dot reaches exclusion area, make it disappear and replace it
%         counter = 2;
%        while counter > 0
%           counter = 2;
%          badDotsL = (coordL(1, :, i)>=exclusionArea(1) & coordL(2, :, i)>=exclusionArea(2) & coordL(1, :, i)<=exclusionArea(3) & coordL(2, :, i)<=exclusionArea(4));
%          badDotsR = (coordR(1, :, i)>=exclusionArea(1) & coordR(2, :, i)>=exclusionArea(2) & coordR(1, :, i)<=exclusionArea(3) & coordR(2, :, i)<=exclusionArea(4));
%          if any(badDotsL)
%              chosenDots = randsample(sizeXY,sum(badDotsL(:)), 0) ;
%              temp1 = coordL(:,:, i); 
%              temp2 = coordR(:,:, i);
%             % saveDotsR = coordR(:,badDotsL, i); 
%              temp1(:,badDotsL) = [xAreaLine(chosenDots)'- disparity/2; yAreaLine(chosenDots)'];
%              temp2(:,badDotsL) = [xAreaLine(chosenDots)'+ disparity/2; yAreaLine(chosenDots)'];
%              coordL(:,:, i) = temp1;
%              coordR(:,:, i) = temp2;
%              
%          else
%              counter = counter - 1;
%          end
%          if any(badDotsR)
%              chosenDots = randsample(sizeXY,sum(badDotsR(:)), 0) ;
%              temp1 = coordL(:,:, i); 
%              temp2 = coordR(:,:, i);
%              % saveDotsL = coordL(:,badDotsR, i); 
%              temp1(:,badDotsR) = [xAreaLine(chosenDots)'- disparity/2; yAreaLine(chosenDots)'];
%              temp2(:,badDotsR) = [xAreaLine(chosenDots)'+ disparity/2; yAreaLine(chosenDots)'];
%              coordL(:,:, i) = temp1;
%              coordR(:,:, i) = temp2;
%          else
%              counter = counter - 1;
%          end 
%        end
% 
%         %if coordinates are outside of frame, make it jump on the other side
%          if any(coordL(1, :, i)<minLimit) ; coordL(1, coordL(1, :, i)<minLimit, i) = coordL(1, coordL(1, :, i)<minLimit, i) + trueWidth; end
%          if any(coordR(1, :, i)<minLimit) ; coordR(1, coordR(1, :, i)<minLimit, i) = coordR(1, coordR(1, :, i)<minLimit, i) + trueWidth; end
%          if any(coordL(2, :, i)<minLimit) ;  coordL(2, coordL(2, :, i)<minLimit, i) = coordL(2, coordL(2, :, i)<minLimit, i) + trueHeight;end
%          if any(coordR(2, :, i)<minLimit) ;  coordR(2, coordR(2, :, i)<minLimit, i) = coordR(2, coordR(2, :, i)<minLimit, i) + trueHeight;end
%          if any(coordL(1, :, i)>maxLimitWidth) ;  coordL(1, coordL(1, :, i)>maxLimitWidth, i) = coordL(1, coordL(1, :, i)>maxLimitWidth, i)- trueWidth;end
%          if any(coordR(1, :, i)>maxLimitWidth) ;  coordR(1, coordR(1, :, i)>maxLimitWidth, i) = coordR(1, coordR(1, :, i)>maxLimitWidth, i) - trueWidth;end
%          if any(coordL(2, :, i)>maxLimitHeight) ;  coordL(2, coordL(2, :, i)>maxLimitHeight, i) = coordL(2, coordL(2, :, i)>heightpp, i)- trueHeight;end
%          if any(coordR(2, :, i)>maxLimitHeight) ;  coordR(2, coordR(2, :, i)>maxLimitHeight, i) = coordR(2, coordR(2, :, i)>heightpp, i) - trueHeight;end
% 
%     %     %if coordinates are outside of frame, redraw a new dot
%     %     replaceVector = (coord(1, :, i)<0 | coord(2, :, i)<0 | coord(1, :, i)>widthpp | coord(2, :, i)>heightpp);
%     %     if any(replaceVector)
%     %             tt=randsample(sizeXY,sum(replaceVector));
%     %             coord(:, replaceVector, i) = [xAreaLine(tt)'; yAreaLine(tt)'];
%     %     end
%     end
% end
