function [ IOC, endDisparity ] = ShortTrainStereoacuity( trialName )
%SHORTTRAINSTEREOACUITY
%   Measures IOC with both Hess and Ding methods, then presents
%   StereoacutiyRectangles stimuli with feedback.  Repeats IOC measurement
%   at middle and end.
        
    % Make sure there aren't data files still in this folder
    % TODO write data to a temporary data folder and check for files there
    psychassert(isempty(dir('*.mat')), ...
        'TrainStereoacuity:MATFilesInFolder', ...
        ['Found .mat files in the current working directory! Please' ...
        ' move or remove files from previous experiments!']);
    
    % Parse arguments
    if nargin == 0
        trialName = input('Identifier for this set of trials: ', 's');
    end
    isDemo = ~isempty(strfind(trialName, 'demo'));
    isTesting = ~isempty(strfind(trialName, 'test')) || isDemo;
    
    if isDemo
        fprintf('Running demo version of experiment!\n');
    end
    
    [M, ~, HW] = Parameters();
    E = DefaultStereoacuityParameters();
    M = StatModelStereoacuity(M);
    
    [AE, ~] = AdjustmentParameters();
    
    acuityLow = [];
    while isempty(acuityLow)
        acuityText = input(['Use low-acuity version of Ding stimulus?' ...
            ' (yes/no or low/high): '], 's');
        switch lower(acuityText)
            case {'y', 'yes', 'l', 'low'}
                acuityLow = true;
            case {'n', 'no', 'h', 'high'}
                acuityLow = false;
            otherwise
                acuityLow = [];
                fprintf('Huh? Try again... ');
        end
    end
    if acuityLow
        AE.P.widthDeg = 2.0;
    end
    
    % Start experiment
    [didHWInit, HW] = InitializeHardware(HW);
    
    caughtException = [];
    try
        % Don't start until key pressed
        startMessage = 'Press a key when ready...';
        if isDemo
            startMessage = ['DEMO - ' startMessage];
        end
        HW = Breaktime(HW, 0, [], startMessage);
        
        % Measure initial IOCs
        [HW, initHessIOC, initDingIOC] = findIOCs(HW, trialName, 'Start', isTesting, AE);
        % For use when skipping initial findIOCs step:
        %[initHessIOC, initDingIOC] = deal(-0.3, -0.2);
        fprintf('Pre-training IOCs: %f, %f\n', initHessIOC, initDingIOC);
        
        % Stereoacuity measurement
        if isTesting
            E.numTrials = 20;
            E.pauseTimes = 5;
        end
        [folder, dataFolder, subfolder] = ...
            createFolderName([trialName ' StereoAcuity']);
        startDataLog();
        HW = Breaktime(HW, 0, [], 'Stereoacuity section; press a key when ready...');
        initTrainingIOC = mean([initHessIOC, initDingIOC]);
        [HW, endDisparity] = runTraining(initTrainingIOC, HW, M, E);
        fprintf('Ending stereoacuity disparity: %f\n', endDisparity);
        commitDataLog(folder, dataFolder, subfolder);
        
        if ~isDemo
            HW = Breaktime(HW, 0, [], 'Done with this phase... (Experimenter: please press a key.)');

            % Data summary
            [folder, dataFolder, subfolder] = ...
                createFolderName([trialName ' Session Summary']);
            startDataLog();
            fprintf('Start: %f, %f\n', ...
                initHessIOC, initDingIOC);
            IOCdata = [initHessIOC, initDingIOC]; %#ok<NASGU>
            save('IOCdata.mat', 'IOCdata');
            fileattrib('IOCdata.mat', '-w'); %readonly
            commitDataLog(folder, dataFolder, subfolder);

            IOC = initTrainingIOC;
        else
            IOC = -1;
        end
    catch e
        caughtException = e;
    end
    if didHWInit
        HW = CleanupHardware(HW); %#ok<NASGU>
    end
    if ~isempty(caughtException)
        rethrow(caughtException);
    end
end

function [folder, dataFolder, subfolder] = createFolderName(trialName)
    % Generate output folder name
    dataFolder = 'data\'; %TODO parameterize
    curdate = datestr(now);
    curdate(curdate == ':') = '-'; % since ':' not allowed in folder names
    if isempty(trialName)
        subfolder = curdate;
    else
        subfolder = [curdate ' ' trialName];
    end
    folder = [dataFolder subfolder];
end

function startDataLog()
    % Start logging input/output
    diary('diary.log');
    fprintf('\nStarting experiment...\n');
end

