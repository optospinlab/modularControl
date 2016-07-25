function tf = mcViewNDScan(data, params)

    switch lower(plotMode)
        case {1, '1d'}
            
        case {2, '2d'}
            if params.isRGB
                
            else
                [c, x, y] = getNumeric2DSlice(data, paramsND, input, axisX, axisY, layer, ifInputNotSingularFnc)
            
                imagesc(x, y, c, 'alphadata', ~isnan(r));
            end
        case {3, '3d'}
            error('3D plotMode Not Implemented');
        otherwise
            error('plotMode not understood');
    end
end

function [c, x, y] = getNumeric2DSliceFromOneAxis(data, paramsND, input, axisX, layer, ifInputNotSingularFnc)

end

function [c, x, y] = getNumeric2DSlice(data, paramsND, input, axisX, axisY, layer, ifInputNotSingularFnc)
    if      ischar(axisX) && ischar(axisY)
        warning('NotImplemented')
    elseif  isobject(axisX) && isobject(axisY)
        warning('NotImplemented')
    elseif  isnumeric(axisX) && isnumeric(axisY) && sum(size(axisX)) == 2 && sum(size(axisY)) == 2
        axisXindex = axisX;
        axisYindex = axisY;
    end
    
%     c =     NaN(paramsND.lengths(axisXindex), paramsND.lengths(axisYindex));
%     cnorm = NaN(paramsND.lengths(axisXindex), paramsND.lengths(axisYindex));
    
    x =     paramsND.ranges(axisXindex);
    y =     paramsND.ranges(axisYindex);

    if paramsND.isInputBeginEnd(axisXindex)         % If the axis is a beginend input...
        error('NotImplemented');
        
%         b = data.begin{input};
%         e = data.end{input};
%         
%         if paramsND.isInputSingular(axisXindex)     % If b and e will be numeric...
%             c = 
%         else                                        % Otherwise if b and e will be cell...
%             b = cell2mat( cellfun(ifInputNotSingularFnc, b) );
%         end
    else                                            % ...Otherwise, if it is an everypoint input...
        d = data.data{input};
        
        if paramsND.isInputSingular(axisXindex)     % If d will be numeric...
            c = d( getIndex(paramsND.lengths, axisXindex, axisYindex, layer) );
        else                                        % Otherwise if d will be cell...
            c = cell2mat( cellfun(ifInputNotSingularFnc, d{ getIndex(paramsND.lengths, axisXindex, axisYindex, layer) }) );
        end
    end
end

function output_txt = labeldtips(obj,event_obj)
% Display an observation's Y-data and label for a data tip
% obj          Currently not used (empty)
% event_obj    Handle to event object
% xydata       Entire data matrix
% labels       State names identifying matrix row
% xymean       Ratio of y to x mean (avg. for all obs.)
% output_txt   Datatip text (string or string cell array)
% This datacursor callback calculates a deviation from the
% expected value and displays it, Y, and a label taken
% from the cell array 'labels'; the data matrix is needed
% to determine the index of the x-value for looking up the
% label for that row. X values could be output, but are not.

    pos = get(event_obj,'Position');
    x = pos(1); y = pos(2);

%     global xaxis yaxis raxis gaxis baxis zaxis isRGB plotMode

    switch lower(plotMode)
        case {1, '1d'}
            output_txt =   {[xaxis.label() ': ' num2str(x)], ...
                            [yaxis.label() ': ' num2str(y)]};
        case {2, '2d'}
            if isRGB
                output_txt =   {[xaxis.label() ': ' num2str(x)], ...
                                [yaxis.label() ': ' num2str(y)], ...
                                [raxis.label() ': ' num2str(z)], ...
                                [gaxis.label() ': ' num2str(z)], ...
                                [baxis.label() ': ' num2str(z)]};
            else
                output_txt =   {[xaxis.label() ': ' num2str(x)], ...
                                [yaxis.label() ': ' num2str(y)], ...
                                [zaxis.label() ': ' num2str(z)]};
            end
        case {3, '3d'}
            error('3D plotMode Not Implimented');
        otherwise
            error('plotMode not understood');
    end


    idx = find(xydata == x,1);  % Find index to retrieve obs. name

% The find is reliable only if there are no duplicate x values
% [row,col] = ind2sub(size(xydata),idx);

end




