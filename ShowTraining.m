function [ HW ] = ShowTraining( HW, displayDurSec, contrastLR, gaborTexture, gaborTextureInv )
%SHOWTRAINING Summary of this function goes here (not determined yet)
%   Detailed explanation goes here
% contrastLR = [1.0 0.25]; % contrast of gabors, relative to maximum possible for screen (0.5)

e = []; %caught exception
if nargin < 1 || isempty(HW)
    HW = HardwareParameters();
end
[didHWInit, HW] = InitializeHardware(HW);

screenCenter = 0.5*(HW.screenRect([1 2]) + HW.screenRect([3 4]));

screenSize = HW.screenRect([3 4]) - HW.screenRect([1 2]);
screenDiagPx = sqrt(sum(screenSize .* screenSize));
screenDiagDeg = screenDiagPx / HW.ppd; % TODO use tangent? Though error is low

fixWidthPx = 0.02*screenSize(1);
fixLineWidthPx = 2;

sizeChoices = 15 * 2.^(0:0.5:3); % arbitrary units - FIXME should be sigma in arcmin at fovea 
separation = 2; % Number of sigma between the centers of the gabors - FIXME is this used correctly?

% Calculate how much "cortical radius" the screen fills (equiv. visual
% angle at fovea)
% From CorticalMag, r_VisSpace = E_h * (exp(r_cortex/E_h) - 1);
% Thus the cortical radius to fill the screen is E_h*ln(r_VisSpace/E_h + 1)
E_h = 2.5;
corticalRadiusDeg = E_h*log(screenDiagDeg/E_h + 1);
corticalR_AM = corticalRadiusDeg * 60;

% Calculate coordinates of stimuli
hexCoordsDeg = [];
hexSizesAM = [];
for sizeIdx = 1:length(sizeChoices)
    thisSize = sizeChoices(sizeIdx);
    nTilesAcross = corticalR_AM/(thisSize*separation) + 1;
    thisSizeCoordsDeg = HexLattice(nTilesAcross) * thisSize/60 * separation;
    nTheseCoords = size(thisSizeCoordsDeg, 1);
    hexCoordsDeg = [hexCoordsDeg; thisSizeCoordsDeg];
    hexSizesAM = [hexSizesAM; thisSize*ones(nTheseCoords, 1)];
end
[magCoordsDeg, relMag] = CorticalMag(hexCoordsDeg, 'BackusLab');
nMagCoords = size(magCoordsDeg, 1);
magCoordsPx = magCoordsDeg * HW.ppd + ones(nMagCoords, 1) * screenCenter;
magCoordScalesAM = hexSizesAM .* relMag;
magCoordScalesPx = magCoordScalesAM * (HW.ppd/60);

aRatioMin = 5/6; % ratio of x to y; stretch y to achieve this
aRatioMax = 5/6;
bgLum = 0.5;

framesPerPres = 2; % Number of frames per presentation of gabors

startTime = GetSecs();

try
    %% Generate texture
    if didHWInit || nargin < 4
        [HW, gaborTexture, gaborTextureInv] = GenerateGaborTexture(HW);
    end
    
    presCenter = screenCenter; % move "center" around slightly
    presCenterVel = [0 0]; % pixels / frame
    while GetSecs() < startTime + displayDurSec
        presCenterVel = 0.95*presCenterVel - 0.01*(presCenter - screenCenter) + 2*(rand(1,2)-0.5);
        presCenter = presCenter + presCenterVel;
        
        %% Single presentation of gabors
        coordIndexes = (abs(hexSizesAM - sizeChoices(randi(length(sizeChoices)))) < 1e-5);
        gaborCenters = magCoordsPx(coordIndexes, :);
        nGabors = size(gaborCenters, 1);
        
        sizes = magCoordScalesPx(coordIndexes); % FIXME maybe needs * 6 = (2*textureSpan/sigma) as passed to GenerateGaborTexture, then fix above
        ySizes = sizes .* 1.0./(aRatioMin + rand(nGabors,1).*(aRatioMax - aRatioMin));
        offsets = 0.5*[sizes ySizes]; % offsets of each texture away from the centers of each gabor
        texDestPos = [gaborCenters - offsets, gaborCenters + offsets];
        texDestThetas = rand(nGabors,1) * 360; % degrees :(
        
        invertOrNot = sign(rand(nGabors,1)-0.5);
        
        for frameNum = 1:framesPerPres
            for eye = [0 1]
                HW = ScreenCustomStereo(...
                    HW, 'SelectStereoDrawBuffer', HW.winPtr, eye);
                Screen('FillRect', HW.winPtr, HW.white * bgLum);
            end
            HW = DrawFixationMark(HW, presCenter, fixWidthPx, fixLineWidthPx);
                
            for eye = [0 1]
                HW = ScreenCustomStereo(...
                    HW, 'SelectStereoDrawBuffer', HW.winPtr, eye);
                contrastThisEye = contrastLR(eye + 1);
                
                % Doesn't work :( Using two textures instead
                %texColors = HW.white .* (contrastThisEye)*bgLum .* (invertOrNot * [1 1 1]);
                texColors = HW.white .* (contrastThisEye)*bgLum;
                
                invIdxs = invertOrNot < 0;
                
                [HW, oldSrc, oldDst, oldColorMask] = ...
                    ScreenCustomStereo(HW, 'BlendFunction', ...
                    HW.winPtr, GL_SRC_ALPHA, GL_ONE);
                Screen('DrawTextures', HW.winPtr, ...
                    gaborTexture, [], texDestPos(~invIdxs,:)', ...
                    texDestThetas(~invIdxs)', [], [], texColors');
                Screen('DrawTextures', HW.winPtr, ...
                    gaborTextureInv, [], texDestPos(invIdxs,:)', ...
                    texDestThetas(invIdxs)', [], [], texColors');
                HW = ScreenCustomStereo(HW, 'BlendFunction',...
                    HW.winPtr, oldSrc, oldDst, oldColorMask);
            end

            HW = ScreenCustomStereo(HW, 'Flip', HW.winPtr);
        end
        % End single presentation
        
        [ ~, ~, keyCode ] = KbCheck;
        if keyCode(KbName('ESC'));
            break;
        end
    end
catch e
end

if didHWInit
    if exist('gaborTexture', 'var')
        Screen('Close', [gaborTexture, gaborTextureInv]);
    end
    HW = CleanupHardware(HW);
end
if ~isempty(e)
    rethrow(e);
end
end

