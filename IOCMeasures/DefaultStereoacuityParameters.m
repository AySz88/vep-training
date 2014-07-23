function E = DefaultStereoacuityParameters()
% Stimulus parameters (P structure) fields
% *From E*
% borderWidth
% borderColor
% balanceJitterFlag
% rectTL
% rectBL
% rectTR
% rectBR
% background
% light
% dark
% mid
% fuse
% fuseTargetOuter_L
% fuseTargetOuter_R
% outerFuseThickness
% occludingBarPos
% textureImageSF_cpi
% textureImageContrast
% textureImagePhi
% maskFadedArea
% 
% *From R*
% topJitter
% bottomJitter
% leftOffset
% rightOffset
% currNearRect
% lightRect

% Specify parameters here: units are indicated as cm, arc-min, degrees, pixels, or sec
viewDist_CM = 145;          % distance of subject from screen % FIXME duplicates settings in HW (take in HW?)
pixelsPerCM = 1920 / 91.4;  % pixels per cm on screen
rectH_CM = 12;            	% height of display rectangles
rectW_CM = 6;               % width of display rectangles
borderWidth = 3;            % width of the border in pixels
borderColor = 0;            % scalar, grayscale color of border (0 = black, 1 = white).
occludingBarW_CM = 1.5;     % width of horizontal occluding bar
maskFadedArea = 400;        % width of the faded area in pixels
vertOverlap_CM = 0.8;       % amount of vertical overlap of upper/lower rectangles
balanceJitterFlag = true;   % true: disp split between top and bottom.  false: all disparity in bottom. 
minJitter_AM = 6;           % minimum jitter of rectangle from center position
maxJitter_AM = 12;          % maximum jitter of rectangle from center position
maxDisparity_AM = 60;        % maximum disparity between OD/OS positions of bottom bar relative to top bar (can be pos or neg)
initDisparity_AM = 15;       % initial disparity between OD/OS positions
  
numTrials = 80;            % total number of trials
pauseFractions = [0.25 0.5 0.75];  % fractions of experiment after which there is a pause
% pauseLength = 60;           % minimum length of rest during breaks (seconds)
% stimulusDuration = 1;       % stimulus duration in seconds
% postResponsePause = 1;      % pause between user response and next trial (sec)
% reactionTime = 0.15;        % time to wait following initiation of stimulus before accepting response (sec)
% fixationPause = 0.5;        % pause to fixation the square in seconds
% preTrialPause = 0.5;        % duration of the pause just before the trial
% postFusePause = 0;          % time between fusion target and next stimulus
% fixationSize = 30;          % size of the fixation square in pixels
% fixationThickness = 3;      % thickness of the fixation square in pixels

% numAtMaxDisparity = 1000;     % number of repeats at max disparity (after first 20 trials) at which to alert operator

backgroundColor = [0 0 0];  % background color
lightColor = [225 225 225]; % color of lighter rectangle
darkColor = [225 225 225];  % color of darker rectangle
midColor = [165 165 165];   % color of occluding bar %FIXME maybe supposed to be 50% luminance?
fuseColor = [195 195 195];  % color of fusion target %FIXME maybe supposed to be 75% luminance?

nAdj = 3;                   % number of adjustments tasks in each adjustment subsession
outerFuseSize = 6.0;                % length of side of outer fusion square (around simulus) in degrees
outerFuseThickness = 0.3;           % thickness of outer fusion square lines in degrees
innerFuseSize = 1.8;                % length of size of inner fusion square in degrees
innerFuseThickness = 6 ;         	% thickness of inner fusion square lines in pixels
innerFuseTargetThickness = 6 ;    	% thickness of nonius fusion target lines in pixels
fuseLineLength = 0.4;               % length of nonius inner lines of fusion target in degrees
fuseTargetBiasMax = 0.166;          % deviation max of the correct aligned position of the lines from the center in degrees
fuseTargetJitterMax = 0.166;        % deviation max of the lines at the begining of a trial from the correct position
adjustmentStep = 0.1;               % step of the adjustment lines in pixels

% textSize = 48;                      % text size for on-screen messages

