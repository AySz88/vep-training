function [ ts, sds, Ss ] = FindDotThreshExperiment( trialName )
%FINDDOTTHRESHEXPERIMENT Summary of this function goes here
%   Detailed explanation goes here
%
%   trialName	: Identifier for this set of trials, i.e. to be used in
%                 graphs and folder names

    % Make sure there aren't data files still in this folder
    % TODO write data to a temporary data folder and check for files there
    
    psychassert(isempty(dir('*.mat')), ...
        'FindDotThreshExperiment:MATFilesInFolder', ...
        ['Found .mat files in the current working directory! Please' ...
        ' move or remove files from previous experiments!']);
    
    % Parse arguments
    if nargin == 0
        trialName = input('Identifier for this set of trials: ', 's');
    end
    
    % parse folder name
    psychassert(ischar(trialName), ...
        'FindDotThreshExperiment:badParameter', ...
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
    
    labels =  {'Run 1', ...
        'Run 2', ...
        'Run 3', ...
        'Run 4', ...
        'Run 5', ...
        'Run 6'};
    
    [M, E, HW] = Parameters();
    [didHWInit HW] = InitializeHardware(HW);
    
    % Initialize accumulators
    loops = 6; % TODO parameterize
    sizeArgs = {loops, 1};
    Ss = cell(sizeArgs{:});
    ts = zeros(sizeArgs{:});
    sds = zeros(sizeArgs{:});
    
    dirtylog = [];
    
    caughtException = [];
    try
        % Prepare to draw staircases
        figure;
        subplot(sizeArgs{:}, 1);
        
        for setIndex=1:loops
            axesHandle = subplot(sizeArgs{:}, setIndex);
            
            [t, sd, S, HW] = FindThreshold(M, E, HW, axesHandle);
        
            ts(setIndex,1) = t;
            sds(setIndex,1) = sd;
            Ss{setIndex,1} = S;

            % remove x axis labels so there's more room for the graphs
            set(gca,'xtick',[]);
            
            filename = ['S ' labels{setIndex} '.mat'];
            save(filename, 'S');
            fileattrib(filename, '-w'); %readonly
            
            dirtylog = [dirtylog; DirtyRecord(S)];
            
            HW = Breaktime(HW, 15);
        end
        
        %save staircases figure
        hgsave('staircases.fig');

        hold off;
        
        % TODO make a version of GraphResults for coherence thresholds
        %GraphResults(ts, sds, trialName, labels, noiseContrasts);
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

        labels = {'signalDots', 'correct'};
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

        mkdir(folder);
        movefile('*.fig', folder);
        movefile('*.mat', folder);
        movefile('*.xls', folder);
        movefile('*.csv', folder);
        copyfile('*.m', folder);

%         system(...
%             ['hg add --cwd ' dataFolder ' --include "' subfolder '\*"']);
%         message = sprintf('"Automatic commit of new data: %s"', folder);
%         system(['hg commit --cwd ' dataFolder ' -u MATLAB -m ' message]);
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

function dirtylog = DirtyRecord(S)
    corrects = cat(1, S.trialLog{:,2});
    dirtylog = [S.trialVals, corrects];
end
