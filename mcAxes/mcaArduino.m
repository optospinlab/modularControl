classdef (Sealed) mcaArduino < mcAxis          % ** Insert mca<MyNewAxis> name here...
% mcaTemplate aims to explain the essentials for making a custom mcAxis.
%
% 1) To make a custom axis, copy and rename this file to mca<MyNewAxis> where <MyNewAxis> is a descriptive, yet brief name
% for this type of axis (e.g. mcaDAQ for DAQ axes, mcaMicro for Newport Micrometers).
% 2) Next, replace all of the lines starred with '**' with code appropriate for the new type.
%
% Keep in mind the separation between behavior (the content of the methods) and identity (the content of a.config).
%
% There are five (relevant) properties that are pre-defined in mcAxis that the user should be aware of:
%       a.config    % The config structure that should only be used to define the axis identity. *No* runtime information should be stored in config (e.g. serial session).
%       a.s         % This should be used for the persistant axis session, whether serial, NIDAQ, or etc.
%       a.t         % An additional 'timer' session for unusual axes (see mcaMicro for use to poll the micros about the current position).
%       a.extra     % A (currently unused) cell array which should contain the names of the essential custom variables for the config (why isn't this in a.config?).
%       a.x         % Current position of the axis in the internal units of the 1D parameterspace.
%       a.xt        % Target position of the axis in the internal units of the 1D parameterspace. This is useful for 'slow' axes which do not immdiately reach the destination (e.g. micrometers) for 'fast' axes (e.g. piezos), a.x should always equal a.xt.
%
% Syntax:
%
% + Initialization:
%
%   a = mca<MyNewAxis>()                        % Open with default configuration.
%   a = mca<MyNewAxis>(config)                  % Open with configuration given by the struct 'config'.
%   a = mca<MyNewAxis>('config_file.mat')       % Open with config file in 'MATLAB_PATH\configs\axisconfigs\' (not entirely functional at the moment)
%
%   config = mca<MyNewAxis>.<myType>Config()    % Returns a static config struture for that type (e.g. use as the config struct above).
%   
% + Naming:
%
%   str =   a.name()                            % Returns the default name. This is currently nameShort().
%   str =   a.nameUnits()                       % Returns info about this axis in 'name (units)' form.
%   str =   a.nameShort()                       % Returns short info about this axis in a readable form.
%   str =   a.nameVerb()                        % Returns verbose info about this axis in a readable form.
%
% + Interaction:
%
%   tf =    a.open()                            % Opens a session of the axis (e.g. for the micrometers, a serial session); returns whether open or not.
%   tf =    a.close()                           % Closes the session of the axis; returns whether closed or not.
%
%   tf =    a.inRange(x)                        % Returns true if x is in the external range of a.
%
%   tf =    a.goto(x)                           % If x is in range, makes sure axis is open, moves axis to x, and returns success.
%
%   tf =    a.read()                            % Reads the current position of the axis, returns success. This is useful for 'slow' axes like micrometers where a.xt (the target position) does not match the real position.
%
%   x =     a.getX(x)                           % Returns the position of the axis (a.x) in external units.
%   x =     a.getXt(x)                          % Returns the target position of the axis (a.xt) in external units.
%
% Also see mcAxis.

    methods (Static)    % The folllowing static configs are used to define the identity of axis objects. configs can also be loaded from .mat files
        % ** Change the below so that future users know what neccessary extra variables should be included in custom configs (e.g. 'dev', 'chn', and 'type' for DAQ devices).
        % Neccessary extra vars:
        %  - customVar1
        %  - customVar2
        
        function config = defaultConfig()               % Static config that should be used if no configuration is provided upon intialization.
            config = mcaArduino.flipMirrorConfig();
        end
        function config = flipMirrorConfig()
            config.class =              'mcaArduino';  % ** Change this to 'mca<MyNewAxis>'.
            
            config.name =               'Flip Mirror';

            config.kind.kind =          'arduino';
            config.kind.name =          'Arduino-Controlled Flip Mirror';
            config.kind.intRange =      {0 1};
            config.kind.int2extConv =   @(x)(x);
            config.kind.ext2intConv =   @(x)(x);
            config.kind.intUnits =      '0/1';
            config.kind.extUnits =      '0/1';
            config.kind.base =          0;
            
            config.keyStep =            1;
            config.joyStep =            1;
            
            config.port = 'COM7';
        end
    end
    
    methods             % Initialization method (this is what is called to make an axis object).
        function a = mcaArduino(varin)
            a.extra = {'port'};
            if nargin == 0
                a.construct(a.defaultConfig());
            else
                a.construct(varin);
            end
            a = mcInstrumentHandler.register(a);
        end
    end
    
    % These methods overwrite the empty methods defined in mcAxis. These methods are used in the uncapitalized parent methods defined in mcAxis.
    methods
        % NAME ---------- The following functions define the names that the user should use for this axis.
        function str = NameShort(a)     % 'short' name, suitable for UIs/etc.
            str = [a.config.name ' (' a.config.port ')'];
        end
        function str = NameVerb(a)      % 'verbose' name, suitable to explain the identity to future users.
            str = [a.config.name ' (Arduino on port ' a.config.port ')'];
        end
        
        %EQ ------------- The function that should return true if the custom vars are the same (future: use a.extra for this?)
        function tf = Eq(a, b)          % Compares two mcaTemplates
            tf = strcmpi(a.config.port,  b.config.port);
        end
        
        % OPEN/CLOSE ---- The functions that define how the axis should init/deinitialize (these functions are not used in emulation mode).
        function Open(a)                % Do whatever neccessary to initialize the axis.
            a.s = serial(a.config.port);
            set(a.s, 'BaudRate', 74880);    % Make this a config var?
            fopen(a.s);                     % Error check?
        end
        function Close(a)               % Do whatever neccessary to deinitialize the axis.
            fclose(a.s);
        end
        
        % GOTO ---------- The 'meat' of the axis: the funtion that translates the user's intended movements to reality.
        function GotoEmulation(a, x)
            a.xt = a.config.kind.ext2intConv(x);    % ** Usually, behavior should not deviate from this default a.GotoEmulation(x) function. Change this if more complex behavior is desired.
            a.x = a.xt;
        end
        function Goto(a, x)
            a.xt = a.config.kind.ext2intConv(x);
            a.x = a.xt;
            printf(a.s, num2str(a.x));  % Send '0' or '1' to the pump...
        end
    end
end




