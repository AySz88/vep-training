function HW = StereoacuityRectangles(P,HW)
% StereoacuityRectangles.m Two stereo cylinders at diff depths w/ occluder
% 
% FIXME old usage info below:
% Usage: DrawStimuli(E,R,window)
%        R: A structure holding all information needed to run current trial
%        E:	A structure containing all parameters for running experiment
%        window: pointer to window presenting stimuli
%        texturePointer: pointer to textures to use
%
%   Alisa Surkis SUNYOpt 4/2010
%   Ben Backus and Joanne Malek 7/2010: switched to Textures instead of
%      FillRect.  The colors of the rectangles are still in the code, but
%      are not currently used for anything.
%   Ben and Joanne 3/3/11: change code so that yoked stimuli start with the
%       occluding bar.  All trials start with the occluding bar present.
%       Yoked trials then re-draw the stimulus without the bar.
%
% Stuff expected in P:
% *From E*
% borderColor
% balanceJitterFlag
% rectTL
% rectBL
% rectTR
% rectBR
% borderWidth
% light
% dark
% background
% fuse
% occludingBarPos
% mid
% maskFadedArea
% 
% *From R*
% topJitter
% bottomJitter
% leftOffset
% rightOffset
% currNearRect
% lightRect
%
% * New *
% lockWidthDeg
% lockSquares

try 
    % Process parameters
    
    if ~isfield(HW, 'SARTexturesInitialized') || ~HW.SARTexturesInitialized
        % From StereoacuityTraining4/StereoacuityTrainingMain.m
        % Create texture to be used for rectangles  %%% Ben and Joanne
        imageXvals = linspace(-pi, pi, 200);
        textureLine = 0*imageXvals;
        for iComponent = 1:length(P.textureImageSF_cpi)
            newComponent = P.textureImageContrast(iComponent)* cos(imageXvals*P.textureImageSF_cpi(iComponent) - P.textureImagePhi(iComponent));
            textureLine = textureLine + newComponent;
        end
        textureImage = repmat(floor(255.99 * (0.5+0.5*textureLine)), 200, 1);
        [HW, texturePointer] = ScreenCustomStereo(HW, 'MakeTexture', HW.winPtr, textureImage);
        % Create mask
        widthPx = HW.screenRect(3);
        heightPx = HW.screenRect(4);
        maskXvals = repmat(linspace(0,pi/2, P.maskFadedArea), heightPx, 1);
        surf = ones(heightPx, widthPx/2) * pi/2;
        surf(:,1:size(maskXvals,2)) = maskXvals;
        surf = [surf fliplr(surf)];
        maskMat(:,:,1) = zeros(heightPx, widthPx);
        maskMat(:,:,2) = 255*(1-sin(surf).^2);
        [HW, mask] = ScreenCustomStereo(HW, 'MakeTexture', HW.winPtr, maskMat);

        [HW, borderTex] = ScreenCustomStereo(HW, 'MakeTexture', HW.winPtr, 255*P.borderColor*ones(1,1));    % Specify color of border (a rectangle under the texture)
        % end from StereoacuityTrainingMain.m
        
        HW.SARTexturesInitialized = true;
        HW.SARTexturePointer = texturePointer;
        HW.SARMask = mask;
        HW.SARBorderTex = borderTex;
    else
        texturePointer = HW.SARTexturePointer;
        mask = HW.SARMask;
        borderTex = HW.SARBorderTex;
    end
    
    % define position/size of rectangles based on change in center position
    % from jitter of top and bottom rectangles, and disparity between left
    % and right bottom rectangles.  If P.balanceJitterFlag is false, then the
    % top rectangle will always be in the disparity plane of the monitor.  If
    % P.balanceJitterFlag is true, then the disparity will be balanced between
    % the top and bottom rectangles, so that one will be closer and one farther
    % than the frame. (Ben B and Joanne M, 6/2011)
    if P.balanceJitterFlag
        positionOfRectLTop = P.rectTL + (P.topJitter-P.leftOffset/2)*[1 0 1 0];
        positionOfRectLBottom = P.rectBL + (P.bottomJitter+P.leftOffset/2)*[1 0 1 0];
        positionOfRectRTop = P.rectTR + (P.topJitter-P.rightOffset/2)*[1 0 1 0];
        positionOfRectRBottom = P.rectBR + (P.bottomJitter+P.rightOffset/2)*[1 0 1 0];
    else
        positionOfRectLTop = P.rectTL + (P.topJitter)*[1 0 1 0];
        positionOfRectLBottom = P.rectBL + (P.bottomJitter+P.leftOffset)*[1 0 1 0];
        positionOfRectRTop = P.rectTR + (P.topJitter)*[1 0 1 0];
        positionOfRectRBottom = P.rectBR + (P.bottomJitter+P.rightOffset)*[1 0 1 0];
    end
    
    % if bottom bar appears closer, put bottom over top rectangle
    % if top bar appears closer, put top over bottom rectangles
    %     if (P.currNearRect == 1)
    %         RectPositions = [positionOfRectLTop' positionOfRectLBottom' positionOfRectRTop' positionOfRectRBottom'];
    %      elseif (P.currNearRect == 0)
    %         RectPositions = [positionOfRectLBottom' positionOfRectLTop' positionOfRectRBottom' positionOfRectRTop'];
    %     end
