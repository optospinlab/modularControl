classdef (Sealed) mcaPoints < mcAxis          % ** Insert mca<MyNewAxis> name here...
% mcaPoints is an axis that traverses a series of points. There is no limit to the number of points nor the number of axes which
% define each point.
%
% For example, our series of (say, N) points could be defined in 3D piezo-space, where our three axes are piezoX, piezoY, piezoZ.
%
% This axis is similar to mcaGrid, with a critical difference:
%
% Also see mcAxis.

    properties
        axes_ = {};
    end

    methods (Static)    % The folllowing static configs are used to define the identity of axis objects. configs can also be loaded from .mat files
        %  - A
        
        function config = defaultConfig()               % Static config that should be used if no configuration is provided upon intialization.
            config = mcaPoints.customConfig();
        end
        function config = brightSpotConfig(data)
            config.class =              'mcaPoints';
            
            config.name =               'Template';     % ** Change this to the UI name for this identity of mca<MyNewAxis>.

            config.kind.kind =          'template';     % ** Change this to the programatic name that the program should use for this identity of mca<MyNewAxis>.
            config.kind.name =          'Template';     % ** Change this to the technical name (e.g. name of device) for this identity of mca<MyNewAxis>.
            config.kind.intRange =      [-42 42];       % ** Change this to the range of the axis (e.g. [0 10] for a 0 -> 10 V DAQ piezo). This is in internal units (.extRange is generated by mcAxis). Use a cell array if the range is not continuous (e.g. on/off would be {0 1})
            config.kind.int2extConv =   @(x)(x);        % ** Change this to the conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)(x);        % ** Change this to the conversion from 'external' units to 'internal' (inverse of above).
            config.kind.intUnits =      'units';        % ** Rename these to whatever units are used...     ...internally (e.g. 'V' for DAQ piezos)
            config.kind.extUnits =      'units';        % **                                                ...externally (e.g. 'um' for DAQ piezos)
            config.kind.base =          0;              % ** Change this to the point (in external units) that the axis should seek at startup (future: NaN = don't seek?).
            
            config.keyStep =            .1;             % ** Change this to the speed or step-every-tick (in external units) that this axis should move with...     ...the keyboard and
            config.joyStep =            1;              % **                                                                                                        ...the joystick  (these can be modified in the mcUserInput UI).
            
            config.A =      ;
            config.axes =   data.d.a;
        end
    end
    
    methods             % Initialization method (this is what is called to make an axis object).
        function a = mcaTemplate(varin)                 % ** Insert mca<MyNewAxis> name here...
            a.extra = {'A', 'axes'};     % ** Record the names of the custom variables here (These may be used elsewhere in the program in the future).
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
            str = [a.config.name ' (' a.config.customVar1 ':' a.config.customVar2 ')'];                                                     % ** Change these to your custom vars.
        end
        function str = NameVerb(a)      % 'verbose' name, suitable to explain the identity to future users.
            str = [a.config.name ' (a template for custom mcAxes with custom vars ' a.config.customVar1 ' and ' a.config.customVar2 ')'];   % ** Change these to your custom vars.
        end
        
        %EQ ------------- The function that should return true if the custom vars are the same (future: use a.extra for this?)
        function tf = Eq(a, b)          % Compares two mcaTemplates
            tf = strcmpi(a.config.customVar1,  b.config.customVar1) && strcmpi(a.config.customVar2,  b.config.customVar2);                  % ** Change these to your custom vars.
        end
        
        % OPEN/CLOSE ---- The functions that define how the axis should init/deinitialize (these functions are not used in emulation mode).
        function Open(a)                % Do whatever neccessary to initialize the axis.
            a.s = open(a.config.customVar1, a.config.customVar2);   % ** Change this to the custom code which opens the axis. Keep in mind that a.s should be used to store session info (e.g. serial ports, DAQ sessions). Of course, for some inputs, this is unneccessary.
        end
        function Close(a)               % Do whatever neccessary to deinitialize the axis.
            close(a.config.customVar1, a.config.customVar2);        % ** Change this to the custom code which closes the axis.
        end
        
        % READ ---------- For 'slow' axes that take a while to reach the target position (a.xt), define a way to determine the actual position (a.x). These do *not* have to be defined for 'fast' axes.
        function ReadEmulation(a)       
            a.x = a.xt;         % ** In emulation, just assume the axis is 'fast'?
        end
        function Read(a)
            a.x = read(a.s);    % ** Change this to the code to get the actual postition of the axis.
        end
        
        % GOTO ---------- The 'meat' of the axis: the funtion that translates the user's intended movements to reality.
        function GotoEmulation(a, x)
            a.xt = a.config.kind.ext2intConv(x);    % ** Usually, behavior should not deviate from this default a.GotoEmulation(x) function. Change this if more complex behavior is desired.
            a.x = a.xt;
        end
        function Goto(a, x)
            a.xt = a.config.kind.ext2intConv(x);    % Set the target position a.xt (in internal units) to the user's desired x (in internal units).
            a.x = a.xt;                             % If this axis is 'fast' and immediately advances to the target (e.g. peizos), then set a.x.
            goto(a.s, a.x)                          % ** Change this to be the code that actually moves the axis (also change the above if different behavior is desired).
                                                    % Also note that all 'isInRange' error checking is done in the parent mcAxis.
        end
    end
        
    methods
        % EXTRA --------- Any additional functionality this axis should have (remove if there is none).
        function specificFunction(a)    % ** Rename to a descriptive name for the additional functionality.
            specific(a);                % ** Change to the appropriate code for this additional functionality.
        end
    end
end




