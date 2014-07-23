function [ AE ] = RectangularSinusoidAdjustment( )
%RECTANGULARSINUSOIDADJUSTMENT Default structure for sin'oid stimulus
%   Task: adjust (trade-off) contrasts between eyes until it looks centered

AE = struct();

% Value is log10 contrast ratio between left and right eyes (bigger = left
% brighter)
AE.initValue = 0;
AE.stepSize = log10(1.20); % percent changes (multiplicative)
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
AE.P.phases = (2*pi/6 * [0.5 -0.5]) + pi;
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
    disp(10^newVal);
end

function [AE, newVal] = RectSinusoidGoDown(AE, val)
    newVal = val - AE.stepSize;
    disp(10^newVal);
end

function [AE, newVal, stop] = RectSinusoidStop(AE, val)
    AE.markStage = mod(AE.markStage, length(AE.markBracketsPx)) + 1;
    stop = (AE.markStage == 1); % back to start
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
        P.contrasts = AE.totalContrast .* [10^value 1]/(10^value + 1);
    else
        P.contrasts = [0 0];
    end
    %{
    % Luminance maximization method
    if value > 0
        P.contrasts = [1 10^(-value)];
    else
        P.contrasts = [10^value 1];
    end
    %}
    
    P.markOffsetPx = AE.markBracketsPx(AE.markStage);
end
