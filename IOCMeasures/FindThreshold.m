function [ t, sd, S, HW ] = FindThreshold( M, E, HW, h, S)
%FINDTHRESHOLD Runs a staircase given passed-in parameters
%   TODO Detailed explanation goes here
%   
%   TODO: CATCH TRIALS TO MAKE SURE THAT GOOD EYE IS OPEN:
%       Have some signal dots in good eye moving opposite to ambly eye
%   
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
%
%   To test, run: [t sd S HW] = FindThreshold;
    
    if nargin < 1 || isempty(M)
        warning('FindThreshold:DefaultParams', ...
            'Reading parameters from Parameters.m');
        [M, E, HW] = Parameters();
    end
    
    [didHWInit HW] = InitializeHardware(HW);
    
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
        
        lastRDKTime = 0;
        wasWrongCatch = false;
        
        for i=(S.lastLogged+1):E.maxTrials
            keepGoing = true;
            while keepGoing
            	catchTrial = rand() < E.catchTrialProb;
                
                % setup P = stimulus parameters that (may) change every trial
                [P, overflow, underflow] = E.prepParams(E, HW, S);
                % TODO stop the experiment early if overflow happens too much
                % (subject probably can't see / doesn't understand stimulus)
                % and handle underflow (meaningless trials)
                
                if catchTrial
                    if rand() < 0.5 % TODO Parameterize
                        P.catchDirection = 'left';
                    else
                        P.catchDirection = 'right';
                    end
                else
                    P.catchDirection = '';
                end

                KbWait([],1); % wait until all keys are released
                WaitSecs(max(E.pauseTime, lastRDKTime + E.minPause - GetSecs));
                
                if i==1 || wasWrongCatch
                    % show just the fixation mark before trial for a bit
                    % HACK ...by showing the stimulus with invisible dots
                    fixMarkP = P;
                    fixMarkP.sigDots = 1;
                    fixMarkP.nDots = 2;
                    fixMarkP.contrasts = [-Inf, -Inf; -Inf, -Inf];
                    fixMarkP.catchDirection = ''; % remove any catch dot
                    fixMarkP.duration = 1.0; % FIXME parameterize
                    fixMarkP.clearAtEnd = true;
                    HW = RanDotKgram(fixMarkP, HW);
                    
                    wasWrongCatch = false; % reset flag for next pass
                end
                
                % Show the RDK
                HW = RanDotKgram(P, HW);
                lastRDKTime = GetSecs;

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
                
                if catchTrial
                    correct = ...
                        (strcmp(response,HW.leftKey) ...
                            && strcmp(P.catchDirection, 'left')) ...
                        || (strcmp(response,HW.rightKey) ...
                            && strcmp(P.catchDirection, 'right'));
                else
                    correct = ...
                        (strcmp(response,HW.upKey) ...
                            && strcmp(P.dir, 'up')) ...
                        || (strcmp(response,HW.downKey) ...
                            && strcmp(P.dir, 'down'));
                end

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

                if catchTrial
                    S.catchResponses = [S.catchResponses; i, correct];
                    if ~correct
                        HW = Breaktime(HW, 0, @(t) '', ...
                            ['Keep your eyes on the box!' ...
                            ' Press any key...']);
                        wasWrongCatch = true;
                    end
                    stop = false;
                else
                    % Update staircase and pick the parameters of the next trial
                    [S, stop] = E.update(M, S, P, i, correct, h);
                end

                if stop
                    break; % recommended stopping early!
                end
                
                keepGoing = catchTrial;
            end
        end

        t = QuestMean(S.q);
        sd = QuestSd(S.q);
        fprintf('Final threshold estimate (mean±sd): %.2f ± %.2f\n',t,sd);
        
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

