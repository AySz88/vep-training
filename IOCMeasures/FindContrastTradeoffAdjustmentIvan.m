function [ values, HW ] = FindContrastTradeoffAdjustmentIvan( trialName, HW, AE )
%FINDCONTRASTTRADEOFFADJUTSMENTIVAN
%   Finds the adjusted value by varying the contrast b/t sinusoidal stims
        
    % Make sure there aren't data files still in this folder
    % TODO write data to a temporary data folder and check for files there
    psychassert(isempty(dir('*.mat')), ...
        'FindContrastTradeoffAdjustmentIvan:MATFilesInFolder', ...
        ['Found .mat files in the current working directory! Please' ...
        ' move or remove files from previous experiments!']);
    
    % Parse arguments
    if nargin == 0
        trialName = input('Identifier for this set of trials: ', 's');
    end
    
    if nargin < 2 % both HW and AE are missing
        [AE, HW] = AdjustmentParameters();
    elseif nargin < 3 % only AE is missing
        [AE, ~] = AdjustmentParameters();
    end
    
    % Start logging input/output
    diary('diary.log');
    fprintf('\nStarting experiment...\n');
    
    dataFolder = 'data\'; %TODO parameterize
    curdate = datestr(now);
    curdate(curdate == ':') = '-'; % ':' not allowed in folder names
    if isempty(trialName)
        subfolder = curdate;
    else
        subfolder = [curdate ' ' trialName];
    end
    folder = [dataFolder subfolder];
    
    initialValues = log10([1/0.6, 0.6, 1.0, 0.6, 1/0.6]);
    repeats = length(initialValues);
    values = zeros(1,repeats);
    
    % Start experiment
    [didHWInit, HW] = InitializeHardware(HW);
    caughtException = [];
    try
        % Don't start until key pressed
        HW = Breaktime(HW, 0, [], 'Press a key when ready...');
        
        AEControl = RectangularSinusoidControlAdjustment();
        AEControl.P.widthDeg = AE.P.widthDeg; %HACK
        [controlValue, HW] = AdjustStimulus(HW, AEControl);
        PsychPortAudio('Start', HW.rightSoundHandle);
        
        sprintf('Final control value was: %f\n', controlValue);
        
        for iTrial = 1:repeats
            AE.initValue = initialValues(iTrial);
            [values(iTrial), HW] = AdjustStimulus(HW, AE);
            PsychPortAudio('Start', HW.rightSoundHandle);
        end
        
        save('controlValue.mat', 'controlValue');
        fileattrib('controlValue.mat', '-w'); %readonly
        save('values.mat', 'values');
        fileattrib('values.mat', '-w'); %readonly
        
        % stop logging
        diary off
        
        mkdir(folder);
        [~] = movefile('*.fig', folder);
        [~] = movefile('*.mat', folder);
        [~] = movefile('*.xls', folder);
        [~] = movefile('*.csv', folder);
        [~] = movefile('*.log', folder);
        [~] = copyfile('*.m', folder);
        
        if ~strfind(folder, 'test')
            system(...
                ['hg add --cwd ' dataFolder ' --include "' subfolder '\*"']);
            message = sprintf('"Automatic commit of new data: %s"', folder);
            system(['hg commit --cwd ' dataFolder ' -u MATLAB -m ' message]);
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
