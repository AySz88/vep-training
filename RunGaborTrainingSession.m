% RunGaborTrainingSession.m
%
% Run one session of the Gabor training procedure. It should last about
% 40-45 minutes. Training sequences (fields of gabor patches) are shown updated
% 30 times per second, in alternation with test trials during which the observer
% uses keypad to indicate where on the screen the special stimulus is.
%
% Ben and Alex 2014-07-22
subjectCode = '';
while isempty(subjectCode)
    subjectCode = input('Please enter Subject code (e.g. NBAB06062014): ', 's');
end
% ambEyeString = input('Which eye is amblyopic? Enter r, l, or n: ', 's');

Measure interocular contrast (IOC) using RDK and Ding, and Stereoacuity
mainFolder = pwd;
cd('IOCMeasures');
[log10IOC, ~] = ShortTrainStereoacuity(sprintf('%s pre-Gabor', subjectCode));
IOC = 10^log10IOC;
cd(mainFolder);

% IOC = 1;

%% Choose IOC to use in experiment
fprintf('Measured IOC is (left/right) %.2f\n', IOC);
if IOC > 1
    contrastsDefault = [1, 1/IOC];
else
    contrastsDefault = [IOC, 1];
end
fprintf('Contrasts for gabor training would be: LE %.2f | RE %.2f\n', contrastsDefault(1), contrastsDefault(2));
if any(contrastsDefault < 0.1)
    contrastsDefault = max(0.1, contrastsDefault);
    fprintf('One contrast was too small - changing to: LE %.2f | RE %.2f\n', contrastsDefault(1), contrastsDefault(2));
end
contrasts = [];
contrastsValid = false;
while ~contrastsValid
    iocChoice = input('Use these values? (y/n) ', 's');
    switch lower(iocChoice)
        case {'y', 'yes'}
            contrasts = contrastsDefault;
        case {'n', 'no'}
            try
                fprintf('NOTE: One eye''s contrast must be exactly 1.0:\n');
                contrasts(1) = input('Left eye contrast (0.1 to 1): ');
                contrasts(2) = input('Right eye contrast (0.1 to 1): ');
            catch e
                contrasts = [];
                fprintf('Error - trying again...\n');
            end
        otherwise
            fprintf('Huh? Try y or n.\n');
    end
    contrastsValid = ~(isempty(contrasts) || ~isnumeric(contrasts) || any(contrasts<0.1) || any(contrasts>1)) && sum(contrasts==1)>0;
    if ~contrastsValid
        fprintf('Error - trying again...\n');
    end
end

% ambEyeString = upper(ambEyeString);
% switch ambEyeString
%     case {'L', 'LEFT'}
%         contrasts = [1.0 0.25];
%     case {'R', 'RIGHT'}
%         contrasts = [0.25 1.0];
%     case {'N', 'NORM', 'NORMAL'}
%         contrasts = [1.0 1.0];
% end

%% Initializations
experimentDurMin = 40;  % How long training should last
nRest = 3;              % Number of rests during the experiment (between blocks)
restDuration = 30;      % Number of seconds per resting period
trainDurRange = [1 5];  % Range of randomly chosen training durations (uniformly distributed)
testDurationInit = 1.5;
testDurationFactorDown = 0.9;                            % When correct
testDurationFactorUp = testDurationFactorDown^(-3.1);    % When wrong

HW = HardwareParameters();
[didHWInit, HW] = InitializeHardware(HW);   % This seeds the rng too!
[HW, gaborTexture, gaborTextureInv] = GenerateGaborTexture(HW);
ListenChar(0);
KbQueueCreate();

%% Open the data file
trialNumber = 1;
blockNumber = 1;
if exist('trialRecords', 'var')
    clear('trialRecords');
end

dataColumns = {'trialNum', 'eyeCond', 'testDuration', 'correct', 'correctKey', 'response', 'reactionTime', 'orientedZone', 'orientedTheta', 'prevTrainDuration'};
data = DataFile(DataFile.defaultPath(subjectCode), dataColumns);

