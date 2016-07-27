classdef mcProcessedData < handle
% mcProcessedData contains, as the name might suggest, a processed version
% of data stored in a mcData structure. The data can be 1D (plot) or 2D
% (colormap) (and maybe eventually 3D). The parent mcData structure is
% referenced in 'parent'. The data that is processed is 'data'. The
% parameters that define the proccessing procedure is defined in 'params'.
%
% Syntax:
%   pd = mcProcessedData(parent)            % Proccess parent data (mcData) with default settings
%   pd = mcProcessedData(parent, params)    % Proccess parent data (mcData) with settings defined by 'params'
    
    properties
        parent = [];
        viewer = [];
        
        params = [];
        
        listener = [];
    end
    properties (SetObservable)
        data = NaN;
    end
    
    methods (Static)
        function params = defaultParams()
            params.plotMode = 0;       % 0=Don't do anything; {1, '1D'}=plot 1D vector (lineplot); {2, '2D'}=plot 2D image (colormap)
            params.inputIndex = 0;
            params.layerIndex = []; % X Y Z (not all used)
            
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
            
            prop = findprop(mcData, 'data');
            pd.listener = event.proplistener(pd.parent, prop, 'PostSet', @pd.parentChanged_Callback);
        end
        
        function m = min(pd)
            m = min(min(min(pd.data)));
        end
        function M = max(pd)
            M = max(max(max(pd.data)));
        end
        
        function parentChanged_Callback(pd, ~, ~)
            pd.process();
        end
        
        function process(pd)
%             disp('here');
%             if exists(pd.parent.dataViewer)    % If there is a dataViewer...
                switch pd.parent.data.plotMode
                    case {1, '1D'}
                        
                    case {2, '2D'}
                        
                        nums = 1:pd.parent.data.numAxes;
                        
                        axisXindex = nums(pd.parent.data.layer == 1);
                        axisYindex = nums(pd.parent.data.layer == 2);
        
                        d = pd.parent.data.data{pd.parent.data.input};
                        
                        if pd.parent.data.inputDimension(pd.parent.data.input) == 0     % If d will be numeric...
%                             getIndex(pd.parent.data.lengths, axisXindex, axisYindex, pd.parent.data.layer - 2)
                            pd.data = d( getIndex(pd.parent.data.lengths, axisXindex, axisYindex, pd.parent.data.layer - 2) );
                        else                                        % Otherwise if d will be cell...
%                             c = cell2mat( cellfun(ifInputNotSingularFnc, d{ getIndex(paramsND.lengths, axisXindex, axisYindex, layer) }) );
                            error('NotImplemented');
                        end
                    case {3, '3D'}
                        error('3D NotImplemented');
                    otherwise
                        error('Plotmode not recognized...');
                end
%             else
%                 error('NotImplemented: mcProcessedData must have a data viewer (and not sure if it should be implemented)');
%             end
        end
    end
    
end




