classdef mcAxis < mcSavableClass
% Abstract class for instruments with linear motion.
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
%
%   x =     a.getX(x)                           % Returns the position of the axis (a.x) in external units.
%   x =     a.getXt(x)                          % Returns the target position of the axis (a.xt) in external units.
%
% Status: Finished and mostly commented. Very messy, however. Future plans below.
%
% IMPORTANT: Not sure whether a better architecture decision would be to
% have kinds (such as piezos and galvos) extend the mcAxis class in their
% own subclass (e.g. mcPiezo < mcAxis) instead of the potentially-messy 
% switch statements that are currently in the code.
% UPDATE: Decided to change this eventually, but keep it the same for now.

    properties
%         config = [];            % Defined in mcSavableClass. All static variables (e.g. valid range) go in config.
        
        s = [];                 % Session, whether serial, NIDAQ, or etc.
        t = []                  % Timer to read the axis, for certain axes which do not travel immediately.
        
        isOpen = false;         % Boolean.
        inUse = false;          % Boolean.
        isReserved = false;     % Boolean.    
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
        function config = piezoZConfig()
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
            config.chn =                'ao2';
            config.type =               'Voltage';
            
            config.keyStep =            .1;
            config.joyStep =            .5;

            config.pos =                config.kind.base;

            config.intSpeed =           10;                     % 'Internal' units per second.
        end
        function config = piezoConfig()
            config.name =               'Default Piezo';

            config.kind.kind =          'NIDAQanalog';
            config.kind.name =          'MadCity Piezo';
            config.kind.intRange =      [0 10];
            config.kind.int2extConv =   @(x)(5.*(5 - x));       % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)((25 - x)./5);      % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      'V';                    % 'Internal' units.
            config.kind.extUnits =      'um';                   % 'External' units.
            config.kind.base =           0;

            config.dev =                'Dev1';
            config.chn =                'ao0';
            config.type =               'Voltage';
            
            config.keyStep =            .1;
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
            
            config.keyStep =            .5;
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
            
            config.keyStep =            .5;
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
            
            config.keyStep =            0;
            config.joyStep =            0;
        end
        function config = polarizationConfig()
            config.name = 'Half Wave Plate';

            config.kind.kind =          'manual';
            config.kind.name =          'Polarization';
            config.kind.intRange =      [-180 180];             % Change this?
            config.kind.int2extConv =   @(x)(x);                % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)(x);                % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      'deg';                  % 'Internal' units.
            config.kind.extUnits =      'deg';                  % 'External' units.
            config.kind.base =          0;
            config.kind.resetParam =    '';
            
            config.keyStep =            0;
            config.joyStep =            0;
            
            config.message = 'Polarization is not currently automated...';
            config.verb = 'rotate';
        end
        function config = gridConfig(grid, index)
            config.name = 'Grid Axis in the A direction';

            config.kind.kind =          'grid';
            config.kind.name =          'Grid Axis';
            config.kind.intRange =      [-Inf Inf];             % Change this?
            config.kind.int2extConv =   @(x)(x);                % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)(x);                % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      'sets';                  % 'Internal' units.
            config.kind.extUnits =      'sets';                  % 'External' units.
            config.kind.base =          1;
            config.kind.resetParam =    '';
            
            config.keyStep =            0;
            config.joyStep =            0;
            
            config.grid = grid;
            config.index = index;
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

            params = mcInstrumentHandler.getParams();
            if ismac || params.shouldEmulate
                a.inEmulation = true;
            end
            
            a.x = a.config.kind.base;
            a.xt = a.x;