%% Start the code loop
nBlock = nRest+1;
blockDurSec = 60*experimentDurMin/nBlock;    % Duration of blocks between breaks 
testDuration = testDurationInit * ones(1,3); % left, right, both
startTime = GetSecs();

nextRestTime = startTime + blockDurSec;
% while GetSecs() < startTime + 60*experimentDurMin     % Keep showing training and test stimuli until end of experiment 
while blockNumber < nBlock + 1     % Keep showing training and test stimuli until end of experiment 
    
    % Show a training stimulus
    trainDuration = rand * diff(trainDurRange) + trainDurRange(1); 
    HW = ShowTraining(HW, trainDuration, contrasts, gaborTexture, gaborTextureInv);
    
    % Show a test stimulus
    eyeCond = randi(3);
    KbQueueFlush();
    KbQueueStart();
    trialShowTime = GetSecs();
	[HW, testRecord] = ShowTest(HW, testDuration(eyeCond), contrasts, eyeCond, gaborTexture, gaborTextureInv);
    testRecord.prevTrainDuration = trainDuration;
    testRecord.duration = testDuration(eyeCond);
    
    % Collect response
    HW = ShowTraining(HW, 0.5, contrasts, gaborTexture, gaborTextureInv);  % Give the subject 500 ms after end of test stim to respond
    KbQueueStop();
    [pressed, firstPress, ~,~,~] = KbQueueCheck();
    correct = sum(firstPress > 0) == 1 && strcmp(KbName(firstPress), testRecord.correctKey);
    unscheduledBreakFlag = strcmp(KbName(firstPress), '5');
    earlyQuitFlag = strcmp(KbName(firstPress), 'x');
    
    testRecord.eyeCond = eyeCond;
    testRecord.response = KbName(firstPress);
    testRecord.correct = correct;
    if sum(firstPress>0) == 1
        pressTime = firstPress(firstPress>0);
        testRecord.reactionTime = pressTime - trialShowTime;
    else
        testRecord.reactionTime = -1;
    end
    
    trialRecords(trialNumber) = testRecord;
    if isempty(testRecord.response)
        datafileResponse = 0;
    else
        try
            datafileResponse = str2num(KbName(firstPress)); % if multiple keys pressed, will throw error and go to catch block
            if isempty(datafileResponse)
                datafileResponse = -1;
            end
        catch e
            datafileResponse = -1;
        end
    end
    data.append([trialNumber, eyeCond, testDuration(eyeCond), correct, str2num(testRecord.correctKey), datafileResponse, testRecord.reactionTime, testRecord.orientedZone, testRecord.orientedTheta, trainDuration]);
    
    if correct
        testDuration(eyeCond) = testDuration(eyeCond) * testDurationFactorDown;
        PsychPortAudio('Start', HW.rightSoundHandle);
    else
        testDuration(eyeCond) = testDuration(eyeCond) * testDurationFactorUp;
        PsychPortAudio('Start', HW.failSoundHandle);
    end
    
    trialNumber = trialNumber + 1;
    
    if GetSecs() > nextRestTime
        if blockNumber < (nRest+1)
            HW = Breaktime(HW, restDuration, @(t) sprintf('Done with block %i of %i. Please take a %i second break!', blockNumber, nRest+1, t), [], 5);
            nextRestTime = GetSecs() + blockDurSec;
        end
        blockNumber = blockNumber + 1;
    end
    
    if unscheduledBreakFlag
        startBreakTime = GetSecs();
        HW = Breaktime(HW, 0, [], 'Press 5 key to resume...');
        endBreakTime = GetSecs();
        nextRestTime = nextRestTime + (endBreakTime - startBreakTime);
    end
    
    if earlyQuitFlag
        break;
    end
    
    fprintf('LE %.2f | RE %.2f | Both %.2f\n', testDuration(1), testDuration(2), testDuration(3))
    
end

if ~earlyQuitFlag
    HW = Breaktime(HW, 0, [], 'Thank you!');
end

%% Close the data file
delete(data);

%% Terminations

if didHWInit
    HW = CleanupHardware(HW);
end
