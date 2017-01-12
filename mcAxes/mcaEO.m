
classdef (Sealed) mcaEO < mcAxis
% mcaEO controls the (Edmonds Optics?) Z objective peizo in Brynn's microscope (untested!).
%
% Also see mcAxis.

    methods (Static)    % The folllowing static configs are used to define the identity of axis objects. configs can also be loaded from .mat files
        % Neccessary extra vars:
        %  - customVar1
        %  - customVar2
        
        function config = defaultConfig()               % Static config that should be used if no configuration is provided upon intialization.
            config = mcaEO.brynnObjConfig();
        end
        function config = brynnObjConfig()
            config.class =              'mcaEO';
            
            config.name =               'EO Z';

            config.kind.kind =          'eopizeo';
            config.kind.name =          'Edmonds Optics Piezo';
            config.kind.intRange =      [0 100];
            config.kind.int2extConv =   @(x)(x);
            config.kind.ext2intConv =   @(x)(x);
            config.kind.intUnits =      'um';
            config.kind.extUnits =      'um';
            config.kind.base =          0;
            
            config.keyStep =            .1;
            config.joyStep =            1;
            
            config.srl = int16(1051);
        end
    end
    
    methods             % Initialization method (this is what is called to make an axis object).
        function a = mcaEO(varin)
            a.extra = {'srl'};
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
            str = [a.config.name ' (' num2str(a.config.srl) ')'];
        end
        function str = NameVerb(a)      % 'verbose' name, suitable to explain the identity to future users.
            str = [a.config.name ' (an Edmonds Optics piezo with serial number ' num2str(a.config.srl) ')'];   % ** Change these to your custom vars.
        end
        
        %EQ ------------- The function that should return true if the custom vars are the same (future: use a.extra for this?)
        function tf = Eq(a, b)          % Compares two mcaEO
            tf = a.config.srl == b.config.srl;
        end
        
        % OPEN/CLOSE ---- The functions that define how the axis should init/deinitialize (these functions are not used in emulation mode).
        function Open(a)                % Do whatever neccessary to initialize the axis.
            addpath('C:\Program Files\Edmund Optics\EO-Drive\');

            % Check if dll already loaded; if not, load dll
            if ~libisloaded('EO_Drive')
                loadlibrary('EO_Drive.dll','eo_drive.h');
            end

            % Initialize and get handle for controller.
            calllib('EO_Drive','EO_InitHandle');
            a.s = calllib('EO_Drive','EO_GetHandleBySerial',srl);
        end
        function Close(a)               % Do whatever neccessary to deinitialize the axis.
            calllib('EO_Drive','EO_ReleaseHandle');
            a.s = [];
        end
        
        % READ ---------- For 'slow' axes that take a while to reach the target position (a.xt), define a way to determine the actual position (a.x). These do *not* have to be defined for 'fast' axes.
        function ReadEmulation(a)       
            a.x = a.xt;
        end
        function Read(a)
            pos = libpointer('doublePtr',0); %initialize pointer (type 'double', value 0) to get commanded position
            [errcode,pos] = calllib('EO_Drive','EO_GetCommandPosition',hndl,pos);   % Return commanded position (pos)
            
            a.x = pos;
        end
        
        % GOTO ---------- The 'meat' of the axis: the funtion that translates the user's intended movements to reality.
        function GotoEmulation(a, x)
            a.xt = a.config.kind.ext2intConv(x);
            a.x = a.xt;
        end
        function Goto(a, x)
            [errcode] = calllib('EO_Drive', 'EO_Move', a.s, x);     % Move to commanded position (position in um)
        end
    end
end