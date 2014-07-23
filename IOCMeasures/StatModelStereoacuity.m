function [ M ] = StatModelStereoacuity( M )
%STATMODELSTEREOACUITY "Model" for Stereoacuity

    % TODO this statistical model isn't used for training, so it hasn't
    % been changed much from the dot one (yet)
    %From QuestCreate
    M.tAverage	= log10(15);	% Average/mode threshold in the population
    M.tSD       = log10(20);	% Distribution of thresholds in the pop
    M.beta      = 10;	% Steepness of p'metric func (low=more spread)
    M.delta     = 0.02;	% Error (ex. random mistype) rate
    M.gamma     = 0.5;	% Prob of correct by chance (0.5 for 2AFC)
    M.grain     = 0.005;	% How finely QUEST should keep track of the ...
                            % probability density function
    M.range     = 1;	% How far away from initial threshold to search
        % Warning: QUEST must stay in tAverage +/- 0.5*range, so setting
        %   range too low will screw up threshold estimate!
    M.pThreshold= 0.82;	% Threshold will have this correctness level
        % (will be overridden if using nDownmUp)
        
    M.sdTarget	= 0.0;	% Exit early if QUEST says std dev is below this
        % This 95.45% confidence interval would result:
        %   (threshold-2*sdTarget, threshold+2*sdTarget)
        % (use 0 to disable early exits)
        
    if ~M.useQuest
        % nDownmUp
        M.downCount = 3;	% How many consecutive correct before harder?
        M.upCount = 1;      % (only upCount = 1 works properly right now)
        
        M.tStart = log10(50); % Initial disparity (suggest starting easy!)

        % Suggested/calculated numbers from Garcia-Perez (1998):
        [M.stepDown, M.stepUp, M.pThreshold] = ...
            CalcGarciaPerezStaircase(M);
    end
end

