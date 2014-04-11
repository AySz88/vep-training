e = []; %caught exception
HW = HardwareParameters();
[didHWInit, HW] = InitializeHardware(HW);

iters = 30 * 60;
pauseTime = 1.0/60.0;
% iters = 5;
% pauseTime = 0.5;
textureRes = 512;
gabors = 10;
sizeMin = 2;
sizeMax = 4;
aRatioMin = 1.0; % ratio of x to y; stretch y to achieve this
aRatioMax = 1.0;
lumMin = 0.5;
lumMax = 0.9;
try
    %% Generate texture
    [X, Y] = meshgrid(-4*pi:(8*pi)/(textureRes-1):4*pi);
    
    % from Gabor2D
    % sigma = size of gabor
    % gamma = aspect ratio
    % lambda = wavelength
    % phi = phase shift
    sigma = pi;
    gamma = 1.0;
    lambda = 2*pi;
    phi = 0.0;
    
    Z = exp(-(X.^2 + gamma^2 * Y.^2)/(2*sigma^2)) .* cos(2*pi*X/lambda + phi);

    HW = ScreenCustomStereo(...
        HW, 'SelectStereoDrawBuffer', HW.winPtr, 0);
    [HW, gaborTexture] = ScreenCustomStereo(...
        HW, 'MakeTexture', HW.winPtr, Z, [], [], 1);
    
    for i=1:iters
        %% Single frame of gabors
        screenSize = HW.screenRect([3 4]) - HW.screenRect([1 2]);
        screenCenter = 0.5*(HW.screenRect([1 2]) + HW.screenRect([3 4]));
        
        gaborCenters = rand(gabors, 2) .* repmat(screenSize, gabors, 1);
        sizes = sizeMin + rand(gabors,1).*(sizeMax - sizeMin);
        sizes = sizes .* pdist2(gaborCenters, screenCenter).^0.7; % for now
        ySizes = sizes .* 1.0./(aRatioMin + rand(gabors,1).*(aRatioMax - aRatioMin));
        offsets = 0.5*[sizes ySizes];
        texDestPos = [gaborCenters - offsets, gaborCenters + offsets];
        texDestThetas = rand(gabors,1) * 360; % degrees :(
        
        lums = lumMin + rand(gabors,1).*(lumMax - lumMin);
        texColors = HW.white .* cat(2, lums, lums, lums);
        
        for eye = [0 1]
            HW = ScreenCustomStereo(...
                    HW, 'SelectStereoDrawBuffer', HW.winPtr, eye);
            Screen('FillRect', HW.winPtr, 128);

            [HW, oldSrc, oldDst, oldColorMask] = ...
                ScreenCustomStereo(HW, 'BlendFunction', ...
                HW.winPtr, GL_SRC_ALPHA, GL_ONE);
            Screen('DrawTextures', HW.winPtr, ...
                gaborTexture, [], texDestPos', ...
                texDestThetas', [], [], texColors');
            HW = ScreenCustomStereo(HW, 'BlendFunction',...
                HW.winPtr, oldSrc, oldDst, oldColorMask);
        end
        
        HW = ScreenCustomStereo(HW, 'Flip', HW.winPtr);
        % End single frame
        
        pause(pauseTime);
        
        [ ~, ~, keyCode ] = KbCheck;
        if keyCode(KbName('ESC'));
            break;
        end
    end
catch e
end
if didHWInit
    HW = CleanupHardware(HW);
end
if ~isempty(e)
    rethrow(e);
end
