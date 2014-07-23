function S = GenericInitStaircase(M, E)
%GenericInitStaircase Intializes experiment state variable S
%   M: Model (i.e. staircase) parameter structure
%   E: Experiment (i.e. stimulus) parameter structure
%
%   S: Current experiment state
%       S.q: QUEST object
%       S.trialVal: value to test at for next (i.e. first) trial
%       S.trialLog:
%           one row per trial {P, correct} where P is stimulus parameters
    S.q=QuestCreate(M.tAverage, M.tSD, ...
        M.pThreshold, M.beta, M.delta, M.gamma, M.grain, M.range);
    
    if M.useQuest
        S.trialVal = QuestQuantile(S.q);
    else %nDownmUp
        S.trialVal = M.tStart;
        
        % Variables used in nDownmUp:
        S.recentRight = 0;
        S.recentWrong = 0;
        
        % Initialization period: start w/ quick 'down's, like Garcia-Perez
        S.initialization = true;
        
        % Reversal tracking
        S.lastDirWasDown = true;
        S.reversals = ...
            zeros(1,ceil(2*E.maxTrials/(M.downCount + M.upCount)));
        S.reversalNum = 1; % which reversal index is next
    end
    
    S.trialVals = zeros(E.maxTrials, 1);
    S.trialLog = cell(E.maxTrials, 2);
    S.lastLogged = 0; % how many rows of trialLog have data?
end
