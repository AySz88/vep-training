function coords = HexLattice(radius);
% function coords = HexLattice(size);
%
% Create a hexagonal lattice with unit spacing that contains all lattice points out to
% to the specified radius.  Lattice has unit spacing along the x-axis (thus
% 
%
% Input:    radius (scalar)
% Output:   coords (N x 2 matrix of Cartesian x,y coordinate pairs)
% 
% Ben Backus 9/16/2013

% One row of the lattice
xVals  = -ceil(radius):1:ceil(radius); 
coords = [xVals' zeros(size(xVals'))];   

% Offsets
nRow = ceil(2*radius/(sqrt(3)/2));
if ~mod(nRow,2)
    nRow = nRow+1;   % Make sure there are an odd number of rows so that center row will be at origin
end
rowNums  = -(nRow/2 - 0.5):1:(nRow/2 - 0.5);
xOffsets = mod(rowNums,2) * 0.5;     % Every other row is moved over by 0.5
[X,Y] = meshgrid(xVals, rowNums);
X = X + repmat(xOffsets', 1, length(xVals));
Y = Y * sqrt(3)/2;

coords = [X(:) Y(:)];
coords(sum(coords.^2,2) > radius^2, :) = []; % Keep only the points that lie within original radius
