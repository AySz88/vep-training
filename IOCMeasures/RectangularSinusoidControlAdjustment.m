function [ AE ] = RectangularSinusoidControlAdjustment( )
%RECTANGULARSINUSOIDCONTROLADJUSTMENT Control stimulus parameters
%   Task: Adjust the actual phase (position) of the grating on the screen
%   until it looks centered

AE = struct();

% Value is change of phase from pi (black band centered)
AE.initValue = (pi/6 * [0.5 0.5]);
AE.stepSize = 0.125*(pi/6); % phase changes
AE.totalContrast = 1.0;
AE.goUp = @RectSinusoidGoUp;
AE.goDown = @RectSinusoidGoDown;
AE.stopCheck = @RectSinusoidStop;
AE.prepParams = @prepParams;
AE.stimulus = @RectangularSinusoidDisplay; %@(P, HW) disp(P);
AE.flashUptime = 1.0;
AE.flashDowntime = 1.0;

% State machine
AE.markBracketsPx = [ -15 15 0 ];
AE.markStage = 1;

% Default stimulus parameters
AE.P.bgLum = 0.5;
AE.P.widthDeg = 0.25;
AE.P.heightDeg = 6.0;
AE.P.bands = 16; % # of bands, use [] for no banding
AE.P.phases = pi;
AE.P.cycles = 1;
AE.P.lockWidthDeg = 8.0; % full width of the lock box
AE.P.lockSquares = 16;
AE.P.markWidthPx = 100;
AE.P.markHeightPx = 5;
AE.P.markOffsetPx = 0;

end

function [AE, newVal] = RectSinusoidGoUp(AE, val)
    % wants left eye (higher) to be brighter
    newVal = val + AE.stepSize;
    disp(newVal);
end

function [AE, newVal] = RectSinusoidGoDown(AE, val)
    newVal = val - AE.stepSize;
    disp(newVal);
end

function [AE, newVal, stop] = RectSinusoidStop(AE, val)
    AE.markStage = mod(AE.markStage, length(AE.markBracketsPx)) + 1;
    fprintf('Hit stop! Went to %i\n', AE.markStage);
    stop = (AE.markStage == 1); % went back to start
    if ~stop
        fprintf('Bracketed at: %f\n', val);
    end
    newVal = val;
end

function P = prepParams(AE, value)
    P = AE.P; % copy defaults over
    
    % decide whether to display full stimulus
    % divides time up into up and down times
    flashTime = AE.flashUptime + AE.flashDowntime;
    flashUp = mod(GetSecs, flashTime) < AE.flashUptime;
    
    if flashUp
        P.contrasts = AE.totalContrast .* [0.5 0.5];
    else
        P.contrasts = [0 0];
    end
    
    P.phases = AE.P.phases + value;
    
    P.markOffsetPx = AE.markBracketsPx(AE.markStage);
end
