function [ ts, sds, Ss ] = FindContrastThreshold( trialName, signalSide )
%FINDCONTRASTTHRESHOLD TODO Summary of this function goes here
%   Detailed explanation goes here
%
%   trialName	: Identifier for this set of trials, i.e. to be used in
%                 graphs and folder names
%   signalSide	: Which eye to have signal dots, 'l'/'left' or 'r'/'right'
%
%   To test, run: [ts sds Ss] = FindContrastThreshold();
%
% Plotting staircase:
%   plot(S.trialVals)
% Plotting psychometric function result:
% QuestCreate(S.q.t, S.q.sd, M.pThreshold, ...
%   BETA FROM FIT, M.delta, M.gamma, M.grain, M.range)
% plot(10.^(S.q.x2+S.q.tGuess), S.q.p2)
% axis([0,0.3, .5, 1])
%
% QuestBetaAnalysis(q, file handle)
%
% TODO make more like FindContrastThresholdAmb
    
    % Make sure there aren't data files still in this folder
    % TODO write data to a temporary data folder and check for files there
    psychassert(isempty(dir('*.mat')), ...
        'FindContrastThreshold:MATFilesInFolder', ...
        ['Found .mat files in the current working directory! Please' ...
        ' move or remove files from previous experiments!']);
    
    % Start logging input/output, don't stop until successful experiment
    diary('diary.log');
    fprintf('\nStarting experiment...\n');
    
    % Parse arguments
    if nargin == 0
        trialName = input('Identifier for this set of trials: ', 's');
        signalSide = input('Signal dots in (l)eft or (r)ight eye? ', 's');
    else
        psychassert(nargin >= 2, ...
            'FindContrastThreshold:missingParameter', ...
            'Not enough arguments!  Need trialName and signalSide');
    end
    
    % parse folder name
    psychassert(ischar(trialName), ...
        'FindContrastThreshold:badParameter', ...
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
    
    % parse which eye has signal dots
    psychassert(ischar(signalSide), ...
        'FindContrastThreshold:badParameter', ...
        'Signal side must be a string!');
    
    sigEyeMatcher = {'left', 'right'};
    sigEyeAbbrev = {'l', 'r'};
    sigEye = find(strcmpi(signalSide, sigEyeMatcher) ...
                | strcmpi(signalSide, sigEyeAbbrev));
    psychassert(~isempty(sigEye), 'FindContrastThreshold:badParameter', ...
        'Signal side must be ''left'', ''l'', ''right'', or ''r''!');
    
    signalSide = sigEyeMatcher{sigEye}; % reset to 'canonical' string
    otherEye = mod(sigEye,2)+1;
    
    labels =  {['Signal ' signalSide ', noise same'], ...
        ['Signal ' signalSide ', noise different'], ...
        ['Signal ' signalSide ', noise different (2nd time)'], ...
        ['Signal ' signalSide ', noise same (2nd time)']};
    
    % Read parameter files
    [M, E, HW] = Parameters();
    M = StatModelContrast(M);
    [E.prepParams, E.update] = ContrastStaircaseHelpers();
    
    % FIXME parameterize
    noiseContrasts = log10(0.0:0.1:0.3);
    
    % Initialize accumulators
    Ss = cell(4,length(noiseContrasts));
    ts = zeros(4,length(noiseContrasts));
    sds = zeros(4,length(noiseContrasts));
    
    dirtylog = [];
    
    % Start experiment
    [didHWInit HW] = InitializeHardware(HW);
    caughtException = [];
    try
        % Prepare to draw staircases
        figure;
        spargs = {4, length(noiseContrasts)};
        subplot(spargs{:}, 1);
        
        % monocular (forward)
        for i=1:length(noiseContrasts)
            noise=noiseContrasts(i);

            contrasts = -inf(2);
            contrasts(1,sigEye) = NaN; % doesn't matter
            contrasts(2,sigEye) = noise;

            E.P.contrasts = contrasts;
            
            axesh = subplot(spargs{:}, (1-1)*length(noiseContrasts)+i);
            [t, sd, S, HW] = FindThreshold(M, E, HW, axesh);

            ts(1,i) = t;
            sds(1,i) = sd;
            Ss{1,i} = S;

            plot(S.trialVals);
            filename = sprintf(['S ' labels{1} ' %.1f.mat'], 10^noise);
            save(filename, 'S');
            fileattrib(filename, '-w'); %readonly

            dirtylog = [dirtylog; DirtyRecord(contrasts, S)];
        end

        HW = Breaktime(HW, 30);

        %dichoptic (forward)
        for i=1:length(noiseContrasts)
            noise=noiseContrasts(i);

            contrasts = -inf(2);
            contrasts(1,sigEye) = NaN; % doesn't matter, to be replaced
            contrasts(2,otherEye) = noise;

            E.P.contrasts = contrasts;
            
            axesh = subplot(spargs{:}, (2-1)*length(noiseContrasts)+i);
            [t, sd, S, HW] = FindThreshold(M, E, HW, axesh);

            ts(2,i) = t;
            sds(2,i) = sd;
            Ss{2,i} = S;

            plot(S.trialVals);
            filename = sprintf(['S ' labels{2} ' %.1f.mat'], 10^noise);
            save(filename, 'S');
            fileattrib(filename, '-w'); %readonly

            dirtylog = [dirtylog; DirtyRecord(contrasts, S)];
        end

        % 120s break, interruptible after 30
        HW = Breaktime(HW, 120, [], [], 30);

        %dichoptic (reverse)
        for i=length(noiseContrasts):-1:1
            noise=noiseContrasts(i);

            contrasts = -inf(2);
            contrasts(1,sigEye) = NaN; % doesn't matter
            contrasts(2,otherEye) = noise;

            E.P.contrasts = contrasts;
            
            axesh = subplot(spargs{:}, (3-1)*length(noiseContrasts)+i);
            [t, sd, S, HW] = FindThreshold(M, E, HW, axesh);

            ts(3,i) = t;
            sds(3,i) = sd;
            Ss{3,i} = S;

            plot(S.trialVals);
            filename = sprintf(['S ' labels{3} ' %.1f.mat'], 10^noise);
            save(filename, 'S');
            fileattrib(filename, '-w'); %readonly

            dirtylog = [dirtylog; DirtyRecord(contrasts, S)];
        end

        HW = Breaktime(HW, 30);

        % monocular (reverse)
        for i=length(noiseContrasts):-1:1
            noise=noiseContrasts(i);

            contrasts = -inf(2);
            contrasts(1,sigEye) = NaN; % doesn't matter
            contrasts(2,sigEye) = noise;

            E.P.contrasts = contrasts;
            
            axesh = subplot(spargs{:}, (4-1)*length(noiseContrasts)+i);
            [t, sd, S, HW] = FindThreshold(M, E, HW, axesh);

            ts(4,i) = t;
            sds(4,i) = sd;
            Ss{4,i} = S;

            plot(S.trialVals);
            filename = sprintf(['S ' labels{4} ' %.1f.mat'], 10^noise);
            save(filename, 'S');
            fileattrib(filename, '-w'); %readonly

            dirtylog = [dirtylog; DirtyRecord(contrasts, S)];
        end

        %save staircases figure
        hgsave('staircases.fig');

        hold off;
        
        GraphResults(ts, sds, trialName, labels, noiseContrasts);
        hgsave('thresholds.fig');

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
        xlswrite('dirtylog.xls', dirtycelllog);
        fileattrib('dirtylog.xls', '-w'); %readonly

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
        movefile('*.fig', folder);
        movefile('*.mat', folder);
        movefile('*.xls', folder);
        movefile('*.csv', folder);
        movefile('*.log', folder);
        copyfile('*.m', folder);

        system(['hg add --cwd ' dataFolder ' --include "' subfolder '\*"']);
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

function dirtylog = DirtyRecord(columns, S)
    % make parameters a vector, going row-wise
    if ndims(columns) > 1
        columns = reshape(columns',[],1)';
    end
    
    vals = S.trialVals;
    data = ones(length(S.trialVals), length(columns));
    
    for i=find(~isnan(columns))
        data(:, i) = columns(i);
    end
    
    data(:, isnan(columns)) = vals;
    corrects = cat(1, S.trialLog{:,2});
    dirtylog = [data, corrects];
end
