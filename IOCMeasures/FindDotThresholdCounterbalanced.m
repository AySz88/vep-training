function [ ts, sds, Ss ] = FindDotThresholdCounterbalanced( trialName )
%FINDDOTTHRESHOLDCOUNTERBALANCED
%   Finds a threshold by varying the number of signal dots
        
    % Make sure there aren't data files still in this folder
    % TODO write data to a temporary data folder and check for files there
    psychassert(isempty(dir('*.mat')), ...
        'FindDotThresholdCounterbalanced:MATFilesInFolder', ...
        ['Found .mat files in the current working directory! Please' ...
        ' move or remove files from previous experiments!']);
    
    % Parse arguments
    if nargin == 0
        trialName = input('Identifier for this set of trials: ', 's');
    end
    
    [M, E, HW] = Parameters();
    E.catchTrialProb = 0.0; % Probability of inserting a catch trial
    
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
    
    labels =  {'Left eye', ...
        'Right eye', ...
        'Right eye (2nd time)', ...
        'Left eye (2nd time)'};
    
    sizeArgs = {4, 1};
    Ss = cell(sizeArgs{:});
    ts = zeros(sizeArgs{:});
    sds = zeros(sizeArgs{:});
    
    % Start experiment
    [didHWInit HW] = InitializeHardware(HW);
    caughtException = [];
    try
        % Prepare to draw staircases
        figure;
        subplot(sizeArgs{:}, 1);
        
        % Don't start until key pressed
        HW = Breaktime(HW, 0, [], 'Press a key when ready...');
        
        % Signal left, noise left
        setIndex = 1;
        sigEye = 1;
        noiseEye = 1;
        [ts, sds, Ss] = RunSet(...
            setIndex, sigEye, noiseEye, ...
            sizeArgs, labels, M, E, HW, ...
            ts, sds, Ss);
        
        % Signal right, noise right
        setIndex = 2;
        sigEye = 2;
        noiseEye = 2;
        [ts, sds, Ss] = RunSet(...
            setIndex, sigEye, noiseEye, ...
            sizeArgs, labels, M, E, HW, ...
            ts, sds, Ss);
        % 30s break, interruptible after 5
        HW = Breaktime(HW, 30, [], [], 5);
        
        % Signal right, noise right (second time)
        setIndex = 3;
        sigEye = 2;
        noiseEye = 2;
        [ts, sds, Ss] = RunSet(...
            setIndex, sigEye, noiseEye, ...
            sizeArgs, labels, M, E, HW, ...
            ts, sds, Ss);
        
        % Signal left, noise left (second time)
        setIndex = 4;
        sigEye = 1;
        noiseEye = 1;
        [ts, sds, Ss] = RunSet(...
            setIndex, sigEye, noiseEye, ...
            sizeArgs, labels, M, E, HW, ...
            ts, sds, Ss);
        %re-enable x-axis marks on bottom plots
        for iHorizPlot=1
            subplot(sizeArgs{:}, sizeArgs{1}*sizeArgs{2}-iHorizPlot+1);
            set(gca,'xtickMode','auto');
        end
        
        %save staircases figure
        hgsave('staircases.fig');

        hold off;

        save('Ss.mat', 'Ss');
        fileattrib('Ss.mat', '-w'); %readonly
        save('ts.mat', 'ts');
        fileattrib('ts.mat', '-w'); %readonly
        save('sds.mat', 'sds');
        fileattrib('sds.mat', '-w'); %readonly
        save('labels.mat', 'labels');
        fileattrib('labels.mat', '-w'); %readonly
        
        % stop logging
        diary off
        
        mkdir(folder);
        [~] = movefile('*.fig', folder);
        [~] = movefile('*.mat', folder);
        [~] = movefile('*.xls', folder);
        [~] = movefile('*.csv', folder);
        [~] = movefile('*.log', folder);
        [~] = copyfile('*.m', folder);

        system(...
            ['hg add --cwd ' dataFolder ' --include "' subfolder '\*"']);
        message = sprintf('"Automatic commit of new data: %s"', folder);
        system(['hg commit --cwd ' dataFolder ' -u MATLAB -m ' message]);
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

function [ts, sds, Ss] = RunSet(...
            setIndex, sigEye, noiseEye,...
            spargs, labels, M, E, HW, ...
            ts, sds, Ss)
    % decimated version of FindContrastTradeoffThresholdLisa's RunSet
    
    % Pick out which eyes should have signal and noise dots
    % TODO warn if there are multiple different values for ...
    %   signal or noise contrast
    newContrasts = - inf(2);
    newContrasts(1,sigEye) = ...
        mean(E.P.contrasts(1,~isinf(E.P.contrasts(1,:))));
    newContrasts(2,noiseEye) = ...
        mean(E.P.contrasts(2,~isinf(E.P.contrasts(2,:))));
    E.P.contrasts = newContrasts;

    staircaseText = labels{setIndex};

    % Initialize staircase plot area
    axesh = subplot(spargs{:}, setIndex);
    %title(axesh, staircaseText, 'FontSize', 6);

    [t, sd, S, HW] = FindThreshold(M, E, HW, axesh);

    ts(setIndex,1) = t;
    sds(setIndex,1) = sd;
    Ss{setIndex,1} = S;

    % remove x axis labels so there's more room for the graphs
    set(axesh,'xtick',[]);

    filename = sprintf('S %s.mat', staircaseText);
    save(filename, 'S');
    fileattrib(filename, '-w'); %readonly
end
