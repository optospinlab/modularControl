classdef mcInput < handle
% Abstract class for instruments with that measure some sort of data. This includes:
%   - NIDAQ
%       + Counters
%       + Analog/Digital in
%   - Spectrometers
%   - Cameras
%
% IMPORTANT: Not sure whether a better architecture decision would be to
% have kinds (such as piezos and galvos) extend the mcAxis class in their
% own subclass (e.g. mcPiezo < mcAxis) instead of the potentially-messy 
% switch statements that are currently in the code.
% UPDATE: Decided to change this eventually, but keep it the same for now.
%
% Syntax:
%   I = mcInput()                               % Open with default configuration.
%   I = mcInput(config)                         % Open with configuration given by config.
%   I = mcInput('config_file.mat')              % Open with config file in 'MATLAB_PATH\configs\axisconfigs\'
%   I = mcInput(config, emulate)                % Same as above, except with the option (tf) to start axis in emulation mode.
%   I = mcInput('config_file.mat', emulate)     
%
%   config = mcInput.[INSERT_TYPE]Config        % Returns the default config struture for that type
%   
%   str =   I.name()                            % Returns the default name. This is currently nameShort().
%   str =   I.nameUnits()                       % Returns info about this input in 'name (units)' form.
%   str =   I.nameShort()                       % Returns short info about this input in a readable form.
%   str =   I.nameVerb()                        % Returns verbose info about this input in a readable form.
%
%   tf =    I.open()                            % Opens a session of the axis (e.g. for the micrometers, a serial session); returns whether open or not.
%   tf =    I.close()                           % Closes the session of the axis; returns whether closed or not.
%
%   tf =    I.inRange(x)                        % Returns true if x is in the external range of a.
%
%   tf =    I.goto(x)                           % If x is in range, makes sure axis is open, moves axis to x, and returns success.

    
    properties
        config = [];            % All static variables (e.g. valid range) go in config.
        
        s = [];                 % Session, whether serial or NIDAQ.
        
        isOpen = false;         % Boolean.
        inUse = false;          % Boolean.
        inEmulation = false;    % Boolean.
    end
    methods (Static)
        function config = defaultConfig()
            config = mcInput.functionConfig();
        end
        function config = counterConfig()
            config.name =               'Default Counter';

            config.kind.kind =          'NIDAQcounter';
            config.kind.name =          'DAQ Counter';
            config.kind.extUnits =      'cts/sec';              % 'External' units.
            config.kind.shouldNormalize = true;                 % If this variable is flagged, the measurement is subtracted from the previous and is divided by the time spent on a pixel.
            config.kind.sizeInput =    [1 1];
            
            config.dev =                'Dev1';
            config.chn =                'ctr0';
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