% fill parameter structure -- distances originally were in pixels unless noted
E = struct( ...
    ... from original E ...
...% 	'ResultFilePath',           [cd '\results\'], ...
...%     'ExptDate',                 '', ...             	% date on which expt is run
...%     'StartTime',                '', ...                 % time at which expt starts
...%     'EndTime',                  '', ...                 % time at which expt ends
...%     ...'SubjectInit',              SubjectInit, ...        % initials of subject run
...%     ...'SubjectID',                SubjectID, ...          % ID of subject run
...%     'Group',                    GroupName, ...          % group subject is in
...%     'pixSize',                  pixSize, ...            % size of the pixels in cm
...%     'viewingDistance',          viewingDistance, ...    % distance to the screen in cm
	'numTrials',                numTrials, ...          % total number of trials
...%     'stimDuration',             stimulusDuration, ...   % length of stimulus (sec)
...% 	'postRespPause',            postResponsePause, ...  % pause after subject response (sec)
...%     'reactionTime',             reactionTime, ...       % time following stimulus presentation before responses accepted (sec)
...%     'fixationPause',            fixationPause, ...
...%     'preTrialPause',            preTrialPause, ...
...%     'postFusePause',            postFusePause, ...      % time between fusion target and next stimulus
...%     'fixationSize',             fixationSize, ...
...%     'fixationThickness',        fixationThickness, ...
...%     'fixationPos',              fixationPos, ...
...% 	'numRepeat',                numAtMaxDisparity, ...  % criterion for alerting operator after repeats at max disparity
     'pauseTimes',               round(numTrials*pauseFractions), ...	% trials after which to automatically pause expt
...%     'minPauseLen',              pauseLength, ...        % minimum length of time for scheduled pauses (sec)
...%     'stepSize',                 stepSize, ...
...%     'noMansLandW',              noMansLandW_CM*pixelsPerCM, ...       
    'rectH',                    rectH_CM*pixelsPerCM, ...             
    'rectW',                    rectW_CM*pixelsPerCM, ...    
    'occludingBarW',            occludingBarW_CM*pixelsPerCM, ...               
    'vertOverlap',              vertOverlap_CM*pixelsPerCM, ...    
    'minJitter',                viewDist_CM*pixelsPerCM*tan((pi/180)*minJitter_AM/60), ...            
    'maxJitter',                viewDist_CM*pixelsPerCM*tan((pi/180)*maxJitter_AM/60), ...            
    'maxDisparity',             viewDist_CM*pixelsPerCM*tan((pi/180)*maxDisparity_AM/60), ... 
    'initDisparity',            viewDist_CM*pixelsPerCM*tan((pi/180)*initDisparity_AM/60), ... 
...%     'occludingBarFadeDur',      occludingBarFadeDur,... % duration over which occluding bar fades out on yoked trial
    'noniusTaskP', struct( ... % Parameters that only apply to the nonius line adjustment task
        'nAdj',                     nAdj,...             	% number of adjustment tasks by block
...%         'fuseTargetInner_L',        [0 0 0 0], ...          % position of left inner fusion target
...%         'fuseTargetInner_R',        [0 0 0 0], ...          % position of right inner fusion target
        'innerFuseSize',            innerFuseSize, ...      % size of outer fusion square
        'innerFuseThickness',       innerFuseThickness, ...	% thickness of inner fusion square
        'innerFuseTargetThickness', innerFuseTargetThickness, ...
        'outerFuseSize',            outerFuseSize, ...      % size of outer fusion square
        'outerFuseThickness',       viewDist_CM*pixelsPerCM*tan((pi/180)*outerFuseThickness), ...   % thickness of outer fusion square
        'fuseLineLength',     viewDist_CM*pixelsPerCM*tan((pi/180)*fuseLineLength), ...             % length of inner fusion target lines
        'fuseTargetBiasMax', viewDist_CM*pixelsPerCM*tan((pi/180)*fuseTargetBiasMax), ...
        'fuseTargetJitterMax', viewDist_CM*pixelsPerCM*tan((pi/180)*fuseTargetJitterMax), ...
        'adjustmentStep', adjustmentStep)..., ...
...%     'textSize', textSize, ...
...%     ... from original R ...
...%     ...%'currDisparity',E.initDisparity, ... % not accessible here
...%     'nextStair',    3, ...
...%     ...%'nearRectArray',zeros(1,P.numTrials), ... % not accessible here
...%     'totalTrials',  1, ...
...%     'totalAtMaxDisparity', 0, ...
...%     'topJitterSaved', 0, ...
...%     'bottomJitterSaved', 0 ...
);
%E.currDisparity = E.initDisparity;
%E.nearRectArray = zeros(1,E.numTrials);

% For FindThreshold
E.maxTrials	= E.numTrials;	% Maximum number of trials in staircase
E.catchTrialProb = 0.0; % Probability of inserting a catch trial
E.pauseTime	= 0.0; % Pause between keyboard response and next trial
E.minPause	= 0.50; % Minimum total pause between stimuli

P = struct( ...
    ... from original E ...
    'background',               backgroundColor, ...    % color of screen background
    'light',                    lightColor, ...         % color of lighter rectangle
    'dark',                     darkColor, ...          % color of darker rectangle
    'mid',                      midColor, ...           % color of occluding bar
    'fuse',                     fuseColor, ...          % color of fusion target
    'maskFadedArea',            maskFadedArea, ...      % 
    'borderWidth',              borderWidth, ...
    'borderColor',              borderColor, ...
    'balanceJitterFlag',        balanceJitterFlag, ...
    ... from original R ...
    'lightRect',    round(rand), ...
    ... new ...
    'lockWidthDeg', 7.0, ...
    'lockSquares', 16 ...
    ... from original E, now populated in SARTrainingPrepParams ...
...%     'rectTL',                   [0 0 0 0], ...          % center position of top left rectangle
...%     'rectTR',                   [0 0 0 0], ...          % center position of top right rectangle
...%     'rectBL',                   [0 0 0 0], ...          % center position of bottom left rectangle
...%     'rectBR',                   [0 0 0 0], ... 	        % center position of bottom right rectangle
...%     'occludingBarPos',          [0 0 0 0], ...          % position of occluding bar
    ... from original R, now populated in SARTrainingPrepParams ...
...%    'currNearRect', 0, ...
...%    'topJitter',    0, ...
...%    'bottomJitter', 0, ...
...%    'rightOffset',  0, ...
...%    'leftOffset',   0, ...
);

% Specify vertical grating parameters for texture image
P.textureImageSF_cpi = [1 1.5];  % Cycles per image for each component
P.textureImagePhi = [0 -pi];  % Phase offsets in radians from cosine
P.textureImageContrast = [0.8 0.8/3];  % Contrast of each component
% P.textureImageSF_cpi = [1];  % Cycles per image for each component
% P.textureImagePhi = [0];  % Phase offsets in radians from cosine
% P.textureImageContrast = [1];  % Constrast of each component
% P.textureImageSF_cpi = [1.5 4.5];  % Cycles per image for each component
% P.textureImagePhi = [0 0];  % Phase offsets in radians from cosine
% P.textureImageContrast = [0.3 0.1];  % Constrast of each component

% end of SetExperimentParameters.m

% randomly sort elements of currNearRect, which are dividied equally
% between top (0) and bottom (1) closer
% BB & JM 4/2011: permute only the staircase trials; following yoked trial has same top/bottom answer.
% Note that SetExperimentParameters.m checks for divisibility by 4 of E.numTrials
nearVec = [zeros(1, E.numTrials/4) ones(1, E.numTrials/4)];  % specify number of top vs bottom trials for staircase trials
nearVec = nearVec(randperm(E.numTrials/2));   % random permutation, half of entries are 0, half are 1
nearVec = [nearVec ; nearVec];   % 2 x E.numTrials/2 array
E.nearRectArray = nearVec(:);    % 1 x E.numTrials vector

E.P = P;
E.prepParams = @SARTrainingPrepParams;
E.update = @SARTrainingUpdate;
end

function [P, overflow, underflow] = SARTrainingPrepParams(E, HW, S)
%SARTrainingPrepParams Build stim parameters from current experiment state
%
%   Inputs:
%       E = Experiment parameter structure
%       HW = Hardware parameter structure
%       S = Current experiment state
%
%   Outputs:
%       P = Next stimulus parameters
%       overflow = Whether disparity would be larger than E.maxDisparity
%       underflow = Whether disparity would be less than one pixel (? TODO)
    P = E.P;
    desiredDisparity = 10.^S.trialVal; % turns out this is in pixels! :(
    
    overflow = (desiredDisparity > E.maxDisparity);
    desiredDisparity = min(desiredDisparity, E.maxDisparity);
    
    underflow = false; % TODO
    
    P.currNearRect = E.currNearRect;
    
    P.rightOffset = 0.5 * desiredDisparity;
    if P.currNearRect == 1 % bottom is nearer
        P.dir = 'bottom';
        P.rightOffset = -P.rightOffset; % flip sign
    else
        P.dir = 'top';
    end
    P.leftOffset = -P.rightOffset; % always equal and opposite
    
    % From old parameter file
    % {
    % use screen dimensions and operator chosen experiment parameters to
    % determine the position of the occluding bar and the baseline (pre-jitter
    % and offset) positions of the four rectangles
    % X0_L = 0.25*(screenRect(3) + 3*screenRect(1) - P.noMansLandW);
    % X0_R = 0.25*(3*screenRect(3) + screenRect(1) + P.noMansLandW);
    % X0 = (X0_L+X0_R)/2;
    % Y0 = (screenRect(4) - screenRect(2))/2.0;
    X0 = HW.screenRect(3)/2;
    Y0 = HW.screenRect(4)/2;
    TopBarT = Y0+0.5*E.vertOverlap-E.rectH;
    TopBarB = Y0+0.5*E.vertOverlap;
    BottomBarT = Y0-0.5*E.vertOverlap;
    BottomBarB = Y0-0.5*E.vertOverlap+E.rectH;
    LeftBarL = X0-0.5*E.rectW;
    LeftBarR = X0+0.5*E.rectW;
    RightBarL = X0-0.5*E.rectW;
    RightBarR = X0+0.5*E.rectW;
    P.rectTL = [LeftBarL TopBarT LeftBarR TopBarB];
    P.rectBL = [LeftBarL BottomBarT LeftBarR BottomBarB];
    P.rectTR = [RightBarL TopBarT RightBarR TopBarB];
    P.rectBR = [RightBarL BottomBarT RightBarR BottomBarB];
    P.occludingBarPos = [HW.screenRect(1) Y0-E.occludingBarW*0.5 HW.screenRect(3) Y0+E.occludingBarW*0.5];
    % } end: from old parameter file
    
    % Randomize jitter; bottom jitter is equal and opposite to top jitter
    randSigned = 2*(rand-0.5);     % Number between -1 and 1
    randJitter = sign(randSigned)*E.minJitter + randSigned*(E.maxJitter-E.minJitter);    
    P.topJitter = randJitter;
    P.bottomJitter = -randJitter;
end

function [S, stop] = SARTrainingUpdate(M, S, P, i, correct, h)
%SARTrainingUpdate Update experiment state based on trial response
%   Inputs:
%       M = Model (i.e. staircase) parameter structure
%       S = Current experiment state (before latest response)
%       P = Last stimulus parameters
%       i = Current trial number (the one that just ran)
%       correct = Whether response was correct
%       h = Axes handle on which to plot staircase progress (optional)
%   
%   Outputs:
%       S = Updated experiment state
%       stop = Whether staircase should halt
    
    offset = abs(P.rightOffset - P.leftOffset);
    
    % Log the trial to the screen (and diary if applicable)
    if correct
        correctStr = 'right';
    else
        correctStr = 'wrong';
    end
    fprintf('Trial %3d at 10^%5.2f = %5.2f was %s\n', ...
        i, S.trialVal, offset, correctStr);
    
    % Update the actual staircase
    [S, stop] = GenericUpdateHelper(M, S, P, i, correct, log10(offset));
end
