function [ t, sd, S, HW ] = SARTrainingStaircase( M, E, HW, h, S)
%SARTRAININGSTAIRCASE Runs a SAR staircase given passed-in parameters
%   Inputs:
%       M: Model (i.e. staircase) parameter structure
%       E: Experiment parameter structure
%       HW: Hardware parameter structure
%       h: axes handle to which the staircase should be plotted
%       S: Experiment state information
%       	as input: information with which to restart the staircase
%           (TODO not currently tested)
%   Outputs:
%       t: Threshold value found
%       sd: Standard error of the threshold value
%       HW: Hardware parameter structure
%       S: Experiment state information
%           as output: all trial info (including any trials passed in)
    
    [didHWInit, HW] = InitializeHardware(HW);
    
    % Any exception in experiment code will be saved to here for later use
    caughtException = [];
    
    try
        if nargin < 4
            h = [];
        end
        
        if nargin < 5 || isempty(S)
            S = M.initialize(M, E); % S = staircase state
        end
        
        if ~isfield(S, 'catchResponses')
            S.catchResponses = [];
        end
        
        lastTrialTime = 0;
        adjustTaskNum = 0;
        
        for i=(S.lastLogged+1):E.maxTrials
            % setup P = stimulus parameters that (may) change every trial
            E.currNearRect = E.nearRectArray(i);
            [P, overflow, underflow] = E.prepParams(E, HW, S);
            % TODO stop the experiment early if overflow happens too much
            % (subject probably can't see / doesn't understand stimulus)
            % and handle underflow (meaningless trials)

            KbWait([],1); % wait until all keys are released
            WaitSecs(max(E.pauseTime, lastTrialTime + E.minPause - GetSecs));

            % Show the stimulus
            HW = StereoacuityRectangles(P, HW);
            lastTrialTime = GetSecs;

            % Get and interpret the response
            % TODO use KBName('UnifyKeyNames') and compare key code #s
            [~,keyCode,~] = KbWait([], 2); 
            response = KbName(keyCode);
            while ~(~iscell(response) ...
                    && sum(strcmp(HW.validKeys,response))==1)
                % Tell user to press one of the valid keys
                PsychPortAudio('Start', HW.failSoundHandle);
                % TODO display message to user

                [~,keyCode,~] = KbWait([], 2); 
                response = KbName(keyCode);
            end

            correct = ...
                (strcmp(response,HW.upKey) ...
                && strcmp(P.dir, 'top')) ...
                || (strcmp(response,HW.downKey) ...
                && strcmp(P.dir, 'bottom'));

            if response == HW.haltKey
                % 'graceful' bail
                throw(MException('FindThreshold:Halt', ...
                    ['Halted by user hitting ''' HW.haltKey '''!']));
            end

            % Play feedback sound
            if correct
                soundHandle = HW.rightSoundHandle;
            else
                soundHandle = HW.wrongSoundHandle;
            end
            PsychPortAudio('Start', soundHandle);

            % Update staircase and pick the parameters of the next trial
            [S, stop] = E.update(M, S, P, i, correct, h);

            if stop
                break; % recommended stopping early!
            end
            
            if any(i == E.pauseTimes)
                adjP = E.noniusTaskP;
                outIdxs = adjustTaskNum*adjP.nAdj*2 + (1:adjP.nAdj*2);
                [HW, S.noniusData.angDisp(outIdxs), ...
                    S.noniusData.fixDisp(outIdxs), ...
                    S.noniusData.bias(outIdxs), ...
                    S.noniusData.posInit(outIdxs), ...
                    S.noniusData.posResp(outIdxs), ...
                    S.noniusData.adjustRespTime(outIdxs)] ...
                    = ...
                    NoniusAdjustmentTask(HW, P, adjP);
                adjustTaskNum = adjustTaskNum + 1;
            end
        end

        t = QuestMean(S.q);
        sd = QuestSd(S.q);
        fprintf('Fit threshold estimate (mean±sd): %.2f ± %.2f\n',t,sd);
        
        QuestBetaAnalysis(S.q);
        
        if ~M.useQuest
            % remove extraneous entries
            S.reversals = S.reversals(1:S.reversalNum-1);
            
            S.reversals
            fprintf('%i reversals - mean of all but first 5: %.2f\n', ...
                S.reversalNum-1, mean(S.reversals(5:end)));
        end
        
        % remove extraneous rows in S.trialLog
        S.trialLog = S.trialLog(1:S.lastLogged, :);
        S.trialVals = S.trialVals(1:S.lastLogged);
    catch e
        caughtException = e;
    end
    
    if didHWInit
        HW = CleanupHardware(HW);
    end
    
    if ~isempty(caughtException)
        rethrow(caughtException);
        % TODO: Look at the exception before deciding whether to keep
        % any data collected.  Suggest catching it and then saving out the
        % MException object along with M, E, HW, S to enable restart.
    end
end

