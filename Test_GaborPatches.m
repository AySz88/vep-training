% Test_GaborPatches.m

e = []; %caught exception
HW = HardwareParameters();
[didHWInit, HW] = InitializeHardware(HW);

iters = 1200 * 60; % seconds * framerate
pauseTime = 0; % explicit pause between frames
% iters = 5;
% pauseTime = 0.5;
nGabors = 10; % gabors per frame

% Distributions of gabor sizes, etc.
sizeMin = 2; % relative to textureRes, arbitrary
sizeMax = 4;
aRatioMin = 0.5; % ratio of x to y; stretch y to achieve this
aRatioMax = 1.0;
lumMin = .5; % contrast of lowest-contrast gabor, relative to maximum possible for screen (0.5)
lumMax = .5;
try
    %% Generate texture
    [HW, gaborTexture] = GenerateGaborTexture(HW);
    
    screenSize = HW.screenRect([3 4]) - HW.screenRect([1 2]);
    screenCenter = 0.5*(HW.screenRect([1 2]) + HW.screenRect([3 4]));
    
    presCenter = screenCenter; % move "center" around slightly
    presCenterVel = [0 0]; % pixels / frame
    for i=1:iters
        presCenterVel = 0.95*presCenterVel - 0.01*(presCenter - screenCenter) + 2*(rand(1,2)-0.5);
        presCenter = presCenter + presCenterVel;
        
        %% Single frame of gabors
        gaborCenters = rand(nGabors, 2) .* repmat(screenSize, nGabors, 1);
        sizes = sizeMin + rand(nGabors,1).*(sizeMax - sizeMin);
        sizes = sizes .* pdist2(gaborCenters, presCenter).^0.7; % for now
        ySizes = sizes .* 1.0./(aRatioMin + rand(nGabors,1).*(aRatioMax - aRatioMin));
        offsets = 0.5*[sizes ySizes]; % offsets of each texture away from the centers of each gabor
        texDestPos = [gaborCenters - offsets, gaborCenters + offsets];
        texDestThetas = rand(nGabors,1) * 360; % degrees :(
        
        lums = lumMin + rand(nGabors,1).*(lumMax - lumMin);
        texColors = HW.white .* cat(2, lums, lums, lums);
        
        fixWidthPx = 0.02*screenSize(1);
        fixLineWidthPx = 2;
        
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
        HW = DrawFixationMark(HW, presCenter, fixWidthPx, fixLineWidthPx);
        
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