%             a.goto(a.x);
            
            if ~strcmpi(a.config.name, 'time')      % This prevents infinite recursion...
                a = mcInstrumentHandler.register(a);
            else
                if mcInstrumentHandler.open();
                    warning('Time is automatically added and does not need to be added again...');
                end
            end
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
            
            if strcmpi(a.config.kind.kind, b.config.kind.kind)     % If they are the same kind...
                tf = Eq(a,b);
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
%             switch lower(a.config.kind.kind)
%                 case 'nidaqanalog'
%                     str = [a.config.name ' (' a.config.dev ':' a.config.chn ')'];
%                 case 'nidaqdigital'
%                     str = [a.config.name ' (' a.config.dev ':' a.config.chn ')'];
%                 case 'serial micrometer'
%                     str = [a.config.name ' (' a.config.port ':' a.config.addr ')'];
%                 case 'manual'
%                     str = [a.config.name ' (' a.config.kind.name ':' a.config.verb ')'];
%                 otherwise
%                     str = a.config.name;
%             end
            
            if a.inEmulation
                str = [a.NameShort() ' (Emulation)'];
            else
                str = a.NameShort();
            end
        end
        function str = nameVerb(a)  % Returns a more-detailed description of the Axis.
%             switch lower(a.config.kind.kind)
%                 case 'nidaqanalog'
%                     str = [a.config.name ' (analog input on '  a.config.dev ', channel ' a.config.chn ' with type ' a.config.type ')'];
%                 case 'nidaqdigital'
%                     str = [a.config.name ' (digital input on ' a.config.dev ', channel ' a.config.chn ' with type ' a.config.type ')'];
%                 case 'serial micrometer'
%                     str = [a.config.name ' (serial micrometer on port ' a.config.port ', address' a.config.addr ')'];
%                 case 'manual'
%                     str = [a.config.name ' (' a.config.message ' We must ' a.config.verb 'the ' a.config.kind.name ')'];
%                 otherwise
%                     str = a.config.name;
%             end
            
            if a.inEmulation
                str = [a.NameVerb() ' (Emulation)'];
            else
                str = a.NameVerb();
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
%                     switch lower(a.config.kind.kind)
%                         case 'nidaqanalog'
%                             a.s = daq.createSession('ni');
%                             addAnalogOutputChannel(a.s, a.config.dev, a.config.chn, a.config.type);
%                             a.s.outputSingleScan(a.x);
%                         case 'nidaqdigital'
%                             a.s = daq.createSession('ni');
%                             addDigitalChannel(a.s, a.config.dev, a.config.chn, 'OutputOnly');
%                             a.s.outputSingleScan(a.x);
%                         case 'serial micrometer'
%                             a.s = serial(a.config.port);
%                             set(a.s, 'BaudRate', 921600, 'DataBits', 8, 'Parity', 'none', 'StopBits', 1, ...
%                                 'FlowControl', 'software', 'Terminator', 'CR/LF');
%                             fopen(a.s);
% 
%                             % The following is Srivatsa's code and should be examined.
% 
%                             pause(.25);
%                             fprintf(a.s, [a.config.addr 'HT1']);        % Simplyfying function for this?
%                             fprintf(a.s, [a.config.addr 'SL-5']);        % negative software limit x=-5
%                             fprintf(a.s, [a.config.addr 'BA0.003']);     % change backlash compensation
%                             fprintf(a.s, [a.config.addr 'FF05']);        % set friction compensation
%                             fprintf(a.s, [a.config.addr 'PW0']);         % save to controller memory
%                             pause(.25);
% 
%                             fprintf(a.s, [a.config.addr 'OR']);          % Get to home state (should retain position)
%                             pause(.25);
%                     end
                    tf = a.Open();
                end
%                 tf = true;
            end
        end
        function tf = close(a)      % Closes the session of the axis; returns whether closed or not.
            if a.isOpen
                a.isOpen = false;
                a.inUse = false;
                
                if a.inEmulation
                    % Should something be done?
                else
%                     switch lower(a.config.kind.kind)
%                         case {'nidaqanalog', 'nidaqdigital'}
%                             a.s.release();
%                         case 'serial micrometer'
%                             fprintf(a.s, [a.config.addr 'RS']);
%                             
%                             fclose(a.s);    % Not sure if all of these are neccessary; Srivatsa's old code...
% %                             close(a.s);
%                             delete(a.s); 
%                     end
                    try
                        tf = a.Close();
                    catch err
                        disp(['mcAxis.close(): ' err]);
                        tf = false;
                    end
                end
