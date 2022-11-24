function [max,min]=contrSym2Lum(C,background)
%------------------------------------------------------------------------
%       General function to get the max and min luminance value needed given the background
% to get a contrast of C for a sinus equally balanced around the background
%------------------------------------------------------------------------
%Last edit: July, the 27th, 2009
%Function created by Adrien Chopin in july 2009 
%------------------------------------------------------------------------
max=(C+1)*background;
min=background-(max-background);
