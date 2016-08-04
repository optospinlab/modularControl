classdef mcWaypoints < mcSavableClass
% mcWaypoints 
%
% Syntax:
%   mcWaypoints()                   % Default config - microX, microY, PiezoZ.
%   mcWaypoints(config)             % Load from config struct.
%   mcWaypoints('config.mat')       % Load from config file.
%   mcWaypoints(axes)               % Make a waypoint manager with the mcAxes in cell array axes.
%
% Status: Needs UI to 
    
    properties
%         config = [];        % Defined in mcSavableClass.
        
%         config.axes         % A cell array to be filled with mcAxes. 
%         
%         config.xi           % The axis that's currently displayed on the x-axis of the plot.
%         config.yi           % The axis that's currently displayed on the y-axis of the plot.
%         
%         config.waypoints    % A cell array to be filled with i numeric arrays for which the jth index corresponds to the ith component of the jth waypoint. The i+1th index will be filled with the mode of that waypoint.
        
        f = [];             % Figure
        a = [];             % Axes
        w = [];             % Waypoints scatter
        p = [];             % Axes position scatter
        t = [];             % Axes target position scatter
        g = [];             % Grid scatter
        
        listeners = [];     % These listen to x and xt.
        
        grid = [];
        gf = [];
        gfl = {};
        gridCoords = [];
        
        menus = [];
    end
    
    methods (Static)
        function config = emptyConfig()
            config.axes = {};
            config.xi = 1;
            config.yi = 2;
        end
        function config = defaultConfig()
            configMicroX = mcAxis.microConfig(); configMicroX.name = 'Micro X'; configMicroX.port = 'COM5';
            configMicroY = mcAxis.microConfig(); configMicroY.name = 'Micro Y'; configMicroY.port = 'COM6';
            configPiezoZ = mcAxis.piezoConfig(); configPiezoZ.name = 'Piezo Z'; configPiezoZ.chn = 'ao2';
            
            config.axes = {mcAxis(configMicroX), mcAxis(configMicroY), mcAxis(configPiezoZ)};
            config.xi = 1;
            config.yi = 2;
        end
    end
    
    methods
        function wp = mcWaypoints(varin)
            switch nargin
                case 0
                    wp.config = mcWaypoints.defaultConfig();
                    wp.emptyWaypoints();
                    wp.config.waypoints{1} = rand(1, 100);  % Comment this...
                    wp.config.waypoints{2} = rand(1, 100);
                    wp.config.waypoints{3} = rand(1, 100);
                    wp.config.waypoints{4} = 1:100;         % Color in the future?
                    wp.config.waypoints{5} = 1:100;         % Name?
                case 1
                    if iscell(varin)
                        wp.config = emptyConfig();
                        wp.config.axes = varin;
                        wp.emptyWaypoints();
                    else
                        wp.load(varin);
                    end
            end
            
            if length(wp.config.axes) < 2
                error('Must have at least two axes to drop waypoints about.');
            end
            
            wp.f = mcInstrumentHandler.createFigure(wp, 'saveopen');
                    
%             f.Resize =      'off';
            wp.f.Visible =     'off';
            wp.f.Position =    [100, 100, 500, 500];