%                 tf = true;     % Return true because axis was open and is now closed.
            elseif a.inUse
                warning([a.name() ' is in use elsewhere and cannot be used...']);
                tf = false;     % Return false because axis is in use by something else.
            else
%                 warning([a.name() ' is not open; nothing to close...']);
                tf = true;     % Return true because axis is closed already.
            end
        end
        
        function x = getX(a)        % Returns the value of a.x in external units.
            a.read();
            x = a.config.kind.int2extConv(a.x);
        end
        
        function x = getXt(a)       % Returns the value of a.xt in external units.
            x = a.config.kind.int2extConv(a.xt);
        end
        
        function tf = read(a)       % Reads the value of a.x internally; Returns success.
            tf = true;
            
            if a.isOpen
                if a.inEmulation
                    a.ReadEmulation();
                else
                    a.Read();
                end
            else
                tf = false;
            end
        end
        
        function tf = inRange(a, x)
            if iscell(a.config.kind.extRange)
                switch x
                    case a.config.kind.extRange
                        tf = true;
                    otherwise
                        tf = false;
                end
            else
                tf = x <= max(a.config.kind.extRange) && x >= min(a.config.kind.extRange);
            end
        end
        
        function tf = goto(a, x)    % If x is in range, makes sure axis is open, moves axis to x, and returns success.
            tf = true;
            
            if a.inEmulation
                a.xt = a.config.kind.ext2intConv(x);        % Check range?
                
                switch lower(a.config.kind.kind)
%                     case 'serial micrometer'
%                         % The micrometers are not immediate.
%                     case 'manual'
%                         if inRange(a.config.kind.ext2intConv(x), a.config.kind.intRange)
%                             load(gong.mat);
%                             sound(y);
%                             if a.x ~= a.config.kind.ext2intConv(x)
%                                 questdlg([a.config.message ' Please ' a.config.verb ' the ' a.config.kind.name ' of  the ' a.config.name...
%                                           ' from ' num2str(a.config.kind.int2extConv(a.x)) ' ' a.config.kind.extUnits ' to ' num2str(x) ' ' a.config.kind.extUnits], ['Please ' a.config.verb '!'], 'Done', 'Done');
% 
%                                 a.xt = a.config.kind.ext2intConv(x);
%                                 a.x = a.xt;
%                             else
%                                 questdlg([a.config.message ' Is the ' a.config.name...
%                                           ' at ' num2str(a.config.kind.int2extConv(a.x)) '? If not, please ' a.config.verb ' it'], ['Please ' a.config.verb '!'], 'Done', 'Done');
% 
%                             end
%                         else
%                             warning([num2str(x) ' ' a.config.kind.extUnits ' not a valid output.']);
%                             tf = false;
%                         end
%                     otherwise
%                         if inRange(a.config.kind.ext2intConv(x), a.config.kind.intRange)
%                             a.x = a.xt;
%                         else
%                             warning([num2str(x) ' ' a.config.kind.extUnits ' not a valid output for an analog NIDAQ channel.']);
%                             tf = false;
%                         end
                end
            else
                if a.open();   % If the axis is not already open, open it...
                    switch lower(a.config.kind.kind)
