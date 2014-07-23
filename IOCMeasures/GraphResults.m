function [] = GraphResults(ts, sds, id, labels, noiseContrasts)
%GRAPHRESULTS TODO finish documentation
% Details here
% TODO parameterize choice of confidence interval vs std error
    % draw results
    figure;
    hold on;
    sigContrasts = 10.^ts;
    seriesCount = size(sigContrasts, 1);
    
    % 95% conf interval
    %upper = 10.^(ts + norminv(1-(1-.95)/2)*sds) - sigContrasts;
    %lower = sigContrasts - 10.^(ts - norminv(1-(1-.95)/2)*sds);
    
    % 1 std error
    upper = 10.^(ts + sds) - sigContrasts;
    lower = sigContrasts - 10.^(ts - sds);
    
    %TODO FIXME parameterize
%     cols = 'bcrm'; % parameterize this
%     style = cell(1, size(sigContrasts, 1));
%     for i=1:size(sigContrasts, 1)
%         if i <= (size(sigContrasts,1)/2)
%             style{i} = [cols(i) '-'];
%         else
%             style{i} = [cols(size(sigContrasts,1)-i+1) '--'];
%         end
%     end
    lines = {'b-', 'c-', 'r-', 'm-', 'm--', 'r--', 'c--', 'b--'};
    for i=1:seriesCount
        errorbar((1:size(sigContrasts,2)) ...
            + (i-floor(seriesCount/2))*0.025, ... % stagger slightly
            sigContrasts(i,:), lower(i,:), upper(i,:), lines{i});
    end
    
    % make bottom edge of plot always at x axis
    xxyy = axis;
    xxyy(3) = 0;
    axis(xxyy);
    
    % Label figure
    set(gca,'XTick',1:4);
    noiseContrastLabels = cell(1, length(noiseContrasts));
    for i=size(noiseContrastLabels,2)
        noiseContrastLabels{i} = sprintf('%.2f', noiseContrasts(i));
    end
    set(gca,'XTickLabel',noiseContrastLabels);
    xlabel('Contrast of noise dots');
    ylabel('Contrast threshold of signal dots');
    if exist('id', 'var')
        title(['Signal contrast thresholds - ' id]);
    else
        title('Signal contrast threshold');
    end
    
    legend(labels{1:size(sigContrasts)}, 'Location', 'NW');
    
    hold off;
end
