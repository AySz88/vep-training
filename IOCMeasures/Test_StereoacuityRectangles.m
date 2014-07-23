e = []; %caught exception
[~, ~, HW] = Parameters();
E = DefaultStereoacuityParameters();
    E.P.leftLuminance = 255;
    E.P.rightLuminance = 150;
    E.P.lightRect = 0;
[didHWInit, HW] = InitializeHardware(HW);

iters = 5;
pauseTime = 0.5;
try
    for iTrial=1:iters
        E.currNearRect = E.nearRectArray(iTrial);
        S.trialVal = (1.0 + 0.1*iTrial);
        curP = E.prepParams(E, HW, S);
        HW = StereoacuityRectangles(curP, HW);
        
        pause(pauseTime);
    end
catch e
end
if didHWInit
    HW = CleanupHardware(HW);
end
if ~isempty(e)
    rethrow(e);
end
