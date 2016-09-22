classdef (Sealed) mcaTemplate < mcAxis
% mcaTemplate aims to explain the essentials for making a custom mcAxis.
    
    methods (Static)
        % Neccessary extra vars:
        %  - customVar1
        %  - customVar2
        
        function config = defaultConfig()
            config = mcaTemplate.customConfig();
        end
        function config = customConfig()
            config.name = 'Template';

            config.kind.kind =          'template';
            config.kind.name =          'Template';
            config.kind.intRange =      [-42 42];               % Change this?
            config.kind.int2extConv =   @(x)(x);                % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)(x);                % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      'units';                % 'Internal' units.
            config.kind.extUnits =      'units';                % 'External' units.
            config.kind.base =          0;
            
            config.keyStep =            .1;
            config.joyStep =            1;
            
            config.customVar1 = 'Important Var 1';
            config.customVar2 = 'Important Var 2';
        end
    end
    
    methods
        function a = mcaTemplate(varin)     % Insert mca[Custom] name here...
            a.extra = {'customVar1', 'customVar2'};
            if nargin == 0
                a.construct(mcaTemplate.defaultConfig());
            else
                a.construct(varin);
            end
            a = mcInstrumentHandler.register(a);
        end
    end
    
    % These methods overwrite the empty methods defined in mcAxis. mcAxis will use these.
    methods %(Access = ?mcAxis)
        % NAME
        function str = NameShort(a)
            % This is the reccommended a.nameShort().
            str = [a.config.name ' (' a.config.customVar1 ':' a.config.customVar2 ')'];
        end
        function str = NameVerb(a)
            str = [a.config.name ' (a template for custom mcAxes with custom vars ' a.config.customVar1 ' and ' a.config.customVar2 ')'];
        end
        
        %EQ
        function tf = Eq(a, b)          % Compares two mcaTemplates
            tf = strcmpi(a.config.customVar1,  b.config.customVar1) && strcmpi(a.config.customVar2,  b.config.customVar2);
        end
        
        % OPEN/CLOSE
        function Open(a)
            % Do whatever neccessary to initialize the axis.
            open(a.config.customVar1, a.config.customVar2);     % (fake line)
        end
        function Close(a)
            % Do whatever neccessary to deinitialize the axis.
            close(a.config.customVar1, a.config.customVar2);    % (fake line)
        end
        
        % READ
        function ReadEmulation(a)
            a.x = a.xt;         % Sets the actual postition of the axis to the target position in the absence of an actual actual position.
        end
        function Read(a)
            a.x = read(a.s);    % (fake line), reads the session to get the actual postition of the axis.
        end
        
        % GOTO
        function GotoEmulation(a, x)
            % Emulate the behavior of an actual mcaTemplate.
            a.xt = a.config.kind.ext2intConv(x);
            a.x = a.xt;
        end
        function Goto(a, x)
            a.xt = a.config.kind.ext2intConv(x);    % Set the target position to the user's x.
            a.x = a.xt;                             % If this axis immediately advances to the target (e.g. peizos), then set a.x.
        end
    end
        
    methods
        % EXTRA
        function specificFunction(a)
            % A function specific to mcaTemplate.
            specific(a.x);      % (fake line)
        end
    end
end




