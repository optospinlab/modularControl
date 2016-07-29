function peakFinderTest()
sine = @(x, a, b, c)( a*sin(c.*(x-b)));


x = 1:512;

going2 = true;


    f = figure;
    a = axes;
    
while going2
    a = 20+rand*20;
    b = rand*512;
    c = 1/(20 + rand*20);
    y = sine(1:512, a, b, c) + 10*rand([1, 512]);
    
    hold off
    plot(x, y);
    hold on
    
    y = sine(1:512, a, b, abs(meanfreq(y)/pi));
            
    plot(x, y);
    
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

%             try
%                 [mx, my] = myMean(data.*(data == 1), X, Y);
% 
%     %             data = data*
% 
%                 dim = size(data);
%     %             factor = zeros(dim(1));
% 
%                 for x1 = 1:dim(1)
%                     for y1 = 1:dim(1)
%                         data(y1, x1) = data(y1, x1)/(1 + (X(x1) - mx)^2 + (Y(y1) - my)^2);
%                     end
%                 end
%                 
%                 m = min(min(data)); M = max(max(data));
% 
%                 if m ~= M
%                     data = (data - m)/(M - m);
%                 end
%             
%             catch err
%                 display(['Attenuation failed: ' err.message]);
%             end

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
