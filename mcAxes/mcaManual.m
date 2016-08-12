classdef (Sealed) mcaManual < mcAxis
% mcaManual is a subclass of mcAxis for axes that are (not yet) automated. When the program wants to change the value of this
%   axis, the user will be prompted to change it manually.
    
    methods (Static)
        % Neccessary extra vars:
        %  - message
        %  - verb
        
        function config = defaultConfig()
            config = mcaDAQ.piezoConfig();
        end
        function config = polarizationConfig()
            config.name = 'Half Wave Plate';

            config.kind.kind =          'manual';
            config.kind.name =          'Polarization';
            config.kind.intRange =      [-180 180];             % Change this?
            config.kind.int2extConv =   @(x)(x);                % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)(x);                % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      'deg';                  % 'Internal' units.
            config.kind.extUnits =      'deg';                  % 'External' units.
            config.kind.base =          0;
            
            config.keyStep =            0;
            config.joyStep =            0;
            
            config.message = 'Polarization is not currently automated...';
            config.verb = 'rotate';
        end
    end
    
    methods
        function a = mcaManual(varin)
            a = a@mcAxis(varin);
        end
    end
    
    % These methods overwrite the empty methods defined in mcAxis. mcAxis will use these.
    methods (Access = private)
        %EQ
        function tf = Eq(a, b)
            tf = strcmpi(a.config.message,  b.config.message) && strcmpi(a.config.verb,  b.config.verb);
        end
        
        % NAME
        function str = NameShort(a)
            str = [a.config.name ' (' a.config.kind.name ':' a.config.verb ')'];
        end
        function str = NameVerb(a)
            str = [a.config.name ' (' a.config.message ' We must ' a.config.verb ' the ' a.config.kind.name ')'];
        end
        
        % OPEN/CLOSE not neccessary
        
        % GOTO
        function GotoEmulation(a, x)
            load(gong.mat);
            sound(y);           % Glorious
            
            if a.x == a.config.kind.ext2intConv(x)
                questdlg([a.config.message ' Is the ' a.config.name ' at ' num2str(a.config.kind.int2extConv(a.x)) '? '...
                          'If not, please ' a.config.verb ' it'], ['Please ' a.config.verb '!'], 'Done', 'Done');
            else
                questdlg([a.config.message ' Please ' a.config.verb ' the ' a.config.kind.name ' of  the ' a.config.name...
                          ' from ' num2str(a.config.kind.int2extConv(a.x)) ' ' a.config.kind.extUnits ' to ' num2str(x) ' ' a.config.kind.extUnits], ['Please ' a.config.verb '!'], 'Done', 'Done');

                a.xt = a.config.kind.ext2intConv(x);
                a.x = a.xt;
            end
        end
        function Goto(a, x)
            a.GotoEmulation(x);     % There is no need to emulate manual axes differently.
        end
    end
end




