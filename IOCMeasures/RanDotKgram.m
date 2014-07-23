function [ HW ] = RanDotKgram(P, HW )
%RANDOTKGRAM Shows a Random Dot Kinematogram
%   Parameters:
%   
%   P: structure of stimulus parameters, with the following fields...
%    sigdots	: number of signal dots
%    nDots      : number of total dots
%    duration	: time to show stimulus (seconds)
%    lifetime	: dot lifetime for limited-lifetime dots (seconds)
%    contrasts	: 2x2 matrix describing the contrasts of...
%                [ leftSignal rightSignal;
%                  leftNoise  rightNoise ]
%                ...in log10 units above background luminance
%                (ex. 0 means (1 + 10^0)*bgLumnce = 2*bgLumnce)
%                pass '-Inf' to hide completely
%    contrastSDs: 2x2 matrix with the standard deviations of contrasts of:
%                [ leftSignal rightSignal;
%                  leftNoise  rightNoise ]
%                must also pass '0' to hide completely
%    dotType	: shape of dots (Screen('DrawDots?'), dot_type parameter)
%                 can also take the following: 'gaussian'
%    dotSpeedDeg: speed of dot (in visual angle degrees)
%    dir        : 'up' for signal dots up, 'down' (for down), or angle
%                 in radians (with the positive y-axis pointing downwards)
%    sigDirDistr: Statistical distribution of signal dots
%                 'all' to have all dots move directly in signal direction
%                 'sin' to have dots distributed proportionally to
%                   A * (1 + sin(t))/2, where t=0 is the signal direction
%                   and mean velocity is A/2 in the signal direction
%    sigDirPower: For sigDirDistr = 'sin', mean velocity (0.5*A), max 0.5
%                 (sigDirPower)/(1-sigDirPower) is "signal to noise ratio"?
%                 (for sigDirDistr = 'all', this is ignored)
%    dotSizeDeg	: full width (NOT radius) of dot (in visual angle degrees)
%                 if dotType is 'gaussian', this is width of four s.d.
%    viewportDeg: radius of viewport (in visual angle degrees)
%    fixPosDegR, fixPosDegT :
%       [r, theta] of position of fixation box from center (deg)
%    fixWidthDeg: width of fixation box (in visual angle degrees)
%    frameWidDeg: line width of fix box (in vis ang degrees), '0' means 1px
%    catchDirection: location of fixation test dot in fix box ('' for none)
%    lockWidDeg	: half the width of the fusion lock around the stimulus
%    lockSquares: number of squares in the fusion lock per (full) side
%    noGoRadiusDeg: radial width of central no-go circle (vis ang degrees)
%    noGoType	: type of no-go circle ('cover', 'kill', or 'teleport')
%                 'cover' uses a circle to cover up the no-go area
%                 'kill' removes and replaces dots entering the circle
%                 'teleport' reflects the dot position through the center
%    scaleFactor: add'l scaling of simulus (dots, speeds) (defaults to 1.0)
%    scaleFixBox: iff true, scales fixWidthDeg & frameWidDeg by scaleFactor
%    scaleFusion: iff true, scales lockWidDeg by scaleFactor
%    clearAtEnd	: if true, draw just fix & fusion lock as the last frame
%   HW : Hardware parameter structure
%
%   Based on code from: DotDemo, StereoDemo, StereoacuityTraining(SUNY)
%   
%   See Test_RanDotKgram for example and demo code
    