function commitDataLog(folder, dataFolder, subfolder)
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
end

function [ioc, ts, sds, Ss, HW] = RunHessIOC(trialName, HW, isTesting)
    labels =  {'Signal left, noise right', ...
       'Signal right, noise left', ...
       'Signal right, noise left (2nd time)', ...
       'Signal left, noise right (2nd time)'};
    sizeArgs = {4, 1};
    Ss = cell(sizeArgs{:});
    ts = zeros(sizeArgs{:});
    sds = zeros(sizeArgs{:});
    
    dirtylog = [];
    
    % Prepare to draw staircases
    figure;
    subplot(sizeArgs{:}, 1);
    
    [folder, dataFolder, subfolder] = createFolderName(trialName);
    startDataLog();
    
    [M, E, ~] = Parameters();
    M = StatModelContrastTradeoff(M);
    [E.prepParams, E.update] = ContrastTradeoffStaircaseHelpers();
    
    if isTesting
        E.maxTrials = 3;
    else
        E.maxTrials = 25;
    end
    E.catchTrialProb = 0.0;
    
    [ts, sds, Ss, dirtylog, HW] = RunHessSet(...
        1, 1, 2, sizeArgs, labels, M, E, HW, ts, sds, Ss, dirtylog);
    [ts, sds, Ss, dirtylog, HW] = RunHessSet(...
        2, 2, 1, sizeArgs, labels, M, E, HW, ts, sds, Ss, dirtylog);
    M.tStart = ts(2);
    [ts, sds, Ss, dirtylog, HW] = RunHessSet(...
        3, 2, 1, sizeArgs, labels, M, E, HW, ts, sds, Ss, dirtylog);
    M.tStart = ts(1);
    [ts, sds, Ss, dirtylog, HW] = RunHessSet(...
        4, 1, 2, sizeArgs, labels, M, E, HW, ts, sds, Ss, dirtylog);
    
    % ts contains log10(contrast ratio), and log of ratio = difference of logs
    ioc = mean(ts([1,4])) - mean(ts([2,3]));
    
    %re-enable x-axis marks on bottom plots
    subplot(sizeArgs{:}, sizeArgs{1}*sizeArgs{2});
    set(gca,'xtickMode','auto');
    
    %save staircases figure
    hgsave('staircases.fig');
    
    hold off;
    
    % FIXME fix GraphResults and finish!
    %GraphResults(ts, sds, trialName, labels, ^FIX(noiseContrasts)^);
    %hgsave('thresholds.fig');
    
    save('Ss.mat', 'Ss');
    fileattrib('Ss.mat', '-w'); %readonly
    save('ts.mat', 'ts');
    fileattrib('ts.mat', '-w'); %readonly
    save('sds.mat', 'sds');
    fileattrib('sds.mat', '-w'); %readonly
    save('ioc.mat', 'ioc');
    fileattrib('ioc.mat', '-w'); %readonly
    save('labels.mat', 'labels');
    fileattrib('labels.mat', '-w'); %readonly
    
    save('dirtylog.mat', 'dirtylog', '-ascii', '-tabs');
    fileattrib('dirtylog.mat', '-w'); %readonly
    
    labels = {'left signal', 'right signal', ...
        'left noise', 'right noise', 'correct'};
    dirtycelllog = [labels; num2cell(dirtylog)];
    xlsStatus = xlswrite('dirtylog.xls', dirtycelllog);
    if xlsStatus
        fileattrib('dirtylog.xls', '-w'); %readonly
    end
    
    % write dirtylog as csv as well
    fid = fopen('dirtylog.csv', 'a');
    % labels (strings)
    for j=1:size(dirtycelllog, 2)
        fprintf(fid, '%s,', dirtycelllog{1,j});
    end
    fprintf(fid, '\n');
    % data (floats)
    for i=2:size(dirtycelllog, 1)
        for j=1:size(dirtycelllog, 2)
            fprintf(fid, '%f,', dirtycelllog{i,j});
        end
    fprintf(fid, '\n');
    end
    fclose(fid);
    fileattrib('dirtylog.csv', '-w'); %readonly
    
    commitDataLog(folder, dataFolder, subfolder);
end

