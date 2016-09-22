classdef mciAutomation < mcInput
% mciAutomation is the subclass of mcInput that controls what an automation routine should do at each point of a grid.

% (currently under construction; don't use)

    properties
        autoVars = [];  % To store variables that the automation function will use each tick.
        f = [];         % Figure for automation menu.
    end

    methods (Static)
        % Neccessary extra vars:
        
        function config = defaultConfig()
            config = mciAutomation.diamondConfig();
        end
        function config = diamondConfig()
            config.name =               'Automation Function';

            config.kind.kind =          'function';
            config.kind.name =          'Default Function Input';
            config.kind.extUnits =      'arb';                  % 'External' units.
            config.kind.normalize =     false;
            config.kind.sizeInput =    [1 1];
        end
    end
    
    methods
        function I = mciAutomation(varin)
            if nargin == 0
                I.construct(I.defaultConfig());
            else
                I.construct(varin);
            end
            I.config.giveIntegration = nargin(config.fnc) ~= -1;
            
            I.f = mcInstrumentHandler.createFigure(I, 'none');

            I.f.Resize =      'off';
            I.f.Position =    [100, 100, 300, 100];
            I.f.Visible =     'on';
        end
    end
    
    % These methods overwrite the empty methods defined in mcInput. mcInput will use these. The capitalized methods are used in
    %   more-complex methods defined in mcInput.
    methods (Access = private)
        % EQ
        function tf = Eq(I, b)  % Check if a foriegn object (b) is equal to this input object (a).
            tf = isequal(I.config.fnc,  b.config.fnc);
        end
        
        % NAME
        function str = NameShort(I)
            str = [I.config.name ' (' I.config.description ')'];
        end
        function str = NameVerb(I)
            str = [I.config.name ' (function input with description: ' I.config.description ')'];
        end
        
        % OPEN/CLOSE uneccessary.
        
        % MEASURE
        function data = MeasureEmulation(I, integrationTime)
             data = I.Measure(integrationTime);
        end
        function data = Measure(I, integrationTime)
            if I.config.giveIntegration
                data = I.config.fnc(integrationTime);
            else
                data = I.config.fnc();
            end
        end
    end
end