%             config.intSpeed =           10;                  % 'Internal' units per second.
        end
        function config = functionConfig()
            config.name =               'Default Function Input';

            config.kind.kind =          'function';
            config.kind.name =          'Default Function Input';
            config.kind.extUnits =      'arb';                  % 'External' units.
            config.kind.normalize =     false;
            config.kind.sizeInput =    [1 1];
            
            config.fnc =                @rand;
            config.description =        'wraps the MATLAB rand() function';
        end
        function config = spectrumConfig()
            config.name =               'Default Spectrometer Input';

            config.kind.kind =          'INSERT_DEVICE_NAME_spectrum';
            config.kind.name =          'Default Spectrum Input';
            config.kind.extUnits =      'cts';                  % 'External' units.
            config.kind.normalize =     false;                  % Should we normalize?
            config.kind.sizeInput =    [1 512];                  % This input returns a vector, not a number...
            
            % Not finished!
        end
    end
    methods
        function I = mcInput(varin)
            % Constructor 
            switch nargin
                case 0
                    I.config = mcInput.defaultConfig();
                case {1, 2}
                    if nargin == 1
                        config = varin;
                    else
                        config = varin{1};
                    end
                    
                    if ischar(config)
                        if exist(config, 'file') && strcmp(config(end-3:end), '.mat')
                            vars = load(config);
                            if isfield(vars, 'config')
                                I.config = vars.config;
                            else
                                error('.mat file given for config has no field config...');
                            end
                        else
                        	error('File given for config does not exist or is not .mat...');
                        end
                    elseif isstruct(config)
                        I.config = config;
                    else
                        error('Not sure how to interpret config in mcInput(config)...');
                    end
                    
                    if nargin == 2
                        if islogical(varin{2}) || isnumeric(varin{2})
                            I.inEmulation = varin{2};
                        else
                            warning('Second argument not understood; it needs to be logical or numeric');
                        end
                    end
            end
            
            I = mcInstrumentHandler.register(I);
            
            I.inEmulation = ismac;
        end
        
        function tf = eq(I, b)  % Check if a foriegn object (b) is equal to this input object (a).
            if strcmp(I.config.kind.kind, b.config.kind.kind)               % If they are the same kind...
                switch lower(I.config.kind.kind)
                    case {'nidaqanalog', 'nidaqdigital', 'nidaqcounter'}
                        tf = strcmp(I.config.dev,  b.config.dev) && ... % ...then check if all of the other variables are the same.
                             strcmp(I.config.chn,  b.config.chn) && ...
                             strcmp(I.config.type, b.config.type);
                    case 'function'
                        tf = isequal(I.config.fnc,  b.config.fnc);      % Note that the function handles have to be the same; the equations can't merely be the same.
                    otherwise
                        warning('Specific equality conditions not written for this sort of axis.')
                        tf = true;
                end
            else
                tf = false;
            end
        end
        
        function str = name(I)
            str = I.nameShort();
        end
        function str = nameUnits(I)
            str = [I.config.name ' (' I.config.kind.extUnits ')'];
        end
        function str = nameShort(I)
            switch lower(I.config.kind.kind)
                case 'nidaqanalog'
                    str = [I.config.name ' (' I.config.dev ': ' I.config.chn ')'];
                case 'nidaqdigital'
                    str = [I.config.name ' (' I.config.dev ': ' I.config.chn ')'];
                case 'nidaqcounter'
                    str = [I.config.name ' (' I.config.dev ': ' I.config.chn ')'];
                case 'function'
                    str = [I.config.name ' (' I.config.description ')'];
            end
            
            if I.inEmulation
                str = [str ' (Emulation)'];
            end
        end
        function str = nameVerb(I)
            switch lower(I.config.kind.kind)
                case 'nidaqanalog'
                    str = [I.config.name ' (analog ' I.config.type ' input on '  I.config.dev ', channel ' I.config.chn ')'];
                case 'nidaqdigital'
                    str = [I.config.name ' (digital input on ' I.config.dev ', channel ' I.config.chn ')'];
                case 'nidaqcounter'
                    str = [I.config.name ' (counter ' I.config.type ' input on ' I.config.dev ', channel ' I.config.chn ')'];
                case 'function'
                    str = [I.config.name ' (function input with description: ' I.config.description ')'];
            end
            
            if I.inEmulation
                str = [str ' (currently in emulation)'];
            end
        end
        
        function tf = open(I)           % Opens a session of the input; returns whether open or not.
            if I.isOpen
%                 warning([I.name() ' is already open...']);
                tf = true;
            elseif I.inUse
                warning([I.name() ' is already in use...']);
                tf = false;
            else
                I.isOpen = true;
                I.inUse = true;
                
                if I.inEmulation
                    
                else
                    switch lower(I.config.type.kind)
                        case {'nidaqanalog', 'nidaqdigital', 'nidaqcounter'}
                            I.s = daq.createSession('ni');
                            I.addToSession(I.s);
                    end
                end
                
                tf = true;
            end
        end
        function tf = close(I)          % Closes the session of the axis; returns whether closed or not.
            if I.isOpen
                I.isOpen = false;
                I.inUse = false;
                
                if I.inEmulation
                    % Should something be done?
                else
                    switch lower(I.config.kind.kind)
                        case {'nidaqanalog', 'nidaqdigital', 'nidaqcounter'}
                            I.s.close();
                    end
                end
                tf = true;     % Return true because input was open and is now closed.
            elseif I.inUse
                warning([I.name() ' is in use elsewhere and cannot be used...']);
                tf = false;     % Return false because input is in use by something else.
            else
%                 warning([I.name() ' is not open; nothing to close...']);
                tf = true;     % Return true because input is closed already.
            end
        end
        
        function data = measure(I, integrationTime)
            if I.inEmulation
                switch lower(I.config.kind.kind)
                    case {'nidaqcounter'}
                        pause(integrationTime);
                        data = rand*100;
                    case {'function'}
                        data = I.config.fnc();
                    otherwise
                        data = rand(I.config.kind.sizeInput)*100;
                end
            else
                if I.open()
                    switch lower(I.config.kind.kind)
                        case {'nidaqanalog', 'nidaqdigital'}
                            data = I.s.inputSingleScan();
                        case {'nidaqcounter'}
                            I.s.resetCounters();
                            [d1,t1] = I.s.inputSingleScan();
                            pause(integrationTime);             % Inexact way. Should make this asyncronous also...
                            [d2,t2] = I.s.inputSingleScan();

                            data = (d2 - d1)/(t2 - t1);
                        case {'function'}
                            data = I.config.fnc();
                        otherwise
                            data = rand(I.config.kind.sizeInput)*100;
                            warning('Kind not understood.');
                    end
                else
                    data = NaN;
                end
            end
        end
        
        function addToSession(I, s)
            if I.close()
                switch lower(I.config.type.kind)
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




