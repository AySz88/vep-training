function r = RandCos(n, modAmp)
% function r = RandCos(n, modAmp)
%
% Returns a column vector containing n random numbers drawn from a
% distribution with raised-cosine probability density.  All values of r
% are between 0 and 1, with the maximum density occurring at 0 and 1 and
% minimum density (probability density = 0) occurring at 0.5.
% Thus a histogram of r will be a raised cosine in shape.
%
% When modAmp < 1, the raised cosine distribution's pdf is mixed with a
% uniform distribution's pdf in the following manner:
%   resulting pdf = modAmp*(raised cosine) + (1-modAmp)*uniform
%                 = modAmp*(cos(t)+1) + (1-modAmp)
%                 = modAmp*cos(t) + 1
%
% Input:
%    n       whole number, length of output vector containing sample
%    modAmp  modulation amplitude, real, between 0 and 1.  Default = 1.
%
% Note that RandCos(n) returns a single column vector.
% This is unlike other MATLAB random number generators, for which
% passing one argument (ex. rand(n)) returns an nxn matrix of values.
%
% Example 1:
%    x = RandCos(10000);      % Create a 10000 x 1 column vector of values
%    hist(x, 30);             % Make a histogram of them using 30 bins
%
% Example 2:
%    x = RandCos(1e6, 0.5);   % Create a 1e6 x 1 column vector of values
%    hist(x, 50);             % Make a histogram of them using 50 bins
%
% Ben Backus & Alex Yuan, 2012-06-25
%
% The strategy for generating numbers according to this pdf is to first
% represent each point in a 2D space by a pair of randomly chosen (IID)
% numbers, (x,y), with both x and y drawn from the uniform distribution
% on [0,1).  Now we re-scale x and y so that the point lies somewhere in
% plane bounded by 0<=x<pi, -1<=y<1.
% If y <= cos(x), we keep x. Graphically this means that (x,y) landed
% under the curve of y = cos(x), which by construction must happen with
% probability (1+cos(x))/2.
% However, if y > cos(x), then we add pi to x.  Graphically, this point
% was above the curve, and because the probability of this happening has
% probability (1-cos(x))/2, i.e. high probability when x is near 0 and
% low as x approaches pi.  By adding pi to x, we fill in the right half
% of the distribution so that x will have a raised sinusoid pdf on the
% range [0,2*pi].
%
% That's what happens when modAmp = 1.  When modAmp is less than 1, we
% simply test against the curve y = modAmp*cos(x).  Interestingly, the
% resulting distribution has the same pdf as a mixed distribution, with
% samples from two different distributions having cosine pdf and uniform
% pdf respectively. The equivalent mixture draws from the cosine pdf with
% probability modAmp and from the uniform distribution with probability
% (1-modAmp).  That's because the weighted average of a sinusoid
% and the function y=0 is an attenuated (amplitude-modulated) version
% of the sinusoid.
%
% Finally, we divide x by 2*pi, so that its range is [0,1].  The user may
% want to rescale it to run from 0 to 2*pi again, but it's confusing to
% return cosinusoidally distributed numbers on the range [0,2*pi] because
% this would seem more meaningful than it is.
% 
% A nice feature of this method is that all n randomly generated number
% pairs are used on the first pass.  There is no need to check whether one
% has the required number and then generate more of them, or to generate a
% superabundance of numbers in order to be able to reliably take the first
% n of them.

% Check input argument values
switch nargin
    case 0
        n = 1; modAmp = 1;
    case 1
        modAmp = 1;
    case 2
        % do nothing
    otherwise
    error('Too many input arguments to function');
end
if modAmp < 0 || modAmp > 1
    error ('modAmp parameter must be between 0 and 1');
end

x = pi*rand(n,1);
y = 2*rand(n,1) - 1;

% logical vector to index the values of x that fall above the curve
iOutside = (y > modAmp*cos(x));

% instead of discarding these samples, recycle them (as described above)
x(iOutside) = x(iOutside) + pi;
%y(iOutside) = -y(iOutside); % plot(x,y,'.') illustrates the distribution
r = x/pi/2;