%             wp.f.MenuBar =     'none';
            wp.f.ToolBar =     'none';
            wp.f.CloseRequestFcn = @wp.figureClose_Callback;
            
            wp.a = axes(wp.f, 'Position', [0 0 1 1], 'TickDir', 'in', 'DataAspectRatioMode', 'manual', 'DataAspectRatio', [1 1 1]);
            
            hold(wp.a, 'on')
            
            wp.w = scatter(wp.a, [], [], 's');
            wp.p = scatter(wp.a, [], [], 'o');
            wp.t = scatter(wp.a, [], [], 'x');
            wp.g = scatter(wp.a, [], [], 'd');
            
            hold(wp.a, 'off')
            
            wp.a.ButtonDownFcn =      @wp.windowButtonDownFcn;
            wp.w.ButtonDownFcn =      @wp.windowButtonDownFcn;
            wp.g.ButtonDownFcn =      @wp.windowButtonDownFcn;
            wp.f.WindowButtonUpFcn =  @wp.windowButtonUpFcn;
            wp.f.WindowScrollWheelFcn =     @wp.windowScrollWheelFcn;
            
            menuA = uicontextmenu;
            menuW = uicontextmenu;
            menuG = uicontextmenu;
            
            wp.a.UIContextMenu = menuA;
            wp.w.UIContextMenu = menuW;
            wp.g.UIContextMenu = menuG;
            
            wp.menus.pos.name =         uimenu(menuA, 'Label', 'Position: [ ~~.~~ --, ~~.~~ -- ]',  'Callback', @copyLabelToClipboard); %, 'Enable', 'off');
            wp.menus.pos.goto =         uimenu(menuA, 'Label', 'Goto Position', 'Callback',      @wp.gotoPosition_Callback);
            wp.menus.pos.drop =         uimenu(menuA, 'Label', 'Drop Waypoint Here', 'Callback', @wp.drop_Callback);
            wp.menus.pos.drop =         uimenu(menuA, 'Label', 'Drop Waypoint at Axes Position', 'Callback', @wp.dropAtAxes_Callback);
            
            wp.menus.way.pos  =         uimenu(menuW, 'Label', 'Position: [ ~~.~~ --, ~~.~~ -- ]',  'Callback', @copyLabelToClipboard); 
            wp.menus.way.name =         uimenu(menuW, 'Label', 'Waypoint: ~',  'Callback',       @copyLabelToClipboard); %, 'Enable', 'off');
            wp.menus.way.goto =         uimenu(menuW, 'Label', 'Goto Waypoint', 'Callback',      @wp.gotoWaypoint_Callback);
            wp.menus.way.dele =         uimenu(menuW, 'Label', 'Delete Waypoint', 'Callback',    @wp.delete_Callback);
            wp.menus.way.grid =         uimenu(menuW, 'Label', 'Add Waypoint to Grid', 'Callback',  @wp.gridAdd_Callback);
            
            wp.menus.grid.pos =          uimenu(menuG, 'Label', 'Position: [ ~~.~~ --, ~~.~~ -- ]',  'Callback', @copyLabelToClipboard); 
            wp.menus.grid.name =         uimenu(menuG, 'Label', 'Gridpoint: ~',  'Callback',       @copyLabelToClipboard); %, 'Enable', 'off');
            wp.menus.grid.goto =         uimenu(menuG, 'Label', 'Goto Gridpoint', 'Callback',      @wp.gotoGridpoint_Callback);
            wp.menus.grid.dele =         uimenu(menuG, 'Label', 'Whitelist Gridpoint', 'Callback',    @wp.delete_Callback, 'Enable', 'off');
            wp.menus.grid.dele =         uimenu(menuG, 'Label', 'Blacklist Gridpoint', 'Callback',    @wp.delete_Callback, 'Enable', 'off');
            
            wp.menus.currentPos =       [0 0];
            wp.menus.currentWay =       0;
            
            wp.render();
            
            wp.listeners.x = [];
            wp.listeners.y = [];
            
            wp.resetAxisListeners();
            wp.listenToAxes_Callback(0, 0);
                
            wp.f.Visible =     'on';
        end

        function l = length(wp)
            l = length(wp.axes);
        end
        
        function emptyWaypoints(wp)
            wp.config.waypoints = cell(1, length(wp.config.axes) + 2);
        end
        function drop_Callback(wp, ~, ~)
%         function drop(wp)     % Drop a waypoint at the current position of the axes.
            l = length(wp.config.waypoints{1});
            
            wp.dropAtAxes_Callback(0,0);
            
            wp.config.waypoints{wp.config.xi}(l+1) = wp.menus.currentPos(1);
            wp.config.waypoints{wp.config.yi}(l+1) = wp.menus.currentPos(2);
            
            wp.render();
        end
        function dropAtAxes_Callback(wp, ~, ~)
