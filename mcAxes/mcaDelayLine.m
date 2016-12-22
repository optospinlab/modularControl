classdef (Sealed) mcaDelayLine < mcAxis
% mcaDelayLine is a servo-controlled path-delay arm from Emma's previous lab (with picosecond? precision).
%
% Also see mcaTemplate and mcAxis.
    
    methods (Static)
        % Neccessary extra vars:
        %  - port
        
        function config = defaultConfig()
            config = mcaDelayLine.customConfig();
        end
        function config = customConfig()
            config.class =              'mcaDelayLine';
            
            config.name =               'Delay Line';

            config.kind.kind =          'delayline';
            config.kind.name =          'DelayLine<insert servo name>100ps';
            config.kind.intRange =      [0 100];    % Not sure about the range. Using 0 -> 100 mm.
            
            shift_mm             = 0;       % This information should be stored in the functions which convert 'external' units to 'internal' units and back.
            stp_per_mm           = 100;
            mm_per_ps            = 0.06;
            microstep_res        = 64;
            
            config.kind.int2extConv =   @(x)( (x/stp_per_mm/microstep_res + shift_mm)/mm_per_ps );
            config.kind.ext2intConv =   @(x)( (x*mm_per_ps - shift_mm)*microstep_res*stp_per_mm );
            config.kind.intUnits =      'microsteps';
            config.kind.extUnits =      'ps';           % (picoseconds?)
            config.kind.base =          0;
            
            config.keyStep =            .1;
            config.joyStep =            1;
            
            % Custom vars for this delay line
            config.port = 'COM5';
        end
    end
    
    methods
        function a = mcaDelayLine(varin)
            a.extra = {'customVar1', 'customVar2'};
            if nargin == 0
                a.construct(mcaDelayLine.defaultConfig());
            else
                a.construct(varin);
            end
            a = mcInstrumentHandler.register(a);
        end
    end
    
    % These methods overwrite the empty methods defined in mcAxis. mcAxis will use these.
    methods
        % NAME
        function str = NameShort(a)
            % This is the reccommended a.nameShort().
            str = [a.config.name ' (' a.config.port ')'];
        end
        function str = NameVerb(a)
            str = [a.config.name ' (a delay line on port ' a.config.port ')'];
        end
        
        %EQ
        function tf = Eq(a, b)          % Compares two mcaDelayLines
            tf = strcmpi(a.config.port,  b.config.port);
        end
        
        % OPEN/CLOSE
        function Open(a)
            a.s = serial(a.config.port);
            set(a.s,    'Name', [a.config.name '_' a.config.port], ...
                        'BaudRate', 9200, ...
                        'Terminator', '', ...
                        'Timeout', 1);
            fopen(a.s);
            
            a.reset()   % I think that this is currently the best position for reset.
        end
        function Close(a)
            fclose(a.s);
        end
        
        % READ
        function ReadEmulation(a)
            a.x = a.xt;         % Sets the actual postition of the axis to the target position in the absence of an actual actual position.
        end
        function Read(a)
            cmd = [1 53 45 0 0 0];
            a.x = query(a.config.obj, cmd);
        end
        
        % GOTO
        function GotoEmulation(a, x)
            % Emulate the behavior of an actual mcaTemplate.
            a.xt = a.config.kind.ext2intConv(x);
            a.x = a.xt;
        end
        function Goto(a, x)
            a.xt = a.config.kind.ext2intConv(x);    % Set the target position to the user's x.
            
            posBytes = a.data2bytes(a.xt);
            cmd = [1 45 posBytes];
            fprintf(a.s, cmd);
            
            a.x = a.xt;                             % If this axis immediately advances to the target (e.g. peizos), then set a.x.
        end
    end
        
    methods
        % EXTRA
        function cmd_bytes = data2bytes (~, data)
            data = round(data);

            if data < 0
                data = data +256^4;
            end

            cmd_bytes(4) = floor(data / 256^3);
            data = data - cmd_bytes(4)*256^3;
            cmd_bytes(3) = floor(data / 256^2);
            data = data - cmd_bytes(3)*256^2;
            cmd_bytes(2) = floor(data / 256);
            data = data - cmd_bytes(2)*256;
            cmd_bytes(1) = data;
        end

        function reset(a)   %Homes the axis
            cmd = [1 1 0 0 0 0]; 
            fprintf(a.config.obj, cmd);
        end
    end
end




