classdef (Sealed) mcaGrid < mcAxis
% mcaDAQ is the subclass of mcAxis that manages all NIDAQ devices. This includes:
%  - generic digital and analog outputs.
%  - piezos
%  - galvos
    
    methods (Static)
        % Neccessary extra vars:
        %  - grid
        %  - index
        
        function config = defaultConfig()
            config = mcaGrid.gridConfig();
        end
        function config = gridConfig(grid, index)
            config.kind.kind =          'grid';
            config.kind.name =          'Grid Axis';
            config.kind.intRange =      [-Inf Inf];             % Change this?
            config.kind.int2extConv =   @(x)(x);                % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)(x);                % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      'sets';                 % 'Internal' units.
            config.kind.extUnits =      'sets';                 % 'External' units.
            config.kind.base =          1;                      % Cusomize base?
            
            config.keyStep =            0;
            config.joyStep =            0;
            
            config.grid = grid;                                 % Parent grid
            config.index = index;                               % Defines which grid axis is this axis.
            
            alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
            config.letter = alphabet(index);
            config.name = ['Grid Axis in the ' config.letter ' direction'];
        end
    end
    
    methods
        function a = mcaGrid(varin)
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
            str = [a.config.name ' (' a.config.dev ':' a.config.chn ':' a.config.type ')'];
        end
        function str = NameVerb(a)
            switch lower(a.config.kind.kind)
                case 'nidaqanalog'
                    str = [a.config.name ' (analog input on '  a.config.dev ', channel ' a.config.chn ' with type ' a.config.type ')'];
                case 'nidaqdigital'
                    str = [a.config.name ' (digital input on ' a.config.dev ', channel ' a.config.chn ' with type ' a.config.type ')'];
                otherwise
                    str = a.config.name;
            end
        end
        
        %EQ
        function tf = Eq(a, b)
            tf = a.config.grid == b.config.grid && ...      % Not implemented...
                 a.config.index ==  b.config.index;
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
            a.Goto(x);
        end
        function Goto(a, x)
            a.config.grid.virtualPosition(a.config.grid.index) = x;     % Set the grid to the appropriate virtual coordinates...
            a.config.grid.goto();                                       % Then tell the grid to go to this position.
        end
    end
end




