function [S, stop] = GenericUpdateHelper(M, S, P, i, correct, testVal)
%GENERICUPDATEHELPER Generic code to update models based on trial response
%   Intended to be called by specific update methods.
%
%   Inputs:
%       M = Model (i.e. staircase) parameter structure
%       S = Current experiment state
%       P = Last stimulus parameters
%       i = Current trial number
%       correct = Whether response was correct
%       testVal = Value at which the trial stimulus was acutally displayed
%   
%   Outputs:
%       S = Updated experiment state
%       stop = Whether staircase should halt

    % Log result
    S.trialLog(i, :) = {P, correct};
    S.trialVals(i) = S.trialVal;
    S.lastLogged = i;
    
    % Update models/statistics
    S.q = QuestUpdate(S.q, testVal, correct);
    
    if M.useQuest
        S.trialVal = QuestQuantile(S.q);
    else % update nDownmUp
        if correct
            S.recentRight = S.recentRight + 1;
            S.recentWrong = 0;
        else
            S.recentRight = 0;
            S.recentWrong = S.recentWrong + 1;
        end
        
        % debugging code
        %fprintf('%3u right %3u wrong...\n', S.recentRight, S.recentWrong);
        
        % check for staircase steps and reversals
        if S.recentRight >= M.downCount || ...
                (S.initialization && (S.recentRight >= 1))
            % step down (harder)
            if ~S.lastDirWasDown
                S.reversals(S.reversalNum) = S.trialVal;
                S.reversalNum = S.reversalNum + 1;
            end
            S.trialVal = S.trialVal + M.stepDown;
            S.recentRight = 0;
            S.lastDirWasDown = true;
        elseif S.recentWrong >= M.upCount
            % step up (easier)
            if S.lastDirWasDown
                S.reversals(S.reversalNum) = S.trialVal;
                S.reversalNum = S.reversalNum + 1;
            end
            S.trialVal = S.trialVal + M.stepUp;
            S.recentWrong = 0;
            S.initialization = false;
            S.lastDirWasDown = false;
        end
    end
    
    % Check for early halting
    stop = QuestSd(S.q) < M.sdTarget;
    if (stop)
        fprintf('Uncertainty low - recommend stopping early!\n');
    end
end
