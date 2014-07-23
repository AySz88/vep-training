function [ newTs, newSDs, oldTs, oldSDs ] = Reanalyze( folder )
%REANALYZE Merges staircases and reanalyzes
%   Pass in the name of a folder in the data/ directory, or a partial name
%   If the partial name matches multiple folders, all results from those
%       folders will be merged (FIXME TODO - DOESN'T WORK YET)
%   TODO allow passing in array to merge all folders in the array

    DATAFOLDER = 'data/';
    SFILE = '/Ss.mat';
    % hardcoded labels in older pilot data ~9/23-26/11
    labels = {'Monocular (both in right)', ... 
        'Dichoptic (noise left, signal right)', ...
        'Dichoptic (2nd time)', ...
        'Monocular (2nd time)'};
    
    if exist(folder, 'file') == 7
        % Reanalyze a single session of data
        Ss = importdata([folder SFILE]);

        % Import data and strings for labelling
        if exist([folder '/labels.mat'], 'file') == 2
            labels = importdata([folder '/labels.mat']);
        end
        dirtylog = load('-ascii', [folder '/dirtylog.mat']);
        noiseContrasts = 10.^(unique(max(dirtylog(:,3), dirtylog(:,4))));

        % Redraw old figure for comparison
        oldTs = importdata([folder '/ts.mat']);
        oldSDs = importdata([folder '/sds.mat']);
        GraphResults(oldTs, oldSDs, folder, labels, noiseContrasts);
    else
        % Find matching directories and merge all matches
        listing=dir([DATAFOLDER '*' folder '*']);
        
        fprintf('Directories matching %s: %i\n', folder, length(listing));
        
        if length(listing) == 1
            % Don't merge, just call with the "right" name
            newFolder = [DATAFOLDER listing.name];
            [newTs, newSDs] = Reanalyze(newFolder);
            return;
        end
        
        % Merge several sessions of data for analysis
        
        psychassert(false, 'Reanalyze:NotUnique', ...
            'Merging multiple experimental sessions not yet implemented');
        
        % FIXME TODO - MERGING NOT YET IMPLEMENTED
        % assumes 4x4 blocks, need to generalize
        Ss = cell(4, 4*length(listing));
        for i = 1:length(listing)
            thisListing = listing(i);
            path = [DATAFOLDER thisListing.name '/' SFILE];
            Ss(:, (4*i-3):4*i) = importdata(path);
            % TODO also pull labels
        end
    end
    
    % Initialize new structures
    newTs = zeros(size(Ss,1)/2, size(Ss,2));
    newSDs = zeros(size(Ss,1)/2, size(Ss,2));
    subplotargs = {size(Ss,1)/2, size(Ss,2)};
    figure;
    subplot(subplotargs{:}, 1);
    fprintf('\t  t     upper   lower\n');
    
    for i=1:(size(Ss, 1)/2)
        for j=1:size(Ss, 2)
            plotNum = (j-1)*(size(Ss, 1)/2) + i;
            subplot(subplotargs{:}, plotNum);
            thisPlotTitle = sprintf('%s, noise contrast %.2f', ...
                labels{i}, noiseContrasts(j));
            title(thisPlotTitle);
            fprintf('%s\n', thisPlotTitle);
            
            % Load previous data
            S1 = Ss{i,j};
            t1 = QuestMean(S1.q);
            sd1 = QuestSd(S1.q);
            fprintf('1st\t%2.3f\t%2.3f\t%2.3f\n', ...
                10^t1, 10^(t1+sd1), 10^(t1-sd1));
            S2 = Ss{size(Ss,1)-i+1, j};
            t2 = QuestMean(S2.q);
            sd2 = QuestSd(S2.q);
            fprintf('2nd\t%2.3f\t%2.3f\t%2.3f\n', ...
                10^t2, 10^(t2+sd2), 10^(t2-sd2));
            
            %fprintf('%i,%i with %i,%i', ...
            % i, j, size(Ss,1)-i+1, size(Ss,2)-j+1);
            
            % Merge QUEST objects
            q = S1.q;
            
            vals = S2.trialVals;
            corrects = cell2mat(S2.trialLog(:,2));
            
            for k=1:length(vals)
                q = QuestUpdate(q, vals(k), corrects(k));
            end
            
            t = QuestMean(q);
            sd = QuestSd(q);
            
            fprintf('cmb\t%2.3f\t%2.3f\t%2.3f\n', ...
                10^t, 10^(t+sd), 10^(t-sd));
            newTs(i,j) = t;
            newSDs(i,j) = sd;
            
            % Find x-axis range most relevant for plotting/binning
            % TODO find a fitted beta first!
            spreadProbs = [q.gamma+0.01, 1-(1-q.gamma)*q.delta-0.01];
            spreadPoints = 1/q.beta * log10( log( ...
                (1-q.delta)*(1-q.gamma) ...
                ./ (q.delta*q.gamma + 1 - q.delta - spreadProbs)));
            range = 10.^(t+2*spreadPoints);
            
            % Bin first S
            % TODO variable/parameterize # of bins?
            binSize = (range(2)-range(1))/10;
            edges = range(1):binSize:range(2);
            vals = 10.^S1.trialVals;
            corrects = cell2mat(S1.trialLog(:,2));
            
            rightBins = histc(vals(corrects), edges);
            totalBins = histc(vals, edges);
            
            % Bin second S
            vals = 10.^S2.trialVals;
            corrects = cell2mat(S2.trialLog(:,2));
            
            rightBins = rightBins + histc(vals(corrects), edges);
            totalBins = totalBins + histc(vals, edges);
            
            percentBins = rightBins ./ totalBins;
            
            % Plot psychometric function
            % TODO FIXME plot using a re-fit beta!!
            qNew = QuestCreate(t, sd, q.pThreshold, ...
               q.beta, q.delta, q.gamma, q.grain, q.dim*q.grain);
            hold on
            plot(10.^(qNew.x2+qNew.tGuess), qNew.p2);
            
            %TODO FIXME parameterize 95% confidence vs 1 standard error
            
            % 95% conf interval
            % lowers = percentBins - ...
            %     binoinv(0.025, totalBins, percentBins) ./ totalBins;
            % uppers = binoinv(0.975, totalBins, percentBins) ./ totalBins...
            %     - percentBins;
            
            % one standard error
            % simplifed of sqrt(percent .* (1-percent) .* total) / total
            lowers = sqrt(percentBins .* (1-percentBins) ./ totalBins);
            uppers = lowers;
            
            errorbar(edges, percentBins, lowers, uppers);
            
            hold off
            axis([range, .4, 1]);
        end
    end
    
    GraphResults(newTs, newSDs, folder, labels, noiseContrasts);
end
