classdef (Sealed) mcaMicro < mcAxis
% mcaMicro is the subclass of mcAxis for Newport serial micrometers.
%
% Also see mcaTemplate and mcAxis.
%
% Status: Finished. Reasonably commented.
    
    methods (Static)
        % Neccessary extra vars:
        %  - port
        %  - addr
        
        function config = defaultConfig()
            config = mcaMicro.microConfig();
        end
        function config = microConfig()
            config.class =              'mcaMicro';
            
            config.name =               'Default Micrometers';

            config.kind.kind =          'Serial Micrometer';
            config.kind.name =          'Newport Micrometer';
            config.kind.intRange =      [0 25];                 % 0 -> 25 mm.
            config.kind.int2extConv =   @(x)(x.*1000);          % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)(x./1000);          % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      'mm';                   % 'Internal' units.
            config.kind.extUnits =      'um';                   % 'External' units.
            config.kind.base =          0;                      % The (internal) value that the axis seeks at startup.
            config.kind.resetParam =    '';                     % Currently unused? Check this.

            config.port =               'COM6';                 % Micrometer Port.
            config.addr =               '1';                    % Micrometer Address.
            
            config.keyStep =            .5;
            config.joyStep =            5;
        end
    end
    
    methods
        function a = mcaMicro(varin)
            a.extra = {'port', 'addr'};
            if nargin == 0
                a.construct(a.defaultConfig());
            else
                a.construct(varin);
            end
            a = mcInstrumentHandler.register(a);
        end
    end
    
    % These methods overwrite the empty methods defined in mcAxis. mcAxis will use these. The capitalized methods are used in
    %   more-complex methods defined in mcAxis.
    methods %(Access = ?mcAxis)
        % NAME
        function str = NameShort(a)
            str = [a.config.name ' (' a.config.port ':' a.config.addr ')'];
        end
        function str = NameVerb(a)
            str = [a.config.name ' (serial micrometer on port ' a.config.port ', address ' a.config.addr ')'];
        end
        
        % EQ
        function tf = Eq(a, b)
%             a.config
            tf = strcmpi(a.config.port,  b.config.port);
        end
        
        % OPEN/CLOSE
        function Open(a)        % Consider putting error detection on this?
            disp(['Opening micrometer on port ' a.config.port '...']);
            
            a.s = serial(a.config.port);
            set(a.s, 'BaudRate', 921600, 'DataBits', 8, 'Parity', 'none', 'StopBits', 1, ...
                'FlowControl', 'software', 'Terminator', 'CR/LF');
            fopen(a.s);

            % The following is Srivatsa's code.
            pause(.25);
            fprintf(a.s, [a.config.addr 'HT1']);         % Simplifying function for this?
            fprintf(a.s, [a.config.addr 'SL-5']);        % negative software limit x=-5
            fprintf(a.s, [a.config.addr 'BA0.003']);     % change backlash compensation
            fprintf(a.s, [a.config.addr 'FF05']);        % set friction compensation
            fprintf(a.s, [a.config.addr 'PW0']);         % save to controller memory
            pause(.25);

            fprintf(a.s, [a.config.addr 'OR']);          % Get to home state (should retain position)
            pause(.25);
            
            disp(['...Finished opening micrometer on port ' a.config.port]);
        end
        function Close(a)
            fprintf(a.s, [a.config.addr 'RS']);
            fclose(a.s);    % Not sure if all of these are neccessary; Srivatsa's old code...
%            close(a.s);
            delete(a.s);
        end
        
        % READ
        function ReadEmulation(a)
            if abs(a.x - a.xt) > 1e-4           % Simple equation that attracts a.x to the target value of a.xt.
                a.x = a.x + (a.xt - a.x)/100;
            else
                a.x = a.xt;
            end
        end
        function Read(a)
            fprintf(a.s, [a.config.addr 'TP']);	% Get device state
            str = fscanf(a.s);

            a.x = str2double(str(4:end));
        end
        
        % GOTO
        function GotoEmulation(a, x)
            a.xt = a.config.kind.ext2intConv(x);
            
            % The micrometers are not immediate, so...
            if isempty(a.t)         % ...if the timer to update the position of the micrometers is not currently running...
                a.t = timer('ExecutionMode', 'fixedRate', 'TimerFcn', @a.timerUpdateFcn, 'Period', .25); % 4fps
                start(a.t);         % ...then run it.
            end
        end
        function Goto(a, x)
            fprintf(a.s, [a.config.addr 'SE' num2str(a.config.kind.ext2intConv(x))]);
            fprintf(a.s, 'SE');                                 % Not sure why this doesn't use config.addr... Srivatsa?

            a.xt = a.config.kind.ext2intConv(x);
            
            if abs(a.xt - a.x) > 20 && isempty(a.t)
                a.t = timer('ExecutionMode', 'fixedRate', 'TimerFcn', @a.timerUpdateFcn, 'Period', .2); % 10fps
                start(a.t);
            end
        end
    end
    
    methods
        % EXTRA
        function timerUpdateFcn(a, ~, ~)
%             display('timerUpdate');
            a.read();
%             x = a.x
%             xt = a.xt
%             drawnow
            if abs(a.x - a.xt) < 1e-4
                stop(a.t);
                delete(a.t);
                a.t = [];
            end
        end
    end
end




