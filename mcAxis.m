classdef mcAxis < handle
% Abstract class for instruments with linear motion. This includes:
%   - NIDAQ
%       + Piezos
%       + Galvos
%   - Micrometers
%
% IMPORTANT: Not sure whether a better architecture decision would be to
% have kinds (such as piezos and galvos) extend the mcAxis class in their
% own subclass (e.g. mcPiezo < mcAxis) instead of the potentially-messy 
% switch statements that are currently in the code.
% UPDATE: Decided to change this eventually, but keep it the same for now.
%
% Syntax:
%   a = mcAxis()                                % Open with default configuration.
%   a = mcAxis(config)                          % Open with configuration given by config.
%   a = mcAxis('config_file.mat')               % Open with config file in 'MATLAB_PATH\configs\axisconfigs\'
%   a = mcAxis(config, emulate)                 % Same as above, except with the option (tf) to start axis in emulation mode.
%   a = mcAxis('config_file.mat', emulate)     
%
%   config = mcAxis.[INSERT_TYPE]Config         % Returns the default config struture for that type
%   
%   str =   a.name()                            % Returns the default name. This is currently nameShort().
%   str =   a.nameUnits()                       % Returns info about this axis in 'name (units)' form.
%   str =   a.nameShort()                       % Returns short info about this axis in a readable form.
%   str =   a.nameVerb()                        % Returns verbose info about this axis in a readable form.
%
%   tf =    a.open()                            % Opens a session of the axis (e.g. for the micrometers, a serial session); returns whether open or not.
%   tf =    a.close()                           % Closes the session of the axis; returns whether closed or not.
%
%   tf =    a.inRange(x)                        % Returns true if x is in the external range of a.
%
%   tf =    a.goto(x)                           % If x is in range, makes sure axis is open, moves axis to x, and returns success.

    properties
        config = [];            % All static variables (e.g. valid range) go in config.
        
        s = [];                 % Session, whether serial, NIDAQ, or etc.
        
        isOpen = false;         % Boolean.
        inUse = false;          % Boolean.
        inEmulation = false;    % Boolean.
    end
    properties (Access=private, SetObservable)
        x = 0;                  % Current position.
        xt = 0;                 % Target position.
    end
    methods (Static)  
        function config = defaultConfig()
            config = mcAxis.piezoConfig();
        end
        function config = piezoConfig()
            config.name =               'Default Piezo';

            config.kind.kind =          'NIDAQanalog';
            config.kind.name =          'MadCity Piezo';
            config.kind.intRange =      [0 10];
            config.kind.int2extConv =   @(x)(5.*(x - 5));       % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)((x + 25)./5);      % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      'V';                    % 'Internal' units.
            config.kind.extUnits =      'um';                   % 'External' units.
            config.kind.base =           0;

            config.dev =                'Dev1';
            config.chn =                'ao0';
            config.type =               'Voltage';
            
            config.keyStep =            .01;
            config.joyStep =            .5;

            config.pos =                config.kind.base;

            config.intSpeed =           10;                     % 'Internal' units per second.
        end
        function config = digitalConfig()
            config.name =               'Digital Output';

            config.kind.kind =          'NIDAQdigital';
            config.kind.name =          'Digital Output';
            config.kind.base =           0;

            config.dev =                'Dev1';
            config.chn =                'Port0/Line0';
            config.type =               'Output';           % This must be there to differentiate outputs from inputs

            config.keyStep =            1;
            config.joyStep =            1;
            
            config.pos =                config.type.base;

