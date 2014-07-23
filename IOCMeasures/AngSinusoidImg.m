function img = AngSinusoidImg(width, height, rMin, rMax, cycles, bgLum)
% TODO documentation
% Example: image(AngSinusoidImg(1000,1000,200,300,2,.5));
% TODO currently theta=0 along positive x axis, change?

lums = bgLum.*ones(width, height);
centerX = width/2;
centerY = height/2;

[x,y] = meshgrid(1:width, 1:height);
y = y-centerY;
x = x-centerX;
rSqrd = x.*x + y.*y;
mask = (rSqrd>rMin*rMin) & (rSqrd<rMax*rMax);

% TODO check if doing sine explicitly (r=..., sin(t)= y/r) would be faster
% (especially try y/r = y * fastInverseSqrtHack(x.*x+y.*y))
thetaMasked = atan2(y(mask),x(mask));
lums(mask) = sin(thetaMasked*0.5*cycles).^2;

img = cat(3,lums,lums,lums); % to RGB
end