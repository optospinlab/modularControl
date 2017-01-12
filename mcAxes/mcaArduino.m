classdef (Sealed) mcaArduino < mcAxis
% mcaArduino communicates via serial to an Arduino. Currently, it is only programmed to send '1' for
% 'on' and '0' for 'off'. Ideally, this will be made scalable in the future.
%
% Also see mcAxis.

    methods (Static)    % The folllowing static configs are used to define the identity of axis objects. configs can also be loaded from .mat files
        % Neccessary extra vars:
        %  - port
        
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
            fprintf(a.s, num2str(a.x));  % Send '0' or '1' to the pump...
        end
    end
end




