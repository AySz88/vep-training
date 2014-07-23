function [ M, E, HW ] = Parameters()
%PARAMETERS Load default parameters for the experiment into structures.
%   These are only the defaults! You may change these during the experiment
%       (ex. in Find*Threshold experiment code)
%   See inline comments for details.
%   M: Model (i.e. staircase) parameter structure
%   E: Experiment (i.e. stimulus) parameter structure
%       E.P: Defaults for stimulus display parameters
%   HW: Hardware parameter structure
%
% PLEASE NOTE:
% The E.* and M.* values in this file are "canonical" values, and are
% rarely changed.  The HW values are usually left untouched with the
% exception of the "room" and "screenNum" parameters.
%
% If you want to change a parameter just for an individual experiment, that
% is done ***within the file of that experiment*** by overriding the values
% from this file.  They will typically make any special tweaks right after
% they first copy the values from this file, just after the line that
% reads: [M,E,HW] = Parameters();
% For example, FindContrastTradeoffThresholdLisa.m overrides many
% parameters, like E.maxTrials, E.P.scaleFactor, E.P.fixPosDegR,
% E.P.fixPosDegT, etc.
%
% Changes to such overridden values in this file ***will have no effect***
% for that particular experiment, and may result in unexpected changes to
% other experiments!
%
% Some parameters are also overriden or tweaked just before each individual
% trial by the functions specified by E.prepParams (see below).  For
% example, FindContrast*Threshold will override E.P.contrasts.  To adjust
% these parameters, change the code in the helper function (or create a new
% one and use that instead, since helper functions can get shared between
% different experiments).
% 
% This warning applies to all the E and M parameters.  The hardware (HW)
% parameters are not often touched, but this is not guaranteed.  Read the
% experiment code to check.

%% Model parameters: staircases and trial selection
    
    M.listenTo = 'nDOWNmUP'; % Which algorithm to pick trials?
        % Uses QuestQuantile if 'QUEST'
        % otherwise uses nDOWNmUP
        % Fill out all of the rest of these parameters either way!
    M.useQuest = strcmpi(M.listenTo, 'QUEST');
    
    M = StatModelDots(M); % Default statistical model

    % To plot corresponding psychometric function, run:
    %    q=QuestCreate(M.tAverage, M.tSD,...
    %       M.pThreshold, M.beta, M.delta, M.gamma, M.grain, M.range);
    %    plot(q.x2 + q.tGuess, q.p2)
    
    M.initialize = @GenericInitStaircase;
    
