function [ HW ] = RectangularSinusoidDisplay( P, HW )
%RECTANGULARSINUSOIDDISPLAY Draws a grating + fusion lock into the window
% Grating is oriented horizontally (lum changes in vertical direction) with
% luminances from 0 (assumed black) to 1 (display max).
% No color correction is done; that is done elsewhere (i.e. PsychImaging)
% Use of ScreenCustomStereo is (probably?) required
%   Parameters:
%       P.widthDeg     : Width of grating rectangle (deg)
%       P.heightDeg    : Height of grating rectangle (deg)
%       P.bgLum        : Luminance of background relative to display max
%       P.contrasts    : Contrasts relative to max possible for bgLum
%       P.bands        : # of bands to render (use [] for fully smooth)
%       P.phases       : Phase at center (in each eye), positive = shift up
%       P.cycles       : # of cycles vertically (ex. peak to peak)
%       P.lockWidthDeg : Width of fusion lock box (deg), see DrawFusionLock
%       P.lockSquares  : # of squares on each edge of fusion lock box
%       P.markWidthPx  : Width of mark on screen in pixels
%       P.markHeightPx : Height of mark on screen in pixels
%       P.markOffsetPx : Offset of height of mark (for bracketing)
    
    center = 0.5 .* (HW.screenRect([3 4]) - HW.screenRect([1 2]));
    width = round(P.widthDeg * HW.ppd);
    height = round(P.heightDeg * HW.ppd);
    destXs = center(1) + [-0.5 0.5] .* width;
    destYs = center(2) + [-0.5 0.5] .* height;
    trueDestRect = [destXs(1) destYs(1) destXs(2) destYs(2)];
    
    if ~isfield(P, 'bands') || isempty(P.bands)
        P.bands = height;
    end
    
    lockWidthPx = P.lockWidthDeg * HW.ppd;
    
    additive = true;
    
    amp = min(1-P.bgLum, P.bgLum); % maximum possible contrast
    
    stimImg(:,:,:,1) = amp * P.contrasts(1) .* ...
        SinusoidImage(width, P.bands, P.phases(1), P.cycles, additive);
    stimImg(:,:,:,2) = amp * P.contrasts(2) .* ...
        SinusoidImage(width, P.bands, P.phases(2), P.cycles, additive);
    
    stimImg = P.bgLum + stimImg;

    for eye=[1,2]
        HW = ScreenCustomStereo(...
                    HW, 'SelectStereoDrawBuffer', HW.winPtr, eye-1);
        Screen('FillRect', HW.winPtr, HW.white * P.bgLum);
        Screen('PutImage', HW.winPtr, ...
            HW.white * stimImg(:,:,:,eye), trueDestRect);
        
        markRects = [ ... First mark ...
            destXs(1) - P.markWidthPx, ...
            center(2) - 0.5*P.markHeightPx + P.markOffsetPx, ...
            destXs(1), ...
            center(2) + 0.5*P.markHeightPx + P.markOffsetPx; ...
            ... Second mark ...
            destXs(2), ...
            center(2) - 0.5*P.markHeightPx + P.markOffsetPx, ...
            destXs(2) + P.markWidthPx, ...
            center(2) + 0.5*P.markHeightPx + P.markOffsetPx];
        
        Screen('FillRect', HW.winPtr, 0, markRects(1,:));
        Screen('FillRect', HW.winPtr, 0, markRects(2,:));
        
        HW = DrawFusionLock(HW, center, 0.5*lockWidthPx, P.lockSquares);
    end
    
    HW = ScreenCustomStereo(HW, 'Flip', HW.winPtr);
end

