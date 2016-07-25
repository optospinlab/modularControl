classdef mcProcessedData < handle
% mcProcessedData contains, as the name might suggest, a processed version
% of data stored in a mcData structure. The data can be 1D (plot) or 2D
% (colormap) (and maybe eventually 3D). The parent mcData structure is
% referenced in 'parent'. The data that is processed is 'data'. The
% parameters that define the proccessing procedure is defined in 'params'.
%
% Syntax:
%   pd = mcProcessedData(parent)            % Proccess data with default settings
%   pd = mcProcessedData(parent, params)    % Proccess data with settings defined by 'params'
    
    properties (SetObservable)
        data = [];
    end

    properties
        parent = [];
        
        params = [];
        
        needsRendering = false;
    end
    
    methods (Static)
        function params = defaultParams()
            params.plotMode = 0;       % 0=Don't do anything; {1, '1D'}=plot 1D vector (lineplot); {2, '2D'}=plot 2D image (colormap)
            params.inputIndex = 0;
            params.axisIndex = [0 0 0]; % X Y Z (not all used)
            
%             error('defaultParams() NotImplemented');
        end
    end
    
    methods
        function pd = mcProcessedData(varin)
            if nargin == 1
                pd.parent = varin;
                pd.params = mcProcessedData.defaultParams();
            elseif nargin == 2
                pd.parent = varin{1};
                pd.params = varin{2};
            end
            
        end
        
        function m = min(pd)
            m = min(min(min(pd.data)));
        end
        function M = max(pd)
            M = max(max(max(pd.data)));
        end
        
        function parentChanged_Callback(pd, ~, ~)
            
        end
        
        function process(pd)
            if exists(pd.parent.dataViewer)    % If there is a dataViewer...
                switch params.plotMode
                    case {1, '1D'}
                        
                    case {2, '2D'}
                        
                    case {3, '3D'}
                        error('3D NotImplemented');
                    otherwise
                        error('Plotmode not recognized...');
                end
            else
                error('NotImplemented: mcProcessedData must have a data viewer (and not sure if it should be implemented)');
            end
        end
    end
    
end


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


