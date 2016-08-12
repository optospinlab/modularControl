classdef (Sealed) mcaGrid < mcAxis
% mcaDAQ is the subclass of mcAxis that manages all NIDAQ devices. This includes:
%  - generic digital and analog outputs.
%  - piezos
%  - galvos
    
    methods (Static)
        % Neccessary extra vars:
        %  - dev
        %  - chn
        %  - type
        
        function config = defaultConfig()
            config = mcaGrid.gridConfig();
        end
        function config = gridConfig(grid, index)
            config.name = 'Grid Axis in the A direction';

            config.kind.kind =          'grid';
            config.kind.name =          'Grid Axis';
            config.kind.intRange =      [-Inf Inf];             % Change this?
            config.kind.int2extConv =   @(x)(x);                % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)(x);                % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      'sets';                  % 'Internal' units.
            config.kind.extUnits =      'sets';                  % 'External' units.
            config.kind.base =          1;
            config.kind.resetParam =    '';
            
            config.keyStep =            0;
            config.joyStep =            0;
            
            config.grid = grid;
            config.index = index;
        end
    end
    
    methods
        function a = mcaGrid(varin)
            a = a@mcAxis(varin);
        end
    end
    
    % These methods overwrite the empty methods defined in mcAxis. mcAxis will use these. The capitalized methods are used in
    %   more-complex methods defined in mcAxis.
    methods (Access = private)
        %EQ
        function tf = Eq(a, b)
            tf = strcmpi(a.config.dev,  b.config.dev) && ...
                 strcmpi(a.config.chn,  b.config.chn) && ...
                 strcmpi(a.config.type, b.config.type);
        end
        
        % OPEN/CLOSE
        function Open(a)
            switch lower(a.config.kind.kind)
                case 'nidaqanalog'
                    a.s = daq.createSession('ni');
                    addAnalogOutputChannel(a.s, a.config.dev, a.config.chn, a.config.type);
                case 'nidaqdigital'
                    a.s = daq.createSession('ni');
                    addDigitalChannel(a.s, a.config.dev, a.config.chn, 'OutputOnly');
            end
            
            a.s.outputSingleScan(a.x);
        end
        function Close(a)
            a.s.release();
        end
        
        % GOTO
        function GotoEmulation(a, x)
            a.xt = a.config.kind.ext2intConv(x);    % This will cause preformance reduction for digital. Change?
            a.x = a.xt;
        end
        function Goto(a, x)
            a.GotoEmulation(x);        % No need to rewrite code.
            a.s.outputSingleScan(x);
        end
    end    methods
        % NAME
        function str = nameShort(a)
            str = [a.config.name ' (' a.config.dev ':' a.config.chn ':' a.config.type ')'];
        end
        function str = nameVerb(a)
            switch lower(a.config.kind.kind)
                case 'nidaqanalog'
                    str = [a.config.name ' (analog input on '  a.config.dev ', channel ' a.config.chn ' with type ' a.config.type ')'];
                case 'nidaqdigital'
                    str = [a.config.name ' (digital input on ' a.config.dev ', channel ' a.config.chn ' with type ' a.config.type ')'];
                otherwise
                    str = a.config.name;
            end
        end
        
        % EXTRA
        function addToSession(a, s)
            if a.close();  % If the axis is not already closed, close it...
                switch lower(a.config.kind.kind)
                    case 'nidaqanalog'
                        addAnalogOutputChannel( s, a.config.dev, a.config.chn, a.config.type);
                    case 'nidaqdigital'
                        addDigitalChannel(      s, a.config.dev, a.config.chn, 'OutputOnly');
                    otherwise
                        error('This only works for NIDAQ outputs');
                end
            else
                error([a.name() ' could not be added to session.'])
            end
        end
    end
end




