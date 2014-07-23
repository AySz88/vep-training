function [ prepParams update ] = DotStaircaseHelpers( )
%DOTSTAIRCASEHELPERS Returns helper functions for dot threshold staircase
    prepParams = @dotsPrepParams;
    update = @dotsUpdate;
end

function [P, overflow, underflow] = dotsPrepParams(E, ~, S)
%DOTSPREPPARAMS Build stimulus parameters from current experiment state
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
    P.bgLumnce = E.bgLumnce;
    
    desiredDots = 10^S.trialVal;
    
    % warn on boundary conditions
    if desiredDots > P.nDots
        warning('DotsPrepParams:OutOfBounds', ...
            ['Requested number of signal dots' ...
            ' higher than total number of dots!'])
        overflow = true;
    elseif desiredDots < 0
        warning('DotsPrepParams:OutOfBounds', ...
            'Requested number of signal dots negative!')
        underflow = true;
    end

    % Must be integer, so use weighted random rounding
    % ex. 1.25 --> 75% chance of 1 dot, 25% chance of 2 dots.
    numSignal = floor(desiredDots) + (rand() < mod(desiredDots,1));

    % Must be between 0 and numDots inclusive
    numSignal = min(max(numSignal,0), P.nDots);
    
    P.sigDots = numSignal;

    % randomly pick up or down (guided by E.upChance)
    if rand() < E.upChance
        P.dir = 'up';
    else
        P.dir = 'down';
    end
end

function [S, stop] = dotsUpdate(M, S, P, i, correct, h)
%DOTSUPDATE Dots-specific code for updating models based on trial response
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
    
    if correct
        correctStr = 'right';
    else
        correctStr = 'wrong';
    end
    fprintf('Trial %3d at 10^%5.2f = %5.2f (%.2f) is %s\n', ...
        i, S.trialVal, 10.^S.trialVal, P.sigDots, correctStr);
    
    
    [S, stop] = GenericUpdateHelper(M, S, P, i, correct, log10(P.sigDots));
    
    if ~isempty(h)
        plot(h, 10.^S.trialVals(1:S.lastLogged));
        xlabel(h, 'Trial number');
        ylabel(h, 'Signal Dots');
        drawnow expose;
    end
end
