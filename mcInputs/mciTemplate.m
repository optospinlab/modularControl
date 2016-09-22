classdef mciTemplate < mcInput
% mciTemplate aims to explain the essentials for making a custom mcInput.

    methods (Static)
        % Neccessary extra vars:
        %  - customVar1
        %  - customVar2
        
        function config = defaultConfig()
            config = mciTemplate.templateConfig();
        end
        function config = templateConfig()
            config.name = 'Template';

            config.kind.kind =          'template';
            config.kind.name =          'Template';
            config.kind.extUnits =      'units/sec';            % 'External' units.
            config.kind.shouldNormalize = true;                 % If this variable is flagged, the measurement is subtracted from the previous and is divided by the time spent on a pixel. Not that this is done outside the measurement currently in mcData (individual calls to .measure() will not have this behavior currently)
            config.kind.sizeInput =    [1 1];
            
            config.customVar1 = 'Important Var 1';
            config.customVar2 = 'Important Var 2';
        end
    end
    
    methods
        function I = mciTemplate(varin)
            I.extra = {'customVar1', 'customVar2'};
            if nargin == 0
                I.construct(I.defaultConfig());
            else
                I.construct(varin);
            end
            I = mcInstrumentHandler.register(I);
        end
    end
    
    % These methods overwrite the empty methods defined in mcInput. mcInput will use these. The capitalized methods are used in
    %   more-complex methods defined in mcInput.
    methods
        % EQ
        function tf = Eq(I, b)  % Check if a foriegn object (b) is equal to this input object (a).
            tf = strcmp(I.config.dev,  b.config.dev) && ... % ...then check if all of the other variables are the same.
                 strcmp(I.config.chn,  b.config.chn) && ...
                 strcmp(I.config.type, b.config.type);
        end
        
        % NAME
        function str = NameShort(I)
            % This is the reccommended a.nameShort().
            str = [I.config.name ' (' I.config.customVar1 ':' I.config.customVar2 ')'];
        end
        function str = NameVerb(I)
            str = [I.config.name ' (a template for custom mcInput with custom vars ' I.config.customVar1 ' and ' I.config.customVar2 ')'];
        end
        
        % OPEN/CLOSE
        function Open(I)
            create(I.s)     % (fake line)
        end
        function Close(I)
            release(I.s);   % (fake line)
        end
        
        % MEASURE
        function data = MeasureEmulation(I, integrationTime)
            data = rand(I.config.kind.sizeInput)*integrationTime;
        end
        function data = Measure(I, integrationTime)
            data = getData(I.s, integrationTime);    % (fake line)
        end
    end
    
    methods
        % EXTRA
        function specificFunction(I)
            % A function specific to mcaTemplate.
            specific(I);      % (fake line)
        end
    end
end




