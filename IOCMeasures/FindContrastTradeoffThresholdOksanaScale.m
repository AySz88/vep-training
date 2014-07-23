function [ ts, sds, Ss ] = FindContrastTradeoffThresholdOksanaScale( trialName )
%FINDCONTRASTTRADEOFFTHRESHOLDOKSANASCALE TODO Summary of this function
%   Detailed explanation goes here
%
%   trialName	: Identifier for this set of trials, i.e. to be used in
%                 graphs and folder names
    
    % Make sure there aren't data files still in this folder
    % TODO write data to a temporary data folder and check for files there
    
    psychassert(isempty(dir('*.mat')), ...
        'FindContrastTOThresholdOksana:MATFilesInFolder', ...
        ['Found .mat files in the current working directory! Please' ...
        ' move or remove files from previous experiments!']);
    
    % Start logging input/output, don't stop until successful experiment
    diary('diary.log');
    fprintf('\nStarting experiment...\n');
    
    % Parse arguments
    if nargin == 0
        trialName = input('Identifier for this set of trials: ', 's');
    end
    
    %{
    lightState = [];
    while isempty(lightState)
        lightInput = input('Are the room lights ON? ', 's');
        switch lower(lightInput)
            case {'on', 'y', 'yes'}
                lightState = true;
            case {'off', 'n', 'no'}
                lightState = false;
            otherwise
                fprintf('Huh?  Try ''on'' or ''off'', or y/n.  ');
        end
    end
    if lightState
        lightText = 'on';
    else
        lightText = 'off';
    end
    
    trialName = [trialName ' (lights ' lightText ')'];
    %}
    
    % parse folder name
    psychassert(ischar(trialName), ...
        'FindContrastTOThresholdOksana:badParameter', ...
        'Identifier must be a string!');
    
    dataFolder = 'data\'; %TODO parameterize
    curdate = datestr(now);
    curdate(curdate == ':') = '-'; % ':' not allowed in folder names
    if isempty(trialName)
        subfolder = curdate;
    else
        subfolder = [curdate ' ' trialName];
    end
    folder = [dataFolder subfolder];
    
    labels =  {'Signal left, noise same', ...
        'Signal left, noise different', ...
        'Signal right, noise same', ...
        'Signal right, noise different', ...
        'Signal right, noise different (2nd time)', ...
        'Signal right, noise same (2nd time)', ...
        'Signal left, noise different (2nd time)', ...
        'Signal left, noise same (2nd time)'};
    
    % Read parameter files
    [M, E, HW] = Parameters();
    M = StatModelContrastTradeoff(M);
    [E.prepParams, E.update] = ContrastTradeoffStaircaseHelpers();
    
    % Special parameter tweaks for this experiment
    E.maxTrials = 60;
    E.catchTrialProb = 0.0;
    
    % FIXME parameterize as an argument into this function?
    % Independent variables for this experiment
    variables = struct(...
        ...%'sigDots', num2cell([25, 18, 36]) ...
        'scaleFactor', {1.0, 1/sqrt(2.0), sqrt(2.0)} ...
        );
    
    % Initialize accumulators
    sizeArgs = {8, length(variables)};
    Ss = cell(sizeArgs{:});
    ts = zeros(sizeArgs{:});
    sds = zeros(sizeArgs{:});
    
    dirtylog = [];
    
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
        [ts, sds, Ss, dirtylog] = RunSet(...
            variables, setIndex, sigEye, noiseEye, ...
            sizeArgs, labels, M, E, HW, ...
            ts, sds, Ss, dirtylog, false);
        HW = Breaktime(HW, 15);
        
        % Signal left, noise right
        setIndex = 2;
        sigEye = 1;
        noiseEye = 2;
        [ts, sds, Ss, dirtylog] = RunSet(...
            variables, setIndex, sigEye, noiseEye, ...
            sizeArgs, labels, M, E, HW, ...
            ts, sds, Ss, dirtylog, false);
        HW = Breaktime(HW, 15);
        
        % Signal right, noise right
        setIndex = 3;
        sigEye = 2;
        noiseEye = 2;
        [ts, sds, Ss, dirtylog] = RunSet(...
            variables, setIndex, sigEye, noiseEye, ...
            sizeArgs, labels, M, E, HW, ...
            ts, sds, Ss, dirtylog, false);
        HW = Breaktime(HW, 15);
        
        % Signal right, noise left
        setIndex = 4;
        sigEye = 2;
        noiseEye = 1;
        [ts, sds, Ss, dirtylog] = RunSet(...
            variables, setIndex, sigEye, noiseEye, ...
            sizeArgs, labels, M, E, HW, ...
            ts, sds, Ss, dirtylog, false);
        % 120s break, interruptible after 30
        HW = Breaktime(HW, 120, [], [], 30);
        
        % Signal right, noise left (second time)
        setIndex = 5;
        sigEye = 2;
        noiseEye = 1;
        [ts, sds, Ss, dirtylog] = RunSet(...
            variables, setIndex, sigEye, noiseEye, ...
            sizeArgs, labels, M, E, HW, ...
            ts, sds, Ss, dirtylog, true);
        HW = Breaktime(HW, 15);
        
        % Signal right, noise right (second time)
        setIndex = 6;
        sigEye = 2;
        noiseEye = 2;
        [ts, sds, Ss, dirtylog] = RunSet(...
            variables, setIndex, sigEye, noiseEye, ...
            sizeArgs, labels, M, E, HW, ...
            ts, sds, Ss, dirtylog, true);
        HW = Breaktime(HW, 15);
        
        % Signal left, noise right (second time)
        setIndex = 7;
        sigEye = 1;
        noiseEye = 2;
        [ts, sds, Ss, dirtylog] = RunSet(...
            variables, setIndex, sigEye, noiseEye, ...
            sizeArgs, labels, M, E, HW, ...
            ts, sds, Ss, dirtylog, true);
        HW = Breaktime(HW, 15);
        
        % Signal left, noise left (second time)
        setIndex = 8;
        sigEye = 1;
        noiseEye = 1;
        [ts, sds, Ss, dirtylog] = RunSet(...
            variables, setIndex, sigEye, noiseEye, ...
            sizeArgs, labels, M, E, HW, ...
            ts, sds, Ss, dirtylog, true);
        %re-enable x-axis marks on bottom plots
        for iHorizPlot=1:length(variables)
            subplot(sizeArgs{:}, sizeArgs{1}*sizeArgs{2}-iHorizPlot+1);
            set(gca,'xtickMode','auto');
        end
        
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
        HW = CleanupHardware(HW); %#ok<NASGU>
    end
    if ~isempty(caughtException)
        rethrow(caughtException);
    end
