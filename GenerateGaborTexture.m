function [ HW, gaborTexture, gaborTextureInv ] = GenerateGaborTexture( HW, sigma, gamma, lambda, phi, textureRes, textureSpan )
%GENERATEGABORTEXTURE Generates a gabor texture
% Detailed explanation goes here
%     sigma = size of gabor
%     gamma = aspect ratio
%     lambda = wavelength of carrier
%     phi = phase shift
% from Gabor2D

if nargin < 2 % TODO check each of these argument individually
    sigma = pi;
    gamma = 1.0;
    lambda = 2*pi;
    phi = 0.0;
    textureRes = 512; % for the texture of the basic gabor
    textureSpan = 3*sigma;
end

[X, Y] = meshgrid(-(textureSpan):(2*textureSpan)/(textureRes-1):(textureSpan));
Z = exp(-(X.^2 + gamma^2 * Y.^2)/(2*sigma^2)) .* cos(2*pi*X/lambda + phi);

HW = ScreenCustomStereo(...
    HW, 'SelectStereoDrawBuffer', HW.winPtr, 0);
[HW, gaborTexture] = ScreenCustomStereo(...
    HW, 'MakeTexture', HW.realWinPtr, Z, [], [], 1); %FIXME hack realwinptr
[HW, gaborTextureInv] = ScreenCustomStereo(...
    HW, 'MakeTexture', HW.realWinPtr, -Z, [], [], 1); %FIXME hack realwinptr

end

