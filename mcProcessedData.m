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
%
% Status: Mostly finished, but has no clue what to do when data is not numeric (3D not done also). params not currently used,
%   but probably will be when RGB is implemented.

    properties
        parent = [];        % Parent mcData class.
        viewer = [];        % Parent(ish) mcViewer class.
        
        params = [];
        
        listener = [];      % Listens to changes in parent.
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
            switch pd.parent.data.plotMode
                case {1, '1D'}
                    nums = 1:pd.parent.data.numAxes;

                    axisXindex = nums(pd.parent.data.layer == 1);
                    
                    if pd.parent.data.data.layerType(axisXindex) == 0   % If the selected layer is an axis...

                        d = pd.parent.data.data{pd.parent.data.input};

                        if pd.parent.data.inputDimension(pd.parent.data.input) == 0     % If d will be numeric...
    %                         getIndex(pd.parent.data.lengths, pd.parent.data.layer - 1, axisXindex)
                            pd.data = d( getIndex(pd.parent.data.lengths, pd.parent.data.layer - 1, axisXindex) );
                        else                                        % Otherwise if d will be cell...
    %                             c = cell2mat( cellfun(ifInputNotSingularFnc, d{ getIndex(paramsND.lengths, axisXindex, axisYindex, layer) }) );
                            error('NotImplemented');
                        end
                    else                                                % ...otherwise, if the selected layer is an axis of an input.
                        
                    end
                case {2, '2D'}
                    nums = 1:pd.parent.data.numAxes;

                    axisXindex = nums(pd.parent.data.layer == 1);
                    axisYindex = nums(pd.parent.data.layer == 2);

                    d = pd.parent.data.data{pd.parent.data.input};

                    if pd.parent.data.inputDimension(pd.parent.data.input) == 0     % If d will be numeric...
                        pd.parent.data.layer
                        pd.data = d( getIndex(pd.parent.data.lengths, pd.parent.data.layer - 2, axisXindex, axisYindex) );
                    else                                        % Otherwise if d will be cell...
%                             c = cell2mat( cellfun(ifInputNotSingularFnc, d{ getIndex(paramsND.lengths, axisXindex, axisYindex, layer) }) );
                        error('NotImplemented');
                    end
                case {3, '3D'}
                    error('3D NotImplemented');
                otherwise
                    error('Plotmode not recognized...');
            end
        end
    end
    
end




