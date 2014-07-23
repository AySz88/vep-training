% Do something like this....
% May want to structure data differently to account for any slow changes
% over time... (ex. make 4th column 1:numSamples )
%{
for i=1:100
    colors(i) = {[180 180 180] + round(rand(1,3))};
end
DisplayLumForCalibration(colors);

... collect data here ...

for i=1:54 % CHANGE THIS NUMBER
    data(i,:) = [colors{i}-180, i];
end

... enter data in 5th column here ...

data(:,5) = data(:,5)/1000 + 9; % CHANGE THESE NUMBERS
save('data', 'data')
stats = regstats(data(:,5), data(:, 1:4), 'linear')
save('stats', 'stats')
coeffs = stats.beta(2:4) / sum(stats.beta(2:4))
save('coeffs', 'coeffs')
%}

%% Run with this part first to set up the data variable...
data = zeros(8*5,4);
for i=1:40
    data(i,1:3) = [mod(floor((i-1)/4),2) mod(floor((i-1)/2),2) mod(i-1,2)];
end

%% type in last two sig figs into last column of data

%% then run this (replace the 1st line with appropriate numbers):
%{
    data(:,4) = data(:,4)/100 + 9;
    save('data', 'data')
    stats = regstats(data(:,4), data(:, 1:3), 'linear')
    save('stats', 'stats')
    coeffs = stats.beta(2:4) / sum(stats.beta(2:4))
    save('coeffs', 'coeffs')
%}
