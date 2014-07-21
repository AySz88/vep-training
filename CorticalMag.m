function [outCoords, relMag] = CorticalMag(inCoords, rule2use)
% function [outCoords, relMag] = CorticalMag(inCoords, rule2use)
%
% Expand coordinates in coords (input) using cortical magnification rule.
% This function allows one to sample the visual field uniformly in the
% cortical topography, similar to what's done with multi-focal ERG (I wonder
% if they are they doing it right.  We must transform a regularly spaced grid
% (inCoords) to the sampled grid (outCoords).  This requires integration of
% a uniform cortical scaling metric from the origin (fovea) out to the lattice
% point at which the correct radius (in uniform cortical spacing) has been 
% attained. The resulting array should be homogeneously spaced in cortical
% magnfication units (at least in the radial direction).  We do not worry
% about the fact that cortical magnification may be greater for the lower
% visual field than for the upper visual field, nor about the distortion
% introduced by failing to transform from cartesian to spherical coords, which 
% is relatively small, < 2.3% for eccentricities of 15 deg or less:
% tan(15*pi/180)/(15*pi/180) = 1.023.
%
% The cortical magnfication function (from literature):
%
%     The magnification rule from Drasdo (1977) is the same as for van de Grind
%     et al. (1983) or Mankowska (2012), with different values of E_h.  E_h is the eccentricity
%     in visual space at which cortical magnification has dropped to half of its
%     value in the fovea.  Drasdo and van de Grind use E_h = 2.0, Mankowska uses 2.53.
%     For Backus Lab, we'll use E_h = 2.5 as in Lisa's summer 2012 experiment. 
%
%     The formula for computing stimulus size to correct for cortical magnification
%     at a given eccentricity E in the visual field is given by 
%
%        lambda(E) = lambda_0 * N, where N = 1 + E/E_h
%
%     The local relative cortical magnification at E is relMag = 1/N, which
%     is 1 at the fovea and gets smaller as eccentricity increases.  
%
% The math:
%
%     Let x be the desired point's radius (distance from fovea) in uniform cortical space; x is given.
%     Let E be the desired point's eccentricity (radius from fovea in visual space), to be computed.
%     Let y be eccentricity or radius in visual space (a variable).
%    
%     Then we want to solve the following equation for E:  x = int(1/(1+y/E_h), y, 0, E)
%
%     That expression is in matlab symbolic toolbox notation.  In words:
%     x is the integral from 0 to E of (1/(1+y/E_h))dy.
%
%     Thus, we travel outwards from fovea in visual space y until sufficient 
%     cortical magnification has been accumulated to reach a cortical radius of x.
%
%     Solving for E gives E = E_h * (exp(x/E_h) - 1)
%     
% Input:
%
%     inCoords    Nx2 list of X,Y input coordinates, usually a regular hex
%                 grid such as created by HexLattice().  These can be thought
%                 of as having a scale (units) of 1 deg equivalent at the fovea.  
%                 Thus, if E_h = 2, cortical input coordinate of (0,3) will be
%                 mapped onto (0, 2*(exp(3/2) - 1)) = (0,6.96) in the visual field. 
%
%     rule2use    string: 'Drasdo' or 'Mankowska' or 'BackusLab' for different values of E_h 
%
% Output:
%
%     outCoords   Nx2 list of transformed X,Y coordinates in deg visual.
%
%     relMag      Nx1 list of corresponding local relative magnification factors,
%                 i.e. the size scale to use at the corresponding lattice point
%                 to compensate for decrease in cortical magnification in
%                 eccentric vision (this value is always 1 at origin).
%
% Ben Backus 9/26/2013

switch rule2use
    case 'Drasdo',
        E_h = 2.0;
    case 'Mankowska',
        E_h = 2.54;
    case 'BackusLab',
        E_h = 2.5;
    otherwise,
        error('unknown cortical magnification rule')
end

r_cortex = sqrt(sum(inCoords'.^2))';              % N x 1, radius of point in uniform cortical space (x)
r_VisSpace = E_h * (exp(r_cortex/E_h) - 1);       % N x 1, radius of point in visual field space (E)
magFactor = r_VisSpace./r_cortex;
outCoords = [magFactor magFactor].*inCoords;  % N x 2. Normalize each coord pair by dividing by r_cortex, then scale.

% Repair NaN at origin(s) due to divide by zero
origins = all(inCoords==0,2);
outCoords(origins, :) = zeros(sum(origins),2);

relMag = 1 + r_VisSpace/E_h;                      % N x 1

