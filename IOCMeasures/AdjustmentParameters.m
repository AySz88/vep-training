function [ AE, HW ] = AdjustmentParameters( )
%ADJUSTMENTPARAMETERS Default parameters for method-of-adjustment runs
%   Returns:
%       HW: Hardware parameter structure (see Parameters.m)
%       AE: Adjustment task parameter structure
%           Required:
%               AE.initValue (intial value)
%               AE.goUp and AE.goDown (function (AE,oldVal) to [AE,newVal])
%               AE.prepParams (function (AE, value) to stimulus params P)
%               AE.stimulus (stimulus display function, takes (P, HW))
%           See code for an example of an AE structure.
    
    AE = RectangularSinusoidAdjustment();
    [~, ~, HW] = Parameters(); % mostly same parameters as other contexts
    
    % New key just for Method of Adjustment tasks
    HW.stopKey = 'return';
    HW.validKeys = {HW.upKey HW.downKey HW.stopKey HW.haltKey};
    
    %{
    % Adjustment task parameters - test example
    
    % value to start adjustment task at
    AE.initValue = 0;
    
    % (optional) value step up (exists just for convenience of AE.goUp)
    AE.upStep = 1;
    % Function run on step up: takes (AE, oldValue), returns [AE, newValue]
    AE.goUp = @(AE, value) deal(AE, value+AE.upStep);
    
    % Step down and function to step down, analogous to above
    AE.downStep = 1;
    AE.goDown = @(AE, value) deal(AE, value-AE.downStep);
    
    % Function to convert (AE, value), into stimulus parameters
    % (usually 'P', but just something simple here for testing purposes)
    AE.prepParams = @(AE, value) value;
    
    % Stimulus function, run on every frame with params via AE.prepParams
    AE.stimulus = @(params, HW) disp(params);
    %}

end