%% Process/convert and sanity-check parameters
    nSignal = P.sigDots;
    nNoise = P.nDots - P.sigDots;
    direction = P.dir;
    fixPosPolarR = P.fixPosDegR;
    fixPosPolarT = P.fixPosDegT;
    
    if strcmpi(direction,'up')
        % positive y axis is down, not up
        direction = 3*pi/2;
    elseif strcmpi(direction,'down')
        direction = pi/2;
    elseif nSignal == 0
        direction = 0; % doesn't matter
    elseif ~(isnumeric(direction) && isscalar(direction))
        throw(MException( 'RanDotKgram:badParameter', ...
             'direction must be ''up'', ''down'', or a numeric angle'))
    end
    
    psychassert( ...
        ~isempty(nSignal) && isnumeric(nSignal) && isreal(nSignal) ...
        && isscalar(nSignal) && nSignal>=0, ...
        'RanDotKgram:badParameter', 'nSignal is not valid');
    psychassert( ...
        ~isempty(nNoise) && isnumeric(nNoise) && isreal(nNoise) ...
        && isscalar(nNoise) && nNoise>=0, ...
        'RanDotKgram:badParameter', 'nNoise is not valid');
    psychassert( ...
        (nSignal + nNoise) > 0, ...
        'RanDotKgram:badParameter', 'Must have more than 0 total dots');
    
    psychassert( ...
        ~isempty(P.duration) && isnumeric(P.duration) && isreal(P.duration)...
        && isscalar(P.duration) && P.duration>=0, ...
        'RanDotKgram:badParameter', 'duration is not valid');
    
    if (P.duration > 15)
        warning('RanDotKgram:longDuration', 'duration is over 15 seconds');
    end
    
    psychassert(...
        all(size(P.contrasts) == [2,2]) && isnumeric(P.contrasts) ...
        && isreal(P.contrasts), ...
        'RanDotKgram:badParameter', 'contrasts are not valid');
    
    psychassert(...
        all(size(P.contrastSDs) == [2,2]) && isnumeric(P.contrastSDs) ...
        && isreal(P.contrastSDs) && isempty(find(P.contrastSDs<0, 1)), ...
        'RanDotKgram:badParameter', 'contrastSDs are not valid');
    
    psychassert(...
        strcmpi(P.dotType, 'gaussian') ...
        || ~isempty(find(P.dotType == 0:2, 1)), ...
        'RanDotKgram:badParameter', ...
        ['dotType must be ''gaussian'', 0, 1, or 2 -' ...
        ' see Screen(''DrawDots?'')']);
    
    psychassert(...
        P.scaleFactor > 0, ...
        'RanDotKgram:badParameter', ...
        'scaleFactor must be positive');
    
    % KLUDGE cancel out ghosting from nVidia glasses slightly
    % Not quite right - one img should subtract *prev* frame's other eye
    %contrasts = contrasts - 0.1*[contrasts(:,2) contrasts(:,1)];
    % VIP glasses: duty cycle 8 (lights: on, level 3, off, off, off)
    %   phase 23 (on, level 1.3 = one push before level 2, off, off, off)
    
    % Derived parameters (some formulas via DotDemo)
    [center(1), center(2)] = RectCenter(HW.screenRect);
    timestep = 1 / HW.fps;
    dotSpeedPx = P.dotSpeedDeg * HW.ppd / HW.fps; % dot speed (pixels/frame)
    dotSizePx = P.dotSizeDeg * HW.ppd;            % dot size (pixels)
    viewportPx = P.viewportDeg * HW.ppd;
    lockWidPx = P.lockWidDeg * HW.ppd;
    noGoRadiusPx = P.noGoRadiusDeg * HW.ppd;
    
    dotSpeedPx = dotSpeedPx * P.scaleFactor;
    dotSizePx = dotSizePx * P.scaleFactor;
    viewportPx = viewportPx * P.scaleFactor;
    if P.scaleFusion
        lockWidPx = lockWidPx * P.scaleFactor;
    end
    noGoRadiusPx = noGoRadiusPx * P.scaleFactor;
    
    % Calculate fixation mark position
    fixPosRDeg = fixPosPolarR;
    fixPosTheta = fixPosPolarT*pi/180;
    fixPosCenterDeg = fixPosRDeg * [cos(fixPosTheta) -sin(fixPosTheta)];
    % Use more precise calculation than scaling by HW.ppd, for large angles
    fixPosCenterCm = HW.viewDist * tan(fixPosCenterDeg*pi/180);
    monWidthPx = HW.screenRect(3) - HW.screenRect(1);
    fixPosCenterPx = monWidthPx/HW.monWidth * fixPosCenterCm;
    fixPosCenterPx = center + fixPosCenterPx;
    
    fixWidthPx = P.fixWidthDeg * HW.ppd;
    if P.scaleFixBox
        fixWidthPx = fixWidthPx * P.scaleFactor;
    end
    if P.frameWidDeg == 0
        frameWidthPx = 1;
    else
        frameWidthPx = P.frameWidDeg * HW.ppd;
        if P.scaleFixBox
            frameWidthPx = frameWidthPx * P.scaleFactor;
        end
    end
    
    dotMaxRadPx = viewportPx-dotSizePx; % where centers of dots can be...
        %... to avoid touching the viewport edges
    dotMaxRadPxSqrd = dotMaxRadPx*dotMaxRadPx;
    dotMinRadPx = noGoRadiusPx+dotSizePx; % for noGoType = kill or tp only
    dotMinRadPxSqrd = dotMinRadPx * dotMinRadPx;

    nDots = nSignal + nNoise;
    
    % Find actual luminance of background to apply
    if HW.usePTBPerPxCorrection
        bgColorVal = HW.white * P.bgLumnce;
    else
        [bgColorVal, P.bgLumnce] = LumToColor(HW, P.bgLumnce);
    end

