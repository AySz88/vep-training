function HW = DrawFusionLock(HW, center, halfLockWidPx, lockSquares)
%DRAWFUSIONLOCK Draws fusion lock into the current window
% Fusion lock is a checkered frame of 'lockSquares' squares on each side,
% centered at 'center' with width 2*halfLockWdPx.

% TODO maybe faster to draw into a tiny texture with alpha channel?
% size: lockSquares on each side
% each square is just a pixel
% then draw texture at proper width and location

    if lockSquares == 0 || halfLockWidPx <= 0
        return % skip
    end
    
    squareSize = 2.0/lockSquares * halfLockWidPx;
    topLeftCenter = center ...
                    - [halfLockWidPx, halfLockWidPx] ...
                    + 0.5*[squareSize squareSize];
    setWidth = (lockSquares-1.0) * squareSize;
    
    % tttr % t = top set, r = right set, etc.
    % l  r
    % l  r
    % lbbb
    top = (0:lockSquares-2)' * [squareSize 0];
    left = (1:lockSquares-1)' * [0 squareSize];
    right = left + repmat([setWidth, -squareSize], lockSquares-1, 1);
    bottom = top + repmat([squareSize, setWidth], lockSquares-1, 1);
    
    % every square's center, clockwise from top-left, relative to top-left
    coords = [top; right; bottom(end:-1:1,:); left(end:-1:1,:)];
    
    for i=0:1
        HW = ScreenCustomStereo(...
                    HW, 'SelectStereoDrawBuffer', HW.winPtr, i);
        dark = false;
        for coordIdx = 1:(4*(lockSquares-1))
            currCoord = topLeftCenter + coords(coordIdx, :);
            if dark
                color = 0;
            else
                color = HW.white;
            end
            rect = [currCoord-0.5*squareSize, currCoord+0.5*squareSize];
            Screen('FillRect', HW.winPtr, color, rect);
            dark = ~dark;
        end
    end
end
