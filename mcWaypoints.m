classdef mcWaypoints < handle
% mcWaypoints stores waypoints that can be recovered later.
    
    properties
        config = [];
        waypoints = {};
    end
    
    methods (Static)
        function config = defaultConfig()
            configMicroX = mcAxis.microConfig(); configMicroX.name = 'Micro X'; configMicroX.port = 'COM6';
            configMicroY = mcAxis.microConfig(); configMicroY.name = 'Micro Y'; configMicroY.port = 'COM7';
            
            config.axes = {mcAxis(configMicroX), mcAxis(configMicroY)};
        end
    end
    
    methods
        function wp = mcWaypoints(varin)
            wp.config = mcWaypoints.defaultConfig();
        end
        
        function drop(wp)
            [~, ~, wp.waypoints{length(wp.waypoints) + 1}] = mcInstrumentHandler.getAxes();
        end
    end
    
end




