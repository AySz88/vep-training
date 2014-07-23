function [ t, sd, S, HW ] = FindDotThreshold( M, E, HW, h, S )
%FINDDOTTHRESHOLD Finds a threshold by varying the number of signal dots
%   Runs a single staircase with default parameters, no saving of data
%   (Most current defaults are for dot threshold already)
    
    % Start logging input/output
    diary('diary.log');
    fprintf('\nStarting experiment...\n');
    
    if nargin < 1 || isempty(M)
        [M, E, HW] = Parameters();
    end
    
    if nargin < 4
        h = [];
    end
    
    if nargin < 5 || isempty(S)
        S = [];
    end
    
    [t, sd, S, HW] = FindThreshold(M, E, HW, h, S);
    
    diary off
end
