classdef (Sealed) mcaAPT < mcAxis
% mcaAPT connects to Thorlabs APT (Advanced Positioning Technology) devices through the ActiveX GUI.
% The actual GUI is hidden, by defualt, and all communication is done normally via mcAxis methods.
%
% Also see mcAxis.

    methods (Static)    % The folllowing static configs are used to define the identity of axis objects. configs can also be loaded from .mat files
        % Neccessary extra vars:
        %  - control
        %  - SN
        
        function config = defaultConfig()               % Static config that should be used if no configuration is provided upon intialization.
            config = mcaAPT.calibratedConfig();
        end
        function config = rotatorConfig()
            config.class =              'mcaAPT';
            
            config.name =               'Rotator';

            config.kind.kind =          'aptcontrol';
            config.kind.name =          'Thorlabs APT Stepper Rotator';
            config.kind.intRange =      [0 360];                            % How to handle looping from 360 -> 0?
            config.kind.int2extConv =   @(x)(x);
            config.kind.ext2intConv =   @(x)(x);
            config.kind.intUnits =      'degrees';
            config.kind.extUnits =      'degrees';
            config.kind.base =          0;
            
            config.keyStep =            1;
            config.joyStep =            10;
            
            config.control =            'MGMOTOR.MGMotorCtrl.1';
            config.SN =                 83848988;
            
            config.chn =                0;  % Use the first channel. Currently, no multi-channel support.
        end
        function config = calibratedConfig()
            config.class =              'mcaAPT';
            
            config.name =               'Rotator';

            % Fit to 'a*cos( c * (x - b)) + d'
            b = 0.05941;
            c = 0.5566;
            
            config.kind.kind =          'aptcontrol';
            config.kind.name =          'Thorlabs APT Stepper Rotator (Calibrated 1/4/17)';
            config.kind.intRange =      [0 360];                            % How to handle looping from 360 -> 0?
            config.kind.int2extConv =   @(x)( 90*(0.5566 * (x - 0.05941))/(2*pi) );
            config.kind.ext2intConv =   @(x)( 0.05941 + x*(2*pi)/(90*c) );
            config.kind.intUnits =      'uncalibrated degrees';
            config.kind.extUnits =      'degrees';
            config.kind.base =          0;
            
            config.keyStep =            1;
            config.joyStep =            10;
            
            config.control =            'MGMOTOR.MGMotorCtrl.1';
            config.SN =                 83848988;
            
            config.chn =                0;  % Use the first channel. Currently, no multi-channel support.
        end
    end
    
    methods             % Initialization method (this is what is called to make an axis object).
        function a = mcaAPT(varin)
            a.extra = {'control', 'SN'};
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
            str = [a.config.name ' (' a.config.control ':' num2str(a.config.SN) ')'];
        end
        function str = NameVerb(a)      % 'verbose' name, suitable to explain the identity to future users.
            str = [a.config.name ' (an APT control with ActiveX control type ' a.config.control ' and serial number ' num2str(a.config.SN) ')'];   % ** Change these to your custom vars.
        end
        
        %EQ ------------- The function that should return true if the custom vars are the same (future: use a.extra for this?)
        function tf = Eq(a, b)          % Compares two mcaAPT
            tf = strcmpi(a.config.control,  b.config.control) && a.config.SN ==  b.config.SN;
        end
        
        % OPEN/CLOSE ---- The functions that define how the axis should init/deinitialize (these functions are not used in emulation mode).
        function Open(a)                    % Do whatever neccessary to initialize the axis.
            f = figure('Resize', 'off', 'Visible', 'off');                      % Don't show the controller...
            a.s = actxcontrol(a.config.control, [[0 0], f.Position(3:4)], f);   % Initialize the activeX object.
            
            a.s.HWSerialNum = a.config.SN;  % Set the serial number to be the device we are looking for
            
            a.s.StartCtrl;                  % Start the activeX controller.
            
            a.s.Identify;                   % Identify the device
%             a.s.MoveHome(0,0);    % Channel ID = 0; time = 0 (= immediately)
        end
        function Close(a)                   % Do whatever neccessary to deinitialize the axis.
            a.s.StopCtrl;
        end
        
        % READ ---------- For 'slow' axes that take a while to reach the target position (a.xt), define a way to determine the actual position (a.x). These do *not* have to be defined for 'fast' axes.
        function ReadEmulation(a)       
            a.x = a.xt;         % ** In emulation, just assume the axis is 'fast'?
        end
        function Read(a)
            a.x = a.s.GetPosition_Position(a.config.chn);
        end
        
        % GOTO ---------- The 'meat' of the axis: the funtion that translates the user's intended movements to reality.
        function GotoEmulation(a, x)
            a.xt = a.config.kind.ext2intConv(x);    % ** Usually, behavior should not deviate from this default a.GotoEmulation(x) function. Change this if more complex behavior is desired.
            a.x = a.xt;
        end
        function Goto(a, x)
            a.xt = a.config.kind.ext2intConv(x);    % Set the target position a.xt (in internal units) to the user's desired x (in internal units).
            
            a.s.SetAbsMovePos(  a.config.chn, x);
            a.s.MoveAbsolute(   a.config.chn, true);
        end
    end
        
    methods
        % EXTRA --------- Any additional functionality this axis should have (remove if there is none).
%         function specificFunction(a)
%             
%         end
    end
end




