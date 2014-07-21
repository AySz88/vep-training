function [ HW ] = RunTraining( HW )
%RUNTRAINING Summary of this function goes here
%   Detailed explanation goes here

e = []; %caught exception
if nargin < 1 || isempty(HW)
    HW = HardwareParameters();
end
[didHWInit, HW] = InitializeHardware(HW);

screenCenter = 0.5*(HW.screenRect([1 2]) + HW.screenRect([3 4]));

screenSize = HW.screenRect([3 4]) - HW.screenRect([1 2]);
screenDiag = sqrt(sum(screenSize .* screenSize));
screenDiagDeg = screenDiag / HW.ppd; % TODO use tangent? Though error is low

sizesChoices = 0.75 * 2.^[0 1 2 3]; % sigma in arcmin at fovea
separation = 6; % Number of sigma between the centers of the gabors

% From CorticalMag, r_VisSpace = E_h * (exp(r_cortex/E_h) - 1);
% Thus the cortical radius to fill the screen is E_h*ln(r/E_h + 1)
E_h = 2.5;
corticalRadiusDeg = E_h*log(screenDiagDeg/E_h + 1);
corticalR_AM = corticalRadiusDeg * 60;
hexCoordsDeg = [];
hexSizesAM = [];
for sizeIdx = 1:length(sizesChoices)
    thisSize = sizesChoices(sizeIdx);
    nTilesAcross = corticalR_AM/(thisSize*separation);
    thisSizeCoordsDeg = HexLattice(nTilesAcross) * thisSize/60;
    nTheseCoords = size(thisSizeCoordsDeg, 1);
    hexCoordsDeg = [hexCoordsDeg; thisSizeCoordsDeg];
    hexSizesAM = [hexSizesAM; thisSize*ones(nTheseCoords, 1)];
end
[magCoordsDeg, relMag] = CorticalMag(hexCoordsDeg, 'BackusLab');
nMagCoords = size(magCoordsDeg, 1);
magCoordsPx = magCoordsDeg * HW.ppd + ones(nMagCoords, 1) * screenCenter;
magCoordScalesAM = hexSizesAM .* relMag;
magCoordScalesPx = magCoordScalesAM * (HW.ppd/60);

aRatioMin = 0.5; % ratio of x to y; stretch y to achieve this
aRatioMax = 1.0;
lumMin = .5; % contrast of lowest-contrast gabor, relative to maximum possible for screen (0.5)
lumMax = .5;

zones = 1:9;
zoneXs = mod(zones-1, 3);           % [0 1 2 0 1 2 0 1 2]
zoneYs = 3 - floor((zones-1)./3);   % [0 0 0 1 1 1 2 2 2]

nGabors = 20;

iters = 1e6;

try
    %% Generate texture
    [HW, gaborTexture] = GenerateGaborTexture(HW);
    
    presCenter = screenCenter; % move "center" around slightly
    presCenterVel = [0 0]; % pixels / frame
    for i=1:iters
        presCenterVel = 0.95*presCenterVel - 0.01*(presCenter - screenCenter) + 2*(rand(1,2)-0.5);
        presCenter = presCenter + presCenterVel;
        
        %% Single frame of gabors
%         gaborCenters = rand(nGabors, 2) .* repmat(screenSize, nGabors, 1);
%         sizes = sizesChoices(randi(length(sizesChoices), nGabors, 1)) * HW.ppd ./ 60;
%         sizes = sizes' .* pdist2(gaborCenters, presCenter).^0.7;
        coordIndexes = randi(nMagCoords, 1, nGabors);
        gaborCenters = magCoordsPx(coordIndexes, :);
        sizes = magCoordScalesPx(coordIndexes);
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
end

