function [ prepParams update ] = ContrastStaircaseHelpers( )
%CONTRASTSTAIRCASEHELPERS Helper functions for contrast threshold staircase
    prepParams = @contrastPrepParams;
    update = @contrastUpdate;
end

function [P, overflow, underflow] = contrastPrepParams(E, HW, S)
%CONTRASTPREPPARAMS Build stimulus parameters from current experiment state
%   Holds "noise" eye (fellow fixing eye, FFE) steady, changes contrast of
%       signal dots in amblyoptic eye
%   In E.P.contrasts, any "-Inf" signal means no dots in that eye,
%       and anything else means to put dots with the trial contrast
%
%   Inputs:
%       E = Experiment parameter structure
%       HW = Hardware parameter structure
%       S = Current experiment state
%
%   Outputs:
%       P = Next stimulus parameters
%       overflow = Whether S requested easier stimulus than is presentable
%       underflow = Whether S requested harder stimulus than possible
    overflow = false;
    underflow = false;
    P = E.P; % pull defaults over
    
    % calculate nearest stimulus luminance
    wantedLum = (1 + 10.^S.trialVal) * E.bgLumnce;
    
    % warn on boundary conditions
    if wantedLum > 1.0
        warning('ContrastPrepParams:OutOfBounds', ...
            ['Requested contrast mean would cause mean luminance' ...
            ' of signal dots to be brighter than max!'])
        overflow = true;
        wantedLum = 1.0; % clamp to max
    elseif (wantedLum - E.bgLumnce) < (0.5/HW.white)
        warning('ContrastPrepParams:OutOfBounds', ...
            ['Contrast low - rounding will make many/most/all signal' ...
            ' dots the same luminance as the background!']);
        underflow = true;
    end
    
    [~, signalLum] = LumToColor(HW, wantedLum);
    
    signalContrast = log10(signalLum/E.bgLumnce - 1);
    
    % Apply this contrast to visible (i.e. contrast not -Inf) entries
    P.contrasts(1, P.contrasts(1,:) ~= -Inf) = signalContrast;
    
    % randomly pick up or down (guided by E.upChance)
    if rand() < E.upChance
        P.dir = 'up';
    else
        P.dir = 'down';
    end
end

function [S, stop] = contrastUpdate(M, S, P, i, correct, h)
%CONTRASTUPDATE Updating contrast threshold models based on trial response
%   Inputs:
%       M = Model (i.e. staircase) parameter structure
%       S = Current experiment state
%       P = Last stimulus parameters
%       i = Current trial number
%       correct = Whether response was correct
%       h = Axes handle on which to plot staircase progress (optional)
%   
%   Outputs:
%       S = Updated experiment state
%       stop = Whether staircase should halt
    
    sigContrasts = P.contrasts(1,:);
    sigContrast = mean(sigContrasts(sigContrasts ~= -Inf));
    
    if correct
        correctStr = 'right';
    else
        correctStr = 'wrong';
    end
    fprintf(['Trial %3d at 10^%5.2f (10^%5.2f) = %5.2f%% (%.2f%%) ' ...
        'is %s\n'], ...
        i, S.trialVal, sigContrast, ...
        10^(S.trialVal+2), 10^(sigContrast+2), correctStr);
    
    [S, stop] = GenericUpdateHelper(M, S, P, i, correct, sigContrast);
    
    if ~isempty(h)
        plot(h, 10.^(S.trialVals(1:S.lastLogged)));
        xlabel(h, 'Trial number');
        ylabel(h, 'Signal contrast');
        drawnow expose;
    end
end
