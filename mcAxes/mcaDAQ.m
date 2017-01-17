classdef (Sealed) mcaDAQ < mcAxis
% mcaDAQ is the subclass of mcAxis that manages all NIDAQ devices. This includes:
%  - generic digital and analog outputs.
%  - piezos
%  - galvos
%
% Also see mcaTemplate and mcAxis.
%
% Status: Finished. Mostly uncommented.
    
    methods (Static)
        % Neccessary extra vars:
        %  - dev
        %  - chn
        %  - type
        
        function config = defaultConfig()
            config = mcaDAQ.piezoConfig();
        end
        function config = analogConfig()
            config.class =              'mcaDAQ';
            
            config.name =               'Analog Output';

            config.kind.kind =          'NIDAQanalog';
            config.kind.name =          'Analog Output';
            config.kind.intRange =      [0 10];
            config.kind.int2extConv =   @(x)(x);                % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)(x);                % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      'V';                    % 'Internal' units.
            config.kind.extUnits =      'V';                    % 'External' units.
            config.kind.base =           0;                     % The (internal) value that the axis seeks at startup.

            config.dev =                'Dev1';
            config.chn =                'ao0';
            config.type =               'Voltage';
            
            config.keyStep =            .1;
            config.joyStep =            .5;
        end
        function config = PIE616Config()
            config.class =              'mcaDAQ';
            
            config.name =               'High Voltage Analog Output';

            config.kind.kind =          'NIDAQanalog';
            config.kind.name =          'PIE616 x10 Analog Output';
            config.kind.intRange =      [0 10];
            config.kind.int2extConv =   @(x)(x.*10);            % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)(x./10);            % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      'V';                    % 'Internal' units.
            config.kind.extUnits =      'V';                    % 'External' units.
            config.kind.base =           0;                     % The (internal) value that the axis seeks at startup.

            config.dev =                'cDAQ1Mod1';
            config.chn =                'ao0';
            config.type =               'Voltage';
            
            config.keyStep =            .1;
            config.joyStep =            .5;
        end
        function config = greenConfig()
            config.class =              'mcaDAQ';
            
            config.name =               'Green';

            config.kind.kind =          'NIDAQdigital';
            config.kind.name =          'Laser Modulation';
            config.kind.intRange =      {0 1};
            config.kind.int2extConv =   @(x)(x);                % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)(x);                % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      '1/0';                  % 'Internal' units.
            config.kind.extUnits =      '1/0';                  % 'External' units.
            config.kind.base =           0;                     % The (internal) value that the axis seeks at startup.

            config.dev =                'Dev1';
            config.chn =                'Port0/Line2';
            config.type =               'Output';
            
            config.keyStep =            1;
            config.joyStep =            1;
        end
        function config = greenOD2Config()
            config.class =              'mcaDAQ';
            
            config.name =               'Green OD2';

            config.kind.kind =          'NIDAQdigital';
            config.kind.name =          'Optical Density 2';
            config.kind.intRange =      {0 1};
            config.kind.int2extConv =   @(x)(x);                % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)(x);                % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      '1/0';                  % 'Internal' units.
            config.kind.extUnits =      '1/0';                  % 'External' units.
            config.kind.base =           0;                     % The (internal) value that the axis seeks at startup.

            config.dev =                'Dev1';
            config.chn =                'Port0/Line3';
            config.type =               'Output';
            
            config.keyStep =            1;
            config.joyStep =            1;
        end
        function config = redDigitalConfig()
            config.class =              'mcaDAQ';
            
            config.name =               'Red';

            config.kind.kind =          'NIDAQdigital';
            config.kind.name =          'Red Modulation';
            config.kind.intRange =      {0 1};
            config.kind.int2extConv =   @(x)(x);                % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)(x);                % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      '1/0';                  % 'Internal' units.
            config.kind.extUnits =      '1/0';                  % 'External' units.
            config.kind.base =           0;                     % The (internal) value that the axis seeks at startup.

            config.dev =                'Dev1';
            config.chn =                'Port0/Line4';
            config.type =               'Output';
            
            config.keyStep =            1;
            config.joyStep =            1;
        end
        function config = redConfig()
            config.class =              'mcaDAQ';
            
            config.name =               'Red Freq';

            config.kind.kind =          'NIDAQanalog';
            config.kind.name =          'New Focus Laser Freq Modulation';
            config.kind.intRange =      [-3 3];
            config.kind.int2extConv =   @(x)(x);                % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)(x);                % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      'V';                    % 'Internal' units.
            config.kind.extUnits =      'V';                    % 'External' units.
            config.kind.base =           0;                     % The (internal) value that the axis seeks at startup.

