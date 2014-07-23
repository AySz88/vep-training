function [ prepParams update ] = ContrastTradeoffStaircaseHelpers( )
%CONTRASTSTAIRCASEHELPERS Helper functions for contrast threshold staircase
    prepParams = @contrastTOPrepParams;
    update = @contrastTOUpdate;
end

function [P, overflow, underflow] = contrastTOPrepParams(E, HW, S)
%CONTRASTTOPREPPARAMS Build stim parameters from current experiment state
%   Given a background luminosity, finds max contrast
%   (ex. for background of 0.5, 100%; for 0.25, 300%, etc.)
%   Keeps this contrast as the total (linear) contrast b/t signal & noise
%   Staircase is on log steps of signal/noise contrast ratio
%       ex. trialVal = .301 = log10(2.0) at bgLum of 0.25 results in:
%           signal contrast of 200%, luminance of 0.75 (0.50 above bg)
%           noise contrast of 100%, luminance of 0.50 (0.25 above bg)
%
%   Inputs:
%       E = Experiment parameter structure
%       HW = Hardware parameter structure
%       S = Current experiment state
%
%   Outputs:
%       P = Next stimulus parameters
%       overflow = Whether some (signal or noise) luminance is too high
%       underflow = Whether some (signal or noise) luminance is too low
    % Initialize
    overflow = false;
    underflow = false;
    
    P = E.P; % pull defaults over
    P.bgLumnce = E.bgLumnce;
    
    % Calculate desired luminances
    totalContrast = (1.0 / E.bgLumnce) - 1.0;
    sigShare = 10.^S.trialVal;
    contrastShares = [sigShare 1.0] / (sigShare + 1.0); % [sig, noise]
    contrasts = contrastShares * totalContrast;
    wantedLums = (contrasts + 1.0) * E.bgLumnce;
    overflows = wantedLums > 1.0;
    underflows = (wantedLums - E.bgLumnce) < (0.5/HW.white);
    
    % warn on boundary conditions
    if any(overflows)
        switch 2*overflows(1) + overflows(2) % as a bitflag
            case 2 % [1 0]
                type = 'signal';
            case 1 % [0 1]
                type = 'noise';
            case 3 % [1 1]
                type = 'signal and noise';
        end
        
        warning('contrastTOPrepParams:OutOfBounds', ...
            ['Requested contrast would cause mean luminance of ' type ...
            ' dots to be brighter than max!'])
        overflow = true;
        wantedLums = min(1.0, wantedLums); % clamp to max
    end
    if any(underflows)
        switch 2*underflows(1) + underflows(2) % as a bitflag
            case 2 % [1 0]
                type = 'signal';
            case 1 % [0 1]
                type = 'noise';
            case 3 % [1 1]
                type = 'signal and noise';
        end
        warning('contrastTOPrepParams:OutOfBounds', ...
            ['Contrast low - rounding may make many (most/all?) ' type ...
            ' dots the same luminance as the background!']);
        underflow = true;
    end
    
    [~, actualLums] = LumToColor(HW, wantedLums');
    actualLums = actualLums';
    actualContrasts = (actualLums/E.bgLumnce - 1.0);
    actualContrasts = log10(actualContrasts); % because RDK expects log10
    
    sigContrast = actualContrasts(1);
    noiseContrast = actualContrasts(2);
    
    % Apply this contrast to visible (i.e. contrast not -Inf) entries
    P.contrasts(1, P.contrasts(1,:) ~= -Inf) = sigContrast;
    P.contrasts(2, P.contrasts(2,:) ~= -Inf) = noiseContrast;
    
    % randomly pick up or down (guided by E.upChance)
    if rand() < E.upChance
        P.dir = 'up';
    else
        P.dir = 'down';
    end
end

function [S, stop] = contrastTOUpdate(M, S, P, i, correct, h)
%CONTRASTOUUPDATE Update experiment state based on trial response
%   Inputs:
%       M = Model (i.e. staircase) parameter structure
%       S = Current experiment state (before latest response)
%       P = Last stimulus parameters
%       i = Current trial number (the one that just ran)
%       correct = Whether response was correct
%       h = Axes handle on which to plot staircase progress (optional)
%   
%   Outputs:
%       S = Updated experiment state
%       stop = Whether staircase should halt
    
    % Recalculate the signal-to-noise ratio actually presented
    % (stored in P.contrasts from before, in contrastTOPrepParams)
    sigContrasts = P.contrasts(1,:);
    sigContrast = 10.^mean(sigContrasts(sigContrasts ~= -Inf));
    noiseContrasts = P.contrasts(2,:);
    noiseContrast = 10.^mean(noiseContrasts(noiseContrasts ~= -Inf));
    
    % Log the trial to the screen (and diary if applicable)
    if correct
        correctStr = 'right';
    else
        correctStr = 'wrong';
    end
    fprintf(['Trial %3d at 10^%5.2f = %5.2f:1' ...
        '(%5.2f%%/%5.2f%% = %5.2f:1) ' ...
        'was %s\n'], ...
        i, S.trialVal, 10.^S.trialVal, ...
        100*sigContrast, 100*noiseContrast, sigContrast/noiseContrast, ...
        correctStr);
    
    logSNR = log10(sigContrast/noiseContrast);
    
    % Update the actual staircase
    [S, stop] = GenericUpdateHelper(M, S, P, i, correct, logSNR);
    
    % Update the on-screen staircase visualization
    if ~isempty(h)
        titleH = get(h, 'Title');
        titleText = get(titleH, 'String'); % must restore later
        titleSize = get(titleH, 'FontSize');
        plot(h, S.trialVals(1:S.lastLogged));
        set(h, 'FontSize', 5);
        xlabel(h, 'Trial#', 'FontSize', 6);
        ylabel(h, 'logCR', 'FontSize', 6);
        title(h, titleText, 'FontSize', titleSize); % restore original
        drawnow expose;
    end
end