end

function [ts, sds, Ss, dirtylog] = RunSet(...
            variables, setIndex, sigEye, noiseEye,...
            spargs, labels, M, E, HW, ...
            ts, sds, Ss, dirtylog, reverse)
    %TODO FIXME need to return HW as well
    if exist('reverse', 'var') && reverse
        varIdxSet = length(variables):-1:1;
    else
        varIdxSet = 1:length(variables);
    end
    
    for iVar=varIdxSet
        currentVars = variables(iVar);
        % Copy the relevant parameters into E.P
        for variedField = fieldnames(currentVars)'
            assert(isfield(E.P, variedField), ...
                'RunSet:noSuchField',...
                ['Independent variable ' variedField ' doesn''t exist!']);
            E.P.(variedField{:}) = currentVars.(variedField{:});
        end
        
        % Pick out which eyes should have signal and noise dots
        contrasts = -inf(2);
        % actual numbers don't matter because staircase will override them
        % here, NaN just means "use this eye", -Inf means "don't use"
        contrasts(1,sigEye) = NaN;
        contrasts(2,noiseEye) = NaN;
        E.P.contrasts = contrasts;
        
        % Create a name for this set of experiments
        varValues = struct2cell(currentVars); %#ok<NASGU>
        varValueText = evalc('disp(varValues)');
        % get rid of extra whitespace
        varValueText = strtrim(regexprep(varValueText, '\s*', ' '));
        staircaseText = [labels{setIndex} ' ' varValueText];
        
        % Initialize staircase plot area
        axesh = subplot(spargs{:}, ...
            (setIndex-1)*length(variables)+iVar);
        title(axesh, staircaseText, 'FontSize', 6);
        
        [t, sd, S, HW] = FindThreshold(M, E, HW, axesh);

        ts(setIndex,iVar) = t;
        sds(setIndex,iVar) = sd;
        Ss{setIndex,iVar} = S;
        
        % remove x axis labels so there's more room for the graphs
        set(axesh,'xtick',[]);
        
        filename = sprintf('S %s.mat', staircaseText);
        save(filename, 'S');
        fileattrib(filename, '-w'); %readonly

        dirtylog = [dirtylog; DirtyRecord(contrasts, S, E)];
    end
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
