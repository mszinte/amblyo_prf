%function written by Adrien Chopin in August 2007
%to contact me: adrien.chopin@gmail.com
%--------------------------------------

%goal of the function is to convert a size in visual angle
%in a size in cm

function cm=VA2cm(sizeVA,distance)
%sizeVA is the size to convert, in VA (of an object
%on a screen, for example).
%distance is the distance between obs and the screen in cm

%compute the size of one degree of visual angle in cm
%  visualAngCm=2*distance*tan(0.5* pi / 180);
%  cm=sizeVA*visualAngCm

cm = distance.*tan(deg2rad(sizeVA));