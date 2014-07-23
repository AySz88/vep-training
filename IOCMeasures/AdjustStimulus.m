function [ value, HW ] = AdjustStimulus( HW, AE )
%ADJUSTSTIMULUS Have subject adjust the stimulus and return the value
% Draws stimulus every frame, and listens for keystrokes every frame.
%   HW: Hardware parameter structure (see Parameters.m)
%   AE: Adjustment task parameter structure (see AdjustmentParameters.m)

    if nargin < 1 || isempty(HW)
        warning('AdjustStimulus:DefaultParams', ...
            'Reading parameters from AdjustmentParameters.m');
        [AE, HW] = AdjustmentParameters();
    end
    
    [didHWInit HW] = InitializeHardware(HW);
    
    % Any exception in experiment code will be saved to here for later use
    caughtException = [];
    
    try
        value = AE.initValue;
        stop = false;
        
        KbWait([],1); % wait until all keys are released
        wasKeyUp = false;
        
        while ~stop
            % Present new stimulus
            stimParams = AE.prepParams(AE, value);
            
            HW = AE.stimulus(stimParams, HW);

            % Process response
            [keyDown, ~, keyCode, ~] = KbCheck();
            downstroke = keyDown && wasKeyUp;
            if downstroke
                response = KbName(keyCode);
            else
                response = [];
            end
            if downstroke && ~iscell(response)
                switch lower(response)
                    case HW.upKey
                        [AE, value] = AE.goUp(AE, value);
                    case HW.downKey
                        [AE, value] = AE.goDown(AE, value);
                    case HW.stopKey
                        [AE, value, stop] = AE.stopCheck(AE, value);
                    case HW.haltKey
                        % 'graceful' bail
                        throw(MException('FindThreshold:Halt', ...
                            ['Halted by user hitting ''' ...
                            HW.haltKey '''!']));
                    otherwise
                        % That wasn't one of the valid keys!
                        PsychPortAudio('Start', HW.failSoundHandle);
                        % TODO display message to user?
                end
            end
            wasKeyUp = ~keyDown;
        end
    catch e
        caughtException = e;
    end
    
    if didHWInit
        HW = CleanupHardware(HW);
    end
    
    if ~isempty(caughtException)
        rethrow(caughtException);
    end
end

