function [ ] = DisplayLumForCalibration( levels, stereoMode, blankOther )
%DISPLAYLUMFORCALIBRATION Displays a bunch of luminances for calibration
%   All arguments optional (pass [] to skip one)
%   default levels: ([0:10:250, 255, 128:150], 1, false)
%   levels is a list of grayscale raw lumenances, or 
%       a cell array of colors, ex:
%       ({[200,0,0], [0,200,0], [0,0,200], [200,200,200]})
%
%   Example:
%     colors = cell(1,100);
%     for i=1:100
%         colors(i) = {[180 180 180] + round(rand(1,3))};
%     end
%     DisplayLumForCalibration(colors);
%   Press 'x' to halt, or any other key to advance to next luminance
%
%   FIXME Weird display bug happens when blankOther = true!

    if nargin<1 || isempty(levels)
        levels = [0:10:250, 255, 128:150];
    end
    if nargin<2 || isempty(stereoMode)
        stereoMode	= 1; % 1 = OpenGL stereo, see Screen('OpenWindow?')
    end
    if nargin<3 || isempty(blankOther)
        blankOther = false;
    end
    
    [~,~,HW] = Parameters();
    HW.stereoMode = stereoMode;
    HW.stereoTexOffset = [];
    HW.usePTBPerPxCorrection = false;
    dummyLums = [0:10:250, 255]';
    HW.lumCalib = [dummyLums, dummyLums];
    
    [didHWInit HW] = InitializeHardware(HW);
    HW = ScreenCustomStereo(HW, 'Flip', HW.winPtr); % initial flip
    
    caughtE = [];
    try
        if stereoMode
            for lum=levels
                drawRect(HW, lum, 0, blankOther);
            end
            % only do the other eye if the two eyes are different
            if blankOther
                for lum=levels
                    drawRect(HW, lum, 1, blankOther);
                end
            end
        else
            for lum=levels
                drawRect(HW, lum);
            end
        end
    catch e
        caughtE = e;
    end
    
    if didHWInit
        HW = CleanupHardware(HW); %#ok<NASGU>
    end
    
    if ~isempty(caughtE)
        rethrow(caughtE)
    end
end

function [] = drawRect(HW, lum, eye, blankOther)
    if iscell(lum)
        lum = cell2mat(lum);
    end
    
    fprintf('Luminance now at ');
    if numel(lum) > 1
        fprintf('[%3d, %3d, %3d]', lum(1), lum(2), lum(3));
    else
        fprintf('%3d', lum);
    end
    if (nargin > 2)
        side = 'left eye';
        if eye
            side = 'right eye';
        end
        
        if ~blankOther
            side = 'both eyes with stereo on';
        end
        fprintf(' in %s', side);
    else
        fprintf(' with stereo off');
    end
    fprintf('\n');
    
    % TODO Redrawing every frame in attempt to avoid blankOther=true bug
    % but it didn't work!
    KbWait([],1);
    vbl = 0; %Flip at next possible
    while ~KbCheck
        if (nargin > 2)
            % i=0 for left eye, i=1 for right eye
            HW = ScreenCustomStereo(HW, 'SelectStereoDrawBuffer', ...
                HW.winPtr, eye);
        end

        Screen('FillRect', HW.winPtr, lum);

        if (nargin > 2)
            % blank the other eye
            otherEye = mod(eye+1,2);
            HW = ScreenCustomStereo(HW, 'SelectStereoDrawBuffer', ...
                HW.winPtr, otherEye);
            
            if blankOther
                otherEyeLum = 0;
            else
                otherEyeLum = lum;
            end
            
            Screen('FillRect', HW.winPtr, otherEyeLum);
        end
        HW = ScreenCustomStereo(HW, 'DrawingFinished', HW.winPtr);
        [HW, vbl] = ScreenCustomStereo(HW, 'Flip', HW.winPtr, ...
            vbl+0.25/HW.fps);
    end

    % Get and interpret the response
    [~,keyCode,~] = KbWait([]); 
    response = KbName(keyCode);

    if strcmp(response, 'x')
        % 'graceful' bail
        throw(MException('DisplayLumForCalibration:Halt', ...
            'Halted by user!'));
    end
end