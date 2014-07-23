function [ success ] = ConvertToFlatFileSummer2012( inFolder, outFile, ...
    testFlag)
%CONVERTTOFLATFILESUMMER2012 Converts Summer 2012 data folder to flat file
%   ...and
% inFolder: The folder(s) to process, relative to current working dir.
%   Takes wildcards (*).  Will check for a missing "data\". Accepts partial
%   folder names.
%       Examples:
%           '..\..\data\repository\*Jul-2012*'
% outFile: The output file.  If processing one folder, this is relative to
%   the present working directory.  If processing multiple folders, this is
%   relative to each folder that is processed.  Iff this file name contains
%   'test', the testFlag parameter defaults to true.
% testFlag: If this is 'yes' or true, will only print the input and output
%   directory and file names, instead of actually doing the conversion.
%
% This conversion tool does not yet handle experiments where there was a
%   binocular stimulus.
% It will also ask for the type of experiment being processed, unless it is
%   obvious from the name.

STAIR_TYPE = 1;
CATCH_TYPE = 2;

%% Process parameters

if nargin < 1 || isempty(inFolder)
    inFolder = '';
end

% TODO handle case where file gets run from within the folder that should
% be converted

while exist(inFolder, 'file') ~= 7
    % maybe there are wildcards?
    % pick out the part of the path that doesn't get returned by dir()
    % in listing.name
    lastSep = find(inFolder==filesep, 1, 'last');
    if ~isempty(lastSep)
        prepend = inFolder(1:lastSep);
        lastToken = inFolder(lastSep+1:end);
    else
        prepend = '';
        lastToken = inFolder;
    end
    matchString = inFolder;
    listing = dir(matchString);
    listing = listing([listing.isdir]);
    
    % maybe it was a partial name of a folder?
    if isempty(listing)
        matchString = [prepend '*' lastToken '*']; 
        listing = dir(matchString);
        listing = listing([listing.isdir]);
    end
    
    % maybe the data is in a data subfolder?
    if isempty(listing) 
        prepend = [prepend filesep 'data' filesep]; %#ok<AGROW>
        matchString = [prepend '*' lastToken '*'];
        listing = dir(matchString);
        listing = listing([listing.isdir]);
    end
    
    fprintf('Directories matching ''%s'': %i\n', ...
        matchString, length(listing));
    
    if isempty(listing)
        inFolder = input(['Couldn''t find folder ''' inFolder '''! ' ...
            'Which folder should I convert? ']);
    elseif length(listing) == 1
        newFolder = [prepend listing.name];
        fprintf('Couldn''t find folder ''%s'', so using ''%s''.\n', ...
            inFolder, newFolder);
        inFolder = newFolder;
    else
        prompt = sprintf(['There are %i folders that match!' ...
            ' Convert them all? (yes/no): '], length(listing));
        done = false;
        while ~done
            doMultiple = input(prompt, 's');
            
            switch lower(doMultiple)
                case {'y', 'yes'}
                    success = true;
                    for nameIndex = 1:length(listing)
                        newName = [prepend listing(nameIndex).name];
                        
                        if nargin < 2
                            curSuccess = ...
                                ConvertToFlatFileSummer2012(newName);
                        else
                            newOut = [newName filesep outFile];
                            if nargin < 3
                                curSuccess = ...
                                    ConvertToFlatFileSummer2012(newName,...
                                        newOut);
                            else
                                curSuccess = ...
                                    ConvertToFlatFileSummer2012(newName,...
                                        newOut, testFlag);
                            end
                        end
                        
                        if curSuccess
                            fprintf('Succeeded converting ..%s...\n', ...
                                newName);
                        else
                            fprintf(...
                                '** Failed converting ''%s''!! **\n', ...
                                newName);
                        end
                        success = success && curSuccess;
                    end
                    done = true;
                case {'n', 'no'}
                    done = true;
                    success = false;
                otherwise
                    fprintf('Huh? Try ''yes'' or ''no''.  ');
            end
        end
        return; % skip rest of function
    end
end

if nargin < 2 || isempty(outFile)
    outFile = [inFolder filesep 'flatfile.csv'];
end

if nargin < 3
    testFlag = false;
    if ~isempty(strfind(outFile, 'test'))
        fprintf(['Detected ''test'' in the output file name - assuming'...
            ' that you don''t actually want output...' ...
            ' (pass ''noTest'' as the third argument to override)\n']);
        testFlag = true;
    end
end

if ischar(testFlag)
    switch lower(testFlag)
        case {'y', 'yes', 'test'}
            testFlag = true;
        case {'n', 'no', 'notest'}
            testFlag = false;
        otherwise
            testFlag = true;
    end
end

% TODO if output file already exists, overwrite it?
%{
if exist(outFile, 'file') == 2
    outFileResponse =
end
%}

if testFlag
    fprintf('%s ---> %s\t', inFolder, outFile);
    success = true;
    return
end

%% Determine experiment type
name = inFolder;
expType = [];

typeSignatures = { ...
    '(^| )L\S*ABBA', ...
    '(^| )[OI]\S*ABBA', ...
    '(^| )L\S*(IOC|ECC)', ...
    '(^| )O\S*PctCoh.*', ...
    '(^| )O\S*Scale.*', ...
    '(^| )O\S*Lum.*', ... % FIXME are these right?
    '(^| )O\S*Lights', ... % FIXME
    '(^| )I\S*(IOC|r\d)'};

while isempty(expType)
    matches = zeros(1, length(typeSignatures));

    for matchIndex = 1:length(typeSignatures)
        signatureLine = typeSignatures{matchIndex};
        if iscell(signatureLine)
            % Match against any of the possibilities...
            match = false;
            for specificSig = signatureLine
                match = match ...
                    || ~isempty(regexpi(name, specificSig, 'once'));
            end
        else
            match = ~isempty(regexpi(name, signatureLine, 'once'));
        end
        matches(matchIndex) = match;
    end

    if sum(matches) ~= 1
        fprintf(['Which type of experiment is ''%s''?'...
            ' Ex: ''L_ABBA'', ''O_PctCoh''.\n'], inFolder);
        name = input('(type ''skip'' to skip.)  ','s');
        
        if strcmpi(name, 'skip')
            success = false;
            fprintf('Skipped ''%s''!\n', inFolder);
            return;
        end
        
    else
        expType = find(matches, 1);
    end
end

%% Prepare input and output files

SsFilePath = [inFolder filesep 'Ss.mat'];
if exist(SsFilePath, 'file') ~= 2
    if nargout >= 1
        fprintf('Couldn''t find %s!\n', SsFilePath);
        success = false;
        return;
    else
        assert(false, 'ConvertFFS2012:BadFolder', ...
            'Didn''t find ''%s''!', SsFilePath);
    end
end

fprintf('Reading data from ''%s''...', SsFilePath);
Ss = importdata(SsFilePath);
fprintf('done!\n');

outHandle = fopen(outFile, 'wt');
WriteHeader(outHandle);

%% Process S (staircase) structures
caughtException = [];
try
    [sRows, sColumns] = size(Ss);

    grandTrialNum = 1;
    staircaseNum = 1;

    for idxRow = 1:sRows
        if idxRow <= sRows/2
            cols = 1:sColumns;
        else
            % horizontally reversed order in latter half
            cols = sColumns:-1:1;
        end

        for idxCol = cols
            S = Ss{idxRow, idxCol};

            catchTrialNum = 1;

            catches = S.catchResponses;

            for stairTrialNum = 1:length(S.trialLog)
                logRow = S.trialLog(stairTrialNum,:);

                P = logRow{1};
                correct = logRow{2};

                % Process catch trials that happened first
                if ~isempty(catches)
                    catTrialIdxs = find(catches(:,1)==stairTrialNum);
                else
                    catTrialIdxs = [];
                end
                if isempty(catTrialIdxs)
                    % for loop can't handle 0x1 empty matrixes of find(...)
                    catTrialIdxs = [];
                end
                for catTrialIdx = catTrialIdxs
                    catTrial = catches(catTrialIdx, :);
                    staircaseTrialIdx = stairTrialNum + catchTrialNum - 1;

                    catCorrect = catTrial(2);

                    WriteLine(outHandle, ...
                        expType, grandTrialNum, ...
                        staircaseNum, staircaseTrialIdx, ...
                        CATCH_TYPE, catchTrialNum, ...
                        P.contrasts, P.sigDots/P.nDots, '', catCorrect, ...
                        P.scaleFactor, P.fixPosDegR, P.fixPosDegT, 0);

                    catchTrialNum = catchTrialNum + 1;
                    grandTrialNum = grandTrialNum + 1;
                end

                staircaseTrialIdx = stairTrialNum + catchTrialNum - 1;

                WriteLine(outHandle, ...
                    expType, grandTrialNum, ...
                    staircaseNum, staircaseTrialIdx, ...
                    STAIR_TYPE, stairTrialNum, ...
                    P.contrasts, P.sigDots/P.nDots, P.dir, correct, ...
                    P.scaleFactor, P.fixPosDegR, P.fixPosDegT, 0);

                grandTrialNum = grandTrialNum + 1;
            end
            staircaseNum = staircaseNum + 1;
        end
    end
catch e
    caughtException = e;
end

success = isempty(caughtException);
fclose(outHandle);

if nargout < 1 && ~isempty(caughtException)
    rethrow(caughtException);
end

end

function [] = WriteHeader(fileHandle)
    fprintf(fileHandle, [...
        'Experiment Type,'...
        'Experiment Trial Index,'...
        'Staircase Number,'...
        'Staircase Trial Index,'...
        'Trial Type,'...
        'Trial Number in Staircase of This Type,'...
        'Eye Condition,'...
        'log10(Signal Contrast/Noise Contrast),'...
        'log10(Signal Contrast),'...
        'log10(Noise Contrast),'...
        'Fraction Coherence,'...
        'Signal Direction,'...
        'Correct Flag,'...
        'ScaleFactor,'...
        'Fixation Position Radius (deg),'...
        'Fixation Position Theta (deg),'...
        'Filter condition'...
        '\n']);
end

function [] = WriteLine(fileHandle, ...
    expType, grandNo, stairNo, trialNo, trialType, trialNoOfType, ...
    contrasts, pctCoherence, sigDotDir, correct, ...
    scaleFactor, fixPosDegR, fixPosDegT, filterCond)
    %% Convert some parameters to numerical values
    if sum(contrasts(1,:)==-Inf) ~= 1 || sum(contrasts(2,:)==-Inf) ~= 1
        eyeCond = 5; % TODO just output 'other', for now
    else
        eyeCond = 1;
        if contrasts(1,2) ~= -Inf
            eyeCond = eyeCond + 2;
        end
        if contrasts(2,2) ~= -Inf
            eyeCond = eyeCond + 1;
        end
    end
    
    signalContrast = mean(contrasts(1,contrasts(1,:)~=-Inf));
    noiseContrast = mean(contrasts(2,contrasts(2,:)~=-Inf));
    SNR = signalContrast - noiseContrast;
    
    switch lower(sigDotDir)
        case 'up'
            dotDirOutput = 1;
        case 'down'
            dotDirOutput = 2;
        otherwise
            dotDirOutput = 0;
    end

    %% Write entry to file
    fprintf(fileHandle, ...
        ['%i,%i,%i,%i,%i,%i'...
        ',%i,%f,%f,%f'...
        ',%f,%i,%i'...
        ',%f,%f,%f,%i\n'], ...
        expType, grandNo, stairNo, trialNo, trialType, trialNoOfType, ...
        eyeCond, SNR, signalContrast, noiseContrast, ...
        pctCoherence, dotDirOutput, correct, ...
        scaleFactor, fixPosDegR, fixPosDegT, filterCond);
end
