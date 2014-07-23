HW.stereoTexWidth = 6.0/16.0;
HW.stereoTexOffset = [-5.0/16.0, 5.0/16.0];

HW.screenNum = 1;
HW.stereoMode = 0;
HW.white = 255;

HW.lumChannelContrib = [.3, .59, .11];
HW.lumCalib = importdata('media/lumCalib.mat');
HW.lumCalib(:,2) = HW.lumCalib(:,2) / max(HW.lumCalib(:,2));

disp('Initializing...');
[HW, HW.winPtr, HW.screenRect] = ...
    ScreenCustomStereo(HW, 'OpenWindow', HW.screenNum);
disp('Drawing...');
for frameNum=1:2
    HW = ScreenCustomStereo(HW, 'SelectStereoDrawBuffer', HW.winPtr, 0);
    %disp(['Drawing into left eye texture ' num2str(HW.winPtr)]);
    Screen('FillRect', HW.winPtr, [0, 200, 0])
    DrawFormattedText(HW.winPtr, 'Left -X- Left', ...
                        'center', 'center', ...
                        0, 50);
    
    HW = ScreenCustomStereo(HW, 'SelectStereoDrawBuffer', HW.winPtr, 1);
    %disp(['Drawing into right eye texture ' num2str(HW.winPtr)]);
    Screen('FillRect', HW.winPtr, [0, 200, 0]);
    dots = 30;
    dotColors = [(10*(1:dots))' zeros(dots, 2)];
    Screen('DrawDots', HW.winPtr, 20*[1:dots; 1:dots], 10, dotColors');
    DrawFormattedText(HW.winPtr, 'Right -X- Right', ...
                        'center', 'center', ...
                        0, 50);
    
    HW = ScreenCustomStereo(HW, 'Flip', HW.winPtr);
    disp('Flipped; pausing...')
    pause
end
HW = ScreenCustomStereo(HW, 'Close', HW.winPtr);
