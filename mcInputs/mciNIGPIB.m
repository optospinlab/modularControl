classdef mciNIGPIB < mcInput
% mciNIGPIB connects to National Instruments USB to GPIB connectors. Currently, the only GPIB
% instrumnet that we care about connection to is the Newport powermeters.

    methods (Static)
        % Neccessary extra vars:
        %  - chn
        %  - primaryAddress
        %  - boardIndex?
        
        function config = defaultConfig()
            config = mciNIGPIB.powermeterConfig();
        end
        function config = powermeterConfig()
            config.name = 'Powermeter';

            config.kind.kind =          'template';
            config.kind.name =          'Template';
            config.kind.extUnits =      'W';                    % 'External' units.
            config.kind.shouldNormalize = false;                % If this variable is flagged, the measurement is subtracted from the previous and is divided by the time spent on a pixel. Not that this is done outside the measurement currently in mcData (individual calls to .measure() will not have this behavior currently)
            config.kind.sizeInput =    [1 1];
            
            config.chn = 'A';
            config.primaryAddress = 5;
        end
    end
    
    methods
        function I = mciNIGPIB(varin)
            I.extra = {'chn'};
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
            tf = strcmp(I.config.chn,  b.config.chn);
        end
        
        % NAME
        function str = NameShort(I)
            % This is the reccommended a.nameShort().
            str = [I.config.name ' (' I.config.customVar1 ':' I.config.customVar2 ')'];
        end
        function str = NameVerb(I)
            str = [I.config.name ' (a template for custom mcInput with custom vars ' I.config.customVar1 ' and ' I.config.customVar2 ')'];
        end
        
        function Open(I)
            I.s = instrfind('Type', 'gpib', 'BoardIndex', 0, 'PrimaryAddress', I.config.primaryAddress, 'Tag', '');
            % Create the GPIB object if it does not exist
            % otherwise use the object that was found.
            if isempty(I.s)
                I.s = gpib('NI', 0, I.config.primaryAddress);
            else
                fclose(I.s);
                I.s = I.s(1);   % I don't understand this line
            end
            
            fopen(I.s);
        end
        function Close(I)
            fclose(I.s);
        end
        
        % MEASURE
        function data = MeasureEmulation(I, ~)
            data = rand(I.config.kind.sizeInput);
        end
        function data = Measure(I, ~)
            fprintf(I.s, ['R_' I.config.chn '?']);  % Send the command.
            pause(0.5);                             % Is it neccessary to wait this long?
            data = fscanf(I.s);                     % Get the power.
        end
    end
    
    methods
        % EXTRA
        function setWavelength(I, wavelength)
            str = num2str(wavelength);  % Do checks on this?
            
            if I.open()
                fprintf(I.s, ['LAMBDA_' I.config.chn ' ' str]); 
            end
        end
    end
end




