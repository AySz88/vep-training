function ApproxMagArray(inCoords)
% function ApproxMagArray(inCoords)
%
% Create a more-or-less space-filling array of lattice points and cortical scale
% factors.  This can be done using expanding hexagons, each one rotated 30
% deg relative to the preceding one.  There are three such patterns: with stim 
% at fovea, and with no stim at fovea but in a triangle surrounding it
% either pointing up or pointing down.  These "offset-grids" show that what we're  
% really producing are triangular lattices, i.e. hexagonal *tiling*.
%
% Ben Backus 9/27/2013

% Strategy: choose eccentricity first, then make as large as possible at
% that eccentricity.  Hunch: a square or triangular lattice might actually
% work better for this.
%
% Case 1: stim at fovea
r_cortex = [0 1 2 3 4];
mag
hexCoords = HexLattice(1);
hexCoords(all(hexCoords'==0),:) == [];    % Remove central point




% Case 2: perifovea, triangle pointed up
r_cortex = 

% Case 3: perifovea, triangle pointed down (rotated 60 deg)