%                         case 'nidaqanalog'
%                             if inRange(a.config.kind.ext2intConv(x), a.config.kind.intRange)
%                                 a.xt = a.config.kind.ext2intConv(x);
%                                 a.x = a.xt;
%                                 a.s.outputSingleScan(a.x);
%                             else
%                                 warning([num2str(x) ' ' a.config.kind.extUnits ' not a valid output for an analog NIDAQ channel.']);
%                                 tf = false;
%                             end
%                         case 'nidaqdigital'
%                             switch x    % Should this switch be in inRange() also? It isn't currently to save time.
%                                 case {0, 'low', 'LOW', 'lo', 'LO'}
%                                     a.s.outputSingleScan(0);
%                                     a.x = 0;
%                                     a.xt = 0;
%                                 case {1, 'high', 'HIGH', 'hi', 'HI'}
%                                     a.s.outputSingleScan(1);
%                                     a.x = 1;
%                                     a.xt = 1;
%                                 otherwise
%                                     warning([num2str(x) ' not a valid output for a digital NIDAQ channel.']);
%                                     tf = false;
%                             end
%                         case 'serial micrometer'
%                             if inRange(a.config.kind.ext2intConv(x), a.config.kind.intRange)
%                                 fprintf(a.s, [a.config.addr 'SE' num2str(a.config.kind.ext2intConv(x))]);
%                                 fprintf(a.s, 'SE');                                 % Not sure why this doesn't use config.chn... Srivatsa?
%                                 
%                                 a.xt = a.config.kind.ext2intConv(x);
%                                 
%                                 if abs(a.xt - a.x) > 20 && isempty(a.t)
%                                     a.t = timer('ExecutionMode', 'fixedRate', 'TimerFcn', @a.timerUpdateFcn, 'Period', .2); % 10fps
%                                     start(a.t);
%                                 end
%                             else
%                                 warning([num2str(x) ' ' a.config.kind.extUnits ' not a valid output for 0 -> 25mm micrometers.']);
%                                 tf = false;
%                             end
                        case 'time'
                            
%                         case 'manual'
%                             if inRange(a.config.kind.ext2intConv(x), a.config.kind.intRange)
%                                 load(gong.mat);
%                                 sound(y);
%                                 if a.x ~= a.config.kind.ext2intConv(x)
%                                     questdlg([a.config.message ' Please ' a.config.verb ' the ' a.config.kind.name ' of  the ' a.config.name...
%                                               ' from ' num2str(a.config.kind.int2extConv(a.x)) ' ' a.config.kind.extUnits ' to ' num2str(x) ' ' a.config.kind.extUnits], ['Please ' a.config.verb '!'], 'Done', 'Done');
% 
%                                     a.xt = a.config.kind.ext2intConv(x);
%                                     a.x = a.xt;
%                                 else
%                                     questdlg([a.config.message ' Is the ' a.config.name...
%                                               ' at ' num2str(a.config.kind.int2extConv(a.x)) '? If not, please ' a.config.verb ' it'], ['Please ' a.config.verb '!'], 'Done', 'Done');
% 
%                                 end
%                             else
%                                 warning([num2str(x) ' ' a.kind.extUnits ' not a valid output.']);
%                                 tf = false;
%                             end
                        case 'grid'
                            a.config.grid.virtualPosition(a.config.grid.index) = x;     % Set the grid to the appropriate virtual coordinates...
                            a.config.grid.goto();                                       % Then tell the grid to go to this position.
                        otherwise
                            error('Kind not understood...');
                    end
            
                    drawnow limitrate;
                else
                    tf = false;
                end
            end
        end
        function wait(a)            % Wait for the axis to reach the target value.
            a.read();               % Removed possibility of delay if the axis is already there but has not been read...
                
            if strcmpi(a.config.kind.kind, 'grid')  % If it is a virtual grid axis...
                a.config.grid.wait();               % ...then use the virtual grid wait() function.
            else
                while a.x ~= a.xt       % Make it a 'difference less than tolerance'?
                    a.read();
                    pause(.1);
                end
            end
        end
    end
    
    methods (Access = private)
        function tf = Eq(~, ~)
            tf = false;
        end
        
        function str = NameShort(~)
            str = '';
        end
        function str = NameVerb(~)
            str = '';
        end
        
        function Open(~)
        end
        function Close(~)
        end
        
        function ReadEmulation(~, ~)
        end
        function Read(~, ~)
        end
        
        function GotoEmulation(~, ~)
        end
        function Goto(~, ~)
        end
    end
end

