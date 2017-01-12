function peakFinderTest()
gauss = @(x, a, b, c)( a*exp(-c.*(x-b).^2));


x = 1:512;

going2 = true;


    f = figure;
    a = axes;
    
while going2
    y = gauss(1:512, 20+rand*20, rand*512, 1/(100 + 200*rand)^2) + gauss(1:512, 20+rand*20, rand*512, 1/(10 + 20*rand)^2) + gauss(1:512, 20+rand*20, rand*512, 1/(40 + 0*rand)^2) + 10*rand([1, 512]);
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

    plot(x, movmean(y, round(length(y)/10)));
    pause(.1);
    
    pks = []
    
    prom = std1*3
    
    while isempty(pks)
        [pks, locs, wids] = findpeaks(movmean([min(y) y min(y)], round(length(y)/10)), [0 x max(x)+1], 'MinPeakWidth', 3, 'MinPeakProminence', prom, 'SortStr', 'descend')
        prom = prom*.5
    end
    
    [X, ~] = myMeanAdvanced(y', x', 0);
    
    plot([X,X], [min(y)-5, max(y)+5]);
    
%     locs = locs(1) - 1;
%     X = locs(1);
%     
%     plot([X,X], [min(y)-5, max(y)+5]);
%     
%     rx = round(abs(x(end) - x(1))/20)
%     [~, m] = max(y);
%     
%     smally = (x > x(m) - rx & x < x(m) + rx)
%     [~, sm] = max(movmean(y(smally),rx));
%     sx = x(smally);
%     X = sx(sm);
%     
%     
%     plot([X,X], [min(y)-5, max(y)+5]);
    
%     ft = fittype('a*exp(-((x-b)^2)/c)');
%     
%     cf = fit(x', y', ft, 'StartPoint', [pks(1), locs(1), wids(1)], 'Lower', [0, min(x), 0], 'Upper', [2*(max(y) - min(y)), max(x), Inf]);
%     
%     vals = coeffvalues(cf)
%     
%     plot(x, y2);
%     plot(cf);
%     if isempty(locs{ii-1})
%         X = locs{ii-2}(1);
%     else
%         X = locs{ii-1};
%     end
%     X = vals(2);
%     
%     plot([X,X], [min(y)-5, max(y)+5]);
            
    pause(1);
end
end



    function [x, y] = myMean(data, X, Y)
        % Note that this will yield an error if data is all zero. This is purposeful.
        % New Method
        dim = size(data);
        
        data = data ~= 0;
    
        data = imdilate(data, strel('diamond', 2));

        [labels, ~] = bwlabel(data, 8);
        measurements = regionprops(labels, 'Area', 'Centroid');
        areas = [measurements.Area];
        [~, indexes] = sort(areas, 'descend');

        centroid = measurements(indexes(1)).Centroid;
        
        if sum(dim == 1) == 1
            x = linInterp(1, X(1), dim(1), X(dim(1)), max(centroid));
            y = 0;
        else
            x = linInterp(1, X(1), dim(2), X(dim(2)), centroid(1));
            y = linInterp(1, Y(1), dim(1), Y(dim(1)), centroid(2));
        end
    
        % Old Method
        % Calculates the centroid.
%         total = sum(sum(data));
%         dim = size(data);
%         x = sum(data*((X((length(X)-dim(2)+1):end))'))/total;
%         y = sum((Y((length(Y)-dim(1)+1):end))*data)/total;
    end
    function [x, y] = myMeanAdvanced(final, X, Y)
        m = min(min(final)); M = max(max(final));
        if m ~= M
            data = (final - m)/(M - m);

            list = .5:.05:.95;

            X0 = []; % zeros(1, length(list));
            Y0 = []; % zeros(1, length(list));

%             i = 1;

            for threshold = list
                try
                    [a, b] = myMean(data.*(data > threshold), X, Y);
                    
                    X0 = [X0 a];
                    Y0 = [Y0 b];
                    
%                     i = i+1;
                catch err
                    display(err.message);
                end
            end
            
            if isempty(X0) || isempty(Y0)
                try
                    [x, y] = myMean(data.*(data == 1), X, Y);
                catch err
                    display(err.message);
                    
                    x = mean(X);
                    y = mean(Y);
                end
            else
                dim = size(data);
                if sum(dim == 1) == 1
                    while std(X0) > abs(X(1) - X(2))
                        D = ((X0 - mean(X0)).^2);

                        [~, idx] = max(D);

                        X0(idx) = [];

%                         display('      outlier removed');
                    end
                else
                    while std(X0) > abs(X(1) - X(2)) || std(Y0) > abs(Y(1) - Y(2))
                        D = ((X0 - mean(X0)).^2) + ((Y0 - mean(Y0)).^2);

                        [~, idx] = max(D);

                        X0(idx) = [];
                        Y0(idx) = [];

                        display('      outlier removed');
                    end
                end

                x = mean(X0);
                y = mean(Y0);
            end
        else
            x = mean(X);
            y = mean(Y);
        end
    end
    function y = linInterp(x1, y1, x2, y2, x)    % Perhaps make it a spline in the future...
        if x1 < x2
            y = ((y2 - y1)/(x2 - x1))*(x - x1) + y1;
        elseif x1 > x2
            y = ((y1 - y2)/(x1 - x2))*(x - x2) + y2;
        else
            y = (y1 + y2)/2;
        end
    end