%         function drop(wp)     % Drop a waypoint at the current position of the axes.
            l = length(wp.config.waypoints{1});
            
            for ii = 1:length(wp.config.axes)
                wp.config.waypoints{ii}(l+1) = wp.config.axes{ii}.getX();
            end
            
            wp.config.waypoints{length(wp.config.axes) + 1}(l+1) = 1;           % To be color?
            wp.config.waypoints{length(wp.config.axes) + 2}(l+1) = l+1;         % To be name?
            
            wp.render();
        end
        function delete_Callback(wp, ~, ~)
            for ii = 1:length(wp.config.waypoints)
                wp.config.waypoints{ii}(wp.menus.currentWay) = [];
            end
            
            wp.render();
        end
        function gotoPosition_Callback(wp, ~, ~)
            wp.config.axes{wp.config.xi}.goto(wp.menus.currentPos(1));
            wp.config.axes{wp.config.yi}.goto(wp.menus.currentPos(2));
        end
        function gotoWaypoint_Callback(wp, ~, ~)
%             drawnow limitrate;
             for ii = 1:length(wp.config.axes)
                wp.config.axes{ii}.goto(wp.config.waypoints{ii}(wp.menus.currentWay));
             end
%             drawnow;
        end
        function gotoGridpoint_Callback(wp, ~, ~)
            y = wp.grid.config.A * wp.gridCoords(wp.menus.currentGrid, :)';
             for ii = 1:length(wp.config.axes)
                wp.config.axes{ii}.goto(y(ii));
             end
        end
        function gridAdd_Callback(wp, ~, ~)
            
            bw = 100;
            bh = 20;
                
            num = length(wp.config.axes);
                
            rh = 3*bh;
            
            if isempty(wp.gf)
                wp.grid = mcGrid();
                wp.gf = mcInstrumentHandler.createFigure(wp.grid, 'saveopen');
                
                wp.gf.Position = [100, 100, (num+1)*bw 2*bh+rh];
                wp.gf.Resize =      'off';
                
                wp.grid.editArray =     cell(1, num);
                wp.grid.textArray =     cell(1, num);
                
                for ii = 1:num
                    wp.grid.editArray{1, ii} = uicontrol(wp.gf, 'Style', 'edit',...
                                                                'Units', 'pixels',...
                                                                'Position', [ii*bw rh bw bh],...
                                                                'String', wp.config.waypoints{ii}(wp.menus.currentWay));
                    wp.grid.textArray{1, ii} = uicontrol(wp.gf, 'Style', 'text',...
                                                                'Units', 'pixels',...
                                                                'Position', [ii*bw bh+rh bw bh],...
                                                                'String', wp.config.axes{ii}.nameUnits(),...
                                                                'TooltipString', wp.config.axes{ii}.name());
                end
                
                % Add the range labels for grid coordinates (hidden when there are no grid coordinates).
                wp.grid.rangeText{1} = uicontrol(wp.gf, 'Style', 'text',...
                                                        'Units', 'pixels',...
                                                        'Position', [num*bw 3*bh/2 bw bh],...
                                                        'String', 'Range from:  ',...
                                                        'HorizontalAlignment', 'right',...
                                                        'Visible', 'off',...
                                                        'Callback', @makeNumber_Callback);
                wp.grid.rangeText{2} = uicontrol(wp.gf, 'Style', 'text',...
                                                        'Units', 'pixels',...
                                                        'Position', [num*bw bh/2 bw bh],...
                                                        'String', 'to:  ',...
                                                        'HorizontalAlignment', 'right',...
                                                        'Visible', 'off',...
                                                        'Callback', @makeNumber_Callback);
                                                    
                previewButton = uicontrol(wp.gf, 'Style', 'push',...
                                                        'Units', 'pixels',...
                                                        'Position', [(num-1)*bw bh/2 bw 2*bh],...
                                                        'String', 'Preview',...
                                                        'HorizontalAlignment', 'right',...
                                                        'Callback', @wp.previewGrid_Callback);
            else
                alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

                dims = size(wp.grid.editArray);
                l = dims(1) + 1;
                wp.gf.Position(3:4) = [(num + (l+1)/2)*bw (l+1)*bh+rh];
                
                wp.grid.rangeText{1}.Visible = 'on';
                wp.grid.rangeText{2}.Visible = 'on';

                if l > 26
                    warning('mcGrid: You have hit the programatical limit for number of grid coords. You cannot be larger than an alphabet...');
                    return;
                end

                for ii = 1:num              % Add the edits that record the axes coords (and shift up the titles)
                    wp.grid.editArray{l, ii} = uicontrol(wp.gf, 'Style', 'edit',...
                                                                'Units', 'pixels',...
                                                                'Position', [ii*bw (l-1)*bh+rh bw bh],...
                                                                'String', wp.config.waypoints{ii}(wp.menus.currentWay));
                    wp.grid.textArray{1, ii}.Position = [ii*bw l*bh+rh bw bh];
                end

                for ii = 1:l-1              % Add the column of edits for the additional grid coordinate on already-added axes
                    wp.grid.editArray{ii, num+(l-1)} = uicontrol(wp.gf, 'Style', 'edit',...
                                                                'Units', 'pixels',...
                                                                'Position', [(num+l/2)*bw (ii-1)*bh+rh bw/2 bh],...
                                                                'String', 0,...
                                                                'Callback', @makeNumber_Callback);
                end
                
                % Add the range boxes for the new column of grid coordinates
                wp.grid.rangeArray{1, (l-1)} = uicontrol(wp.gf, 'Style', 'edit',...
                                                                    'Units', 'pixels',...
                                                                    'Position', [(num+l/2)*bw bh/2 bw/2 bh],...
                                                                    'String', 0,...
                                                                    'Callback', @makeNumber_Callback);
                wp.grid.rangeArray{2, (l-1)} = uicontrol(wp.gf, 'Style', 'edit',...
                                                                    'Units', 'pixels',...
                                                                    'Position', [(num+l/2)*bw 3*bh/2 bw/2 bh],...
                                                                    'String', 0,...
                                                                    'Callback', @makeNumber_Callback);

                % Add the text box for the new column of grid coordinates
                wp.grid.textArray{1, num+(l-1)} = uicontrol(wp.gf,  'Style', 'text',...
                                                                    'Units', 'pixels',...
                                                                    'Position', [((ii+num+1)/2)*bw bh+rh bw bh],...
                                                                    'String', alphabet(l-1),...
                                                                    'TooltipString', ['The ' getSuffix(l-1) ' coordinate of the grid']);

                for ii = num+1:num+(l-1)    % Add the row of edits for the grid coordinate of the new waypoint (and shift up the titles)
                    wp.grid.editArray{l, ii} = uicontrol(wp.gf, 'Style', 'edit',...
                                                                'Units', 'pixels',...
                                                                'Position', [((ii+num+1)/2)*bw (l-1)*bh+rh bw/2 bh],...
                                                                'String', double(num+(l-1) == ii),...
                                                                'Callback', @makeNumber_Callback);
                    wp.grid.textArray{1, ii}.Position = [((ii+num+1)/2)*bw l*bh+rh bw/2 bh];
                end
            end
        end
        function previewGrid_Callback(wp, ~, ~)
            wp.grid.makeGridFromEdit(wp.config.axes);
            