%% Initialization
    % Initial positions of dots
    % sqrt(uniform random var) for uniform-by-area distribution of dots
    rPositions = GenRadialPos(P.noGoType, dotMinRadPx, dotMaxRadPx, nDots,1);
    rt =  [ rPositions              , 2*pi*rand(nDots,1)    ];
    pos = [ rt(:,1).*cos(rt(:,2))   , rt(:,1).*sin(rt(:,2)) ];
    if ~isempty(P.lifetime)
        life = P.lifetime*rand(nDots, 1);
    end
    % Initial directions (radial)
    if strcmpi(P.sigDirDistr, 'all')
        signalDirs = direction*ones(nSignal,1);
    elseif strcmpi(P.sigDirDistr, 'sin')
        signalDirs = 2*pi*RandCos(nSignal, 2.0*P.sigDirPower) + direction;
        signalDirs = mod(signalDirs, 2*pi);
        %hist(signalDirs, 10);
        %axes(gca); %#ok<MAXES> % to draw and get focus
    end
    vang = [ signalDirs; ...
             2*pi*rand(nNoise,1)        ];
    vel = dotSpeedPx * [ cos(vang), sin(vang) ];
    % Colors (dimensions: particle, (luminance or RGB), which eye)
    lums = zeros(nDots, 1, 2);
    for eye=1:2
        % absoluteAddOne: adds bg luminance iff needed
        if strcmpi(P.dotType, 'gaussian')
            absoluteAddOne = 0;
        else
            absoluteAddOne = 1;
        end
        lums(:,:,eye) = P.bgLumnce .* ...
            (absoluteAddOne + 10.^[ ...
                P.contrasts(1,eye) + randn(nSignal,1)*P.contrastSDs(1,eye); ...
                P.contrasts(2,eye) + randn(nNoise ,1)*P.contrastSDs(2,eye)] ...
            );
    end
    colors = zeros(nDots, 3, 2);
    if HW.usePTBPerPxCorrection
        colors = HW.white .* cat(2, lums, lums, lums);
    else
        for eye=1:2
            colors(:,:,eye) = LumToColor(HW, lums(:,:,eye));
        end
    end
    
    % Texture (for 'gaussian' dotType)
    if strcmpi(P.dotType, 'gaussian')
        gaussianSD = dotSizePx / 4.0; % TODO parameterize magic number
        texSizePx = 6 * gaussianSD; % TODO parameterize 3 sd's captured
        dotImg = normpdf(1:texSizePx, texSizePx/2, gaussianSD);
        
        % normalize so that peak value will be 1.0
        maxPDF = max(dotImg);
        dotImg = dotImg ./ maxPDF;
        
        dotImg = dotImg' * dotImg; % convolve to create 2D image
        
        
        if HW.usePTBPerPxCorrection
            dotImg = HW.white * dotImg;
        else
            % FIXME impossible to be correct without per-pixel correction
            % this is a stopgap color correction method for now
            % should throw warning?
            dotImg = (HW.white - mean(bgColorVal))*dotImg;
        end
        
        % Actually create the texture
        % FIXME HACK only customstereo should have access to HW.realWinPtr
        % or even knows whether or not it should exist
        % Anyway, need to fetch a valid HW.winPtr to create texture
        HW = ScreenCustomStereo(...
            HW, 'SelectStereoDrawBuffer', HW.winPtr, 0);
        [HW, dotTexture] = ScreenCustomStereo(...
            HW, 'MakeTexture', HW.winPtr, dotImg);
        dotTexSize = size(dotImg);
    end
    
    % debugging code
    %{
    disp(['Background:  [' num2str(bgColorVal) ']'])
    disp(['Signal luminances:   [' num2str(lums(1,:,1)) '] L,' ...
        ' [' num2str(lums(1,:,2)) '] R']);
    disp(['Signal colors (raw): [' num2str(colors(1,:,1)) '] L,' ...
        ' [' num2str(colors(1,:,2)) '] R']);
    disp(['Noise luminances:   [' num2str(lums(nSignal+1,:,1)) '] L,' ...
        ' [' num2str(lums(nSignal+1,:,2)) '] R']);
    disp(['Noise colors (raw): [' num2str(colors(nSignal+1,:,1)) '] L,' ...
        ' [' num2str(colors(nSignal+1,:,2)) '] R']);
    %}

