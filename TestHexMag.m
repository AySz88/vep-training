% TestHexMag.m
%
% Script to test code for making hex lattices with cortical magnification.
%
% Aside: There's something interesting here, probably already understood, but I
% don't know of it being described: when you increase scale as a function
% of radial eccentricity, you necessarily map circles in cortex onto elongated shapes
% (egg-shapes pointing at fovea) in space.  Clearly the world does not provide
% egg-shaped inputs.  A circle in space (to one side of fovea) maps onto 
% an outward-pointed egg cortex.  Is it really plausible (as per Melchi,
% Seidemann, Geisler etc NN 2013) that this "fixed" distortion can be easily
% compensated for without labeled line coding?  There would seem now to be
% no benefit to using location in the cortical map as a computational mechanism for
% representing location within the visual field.
%
% Ben Backus 9/20/2013

radius = 4.01;
hexCoords = HexLattice(radius);
[magCoords, relMag] = CorticalMag(hexCoords, 'BackusLab');

% Test
figure

subplot(1,2,1)
h = plot(hexCoords(:,[1 1])', hexCoords(:,[2 2])', '.');  % Plot each symbol as a line with 2 endpoints to get different colors
axis('square')
title('Lattice in cortical space');

subplot(1,2,2)
h = plot(magCoords(:,[1 1])', magCoords(:,[2 2])', 'o');
axis('square')
for iMarker = 1:length(h)
    set(h(iMarker),'MarkerSize', 4*relMag(iMarker));   % Scale the marker size according to rel mag
end
title('Lattice in visual space');