function [HW, HessIOC, DingIOC] = findIOCs(HW, trialName, label, isTesting, AE)
    % Add a key for method-of-adjustment tasks
    HW.stopKey = 'return';
    normalValidKeys = HW.validKeys;
    dingValidKeys = [HW.validKeys {HW.stopKey}];
    
    HessIOC = -Inf;
    DingIOC = Inf;
    maxDiff = 1e10; %log10(1.5); % TODO parameterize
    
    % To skip IOC measurements, just for testing:
    %{
    if isTesting
        HessIOC = -0.8;
        DingIOC = -0.7;
    end
    %}
    
    while abs(HessIOC - DingIOC) > maxDiff
        HessIOCname = [trialName ' - HessIOC' label];
        [HessIOC, ~, ~, ~, HW] = RunHessIOC(HessIOCname, HW, isTesting);

        DingIOCname = [trialName ' - DingIOC' label];
        HW.validKeys = dingValidKeys;
        [DingIOCs, HW] = FindContrastTradeoffAdjustmentIvan(DingIOCname, HW, AE);
        HW.validKeys = normalValidKeys;
        DingIOC = mean(DingIOCs);

%         if isTesting
%             DingIOC = max(min(DingIOC, HessIOC + maxDiff), HessIOC - maxDiff);
%         end
        if isTesting
            HessIOC = 0.0;
            DingIOC = 0.1;
        end
    end
end

function [ts, sds, Ss, dirtylog, HW] = RunHessSet(...
            setIndex, sigEye, noiseEye,...
            spargs, labels, M, E, HW,...
            ts, sds, Ss, dirtylog)
    % Pick out which eyes should have signal and noise dots
    contrasts = -inf(2);
    % actual numbers don't matter because staircase will override them
    % here, NaN just means "use this eye", -Inf means "don't use"
    contrasts(1,sigEye) = NaN;
    contrasts(2,noiseEye) = NaN;
    E.P.contrasts = contrasts;
    
    % Initialize staircase plot area
    axesh = subplot(spargs{:}, setIndex);
    title(axesh, labels{setIndex}, 'FontSize', 6);
    
    [t, sd, S, HW] = FindThreshold(M, E, HW, axesh);
    
    ts(setIndex,1) = t;
    sds(setIndex,1) = sd;
    Ss{setIndex,1} = S;
    
    % remove x axis labels so there's more room for the graphs
    set(axesh,'xtick',[]);
    
    filename = sprintf('S %s.mat', labels{setIndex});
    save(filename, 'S');
    fileattrib(filename, '-w'); %readonly

    dirtylog = [dirtylog; DirtyRecord(contrasts, S, E)];
end

function dirtylog = DirtyRecord(columns, S, E)
    % make parameters a vector, going row-wise
    if ndims(columns) > 1
        columns = reshape(columns',[],1)';
    end
    
    % FIXME rough, adapted from ContrastTradeoffStaircaseHelpers
    totalContrast = (1.0 / E.bgLumnce) - 1.0;
    sigShare = 10.^S.trialVals;
    contrastShares = [sigShare ones(size(sigShare))] ...
                    ./ repmat(sigShare + 1.0, 1, 2);
    contrasts = totalContrast .* contrastShares;
    vals = log10(contrasts);
    
    data = ones(length(S.trialVals), length(columns));
    
    for i=find(~isnan(columns))
        data(:, i) = columns(i);
    end
    
    data(:, isnan(columns)) = vals;
    corrects = cat(1, S.trialLog{:,2});
    dirtylog = [data, corrects];
end

function [HW, endDisparity] = runTraining(iocToUse, HW, M, E)
    bgLum = mean(E.P.background) / 255.0;
    if bgLum > 0.5/255
        totalContrast = (1.0 / bgLum) - 1.0;
        leftShare = 10.^iocToUse;
        rightShare = 1.0;
        totalShares = leftShare + 1.0;
        contrastShares = [leftShare rightShare] ./ totalShares;
        contrasts = contrastShares * totalContrast;
        luminances = 255 * bgLum .* (contrasts + 1.0);
    else
        % Very low background luminance
        % Similar to above code at the limit as bgColor approaches 0
        if iocToUse > 0
            luminances = 255 .* [1.0 10.^(-iocToUse)];
        else
            luminances = 255 .* [10.^iocToUse 1.0];
        end
    end
    
    fprintf('Luminances: %f, %f\n', luminances(1), luminances(2));

    E.P.leftLuminance = luminances(1);
    E.P.rightLuminance = luminances(2);

    [endDisparity, sd, S, HW] = SARTrainingStaircase(M, E, HW); %#ok<ASGLU>

    save('S.mat', 'S');
    fileattrib('S.mat', '-w'); %readonly
    save('endDisparity.mat', 'endDisparity');
    fileattrib('endDisparity.mat', '-w'); %readonly
    save('sd.mat', 'sd');
    fileattrib('sd.mat', '-w'); %readonly
end
