function rectCoord = centerSizedAreaOnPx(pxX, pxY, areaWidth, areaHeight)
% You give pixel coordinates and the size of the area you want centered on that pixel
% It gives you a rect back with xTopLeft, yTopLeft, xBotRight, yBottomRight
%
% We stereotype this to work only with full pixels
% So width and height needs to be odd to avoid half pixels (the function will work but always disp a warning in that case)

%We first round everything
pxX = round(pxX); pxY= round(pxY); areaWidth=round(areaWidth); areaHeight=round(areaHeight);
if mod(areaWidth,2)~=1; disp('Careful! centerSizedAreaOnPx received an even sized area width and resulting rect will be 1px bigger...'); end
if mod(areaHeight,2)~=1; disp('Careful! centerSizedAreaOnPx received an even sized area height and resulting rect will be 1px bigger...'); end

rectCoord = [pxX-floor(areaWidth/2),pxY-floor(areaHeight/2),pxX+floor(areaWidth/2),pxY+floor(areaHeight/2)];

%  resolution of zero or negative values: put them to 1 and give a warning
if any(rectCoord<1)
    disp('Warning, centerSizedAreaOnPx issues some rect values inferior to 1. We correct them to 1 but you should check that.'); 
    indx=(rectCoord<1);
    rectCoord(indx)=1;
end

end

