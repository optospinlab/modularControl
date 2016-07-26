function index = getIndex(lengths, x, y, layer)
    % We want to get a 2D slice of an ND matrix with dimensions layers 
    % (e.g. layers = [3 4 5] ==> a 3 x 4 x 5 matrix.  This 2D slice will be
    % in the x-y plane where x is the xth dimension and y is the yth
    % dimenstion (e.g. x=1,y=2 ==> slice in 1-2 plane). Layer fixes the
    % position of the slice in the other dimensions; the returned slice
    % will always pass through the point layer in ND space (note that the
    % xth and yth components of layer do not matter, of course).
    
    if length(lengths) < 2
        error('Cannot find a 2D slice of a 0D or 1D matrix');
    end
    
    if length(lengths) ~= length(layer)
        error('layer should be the same length as lengths.');
    end
    
%     if sum(lengths < layer | layer > 1)
%         error('layer should be bounded by lengths.');
%     end

    indexWeight = getIndexWeight(lengths);
    
    lx = lengths(x);
    ly = lengths(y);
    
    indexSize = lx*ly;
    
    if x > y
        repWeight = indexWeight(y)*lx;
    else
        repWeight = -indexWeight(y)*ly + indexWeight(x);
    end
    
    nums = 1:length(lengths);
    offset = indexWeight * ((layer - 1).* (nums ~= x & nums ~= y))';
    
    index = reshape(1:indexWeight(y):indexSize*indexWeight(y), ly, lx) + repmat(repWeight*(0:(lx-1)) + offset, ly, 1);
end

function indexWeight = getIndexWeight(lengths)  % Name this something different? This indexWeight is different from the one in mcNDScan.
    l = length(lengths);
    
    indexWeight = ones(1, l);
    
    for ii = 2:l
        indexWeight(ii:end) = indexWeight(ii:end)*lengths(ii-1);
    end
end

