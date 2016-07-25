function peakFinderTest()
gauss = @(x, a, b, c)( a*exp(-c.*(x-b).^2));


x = 1:512;

going2 = true;


    f = figure;
    a = axes;
    
while going2
    y = gauss(1:512, 20+rand*20, rand*512, 1/(100 + 200*rand)^2) + 10*rand([1, 512]);
    hold off
    plot(a, x, y)
    hold on
    % plot(a, diff(y))
    % plot(a, y(1:2:end) + y(2:2:end))
    % plot(a, y(1:4:end) + y(2:4:end) + y(3:4:end) + y(4:4:end))

%     std(y)

    % bins  = length(y);
    ii = 1;
    div = 1;

    going = true;
    
    y2 = y;
    
    std1 = std(y - movmean(y, length(y)/2));

%     while going
%     %     x2 = linspace(1, length(y), length(y)/div) %histcounts(x, length(y)/div)/div
%     %     y2 = histcounts(y, length(y)/div);
% 
%     %     y2 = discretize(y, linspace(1, length(y), length(y)/div + 1))
%         y2 = .5*y2 + movmean(y, div);
% 
%         [pks{ii}, locs{ii}, wids{ii}] = findpeaks(y2, x, 'MinPeakWidth', 5, 'MinPeakProminence', std1, 'SortStr', 'ascend','Annotate','extents','WidthReference','halfheight'); % 
% 
%     plot(x, y2);
%         hold on
%         plot(a, locs{ii},pks{ii},'o','MarkerSize',ii*4)
%     pause(1);
% 
%         length(pks{ii});
% 
%         going = (length(pks{ii}) > 1 || ii < 8) && ~isempty(pks{ii});
%     %     going = ii < 5;
% 
%         ii = ii + 1;
% 
%     %     bins = bins/2
%         div = div*2;
%     end

    plot(x, movmean(y, length(y)/2));
    
    [pks, locs, wids] = findpeaks(movmean(y, length(y)/2), x, 'MinPeakWidth', 3, 'MinPeakProminence', std1, 'SortStr', 'ascend')
    
    ft = fittype('a*exp(-((x-b)^2)/c)');
    
    cf = fit(x, y, ft, 'StartPoint', [pks(1), locs(1), wids(1)])
    
    plot(x, y2);
    if isempty(locs{ii-1})
        X = locs{ii-2}(1);
    else
        X = locs{ii-1};
    end
    
    plot([X,X], [min(y)-5, max(y)+5]);
            
    pause(2);
end
end




