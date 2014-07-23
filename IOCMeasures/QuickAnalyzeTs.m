ts = sort(ts);
meanOfLastFour = mean(ts(1:4));
%meanOfLastFour
med = median(ts);
%med
fprintf('%f,%f\n', meanOfLastFour, med)