%             config.dev =                'cDAQ1Mod1';
            config.dev =                'Dev1';
            config.chn =                'ao3';
            config.type =               'Voltage';
            
            config.keyStep =            .1;
            config.joyStep =            .5;
        end
        function config = piezoConfig()
            config.class =              'mcaDAQ';
            
            config.name =               'Default Piezo';

            config.kind.kind =          'NIDAQanalog';
            config.kind.name =          'MadCity Piezo';
            config.kind.intRange =      [0 10];
            config.kind.int2extConv =   @(x)(5.*(5 - x));       % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)((25 - x)./5);      % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      'V';                    % 'Internal' units.
            config.kind.extUnits =      'um';                   % 'External' units.
            config.kind.base =           0;                     % The (internal) value that the axis seeks at startup.

            config.dev =                'Dev1';
            config.chn =                'ao0';
            config.type =               'Voltage';
            
            config.keyStep =            .1;
            config.joyStep =            .5;
        end
        function config = piezoZConfig()
            config.class =              'mcaDAQ';
            
            config.name =               'Piezo Z';

            config.kind.kind =          'NIDAQanalog';
            config.kind.name =          'MadCity Piezo';
            config.kind.intRange =      [0 10];
            config.kind.int2extConv =   @(x)(5.*(x - 5));       % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)((x + 25)./5);      % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      'V';                    % 'Internal' units.
            config.kind.extUnits =      'um';                   % 'External' units.
            config.kind.base =           0;                     % The (internal) value that the axis seeks at startup.

            config.dev =                'Dev1';
            config.chn =                'ao2';
            config.type =               'Voltage';
            
            config.keyStep =            .1;
            config.joyStep =            .5;
        end
        function config = digitalConfig()
            config.class =              'mcaDAQ';
            
            config.name =               'Digital Output';

            config.kind.kind =          'NIDAQdigital';
            config.kind.name =          'Digital Output';
            config.kind.intRange =      {0 1};                  % Use a cell array to define discrete values.
            config.kind.int2extConv =   @(x)(x);
            config.kind.ext2intConv =   @(x)(x);
            config.kind.intUnits =      '1/0';                  % 'Internal' units.
            config.kind.extUnits =      '1/0';                  % 'External' units. (Should this be volts?)
            config.kind.base =           0;                     % The (internal) value that the axis seeks at startup.

            config.dev =                'Dev1';
            config.chn =                'Port0/Line0';
            config.type =               'Output';               % This must be there to differentiate outputs from inputs

            config.keyStep =            1;
            config.joyStep =            1;
        end
        function config = galvoConfig()
            config.name =               'Default Galvo';

            config.kind.kind =          'NIDAQanalog';
            config.kind.name =          'Tholabs Galvometer';   % Check for better name.
            config.kind.intRange =      [-10 10];
            config.kind.int2extConv =   @(x)(x.*1000);          % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)(x./1000);          % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      'V';                    % 'Internal' units.
            config.kind.extUnits =      'mV';                   % 'External' units.
            config.kind.base =           0;                     % The (internal) value that the axis seeks at startup.

            config.dev =                'cDAQ1Mod1';
            config.chn =                'ao0';
            config.type =               'Voltage';
            
            config.keyStep =            .5;
            config.joyStep =            5;
        end
        function config = galvoXBrynnConfig()
            config.name =               'Galvo X';

            config.kind.kind =          'NIDAQanalog';
            config.kind.name =          'Tholabs Galvometer';   % Check for better name.
            config.kind.intRange =      [-10 10];
            config.kind.int2extConv =   @(x)(x.*1000);          % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)(x./1000);          % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      'V';                    % 'Internal' units.
            config.kind.extUnits =      'mV';                   % 'External' units.
            config.kind.base =          -2.610;                 % The (internal) value that the axis seeks at startup.

            config.dev =                'Dev1';
            config.chn =                'ao0';
            config.type =               'Voltage';
            
            config.keyStep =            .5;
            config.joyStep =            5;
        end
        function config = galvoYBrynnConfig()
            config.name =               'Galvo Y';

            config.kind.kind =          'NIDAQanalog';
            config.kind.name =          'Tholabs Galvometer';   % Check for better name.
            config.kind.intRange =      [-10 10];
            config.kind.int2extConv =   @(x)(x.*1000);          % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)(x./1000);          % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      'V';                    % 'Internal' units.
            config.kind.extUnits =      'mV';                   % 'External' units.
            config.kind.base =          -.490;                  % The (internal) value that the axis seeks at startup.

            config.dev =                'Dev1';
            config.chn =                'ao1';
            config.type =               'Voltage';
            
            config.keyStep =            .5;
            config.joyStep =            5;
        end
    end
    
    methods
        function a = mcaDAQ(varin)
            a.extra = {'dev', 'chn', 'type'};
        
            if nargin == 0
                a.construct(mcaDAQ.defaultConfig());
            else
                a.construct(varin);
            end