%             config.intSpeed =           10;                  % 'Internal' units per second.
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
            config.kind.base =           0;

            config.dev =                'Dev1';
            config.chn =                'ao0';
            config.type =               'Voltage';
            
            config.keyStep =            .05;
            config.joyStep =            5;

            config.pos =                config.kind.base;

            config.intSpeed =           20;                      % 'Internal' units per second.
        end
        function config = microConfig()
            config.name =               'Default Micrometers';

            config.kind.kind =          'Serial Micrometer';
            config.kind.name =          'Tholabs Micrometer';   % Check for better name.
            config.kind.intRange =      [0 25];
            config.kind.int2extConv =   @(x)(x.*1000);          % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)(x./1000);          % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      'mm';                   % 'Internal' units.
            config.kind.extUnits =      'um';                   % 'External' units.
            config.kind.base =          0;
            config.kind.resetParam =    '';

            config.port =               'COM6';                 % Micrometer Port.
            config.addr =               '1';                    % Micrometer Address.
            
            config.keyStep =            .05;
            config.joyStep =            5;

            config.intSpeed =           1;                      % 'Internal' units per second.
        end
        function config = timeConfig()
            config.name =               'Time';

            config.kind.kind =          'Time';
            config.kind.name =          'Time';
            config.kind.intRange =      [0 Inf];
            config.kind.int2extConv =   @(x)(x);                % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)(x);                % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      's';                    % 'Internal' units.
            config.kind.extUnits =      's';                    % 'External' units.
            config.kind.base =          0;
            config.kind.resetParam =    '';
        end
    end
    methods
        function a = mcAxis(varin)
            % Constructor 
            switch nargin
                case 0
                    a.config = mcAxis.defaultConfig();
                case {1, 2}
                    if nargin == 1
                        config = varin;
                    else
                        config = varin{1};
                    end
                    
                    if ischar(config)
                        if exist(config, 'file') && strcmpi(config(end-3:end), '.mat')
                            vars = load(config);
                            if isfield(vars, 'config')
                                a.config = vars.config;
                            else
                                error('.mat file given for config has no field config...');
                            end
                        else
                        	error('File given for config does not exist or is not .mat...');
                        end
                    elseif isstruct(config)
                        a.config = config;
                    else
                        error('Not sure how to interpret config in mcAxis(config)...');
                    end
                    
                    if nargin == 2
                        if islogical(varin{2}) || isnumeric(varin{2})
                            a.inEmulation = varin{2};
                        else
                            warning('Second argument not understood; it needs to be logical or numeric');
                        end
                    end
            end
            
            a.config.kind.extRange = a.config.kind.int2extConv(a.config.kind.intRange);
%             x = a.config.kind.extRange;
            