%% Experiment parameters: experiment structure & default stimulus params
% NOTE:
    E.maxTrials	= 80;	% Maximum number of trials in staircase
    E.catchTrialProb = 0.1; % Probability of inserting a catch trial
    E.pauseTime	= 0.25; % Pause between keyboard response and next trial
    E.minPause	= 1.00; % Minimum total pause between stimuli
    E.bgLumnce	= 0.25; % Background luminance (black=0, white=1)
    
    E.time = now; % Starting time of experiment
    E.randSeed = mod(floor(E.time*60*60*24), 2^32); % random number seed
    
    % Typical RDK parameters
    % For details, see parameters to RanDotKgram (doc RanDotKgram)
    E.P.nDots       = 100;  % Total number of dots in the RDK
    E.P.sigDots     = 12;	% Number of signal dots in the RDK
    E.P.duration	= 0.3;  % duration of stimulus (seconds)
    E.P.lifetime	= 1.0;	% lifetime of dots (seconds)
    E.P.contrasts	= [log10(1.0) -Inf;	% Log10 contrast: [signalL signalR;
                       log10(1.0) -Inf];%                  noiseL  noiseR ]
                            % should be <= log10(1/E.bgLumnce - 1)
    E.P.contrastSDs	= [0 0; 0 0];	% Linear in points of log10 contrast:
                                 	% [signalL signalR; noiseL noiseR]
    E.P.dotType     = 'gaussian';	% see Screen('DrawDots?') dot_type arg
                                    % ...and also accepts 'gaussian'
    E.P.dotSpeedDeg	= 3.0*7/5;	% dot speed (deg/sec)
    E.upChance      = 0.5;	% probability of 'up' signal; otherwise, 'down'
    E.P.sigDirDistr	= 'all'; % distribution of directions of signal dots
                            % see RanDotKgram parameter 'signalDirDistr'
    E.P.sigDirPower	= 0.5;	% for 'sin', avg velocity in the signal
                            % direction, divided by the average dot speed
    E.P.dotSizeDeg	= 0.21;	% width of dot (deg); if gaussian, 4*s.d.
    E.P.viewportDeg	= 3.5;	% radius of viewport (deg) = dot patch size
    E.P.fixPosDegR	= 0;    % fixation position, radial distance (deg)
    E.P.fixPosDegT	= 0;    % fixation position, theta from +x axis (deg)
    E.P.fixWidthDeg	= 0.5;	% width of fixation box (deg)
    E.P.frameWidDeg	= 0;	% width of frame of fix box (deg);0 means 1 px
    E.P.lockWidDeg	= 4.0;	% half width of fusion lock around stim (deg)
    E.P.lockSquares = 16;	% # of squares per full side of fusion lock
    E.P.noGoRadiusDeg = 0.5;% radius of area near fix mark to not have dots
    E.P.noGoType = 'teleport'; % Dots in no-go zone: cover|teleport|kill
    E.P.scaleFactor	= 7/7;	% extra scale for dot size/speed and view size
    E.P.scaleFixBox = false;% whether to scale fix box width/thickness
                            % (fixation box position is never scaled)
    E.P.scaleFusion = true; % whether to scale fusion lock box
    E.P.clearAtEnd	= true; % at end of stimulus, clear away dots?
    
    % Staircase helper functions:
    %   E.prepParams: takes experiment state and gives stimulus parameters
    %    Inputs:
    %       E = Experiment parameter structure
    %       S = Current experiment state
    %    Outputs:
    %       P = Next stimulus parameters
    %       overflow = Whether S requested easier stimulus than presentable
    %       underflow = Whether S requested harder stimulus than possible
    %
    %   E.update: takes responses and updates the staircase
    %    Inputs:
    %       M = Model (i.e. staircase) parameter structure
    %       S = Current experiment state
    %       P = Last stimulus parameters
    %       i = Current trial number
    %       correct = Whether response was correct
    %       h = Axes handle on which to plot staircase progress (optional)
    %    Outputs:
    %       S = Updated experiment state
    %       stop = Whether staircase should halt
    %   
    %   NOTE: these staircase helpers typically get reset within each
    %   individual experiment file!  Ex. FindContrastTradeoffThreshold*
    %   will override these, and set them to the functions provided by
    %   ContrastTradeoffStaircaseHelpers.m
    [E.prepParams, E.update] = DotStaircaseHelpers();
    
