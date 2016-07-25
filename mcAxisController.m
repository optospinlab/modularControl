function [data, returnCellArray] = mcScan(params)
    % Content of params:
    %   - params.axes is a cell array containing the mcAxes objects that will be scanned.
    %   - params.scans is a cell array containing the arrays of values that will be scanned
    %       across for each axis. e.g. if X = [1 2 3 4] and Y = [4 5 6 7] then the scan will
    %       be a 4 x 4 image of the 1:4, 4:7 region.
    %   - params.exposure contains the time (in seconds) that each pixel is exposed.
    %   - params.inputs is a cell array containing the mcInput objects that are read at every pixel.

    if length(params.axes) ~= length(params.scans)
        error('Axes and scans must the same length...');
    end

    if ~iscell(params.axes),        error('Axes must be a cell array...');  end
    if ~iscell(params.scans),       error('Scans must be a cell array...'); end
    
    pixels = ones(1, length(params.axes));

    for ii = 1:length(params.axes)
        if params.axes{ii}.inRange(params.scans{ii})
            error(['The scan range for ' params.axes{ii}.name() ' is invalid...']);
        end
        
        pixels(ii) = length(params.scans{ii});
    end

    if isempty(params.inputs)
        error('Inputs is empty, but there must be something to scan!');
    elseif length(params.inputs) > 1
        returnCellArray = 1;
    elseif params.inputs.isSingleton()
        returnCellArray = 0;
    else
        returnCellArray = 1;
    end

    if returnCellArray
        data = cell(pixels);
    else
        data = NaN(pixels);
    end
    
    
end

















