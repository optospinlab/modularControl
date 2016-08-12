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
% UPDATE: Currently in progress.

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
                tf = a.Eq(b);
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
        function str = nameRange(a) % Returns description in 'nRange: rmin to rmax (units)' form.
            if iscell(a.config.kind.extRange)
                str = ['Allowed Values: ' strjoin(cellfun(@(x)([num2str(x) ',' ]), a.config.kind.extRange(1:end-1), 'UniformOutput', false)) ' or ' num2str(a.config.kind.extRange{end}) ' (' a.config.kind.extUnits ')'];
            else
                str = ['Range: ' num2str(a.config.kind.extRange(1)) ' to ' num2str(a.config.kind.extRange(2)) ' (' a.config.kind.extUnits ')'];
            end
        end
        function str = nameShort(a) % Returns description in 'name (info1:info2:...)' form with ' (Emulation)' if emulating.
            if a.inEmulation
                str = [a.NameShort() ' (Emulation)'];
            else
                str = a.NameShort();
            end
        end
        function str = nameVerb(a)  % Returns a more-detailed description of the Axis.
            if a.inEmulation
                str = [a.NameVerb() ' (Emulation)'];
            else
                str = a.NameVerb();
            end
        end
        
        function tf = open(a)       % Opens a session of the axis (e.g. for the micrometers, a serial session); returns whether open or not.
            if a.isOpen
%                 warning([a.name() ' is already open...']);
                tf = true;     % Return true because axis is open already.
            elseif a.inUse
                warning([a.name() ' is already in use...']);
                tf = false;
            else
                a.isOpen = true;
                a.inUse = true;
                
                if a.inEmulation
                    % Should something be done?
                else
                    try
                        a.Open();
                        tf = true;     % Return true because axis has been opened.
                    catch err
                        disp(['mcAxis.open() - ' a.config.name ': ' err]);
                        tf = false;
                    end
                end
            end
        end
        function tf = close(a)      % Closes the session of the axis; returns whether closed or not.
            if a.isOpen
                a.isOpen = false;
                a.inUse = false;
                
                if a.inEmulation
                    % Should something be done?
                else
                    try
                        a.Close();
                        tf = true;     % Return true because axis was open and is now closed.
                    catch err
                        disp(['mcAxis.close() - ' a.config.name ': ' err]);
                        tf = false;
                    end
                end
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
            
            if a.inRange(x)
                if a.inEmulation
                    a.GotoEmulation(x);
                else
                    if a.open();                % If the axis is not already open, open it...
                        a.Goto(x);

    %                     drawnow limitrate;
                    else
                        tf = false;
                    end
                end
            else
                tf = false;
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
            tf = false;     % or true?
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

