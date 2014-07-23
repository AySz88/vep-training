function [HW, totalTime] = Breaktime(HW, duration, textFunc, afterText, ...
    optionalAfter, autoAdvance)
%BREAKTIME Displays a countdown timer with text on the screen
%   Required input arguments:
%       HW: Hardware parameter structure (see Parameters.m)
%       duration: Duration of break, in seconds
%   Optional input arguments:
%       textFunc: Text to display during break, either as a string or
%           as a function taking in the time left, i.e.
%            [ text ] = @(timeLeft)
%           Pass in empty array [] to leave the following default in place:
%            @(t) sprintf('Please take a %i second break!', t);
%       afterText: after break, text to display
%           default: 'Done! Press a key when ready...'
%       optionalAfter: time (in seconds) after which a keypress
%           will interrupt the countdown. Default: Inf (never)
%       autoAdvance: if true, return without waiting for
%           a keypress when timer expires.  Defaults to false.
%   Output:
%       HW: Hardware parameter structure (with any changes)
%       totalTime: Length of break in seconds
%
%   Example:
%     [~, ~, HW] = Parameters();
%     Breaktime(HW, 5);
%     Breaktime(HW, 5, @(t) 'Blah blah!', 'Ended!');
%     Breaktime(HW, 60, ...
%           @(t) sprintf('Optional after 10 s! Now: %i',t), [], 10);
%     Breaktime(HW, 5,  ...
%           @(t) sprintf('Autoadvance! Now: %i',t), [], [], true);
    
    if nargin < 3 || isempty(textFunc)
        textFunc = @(t) sprintf('Please take a %i second break!', t);
    end
    if ischar(textFunc) % given a string instead of a function
        textFunc = @(t) textFunc;
    end
    if nargin < 4 || isempty(afterText)
        afterText = 'Okay to continue! Press a key when ready...';
    end
    if nargin < 5 || isempty(optionalAfter)
        optionalAfter = Inf;
    end
    if nargin < 6 || isempty(autoAdvance)
        autoAdvance = false;
    end
    
    [didHWInit HW] = InitializeHardware(HW);
    caughtException = [];
    
    try
        start = GetSecs();
        timeLeft = round(start + duration - GetSecs());
        while timeLeft > 0 && ...
            ~(timeLeft < (duration - optionalAfter) && KbCheck)
            
            for i=0:1
                HW = ScreenCustomStereo(...
                    HW, 'SelectStereoDrawBuffer', HW.winPtr, i);
                
                Screen('FillRect', HW.winPtr, 0); % black background
                
                finalText = textFunc(timeLeft);
                DrawFormattedText(HW.winPtr, finalText, ...
                    'center', 'center', ...
                    HW.white, 50);
            end
            HW = ScreenCustomStereo(HW, 'Flip', HW.winPtr);
            
            WaitSecs(1/HW.fps);
            timeLeft = round(start + duration - GetSecs());
        end
        
        % Done with countdown, draw final text
        for i=0:1
            HW = ScreenCustomStereo(...
                    HW, 'SelectStereoDrawBuffer', HW.winPtr, i);
            Screen('FillRect', HW.winPtr, 0); % black background
            DrawFormattedText(HW.winPtr, afterText, ...
                'center', 'center', HW.white, 50);
        end
        HW = ScreenCustomStereo(HW, 'Flip', HW.winPtr);
        
        if ~autoAdvance, KbWait([], 3); end
        
        totalTime = start - GetSecs();
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

