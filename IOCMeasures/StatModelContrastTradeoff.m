function [ M ] = StatModelContrastTradeoff( M )
%STATMODELCONTRASTTRADEOFF Default statistical model for tradeoffs
    
    % trial values (i.e. S.trialVal) are 
    % log(signal dot contrast / noise dot contrast)
    
    % Prior beliefs about p'metric function, as in QuestCreate
    % (but fill these out regardless if you use Quest!)
    % To visualize the initial p'metric function, use:
    %   q = QuestCreate(...);
    %   plot(q.x2+q.tGuess, q.p2);
    M.tAverage	= 0.1;	% Average/mode threshold in the population
    M.tSD       = 0.3;	% Distribution of thresholds in the population
    M.beta      = 4.0;	% Steepness of p'metric func (low=more spread)
    M.delta     = 0.02;	% Error (ex. random mistype) rate
    M.gamma     = 0.5;	% Prob of correct by chance (0.5 for 2AFC)
    M.grain     = 0.01;	% How finely QUEST should keep track of the
                        % probability density function
    M.range     = 4.0;	% How far away from initial threshold to search
        % Warning: QUEST must stay in tAverage +/- 0.5*range, so setting
        %   range too low will screw up threshold estimate!
    M.pThreshold= 0.82;	% Threshold will have this correctness level
                        % (will be overridden if using nDownmUp)
    
    M.sdTarget	= .05;	% Exit early if QUEST says std error is below this
        % This 95.45% confidence interval would result:
        %   (threshold-2*sdTarget, threshold+2*sdTarget)
        % (use 0 to disable early exits)
    
    if ~M.useQuest
        % nDownmUp
        M.downCount = 3;	% How many consecutive correct before harder?
        M.upCount = 1;      % (only upCount = 1 works properly right now)
        
        M.tStart = 0.5;     % Initial trial contrast (start easy!)

        % Suggested/calculated numbers from Garcia-Perez (1998):
        [M.stepDown, M.stepUp, M.pThreshold] = ...
            CalcGarciaPerezStaircase(M);
    end
end

