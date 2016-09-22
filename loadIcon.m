function CData = loadIcon(file)
    [CData, map, alpha] = imread(fullfile('icons', file));
%     map
%     map(:,:,1)+map(:,:,2)+map(:,:,3) == 0
    index = map(:,:,1)+map(:,:,2)+map(:,:,3) == 0 | map(:,:,1)+map(:,:,2)+map(:,:,3) == 3*255
    
%     map(alpha == 0) = NaN     % Turns values that are black or white transparent...
    
    alpha
%     CData = map;
end

