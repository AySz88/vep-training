function img = SinusoidImage(width, height, phase, cycles, additive)
% SINUSOIDIMAGE Creates matrix containing image of sinusoidal contrast stim
% Horizontal grating (luminance varies in vertical direction)
% Parameters:
%   width, height: the dimensions of the image
%   phase       : offset of max from the center (more positive = upwards)
%   cycles      : number of full cycles across the full height
%   additive	: iff true, range from -1 to 1, else range from 0 to 1
% Example: image(SinusoidImage(10,1000, 0, 4, false));

if nargin < 5
    additive = false;
end

centerY = (height+1)/2;
y = (1:height) - centerY;
yLums = sin(2*pi*y*cycles/height + phase + pi/2);
if ~additive
    yLums = yLums*0.5 + 0.5;
end

lums = repmat(yLums', 1, width);

img = cat(3,lums,lums,lums); % to RGB
end