%     addedBorder = P.borderWidth*[-1; -1; 1; 1];
%     if (P.currNearRect == 1)
%         RectPositions = [positionOfRectLTop'+addedBorder positionOfRectLTop' positionOfRectLBottom'+addedBorder positionOfRectLBottom' ...
%             positionOfRectRTop'+addedBorder  positionOfRectRTop' positionOfRectRBottom'+addedBorder positionOfRectRBottom'];
%     else % P.currNearRect == 0
%         RectPositions = [positionOfRectLBottom'+addedBorder positionOfRectLBottom' positionOfRectLTop'+addedBorder positionOfRectLTop'...
%             positionOfRectRBottom'+addedBorder positionOfRectRBottom' positionOfRectRTop'+addedBorder positionOfRectRTop'];
%     end    addedBorder = P.borderWidth*[-1; -1; 1; 1];
    if (P.currNearRect == 1)
        RectPositions = ...
            [positionOfRectLTop' positionOfRectLTop' positionOfRectLBottom' positionOfRectLBottom' ...
             positionOfRectRTop'  positionOfRectRTop' positionOfRectRBottom' positionOfRectRBottom'];
    else
        RectPositions = ...
            [positionOfRectLBottom' positionOfRectLBottom' positionOfRectLTop' positionOfRectLTop' ...
             positionOfRectRBottom' positionOfRectRBottom' positionOfRectRTop' positionOfRectRTop'];
    end
    RectPositions = RectPositions + P.borderWidth*[-1; -1; 1; 1]*[1 0 1 0 1 0 1 0];
    % the above line adds P.borderWidth to the RectPositions matrix like this:
    %     -1     0    -1     0    -1     0    -1     0
    %     -1     0    -1     0    -1     0    -1     0
    %      1     0     1     0     1     0     1     0
    %      1     0     1     0     1     0     1     0

    % if P.lightRect == 0, top rectangles are light, if 1, they are dark
    % NOTE: this section is no longer necessary as rectangles are now textured
    if P.lightRect == 0        
        RectColors = [P.light' P.dark' P.light' P.dark'];
    elseif P.lightRect == 1
        RectColors = [P.dark' P.light' P.dark' P.light'];
    end
    
    % put occluding line into rectangle and color arrays
    RectPositions = [RectPositions P.occludingBarPos'];
    RectColors = [RectColors P.mid'];
    
    % Draw stimuli and display for ALL trials (with or without occluder)
    % NOTE: The colors of the rectangles are no longer used!
    
    % Draw surrounding box
    % Clear screen for background and draw surrounding box
    center = 0.5 .* (HW.screenRect([3 4]) - HW.screenRect([1 2]));
    lockWidthPx = P.lockWidthDeg * HW.ppd;
    % Left eye
    HW = ScreenCustomStereo(HW, 'SelectStereoDrawBuffer', HW.winPtr, 0);
    Screen('FillRect', HW.winPtr, P.background); % Clear screen for background
    % Right eye
    HW = ScreenCustomStereo(HW, 'SelectStereoDrawBuffer', HW.winPtr, 1);
    Screen('FillRect', HW.winPtr, P.background); % Clear screen for background
    
    % First do left eye's image
    HW = ScreenCustomStereo(HW, 'SelectStereoDrawBuffer', HW.winPtr, 0);
    Screen('DrawTexture', HW.winPtr, borderTex, [], RectPositions(:,1));   % Draw black rectangle top? (BB for BP)
    Screen('DrawTexture', HW.winPtr, texturePointer, [], RectPositions(:,2), [], [], [], P.leftLuminance*[1 1 1]);   % Draw texture top? (BB)
    Screen('DrawTexture', HW.winPtr, borderTex, [], RectPositions(:,3));   % Draw black rectangle bottom? (BB)
    Screen('DrawTexture', HW.winPtr, texturePointer, [], RectPositions(:,4), [], [], [], P.leftLuminance*[1 1 1]);  % Draw texture bottom? (BB)
    Screen('FillRect', HW.winPtr, RectColors(:,5), RectPositions(:,9));
    Screen('DrawTexture', HW.winPtr, mask);
    
    % Now do the other eye's image
    HW = ScreenCustomStereo(HW, 'SelectStereoDrawBuffer', HW.winPtr, 1);
    Screen('DrawTexture', HW.winPtr, borderTex, [], RectPositions(:,5));
    Screen('DrawTexture', HW.winPtr, texturePointer, [], RectPositions(:,6), [], [], [], P.rightLuminance*[1 1 1]);
    Screen('DrawTexture', HW.winPtr, borderTex, [], RectPositions(:,7));
    Screen('DrawTexture', HW.winPtr, texturePointer, [], RectPositions(:,8), [], [], [], P.rightLuminance*[1 1 1]);
    Screen('FillRect', HW.winPtr, RectColors(:,5), RectPositions(:,9));
    Screen('DrawTexture', HW.winPtr, mask);
    
    HW = DrawFusionLock(HW, center, lockWidthPx, P.lockSquares);
    
    HW = ScreenCustomStereo(HW, 'Flip', HW.winPtr);
    
catch caughtException
    % This section is executed in case an error happens in the
    % experiment code implemented between try and catch...
    ShowCursor;
    Screen('CloseAll');
    rethrow(caughtException);
end

end
