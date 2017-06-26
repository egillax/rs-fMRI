% ------------------------------------------------------------------------------
% Ben Fulcher, 2014-08-21 (Edited: Linden Parkes)
% ------------------------------------------------------------------------------
% Plots a scatter of a set of distributions with data offset randomly in x
% input is a cell with each element containing a collection of data.
% ------------------------------------------------------------------------------

function JitteredParallelScatter(dataCell,addMeans,doveTail,makeFigure,extraParams)

if nargin < 2
    addMeans = 1;
    % Add strip for mean of each group by default
end

if nargin < 3
    doveTail = 1;
    % Add kernel distribution
end

if nargin < 4
    makeFigure = 1;
end

if nargin < 5
    extraParams = struct;
end

% ------------------------------------------------------------------------------
% Set extra parameters

numGroups = length(dataCell);

% Custom marker for points within the distribution:
if ~isfield(extraParams,'customSpot')
    customSpot = 'o';
else
    customSpot = extraParams.customSpot;
end

% Custom x-offset
if ~isfield(extraParams,'customOffset')
    customOffset = 0;
else
    customOffset = extraParams.customOffset;
end

% Custom offset range; width of each jitter:
% (proportion of each consecutive unit interval to use for the plot)
if ~isfield(extraParams,'offsetRange')
    offsetRange = 0.5;
else
    offsetRange = extraParams.offsetRange;
end

% Custom colormap
if ~isfield(extraParams,'theColors')
    if numGroups == 2
        theColors = BF_getcmap('set1',numGroups,1);
    else
        theColors = BF_getcmap('linden',numGroups,1);
    end
    if length(theColors) < numGroups
        theColors = arrayfun(@(x)zeros(3,1),1:numGroups,'UniformOutput',0);
    end
else
    theColors = extraParams.theColors;
end

% Custom x axis labels
if ~isfield(extraParams,'theLabels')
    theLabels = [];
else
    theLabels = extraParams.theLabels;
end

% add zero line
if ~isfield(extraParams,'add0Line')
    add0Line = false;
else
    add0Line = extraParams.add0Line;
end

% ------------------------------------------------------------------------------

% Reset random number generator for reproducibility:
rng('default');

if makeFigure
    figure('color','w');
end
hold on; box('on');

% ------------------------------------------------------------------------------
% Add kernel distribution
% ------------------------------------------------------------------------------
if doveTail
    ff = cell(numGroups,1);
    xx = cell(numGroups,1);
    for i = 1:numGroups
        if isempty(dataCell{i})
            continue
        end
        if any(isnan(dataCell{i}))
            warning('NaNs in dataCell')
        end
        [f, x] = ksdensity(dataCell{i},'npoints',500);
        f = f/max(f);
        % Only keep range where data exists:
        minKeep = max([1,find(x>=min(dataCell{i}),1,'first')]);
        maxKeep = min([length(x),find(x>=max(dataCell{i}),1,'first')]);
        keepR = minKeep:maxKeep;
        % keepR = (x>=min(dataCell{i}) & x<=max(dataCell{i}));
        x = x(keepR);
        f = f(keepR);
        h1 = plot(customOffset+i+f*offsetRange/2,x,'-','color',theColors{i},'LineWidth',2);
        h2 = plot(customOffset+i-f*offsetRange/2,x,'-','color',theColors{i},'LineWidth',2);
        
%         if i == 1
%             h1.LineStyle = '-';
%             h2.LineStyle = '-';
%         elseif i == 2
%             h1.LineStyle = '--';
%             h2.LineStyle = '--';
%         elseif i == 3
%             h1.LineStyle = ':';
%             h2.LineStyle = ':';
%         end
        
        % Plot top and bottom
        plot(customOffset+i+[-f(1),+f(1)]*offsetRange/2,min(x)*ones(2,1),'-','color',theColors{i},'LineWidth',0.1)
        plot(customOffset+i+[-f(end),f(end)]*offsetRange/2,max(x)*ones(2,1),'-','color',theColors{i},'LineWidth',0.1)
        
        % Keep for dovetailing the jittered scatter points:
        xx{i} = x; ff{i} = f;
    end
end

% ------------------------------------------------------------------------------
% Plot jittered scatter for each group
% ------------------------------------------------------------------------------
if ~isempty(customSpot)
    for i = 1:numGroups
        if doveTail
            xRand = zeros(length(dataCell{i}),1);
            for j = 1:length(dataCell{i})
                try
                    xRand(j) = (rand(1)*offsetRange-offsetRange/2)*ff{i}(find(xx{i} >= dataCell{i}(j),1));
                end
            end
            %i + rand([length(dataCell{i}),1])*offsetRange-offsetRange/2;
        else
            xRand = rand([length(dataCell{i}),1])*offsetRange-offsetRange/2;
        end
        plot(customOffset + i + xRand,dataCell{i},customSpot,'color',theColors{i},'MarkerFaceColor',theColors{i})
    end
end

% ------------------------------------------------------------------------------
% Add strips for means and stds:
% ------------------------------------------------------------------------------
brightenAmount = -0.3;
if any(cellfun(@(x)any(isnan(x)),dataCell)), warning('NaNs in data'); end
for i = 1:numGroups
    try
        brightColor = brighten(theColors{i},brightenAmount);
    catch
        brightColor = theColors{i};
    end
    
    plot([customOffset + i - offsetRange/2,customOffset + i + offsetRange/2],nanmean(dataCell{i})*ones(2,1),'-',...
                            'color',brightColor,'LineWidth',2)
    % plot([customOffset + i - offsetRange/2,customOffset + i + offsetRange/2],(nanmean(dataCell{i})-nanstd(dataCell{i}))*ones(2,1),'--',...
    %                         'color',brightColor,'LineWidth',2)
    % plot([customOffset + i - offsetRange/2,customOffset + i + offsetRange/2],(nanmean(dataCell{i})+nanstd(dataCell{i}))*ones(2,1),'--',...
    %                         'color',brightColor,'LineWidth',2)

    % plot([customOffset + i - offsetRange/2,customOffset + i + offsetRange/2],nanmedian(abs(dataCell{i}))*ones(2,1),'-',...
    %                         'color',brightColor,'LineWidth',2)

end

% ------------------------------------------------------------------------------
% Add dotted line at 0
% ------------------------------------------------------------------------------
if add0Line
    plot([0:numGroups+1],zeros(1,numGroups+2),':','Color','k')
end

% ------------------------------------------------------------------------------
% Add custom x axis labels
% ------------------------------------------------------------------------------
if ~isempty(theLabels)
    set(gca,'XTick',1:length(theLabels),'XTickLabel',theLabels,'FontSize',12)
    xlim([0 length(theLabels) + 1])
    ax = gca;
    ax.XTickLabelRotation = 0;
end


end