%             global ih
%             if isempty(ih)
%                 ih = mcInstrumentHandler();
%             end
%             
%             a = ih.register(a);
            
            if ~strcmpi(a.config.name, 'Time')      % This prevents infinite recursion...
                a = mcInstrumentHandler.register(a);
                a.inEmulation = ismac;
            else
                if 
                    
                end
            end
            
            a.inEmulation
            
            a.x = a.config.kind.base;
            a.xt = a.x;
            a.goto(a.x);
        end
        
        function tf = eq(a, b)      % Check if a foreign object (b) has the same properties as this axis object (a).
            if ~isprop(b, 'config')
                tf = false; return;
            else
                if ~isfield(b.config, 'kind')
                    tf = false; return;
                else
                    if ~isfield(b.config.kind, 'kind')
                        tf = false; return;
                    end
                end
            end
            
            a.config
            b.config
            
            if strcmpi(a.config.kind.kind, b.config.kind.kind)     % If they are the same kind...
                switch lower(a.config.kind.kind)                   % ...then check if all of the other variables are the same.
                    case {'nidaqanalog', 'nidaqdigital'}
                        tf = strcmpi(a.config.dev,  b.config.dev) && ...
                             strcmpi(a.config.chn,  b.config.chn) && ...
                             strcmpi(a.config.type, b.config.type);
                    case 'serial micrometer'
                        tf = strcmpi(a.config.port,  b.config.port) && ...
                             strcmpi(a.config.addr,  b.config.addr);
                    case 'time'
                        tf = true;
                    otherwise
                        warning('Specific equality conditions not written for this sort of axis.')
                        tf = true;
                end
            else
                tf = false;
            end
        end
   
        function str = name(a)
            str = a.nameShort();
        end
        function str = nameUnits(a) % Returns description in 'name (units)' form.
            str = [a.config.name ' (' a.config.kind.extUnits ')'];
        end
        function str = nameRange(a) % Returns description in 'name (rmin:rmax)' form with ' (Emulation)' if emulating.
            str = ['Range: ' num2str(a.config.kind.extRange(1)) ' to ' num2str(a.config.kind.extRange(2)) ' (' a.config.kind.extUnits ')'];
        end
        function str = nameShort(a) % Returns description in 'name (info1:info2)' form with ' (Emulation)' if emulating.
            switch lower(a.config.kind.kind)
                case 'nidaqanalog'
                    str = [a.config.name ' (' a.config.dev ':' a.config.chn ')'];
                case 'nidaqdigital'
                    str = [a.config.name ' (' a.config.dev ':' a.config.chn ')'];
                case 'serial micrometer'
                    str = [a.config.name ' (' a.config.port ':' a.config.addr ')'];
                otherwise
                    str = a.config.name;
            end
            
            if a.inEmulation
                str = [str ' (Emulation)'];
            end
        end
        function str = nameVerb(a)  % Returns a more-detailed description of the Axis.
            switch lower(a.config.kind.kind)
                case 'nidaqanalog'
                    str = [a.config.name ' (analog input on '  a.config.dev ', channel ' a.config.chn ' with type ' a.config.type ')'];
                case 'nidaqdigital'
                    str = [a.config.name ' (digital input on ' a.config.dev ', channel ' a.config.chn ' with type ' a.config.type ')'];
                case 'serial micrometer'
                    str = [a.config.name ' (serial micrometer on port ' a.config.port ', address' a.config.addr ')'];
                otherwise
                    str = a.config.name;
            end
            
            if a.inEmulation
                str = [str ' (currently in emulation)'];
            end
        end
        
        function tf = open(a)       % Opens a session of the axis (e.g. for the micrometers, a serial session); returns whether open or not.
            if a.isOpen
%                 warning([a.name() ' is already open...']);
                tf = true;
            elseif a.inUse
                warning([a.name() ' is already in use...']);
                tf = false;
            else
                a.isOpen = true;
                a.inUse = true;
                
                if a.inEmulation
                    % Should something be done?
                else
                    switch lower(a.config.kind.kind)
                        case {'nidaqanalog', 'nidaqdigital'}
                            a.s = daq.createSession('ni');
                            a.addToSession(a.s);
                            a.s.outputSingleScan(a.x);
                        case 'serial micrometer'
                            a.s = serial(a.config.port);
                            set(a.s, 'BaudRate', 921600, 'DataBits', 8, 'Parity', 'none', 'StopBits', 1, ...
                                'FlowControl', 'software', 'Terminator', 'CR/LF');
                            fopen(a.s);

                            % The following is Srivatsa's code and should be examined.

                            pause(.25);
                            fprintf(a.s, [a.config.addr 'HT1']);        % Simplyfying function for this?
                            fprintf(a.s, [a.config.addr 'SL-5']);        % negative software limit x=-5
                            fprintf(a.s, [a.config.addr 'BA0.003']);     % change backlash compensation
                            fprintf(a.s, [a.config.addr 'FF05']);        % set friction compensation
                            fprintf(a.s, [a.config.addr 'PW0']);         % save to controller memory
                            pause(.25);

                            fprintf(a.s, [a.config.addr 'OR']);          % Get to home state (should retain position)
                            pause(.25);
                    end
                end
                
                tf = true;
            end
        end
        function tf = close(a)      % Closes the session of the axis; returns whether closed or not.
            if a.isOpen
                a.isOpen = false;
                a.inUse = false;
                
                if a.inEmulation
                    % Should something be done?
                else
                    switch lower(a.config.kind.kind)
                        case {'nidaqanalog', 'nidaqdigital'}
                            a.s.close();
                        case 'serial micrometer'
                            fprintf(a.s, [a.config.addr 'RS']);
                            
                            fclose(a.s);    % Not sure if all of these are neccessary; Srivatsa's old code...
                            delete(a.s); 
                            clear(a.s);
                    end
                end
                tf = true;     % Return true because axis was open and is now closed.
            elseif a.inUse
                warning([a.name() ' is in use elsewhere and cannot be used...']);
                tf = false;     % Return false because axis is in use by something else.
            else