%% Animation loop
    startTime = GetSecs;
    while (GetSecs - startTime) < P.duration
        for i=0:1
            % i=0 for left eye, i=1 for right eye
            HW = ScreenCustomStereo(...
                    HW, 'SelectStereoDrawBuffer', HW.winPtr, i);
            Screen('FillRect', HW.winPtr, bgColorVal);

            % To help with stereo glasses debugging/calibration
            %Screen('FrameRect', HW.winPtr, HW.white*[i,0,~i], ...
            %    [center-viewportPx-2*i, center+viewportPx+2*i]);

            thisEyeMask = P.contrasts(:, i+1);

            for j=1:2 % signal (1) vs. noise (2)
                if thisEyeMask(j) ~= -Inf
                    if j == 1
                        whichDots = pos(1:nSignal,:);
                        whichColors = colors(1:nSignal,:,i+1);
                    else
                        whichDots = pos(nSignal+1:end,:);
                        whichColors = colors(nSignal+1:end,:,i+1);
                    end
                    
                    % Actually draw the dots
                    if (~isempty(whichDots))
                        if exist('dotTexture', 'var')
                            % add these *luminances* to the old ones FIXME
                            [HW, oldSrc, oldDst, oldColorMask] = ...
                                ScreenCustomStereo(HW, 'BlendFunction', ...
                                HW.winPtr, GL_SRC_ALPHA, GL_ONE); 
                            numRows = size(whichDots,1);
                            halfSizeMat = ...
                                repmat(0.5*dotTexSize, numRows, 1);
                            centerMat = ...
                                repmat(center, numRows, 1);
                            texDests = ...
                                [(whichDots+centerMat-halfSizeMat) ...
                                 (whichDots+centerMat+halfSizeMat)];
                            Screen('DrawTextures', HW.winPtr, ...
                                dotTexture, [], texDests', ...
                                [], [], [], whichColors');
                            HW = ScreenCustomStereo(HW, 'BlendFunction',...
                                HW.winPtr, oldSrc, oldDst, oldColorMask);
                        else
                            Screen('DrawDots', HW.winPtr, whichDots', ...
                             dotSizePx, whichColors', center, P.dotType);
                        end
                    end
                end
            end
        end
        
        % To help with convergence, draw fixation box and fusion lock
        HW = DrawFixationBox(HW, ...
            fixPosCenterPx, fixWidthPx, frameWidthPx, ...
            noGoRadiusPx, P.noGoType, bgColorVal);
        if ~isempty(P.catchDirection)
            switch lower(P.catchDirection)
                case {'l', 'left'}
                    side = -1;
                case {'r', 'right'}
                    side = 1;
            end
            for i=0:1
                HW = ScreenCustomStereo(...
                    HW, 'SelectStereoDrawBuffer', HW.winPtr, i);
                Screen('DrawDots', HW.winPtr, ...
                    fixPosCenterPx + 0.25*[side*fixWidthPx 0], ...
                    0.5*fixWidthPx, HW.white)
            end
        end
        HW = DrawFusionLock(HW, center, lockWidPx, P.lockSquares);
        
        HW = ScreenCustomStereo(HW, 'Flip', HW.winPtr);

        % Update
        pos = pos + vel;
        life = life + timestep;
        
        % Boundary conditions
        % Check for dots outside the viewport (out-of-bounds, OOB)
        %  and then reflect them
        distSqrd = sum(pos.*pos,2);
        if strcmpi(P.noGoType, 'teleport')
            OOBi = find(distSqrd > dotMaxRadPxSqrd ...
                        | distSqrd < dotMinRadPxSqrd);
        else
            OOBi = find(distSqrd > dotMaxRadPxSqrd);
        end
        pos(OOBi,:) = pos(OOBi,:) - vel(OOBi,:); % undo last timestep
        pos(OOBi,:) = -pos(OOBi,:);
        
        % Check for dead dots, and revive them at random location
        deadDots = false(size(life));
        if ~isempty(P.lifetime)
            % check for end-of-lifetime dots
            deadDots = deadDots | (life > P.lifetime);
        end
        if strcmpi(P.noGoType, 'kill')
            % check for dots that die by straying into the no-go zone
            deadDots = deadDots | (distSqrd < dotMinRadPxSqrd);
        end
        % reset positions at which to revive dots (but preserve velocity)
        deadIdxs = find(deadDots);
        deadSize = size(deadIdxs);
        r = GenRadialPos(...
                P.noGoType, dotMinRadPx, dotMaxRadPx, deadSize);
        t = 2*pi*rand(deadSize);
        pos(deadIdxs,:) = [r.*cos(t), r.*sin(t)];
        if ~isempty(P.lifetime)
            % reset "dead" lifetimes, keeping remaining part of ages
            life(life>P.lifetime) = life(life>P.lifetime) - P.lifetime;
        end
    end
%% Cleanup
    % FIXME if ~clearAtEnd, still remove the catch dot anyway
    if P.clearAtEnd
        for i=0:1
            HW = ScreenCustomStereo(...
                HW, 'SelectStereoDrawBuffer', HW.winPtr, i);
            Screen('FillRect', HW.winPtr, bgColorVal);
        end
        % Draw the fixation box and frame only
        HW = DrawFixationBox(HW, ...
            fixPosCenterPx, fixWidthPx, frameWidthPx, ...
            noGoRadiusPx, P.noGoType, bgColorVal);
        HW = DrawFusionLock(HW, center, lockWidPx, P.lockSquares);
        HW = ScreenCustomStereo(HW, 'Flip', HW.winPtr);
    end
end

function HW = DrawFixationBox(HW, position, fixWidthPx, frameWidthPx, ...
    noGoRadiusPx, noGoType, bgColorVal)
    for i=0:1
        HW = ScreenCustomStereo(...
                    HW, 'SelectStereoDrawBuffer', HW.winPtr, i);
        if strcmpi(noGoType, 'cover')
            Screen('gluDisk', HW.winPtr, bgColorVal, ...
                position(1), position(2), noGoRadiusPx);
        end
        Screen('FrameRect', HW.winPtr, HW.white, ...
            [position-0.5*fixWidthPx, position+0.5*fixWidthPx], ...
            frameWidthPx);
    end
end

function r = GenRadialPos(noGoType, noGoRad, maxRad, varargin)
% The radial component of dot positions generated uniformly in an annulus
%   (when dots are forbidden to go into the no-go area) or circle (when
%   they are not forbidden)
% varargin is the size of matrix to be generated (as interpreted by rand)
    if strcmpi(noGoType, 'teleport') || strcmpi(noGoType, 'kill')
        r = sqrt(...
                (maxRad*maxRad - noGoRad*noGoRad) * rand(varargin{:})...
                + noGoRad*noGoRad ...
                );
    else
        r = maxRad*sqrt(rand(varargin{:}));
    end
end