%% Hardware parameters: user interface, OpenGL, and OS & MATLAB environment
    
    % Projector ('1424'), plasma ('1424plasma'), or stereoscope
    % ('1402chatnoir')?
    HW.room = '1424plasma';
    HW.screenNum = 1; % see Screen('Screens?')
    
    % HW.monWidth: width of entire viewable screen (cm)
    %   (Will later be multiplied by the fraction used, if stereoscope)
    % HW.viewDist: viewing distance (cm)
    knownRoom = false;
    switch lower(HW.room)
        case '1424'
            switch HW.screenNum
                case 1 % Projector
                    HW.monWidth	= 239.6;
                    HW.viewDist	= 150;
                    HW.useStereoscope = false;
                    knownRoom = true;
                case 2 % CRT (dev/console) screen
                    HW.monWidth = 39;
                    HW.viewDist	= 60;
                    HW.useStereoscope = false;
                    knownRoom = true;
            end
        case '1424plasma'
            switch HW.screenNum
                case 1 % Dev screen
                    HW.monWidth = 50;
                    HW.viewDist	= 60;
                    HW.useStereoscope = true;
                    knownRoom = true;
                case 2 % Plasma screen
                    HW.monWidth	= 91.4; % FIXME approx?
                    HW.viewDist	= 145; % FIXME approx
                    HW.useStereoscope = true;
                    knownRoom = true;
            end
        case '1402'
            switch HW.screenNum
                case 1 % Alienware 2310 (production) 120Hz LCD display
                    HW.monWidth = 51;
                    HW.viewDist = 110;
                    HW.useStereoscope = true;
                    knownRoom = true;
                case 2 % hp 1530 (development/console) LCD display
                    HW.monWidth = 30;
                    HW.viewDist = 75;
                    HW.useStereoscope = false;
                    knownRoom = true;
            end
        case '1402chatnoir'
            HW.monWidth = 51;
            HW.viewDist = 110;
            HW.useStereoscope = true;
            knownRoom = true;
    end
    if ~knownRoom
        warning('Parameters:BadDefault', ...
            ['Unknown room / monitor - '...
            ' Using default monitor width and distance!']);
        HW.monWidth = 50;
        HW.viewDist = 100;
        HW.useStereoscope = true;
    end
    
    % HW.stereoMode: see Screen('OpenWindow?'), 1 = OpenGL stereo
    % HW.stereoTexWidth and HW.stereoTexOffset:
    %   Horizontal distances, as proportion of screen (|x|<1) or in pixels
    %   See ScreenCustomStereo
    if HW.useStereoscope
        % Uses ScreenCustomStereo
        HW.stereoMode = 0;
        HW.stereoTexWidth = 7.0/16.0;
        HW.stereoTexOffset = [-4.0/16.0, 4.0/16.0];
        HW.monWidth = HW.monWidth * HW.stereoTexWidth;
    else
        HW.stereoMode = 1;
        % Disable custom stereo with special parameter values
        HW.stereoTexOffset = [];
        HW.stereoTexWidth = 1.0;
    end
    
    HW.initPause = 0.5;	% pause length (in s) after initialization
    
    % Color calibration
    
    % HW.lumChannelContrib
    %	Est. [R, G, B] contribution to total luminance for grayscale steps
    %	(calibrations used for bit-stealing)
    %   Blue pixel contribs are often very uncertain (consistant w/ 0) :(
    % HW.lumCalib:
    %   Two-column table [raw, luminance]
    %   Will normalize max luminance to 1 at end of switch block
    switch lower(HW.room)
        case '1424'
            HW.lumCalib = importdata('media/lumCalib 1424 2012-07-21.mat');
            HW.lumChannelContrib = [.2456 .7293 .0251];
        case '1402'
            HW.lumCalib = importdata('media/lumCalib 1402 2012-07-21.mat');
            HW.lumChannelContrib = [.1616 .7739 .0645];
        case '1402chatnoir'
            HW.lumCalib = ...
                importdata('media/lumCalib 1402chatnoir 2012-10-24.mat');
            HW.lumChannelContrib = [.2846 .5949 .1204];
        otherwise
            warning('Parameters:NoColorCalib', ...
                'No default color calibration data! Loading gamma = 2.0');
            testLums = [0:10:250, 255]';
            testVolts = (testLums ./ 255).^2;
            HW.lumCalib = [testLums, testVolts];
            HW.lumChannelContrib = [.2 .7 .1];
    end
    HW.lumCalib(:,2) = HW.lumCalib(:,2) / max(HW.lumCalib(:,2));
    
    % Use PsychImaging(..., 'DisplayColorCorrection', 'LookupTable')?
    % TODO when using stereoscope, this value is currently ignored
    HW.usePTBPerPxCorrection = true;
    
    % User interface keys
    % TODO use KbName('UnifyKeyNames');
    if IsWin
        %{
        HW.upKey	= 'up';
        HW.downKey	= 'down';
        %}
        HW.upKey	= '8';
        HW.downKey	= '2';
        HW.leftKey	= '4';
        HW.rightKey	= '6';
        HW.haltKey	= 'x';
    elseif IsOSX
        HW.upKey = 'UpArrow';
        HW.downKey = 'DownArrow';
        HW.leftKey = 'LeftArrow'; % FIXME check whether l/r are right
        HW.rightKey = 'RightArrow';
        HW.haltKey = 'x';
    end
    HW.validKeys = {HW.upKey HW.downKey HW.leftKey HW.rightKey HW.haltKey};
    
    % Feedback sounds:
    % sounds for right and wrong answers (may be the same sound)
    HW.rightSound = importdata('media/Windows Balloon (Quirky) 3.wav');
    HW.wrongSound = ...
        importdata('media/Windows Critical Stop (Quirky) 2.wav');
    % sound for bad response, ex. hit an invalid key
    HW.failSound = importdata('media/Windows Hardware Fail.wav');
    
    % Store random number generator
    HW.randStream = RandStream('mt19937ar', 'Seed', E.randSeed);
    
    % Default window position and size for MATLAB plots and figures
    HW.defaultFigureRect = [50 100 1024-100 768-200];
    
    HW.initialized = false; % not yet initialized
end