%             a.name()
            a = mcInstrumentHandler.register(a);
%             a.name()
        end
    end
    
    % These methods overwrite the empty methods defined in mcAxis. mcAxis will use these. The capitalized methods are used in
    %   more-complex methods defined in mcAxis.
    methods
        % NAME
        function str = NameShort(a)
            str = [a.config.name ' (' a.config.dev ':' a.config.chn ':' a.config.type ')'];
        end
        function str = NameVerb(a)
            switch lower(a.config.kind.kind)
                case 'nidaqanalog'
                    str = [a.config.name ' (analog input on '  a.config.dev ', channel ' a.config.chn ' with type ' a.config.type ')'];
                case 'nidaqdigital'
                    str = [a.config.name ' (digital input on ' a.config.dev ', channel ' a.config.chn ' with type ' a.config.type ')'];
                otherwise
                    str = a.config.name;
            end
        end
        
        %EQ
        function tf = Eq(a, b)
            tf = strcmpi(a.config.dev,  b.config.dev) && ...
                 strcmpi(a.config.chn,  b.config.chn) && ...
                 strcmpi(a.config.type, b.config.type);
        end
        
        % OPEN/CLOSE
        function Open(a)
            switch lower(a.config.kind.kind)
                case 'nidaqanalog'
                    a.s = daq.createSession('ni');
                    addAnalogOutputChannel(a.s, a.config.dev, a.config.chn, a.config.type);
                case 'nidaqdigital'
                    a.s = daq.createSession('ni');
                    addDigitalChannel(a.s, a.config.dev, a.config.chn, 'OutputOnly');
            end
            
            a.s.outputSingleScan(a.x);
        end
        function Close(a)
            a.s.release();
            delete(a.s)
        end
        
        % GOTO
        function GotoEmulation(a, x)
            a.xt = a.config.kind.ext2intConv(x);    % This will cause preformance reduction for identity conversions (@(x)(x)) e.g. digital. Change?
            a.x = a.xt;
        end
        function Goto(a, x)
            a.GotoEmulation(x);        % No need to rewrite code.
            a.s.outputSingleScan(a.x);
        end
    end
    
    methods
        % EXTRA
        function addToSession(a, s)
            if a.close()   % If the axis is not already closed, close it...
                switch lower(a.config.kind.kind)
                    case 'nidaqanalog'
                        addAnalogOutputChannel( s, a.config.dev, a.config.chn, a.config.type);
                    case 'nidaqdigital'
                        addDigitalChannel(      s, a.config.dev, a.config.chn, 'OutputOnly');
                    otherwise
                        error('This only works for NIDAQ outputs');
                end
            else
                error([a.name() ' could not be added to session.'])
            end
        end
    end
end




