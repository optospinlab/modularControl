function nvRecTesting()
    data = load('/Users/I/Downloads/Fall 2016 Annealing (Mike)/fall 2016 annealing (mike)-1/2016_12_12 Implanted PLE (hopeful)/cvd7_imaging_area_initial_zoom.mat');
    
    d = data.data.data;
    
    data.data
    
    s1 = medfilt2(d);
    s2 = wiener2(d, [3 3]);
    
    figure;
    
%     subplot(2, 5, 1); imagesc(s1);
%     subplot(2, 5, 2); imagesc(s1 .* (imregionalmax(s1) == 0));
%     subplot(2, 5, 3); imagesc(s1 .* (imregionalmax(s1) == 0 | s1 < quantile(s1(:), .75)));
%     subplot(2, 5, 4); imagesc(s1 .* (~imclearborder(imregionalmax(s1)) | s1 < quantile(s1(:), .75)));
%     subplot(2, 5, 5); imagesc(s1 .* (imclearborder(imregionalmax(s1)) & s1 > quantile(s1(:), .75)));
%     
%     subplot(2, 5, 6); imagesc(s2);
%     subplot(2, 5, 7); imagesc(s2 .* (imregionalmax(s2) == 0));
%     subplot(2, 5, 8); imagesc(s2 .* (imregionalmax(s2) == 0 | s2 < quantile(s2(:), .75)));
%     subplot(2, 5, 9); imagesc(s2 .* (~imclearborder(imregionalmax(s2)) | s2 < quantile(s2(:), .75)));
%     subplot(2, 5, 10); imagesc(s2 .* (imclearborder(imregionalmax(s2)) & s2 > quantile(s2(:), .75)));
    
    r = regionprops(imclearborder(imregionalmax(s2)) & s2 > quantile(s2(:), .75), s2, 'Centroid', 'MaxIntensity');
    
    c = cat(1, r.Centroid);
    
    [~, sorted] = sort(cat(1, r.MaxIntensity), 'descend');
    
    xind = c(sorted,1);
    yind = c(sorted,2);
    
    xvals = data.data.xrange(xind);
    yvals = data.data.yrange(yind);
    
    unitx = abs(data.data.xrange(2) - data.data.xrange(1))    % Make sure length is greater than 1?
    unity = abs(data.data.yrange(2) - data.data.yrange(1))
    
    imagesc(data.data.xrange, data.data.yrange, d);
    daspect([1 1 1])
    
    hold all;
    
    nums = 1:length(xvals);
    
    for ii = nums
        text(xvals(ii), yvals(ii), num2str(ii), 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center', 'color', 'red')
        
        taxi = abs(xind - xind(ii)) + abs(yind - yind(ii));
        
        halfsquarewid = ceil(min(taxi(taxi ~= 0))/4) + .5;
        
        plot(unitx * halfsquarewid * [1 1 -1 -1 1] + xvals(ii), unity * halfsquarewid * [1 -1 -1 1 1] + yvals(ii), 'red')
    end
end




