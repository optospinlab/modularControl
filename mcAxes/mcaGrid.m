classdef (Sealed) mcaGrid < mcAxis
% mcaGrid is the index'th axis of a mcGrid grid. Telling this axis to goto a value will send the axes controlled by the mcGrid
% grid to the appropriate coordinates. For instance, suppose we have a 1D grid in a 2D plane. The virtual axis of the grid will
% control the two real axes of the plane to goto the correct coordinates.
%
% Also see mcaTemplate and mcAxis.
    
%     properties
%         grid = [];  % Runtime variable containing an mcGrid.
%     end

    methods (Static)
        % Neccessary extra vars:
        %  - grid
        %  - index
        % Generated vars:
        %  - letter
        
        function config = defaultConfig()
            config = mcaGrid.gridConfig();
        end
        function config = gridConfig(grid, index)
            config.class =              'mcaGrid';
            
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
            a.extra = {'grid', 'index'};
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
    methods
        % NAME
        function str = NameShort(a)
            str = [a.config.grid.config.name ' ' a.config.letter];
        end
        function str = NameVerb(a)
            str = ['Grid Axis in the ' a.config.letter ' direction for ' a.config.grid.config.name];
        end
        
        % EQ
        function tf = eq(a, b)
            tf = (a.config.grid == b.config.grid) && strcmpi(a.config.letter, b.config.letter);     % Faster to compare the index?
        end
        
        % OPEN/CLOSE
        function Open(a)
            a.config.grid.open();
        end
        function Close(a)
            a.config.grid.open();
        end
        
        % WAIT
        function Wait(a)
            a.config.grid.wait();
        end
        
        % GOTO
        function GotoEmulation(a, x)
            a.Goto(x);
        end
        function Goto(a, x)
            a.config.grid.virtualPosition(a.config.index) = x;       % Set the grid to the appropriate virtual coordinates...
            a.config.grid.goto();                                  % Then tell the grid to go to this position.
        end
    end
end