%             wp.grid.rangeArray
            if ~isempty(wp.grid.config.A)
                ranges = cellfun(@(x)(str2double(x.String)), wp.grid.rangeArray);

                ranges2(1, :) = ceil(min(ranges));
                ranges2(2, :) = floor(max(ranges));

                lengths = diff(ranges2)+1;

                jj = 1;

                finlen = prod(lengths);

                X = zeros(finlen, length(lengths)+1);

                for ii = 1:length(lengths)
                    X(:, ii) = repmat( reshape( repmat((ranges2(1,ii):ranges2(2,ii))', [1, jj])', [], 1), [finlen/(jj*lengths(ii)), 1]);

                    jj = jj*lengths(ii);
                end

                X(:, length(lengths)+1) = 1;

                Y = wp.grid.config.A*(X');

                wp.gridCoords = X;

                wp.g.XData = Y(wp.config.xi, :);
                wp.g.YData = Y(wp.config.yi, :);
            end
        end

        function render(wp)
            wp.w.XData = wp.config.waypoints{wp.config.xi};
            wp.w.YData = wp.config.waypoints{wp.config.yi};
        end
        
        function resetAxisListeners(wp)
            delete(wp.listeners.x);
            delete(wp.listeners.y);
            
            prop = findprop(mcAxis, 'x');
            wp.listeners.x = event.proplistener(wp.config.axes{wp.config.xi}, prop, 'PostSet', @wp.listenToAxes_Callback);
            wp.listeners.y = event.proplistener(wp.config.axes{wp.config.yi}, prop, 'PostSet', @wp.listenToAxes_Callback);
        end
        function listenToAxes_Callback(wp, ~, ~)
            if isvalid(wp)
%                 drawnow limitrate;
                wp.p.XData = wp.config.axes{wp.config.xi}.getX();
                wp.p.YData = wp.config.axes{wp.config.yi}.getX();
                wp.t.XData = wp.config.axes{wp.config.xi}.getXt();
                wp.t.YData = wp.config.axes{wp.config.yi}.getXt();
%                 drawnow;
            end
        end
        
        function windowButtonDownFcn(wp, src, event)
            switch event.Button
                case 1      % left click
                    if isprop(src.Parent, 'Pointer')    % Triggered by axis
                        fig = src.Parent;
                    else                                % Triggered by scatter
                        fig = src.Parent.Parent;
                    end
                    
                    fig.Pointer = 'hand';
                    
                    fig.UserData.last_pixel = [];
                    fig.WindowButtonMotionFcn = @wp.windowButtonMotionFcn;
                case 3      % right click
                    if isprop(src.Parent, 'Pointer')    % Triggered by axis
                        notDragging = strcmpi(src.Parent.Pointer, 'arrow');
                    else                                % Triggered by scatter
                        notDragging = strcmpi(src.Parent.Parent.Pointer, 'arrow');
                    end
                    
                    if notDragging    % If we aren't currently dragging...
                        % Do some selection.
                        x = event.IntersectionPoint(1);
                        y = event.IntersectionPoint(2);
                        
                        wp.menus.currentPos = [x y];
                        wp.menus.pos.name.Label = ['Position: [ ' num2str(x, 4)  ' ' wp.config.axes{wp.config.xi}.config.kind.extUnits ', ' num2str(y, 4)  ' ' wp.config.axes{wp.config.yi}.config.kind.extUnits ' ]'];
                        
                        
                        dlist = (wp.w.XData - x) .* (wp.w.XData - x) + ...
                                (wp.w.YData - y) .* (wp.w.YData - y);
                        
                        ii = find(dlist == min(dlist), 1);
                        
                        wp.menus.currentWay = ii;
                        % Fill this with the other coords (e.g. Z) too.
                        
                        posstr = 'Position: [ ';
                        for kk = 1:length(wp.config.axes)-1
                            posstr = [posstr num2str(wp.config.waypoints{kk}(wp.menus.currentWay), 4) ' ' wp.config.axes{kk}.config.kind.extUnits ', '];
                        end
                        posstr = [posstr num2str(wp.config.waypoints{end}(wp.menus.currentWay), 4) ' ' wp.config.axes{end}.config.kind.extUnits ' ]'];
                        wp.menus.way.pos.Label = posstr;
                        wp.menus.way.name.Label = ['Waypoint: ' num2str(ii)];
                        
                        
                        dlist = (wp.g.XData - x) .* (wp.g.XData - x) + ...
                                (wp.g.YData - y) .* (wp.g.YData - y);
                        
                        jj = find(dlist == min(dlist), 1);
                        
                        wp.menus.currentGrid = jj;
                        
                        if ~isempty(wp.gridCoords)
                            y = wp.grid.config.A * wp.gridCoords(jj, :)';
                            
                            posstr = 'Position: [ ';
                            for kk = 1:length(wp.config.axes)-1
                                posstr = [posstr num2str(y(kk), 4) ' ' wp.config.axes{kk}.config.kind.extUnits ', '];
                            end
                            posstr = [posstr num2str(y(end), 4) ' ' wp.config.axes{end}.config.kind.extUnits ' ]'];
                            wp.menus.grid.pos.Label = posstr;
    
                            wp.menus.grid.name.Label = ['Grid: [ ' num2str(wp.gridCoords(jj, 1:(end-1))) ' ]'];
                        else
                            wp.menus.grid.pos.Label = ['Position: [ ' num2str(wp.g.XData(jj), 4)  ' ' wp.config.axes{wp.config.xi}.config.kind.extUnits ', ' num2str(wp.g.YData(jj), 4)  ' ' wp.config.axes{wp.config.yi}.config.kind.extUnits ' ]'];
                            wp.menus.grid.name.Label = 'Grid: ~';
                        end
                        
                    end
            end
        end
        function windowButtonMotionFcn(wp, src, event)
            curr_pixel = event.Point;

            if ~isempty(src.UserData.last_pixel)    % Only pan if we have a previous pixel point
                pos = src.Position;

                delta_pixel = curr_pixel - src.UserData.last_pixel;
                delta_data1 = delta_pixel(1) * abs(diff(wp.a.XLim)) / pos(3);
                delta_data2 = delta_pixel(2) * abs(diff(wp.a.YLim)) / pos(4);
                
                wp.a.XLim = wp.a.XLim - delta_data1;
                wp.a.YLim = wp.a.YLim - delta_data2;
            end
            
            src.UserData.last_pixel = curr_pixel;
        end
        function windowButtonUpFcn(wp, src, ~)
            switch lower(src.SelectionType)
                case 'normal' % left click
                    src.Pointer = 'arrow';
                    
                    src.UserData.last_pixel = [];
                    src.WindowButtonMotionFcn = [];
                case 'open' % double click (left or right)
                    src.Pointer = 'arrow';
                    src.UserData.last_pixel = [];
                    src.WindowButtonMotionFcn = [];
                    wp.a.XLim = [min(wp.w.XData) max(wp.w.XData)];
                    wp.a.YLim = [min(wp.w.YData) max(wp.w.YData)];
%                 case 'alt' % right click
% %                     % do nothing
% % 
%                 case 'extend' % center click
% %                     % do nothing
            end
        end
        function windowScrollWheelFcn(wp, src, event)
            curr_pixel = src.CurrentPoint;

            pos = src.Position;

            curr_data1 = curr_pixel(1) * diff(wp.a.XLim) / pos(3) + wp.a.XLim(1);
            curr_data2 = curr_pixel(2) * diff(wp.a.YLim) / pos(4) + wp.a.YLim(1);

            if event.VerticalScrollCount > 0
                scale = 1.1;
            else
                scale = 0.9;
            end

            wp.a.XLim = curr_data1 + (wp.a.XLim - curr_data1)*scale;
            wp.a.YLim = curr_data2 + (wp.a.YLim - curr_data2)*scale;
        end
    
        function figureClose_Callback(wp, ~, ~)
            delete(wp.listeners.x);
            delete(wp.listeners.y);
            delete(wp.f);
            delete(wp);
        end
    end
end

function makePositiveInteger_Callback(src,~)
    val = str2double(src.String);
    
    if isnan(val)
        val = 1;
    else
        val = round(val);

        if val < 0
            val = -val;
        end
    end
    
    src.String = val;
end
function makeInteger_Callback(src,~)
    val = str2double(src.String);
    
    if isnan(val)
        val = 1;
    else
        val = round(val);
    end
    
    src.String = val;
end
function makeNumber_Callback(src,~)
    val = str2double(src.String);
    
    if isnan(val)
        val = 1;
    end
    
    src.String = val;
end

function copyLabelToClipboard(src, ~)
    split = strsplit(src.Label, ': ');
    clipboard('copy', split{end});
end




