classdef mcAutomation < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    % 
    % Status: Probably going to replace with mcExperiment.
    
    properties
        grid
        autoFunction
        autoFunctionVars = {};
        
        isIntialized = false;
    end
    
    methods
        function defaultAutoFunction(auto)
            if ~auto.isIntialized
                autoFunctionVars = {};
                
                auto.isIntialized = true;
            end
            
            
        end
    end
    
    methods
        function auto = mcAutomation(grid, autoFunction)
            auto.grid = grid;
            auto.autoFunction = autoFunction;
            auto.isIntialized = false;
        end
        function automate(auto)
            
        end
    end
    
end

