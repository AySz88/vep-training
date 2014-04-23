function [outCoords, mags] = CorticalMag_wrong(inCoords, rule2use)
% function [outCoords, mags] = CorticalMag_wrong(inCoords, rule2use)
%
% This version is wrong--it integrates as though the formula for
% cortical magnification applies to a particular cortical eccentricity
% value, not a particular eccentricity in the visual field.  It may not
% matter, they may be the same thing, but I need to understand this point.
% The fact that we're integrating may solve the problem--accumulating more
% and more magnification as we go is the right thing to do, and the amount
% that we should accumulate is the issue.  The particular value of
% (reciprocal) magnification to use is given by the formula as a function
% of r_VisSpace, not r_cort.
%
% Thus...see CorticalMag.m.
%
% Expand coordinates in coords (input) using cortical magnification rule.
% This function allows one to sample the visual field uniformly in terms of
% cortical magnification, similar to what's done with multi-focal ERG.  The
% first step is to transform a regularly spaced grid (inCoords) to the sampled
% grid (outCoords).  This requires integration of a uniform cortical
% scaling metric from the origin (fovea) out to the lattice point until the
% correct radius (in uniform cortical spacing) has been attained; to do
% this requires traversing a greater and greater distance in the visual field, as
% eccentricity increases.  The resulting array is homogeneously spaced in cortical
% magnfication units (at least in the radial direction).
%
% The math:
%   r_VisSpace = integral from r=0 to r_cort of (1 + r/E_h) dr, where r_cort is the radius in uniform cortical space.
%              = r_cort + (r_cort^2 / (2*E_h))
%   Thus for example if E_h=2, then r_VisSpace(r_cort = 0) is 0, r_VisSpace(1) is 1.25, 
%                                   r_VisSpace(2) is 3, r_VisSpace(3) is 5.25, etc.      
%
% Input
%   inCoords    Nx2 list of X,Y input coordinates, usually a regular hex
%                   grid such as created by HexLattice().  The scaling of
%                   the coordinates should be such that a point with radius
%                   1.0 from the origin will be mapped onto a point in the
%                   visual field that is 1+1/(2*E_h) deg in eccentricity from the
%                   origin.  Thus, if points are desired within the visual field at 
%                   the fovea (r_cortex = 0) and at R deg, the input lattice 
%                   should include points at (0,0) and (0, x) where 
%                   x = E_h * (sqrt(1 + 2*R/E_h) - 1), which is the positive 
%                   quadratic root when solving for x in the equation R = x + x^2/(2*E_h).
%
%   rule2use    string: 'Drasdo' or 'Mankowska' or 'BackusLab'
%
% Output
%   outCoords   Nx2 list of transformed X,Y coordinates in deg visual angle
%                   (we ignore the distortion introduced by failing to 
%                   transform from cartesian to spherical coords, which is a 
%                   relatively small < 2.3% for eccentricities of 15 deg or less
%                   because tan(15*pi/180)/(15*pi/180) = 1.023 )
%   relMag      Nx1 list of corresponding local relative magnification factors,
%                   i.e. the size scale to use at the corresponding lattice point
%                   (the value is always 1 at origin).
%
% The magnification rule for Drasdo or Mankowska is the same but with different E_h,
% where E_h is eccentricity at which resolution is double (cortical mag is
% half), in deg.  Thuse
% We'll use E_h = 2.5 as in Lisa's summer 2012 experiment. 
% Resolution scaling factor lambda equation, taken from van de Grind et al,
% 1983 (citing Drasdo, 1977) is: 
%      lambda(eccDeg) = lambda_0 * N, where N = (1 + E/E_h), E_h being
%             approx. 2.0 (or ~2.545 according to Mankowska (2012)). 
%      N = 1 + stimEcc/E_h
%      relMag = 1./N
%
% Remember that to create a stimulus that takes cortical magnification into
% account, the relative magnification in the display is the reciprocal of
% the local cortical magnification.
%
% Ben Backus 9/24/2013

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

r_cortex = sqrt(sum(inCoords'.^2))';              % Radius of point in uniform cortical space
r_VisSpace = r_cortex + (r_cortex^2 / (2*E_h));   % Radius of point in visual field space

mags = radius./(1 + radius/E_h);
outCoords = diag(mags)*inCoords;

        