%                 warning([a.name() ' is not open; nothing to close...']);
                tf = true;     % Return true because axis is closed already.
            end
        end
        
        function x = getX(a)        % Returns the value of a.x in external units.
            x = a.config.kind.int2extConv(a.x);
        end
        
        function tf = read(a)       % Reads the value of a.x internally; Returns success.
            tf = true;
            
            if a.inEmulation
                switch lower(a.config.kind.kind)
                    case 'serial micrometer'
                        if (a.x - a.xt)*(a.x - a.xt) > .000001  % Simple equation that attracts a.x to the target value of a.xt.
                            a.x = a.x + (a.xt - a.x)/2;
                        else
                            a.x = a.xt;
                        end
                    otherwise
                        a.x = a.xt;
                end
            else
                if a.isOpen
                    switch lower(a.config.kind.kind)
                        case 'serial micrometer'
                            fprintf(a.s, [a.config.addr 'TP']);	% Get device state
                            str = fscanf(a.s);

                            a.x = str2double(str(4:end));
                        otherwise
                            error([a.config.kind.kind ' does not have a read() method.']);
                    end
                else
                    tf = false;
                end
            end
        end
        
        function tf = goto(a, x)    % If x is in range, makes sure axis is open, moves axis to x, and returns success.
            tf = true;
            
            if a.inEmulation
                a.xt = a.config.kind.ext2intConv(x);
                
                switch lower(a.config.kind.kind)
                    case 'serial micrometer'
                        % The micrometers are not immediate.
                    otherwise
                        a.x = a.xt;
                end
            else
                if a.open();   % If the axis is not already open, open it...
                    switch lower(a.config.kind.kind)
                        case 'nidaqanalog'
                            if inRange(a.config.kind.ext2intConv(x), a.config.kind.intRange);
                                a.s.outputSingleScan(x);
                            else
                                warning([num2str(x) ' ' a.extUnits ' not a valid output for an analog NIDAQ channel.']);
                                tf = false;
                            end
                        case 'nidaqdigital'
                            switch x    % Should this switch be in inRange() also? It isn't currently to save time.
                                case {0, 'low', 'LOW', 'lo', 'LO'}
                                    a.s.outputSingleScan(0);
                                    a.x = 0;
                                    a.xt = 0;
                                case {1, 'high', 'HIGH', 'hi', 'HI'}
                                    a.s.outputSingleScan(1);
                                    a.x = 1;
                                    a.xt = 1;
                                otherwise
                                    warning([num2str(x) ' not a valid output for a digital NIDAQ channel.']);
                                    tf = false;
                            end
                        case 'serial micrometer'
                            if inRange(a.config.kind.ext2intConv(x), a.config.kind.intRange);
                                fprintf(a.s, [a.config.chn 'SE' num2str(a.config.kind.ext2intConv(x))]);
                                fprintf(a.s, 'SE');                                 % Not sure why this doesn't use config.chn... Srivatsa?
                            else
                                warning([num2str(x) ' ' a.extUnits ' not a valid output for 0 -> 25 micrometers.']);
                                tf = false;
                            end
                        case 'time'
                            
                        otherwise
                            error('Kind not understood...');
                    end
                else
                    tf = false;
                end
            end
        end
        function wait(a)            % Wait for the axis to reach the target value.
            while a.x ~= a.xt       % Make it a 'difference less than tolerance'?
                a.read();
                pause(.1);
            end
        end
        
        function addToSession(a, s) % Only for NIDAQ; adds axis to some NIDAQ session s.
            if a.close();  % If the axis is not already closed, close it...
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

function tf = inRange(x, range)
    tf = x < max(range) && x > min(range);
end

