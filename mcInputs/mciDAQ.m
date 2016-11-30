classdef mciDAQ < mcInput
% mciDAQ is the subclass of mcInput that manages all NIDAQ devices. This includes:
%  - generic digital, analog, and counter outputs.

    methods (Static)
        % Neccessary extra vars:
        %  - dev
        %  - chn
        %  - type
        
        function config = defaultConfig()
            config = mciDAQ.counterConfig();
        end
        function config = counterConfig()
            config.name =               'Default Counter';

            config.kind.kind =          'NIDAQcounter';
            config.kind.name =          'DAQ Counter';
            config.kind.extUnits =      'cts/sec';              % 'External' units.
            config.kind.shouldNormalize = true;                 % If this variable is flagged, the measurement is subtracted from the previous and is divided by the time spent on a pixel.
            config.kind.sizeInput =    [1 1];
            
            config.dev =                'Dev1';
            config.chn =                'ctr2';
            config.type =               'EdgeCount';
        end
        function config = voltageConfig()
            config.name =               'Default Voltage Input';

            config.kind.kind =          'NIDAQanalog';
            config.kind.name =          'DAQ Voltage Input';
            config.kind.extUnits =      'V';                    % 'External' units.
            config.kind.shouldNormalize = false;
            config.kind.sizeInput =    [1 1];
            
            config.dev =                'Dev1';
            config.chn =                'ai0';
            config.type =               'Voltage';
        end
        function config = digitalConfig()
            config.name =               'Digital Output';

            config.kind.kind =          'NIDAQdigital';
            config.kind.name =          'Digital Output';
            config.kind.shouldNormalize = false;                % If this variable is flagged, the measurement is subtracted from the previous and is divided by the time spent on a pixel.
            config.kind.sizeInput =    [1 1];

            config.dev =                'Dev1';
            config.chn =                'Port0/Line0';
            config.type =               'Output';               % This must be there to differentiate outputs from inputs
        end
    end
    
    methods
        function I = mciDAQ(varin)
            I.extra = {'dev', 'chn', 'type'};
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
            str = [I.config.name ' (' I.config.dev ':' I.config.chn ':' I.config.type ')'];
        end
        function str = NameVerb(I)
            switch lower(I.config.kind.kind)
                case 'nidaqanalog'
                    str = [I.config.name ' (analog ' I.config.type ' input on '  I.config.dev ', channel ' I.config.chn ')'];
                case 'nidaqdigital'
                    str = [I.config.name ' (digital input on ' I.config.dev ', channel ' I.config.chn ')'];
                case 'nidaqcounter'
                    str = [I.config.name ' (counter ' I.config.type ' input on ' I.config.dev ', channel ' I.config.chn ')'];
            end
        end
        
        % OPEN/CLOSE
        function Open(I)
            switch lower(I.config.kind.kind)
                case 'nidaqanalog'
                    I.s = daq.createSession('ni');
                    addAnalogInputChannel(  I.s, I.config.dev, I.config.chn, I.config.type);
                case 'nidaqdigital'
                    I.s = daq.createSession('ni');
                    addDigitalChannel(      I.s, I.config.dev, I.config.chn, 'InputOnly');
                case 'nidaqcounter'
                    I.s = daq.createSession('ni');
                    addCounterInputChannel( I.s, I.config.dev, I.config.chn, I.config.type);
            end
        end
        function Close(I)
            release(I.s);
        end
        
        % MEASURE
        function data = MeasureEmulation(I, integrationTime)
            switch lower(I.config.kind.kind)
                case 'nidaqanalog'
                    data = rand*20 - 10;    % rand from -10 to 10
                case 'nidaqdigital'
                    data = rand > .5;       % 0 or 1
                case {'nidaqcounter'}
                    pause(integrationTime);
                    data = rand*400 + 400;  % Guess at dark count distribution
            end
        end
        function data = Measure(I, integrationTime)
            switch lower(I.config.kind.kind)
                case {'nidaqanalog', 'nidaqdigital'}
                    data = I.s.inputSingleScan();
                case {'nidaqcounter'}
                    I.s.resetCounters();
                    [d1,t1] = I.s.inputSingleScan();
                    pause(integrationTime);             % Inexact way. Should make this asyncronous also...
                    [d2,t2] = I.s.inputSingleScan();

                    data = (d2 - d1)/((t2 - t1)*24*60*60);
            end
        end
    end
    
    methods
        % EXTRA
        function addToSession(I, s)
            if I.close()
                switch lower(I.config.kind.kind)
                    case 'nidaqanalog'
                        addAnalogInputChannel(  s, I.config.dev, I.config.chn, I.config.type);
                    case 'nidaqdigital'
                        addDigitalChannel(      s, I.config.dev, I.config.chn, 'InputOnly');
                    case 'nidaqcounter'
                        addCounterInputChannel( s, I.config.dev, I.config.chn, I.config.type);
                    otherwise
                        warning('This only works for NIDAQ outputs');
                end
            end
        end
    end
end




