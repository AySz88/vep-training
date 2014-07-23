e = []; %caught exception
[M, E, HW] = Parameters();
[didHWInit HW] = InitializeHardware(HW);
E.P.contrasts = log10([0.1, 0; 0, 0.2]);

dir = 'down';

iters = 3;
dur = .50;
pauseTime = 2.0;
try
    for i=1:iters
        if rand() < E.upChance%strcmpi(dir, 'down')%
            dir = 'up';
            %dir = 'down';
        else
            dir = 'down';
        end
        
        curP = E.P;
        curP.bgLumnce = E.bgLumnce;
        curP.duration = dur;
        curP.dir = dir;
        curP.catchDirection = ''; % remove catch dot
        
        RanDotKgram(curP, HW);
        
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
