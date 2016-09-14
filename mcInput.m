classdef mcInput < mcSavableClass
% Abstract class for instruments with that measure some sort of data. This includes:
%   - NIDAQ
%       + Counters
%       + Analog/Digital in
%   - Spectrometers
%   - Cameras
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
%   tf =    I.open()                            % Opens a session of the input (e.g. for a counter, a NIDAQ session); returns whether open or not.
%   tf =    I.close()                           % Closes the session of the input; returns whether closed or not.
%
%   data =  I.measure(integrationTime)          % Measures the input for integrationTime seconds and returns the result.
%
%   tf =    I.addToSession(s)                   % If the input is NIDAQ, adds the input to the NIDAQ session s.
%
% Status: Mostly finished. Mostly commented. See below for future plans.
%
% IMPORTANT: Not sure whether a better architecture decision would be to
% have kinds (such as piezos and galvos) extend the mcAxis class in their
% own subclass (e.g. mcPiezo < mcAxis) instead of the potentially-messy 
% switch statements that are currently in the code.
% UPDATE: Decided to change this eventually, but keep it the same for now.
    
    properties
%         config = [];            % Defined in mcSavableClass. All static variables (e.g. valid range) go in config.
        
        s = [];                 % Session, whether serial or NIDAQ.
        
        isOpen = false;         % Boolean.
        inUse = false;          % Boolean.
        inEmulation = false;    % Boolean.
    end
    
    methods
        function construct(I, varin)
            % Constructor
            if iscell(varin)
                config = varin{1};
                
                if length(varin) == 2
                    if islogical(varin{2}) || isnumeric(varin{2})
                        I.inEmulation = varin{2};
                    else
                        warning('Second argument not understood; it needs to be logical or numeric');
                    end
                end
            else
                config = varin;
            end
                    
            if ischar(config)
                if exist(config, 'file') && strcmpi(config(end-3:end), '.mat')
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
            
            params = mcInstrumentHandler.getParams();
            if ismac || params.shouldEmulate
                I.inEmulation = true;
            end
            
%             I = mcInstrumentHandler.register(I);
        end
        
        function I = mcInput(varin)
            % Constructor 
            switch nargin
                case 0
                    I.config = I.defaultConfig();
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
            
            params = mcInstrumentHandler.getParams();
            if ismac || params.shouldEmulate
                I.inEmulation = true;
            end
            
            I = mcInstrumentHandler.register(I);
        end
        
        function tf = eq(I, b)  % Check if a foriegn object (b) is equal to this input object (a).
            if ~isprop(b, 'config')     % Make sure that b.config.kind.kind exists...
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
            
            if strcmp(I.config.kind.kind, b.config.kind.kind)               % If they are the same kind...
                tf = I.Eq(b);
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
            if I.inEmulation
                str = [I.NameShort() ' (Emulation)'];
            else
                str = I.NameShort();
            end
        end
        function str = nameVerb(I)
            if I.inEmulation
                str = [I.NameVerb() ' (Emulation)'];
            else
                str = I.NameVerb();
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
                    % Do something?
                    tf = true;
                else
                    try
                        I.Open();
                        tf = true;     % Return true because axis has been opened.
                    catch err
                        disp(['mcInput.open() - ' I.config.name ': ' err]);
                        tf = false;
                    end
                end
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
                            release(I.s);
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
            if I.open()
                if I.inEmulation
                    data = I.MeasureEmulation(integrationTime);
                else
                    data = I.Measure(integrationTime);
                end
                
                if length(size(data)) ~= length(I.config.kind.sizeInput)
                    data = NaN(I.config.kind.sizeInput);
                    warning(['mcInput - ' I.config.name ': measured data has unexpected size of [' num2str(size(data)) '] vs [' num2str(I.config.kind.sizeInput) ']...']);
                    return;
                end
                
                if ~all(size(data) == I.config.kind.sizeInput)
                    data = NaN(I.config.kind.sizeInput);
                    warning(['mcInput - ' I.config.name ': measured data has unexpected size of [' num2str(size(data)) '] vs [' num2str(I.config.kind.sizeInput) ']...']);
                end
            else
                data = NaN(I.config.kind.sizeInput);
                warning(['mcInput - ' I.config.name ': could not open input...']);
            end
        end
        
        function axes_ = getInputAxes(I)
            if all(I.config.kind.sizeInput == 1)
                axes_ = [];
            else
                nonsingular = I.config.kind.sizeInput(I.config.kind.sizeInput ~= 1);
                axes_ = cell(1,length(nonsingular));
                
                for ii = 1:length(nonsingular)
                    axes_{ii} = 1:nonsingular(ii);
                end
            end
        end
    end
    
    methods
        % EQ
        function tf = Eq(~, ~)
            tf = false;     % or true?
        end
        
        % NAME
        function str = NameShort(~)
            str = '';
        end
        function str = NameVerb(~)
            str = '';
        end
        
        % OPEN/CLOSE
        function Open(~)
        end
        function Close(~)
        end
        
        % MEASURE
        function data = MeasureEmulation(~, ~)
            data = NaN(I.config.kind.sizeInput);
        end
        function data = Measure(~, ~)
            data = NaN(I.config.kind.sizeInput);
        end
    end
end




