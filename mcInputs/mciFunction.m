classdef mciFunction < mcInput
% mciFunction is the subclass of mcInput that wraps (near) arbitrary functions.

    methods (Static)
        % Neccessary extra vars:
        %  - fnc
        %  - description
        
        function config = defaultConfig()
            config = mciFunction.randConfig();
        end
        function config = randConfig()
            config.name =               'Default Function Input';

            config.kind.kind =          'function';
            config.kind.name =          'Default Function Input';
            config.kind.extUnits =      'arb';                  % 'External' units.
            config.kind.normalize =     false;
            config.kind.sizeInput =    [1 1];
            
            config.fnc =                @rand;
            config.description =        'wraps the MATLAB rand() function';
        end
    end
    
    methods
        function I = mciFunction(varin)
            if nargin == 0
                I.construct(I.defaultConfig());
            else
                I.construct(varin);
            end
            I = mcInstrumentHandler.register(I);
            I.config.giveIntegration = nargin(config.fnc) ~= -1;    % Internal variable to decide whether the integration time in I.measure(integrationTime) should be passed to the mciFunction function as an input.
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




