classdef mcGrid
% mcGrid Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        config = [];
        
        gridAxes = {};
        position = [];
    end
    
    methods
        function grid = mcGrid(wp, indices)
            if length(indices)
                
            end
            
            m = 0;
            
            grid.config.A = 0;
        end
        
        function y = mtimes(grid, x)
            dims = size(x);
            
            if dims(1) == 1
                y = ( grid.config.A * ([x, 1]') )';
            else
                y = grid.config.A * [x; 1];
            end
        end
    end
    
end




