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
        w = [];             % Waypoints
        p = [];             % Axes position
        t = [];             % Axes target position
        
        menus = [];
    end
    
    methods (Static)
        function config = emptyConfig()
            config.axes = {};
            config.xi = 1;
            config.yi = 2;
        end
        function config = defaultConfig()
            configMicroX = mcAxis.microConfig(); configMicroX.name = 'Micro X'; configMicroX.port = 'COM6';
            configMicroY = mcAxis.microConfig(); configMicroY.name = 'Micro Y'; configMicroY.port = 'COM7';
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
            
            wp.a = axes(wp.f, 'Position', [0 0 1 1], 'TickDir', 'in', 'DataAspectRatioMode', 'manual', 'DataAspectRatio', [1 1 1]);
            
            hold(wp.a, 'on')
            
            wp.w = scatter(wp.a, [], [], 'x');
            wp.p = scatter(wp.a, [], [], 'o');
            wp.t = scatter(wp.a, [], [], 'o');
            
            hold(wp.a, 'off')
            
            wp.a.ButtonDownFcn =      @wp.windowButtonDownFcn;
            wp.w.ButtonDownFcn =      @wp.windowButtonDownFcn;
            wp.f.WindowButtonUpFcn =  @wp.windowButtonUpFcn;
            wp.f.WindowScrollWheelFcn =     @wp.windowScrollWheelFcn;
            
            menuA = uicontextmenu;
            menuW = uicontextmenu;
            
            wp.a.UIContextMenu = menuA;
            wp.w.UIContextMenu = menuW;
            
            wp.menus.pos.name =         uimenu(menuA, 'Label', 'Position: [ ~~.~~ --, ~~.~~ -- ]',  'Callback', @copyLabelToClipboard); %, 'Enable', 'off');
            wp.menus.pos.goto =         uimenu(menuA, 'Label', 'Goto Position', 'Callback',      @wp.gotoPosition_Callback);
            wp.menus.pos.drop =         uimenu(menuA, 'Label', 'Drop Waypoint Here', 'Callback', @wp.drop_Callback);
            wp.menus.pos.drop =         uimenu(menuA, 'Label', 'Drop Waypoint at Axes Position', 'Callback', @wp.dropAtAxes_Callback);
            
            wp.menus.way.name =         uimenu(menuW, 'Label', 'Waypoint: ~',  'Callback',       @copyLabelToClipboard); %, 'Enable', 'off');
            wp.menus.way.goto =         uimenu(menuW, 'Label', 'Goto Waypoint', 'Callback',      @wp.gotoWaypoint_Callback);
            wp.menus.way.dele =         uimenu(menuW, 'Label', 'Delete Waypoint', 'Callback',    @wp.delete_Callback);
            
            wp.menus.currentPos =       [0 0];
            wp.menus.currentWay =       0;
            
            wp.render();
                
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
             for ii = 1:length(wp.config.axes)
                wp.config.axes{ii}.goto(wp.config.waypoints{ii}(wp.menus.currentWay));
            end
        end
        
        function render(wp)
            wp.w.XData = wp.config.waypoints{wp.config.xi};
            wp.w.YData = wp.config.waypoints{wp.config.yi};
        end
        
        function resetAxisListeners(gui)
            delete(gui.listeners.x);
            delete(gui.listeners.y);
            
            prop = findprop(mcAxis, 'x');
            switch gui.data.data.plotMode
                case 1
                    gui.listeners.x = event.proplistener(gui.data.data.axes{gui.data.data.layer == 1}, prop, 'PostSet', @gui.listenToAxes_Callback);
                case 2
%                     ax = gui.data.data.axes{gui.data.data.layer == 1}.name()
%                     ay = gui.data.data.axes{gui.data.data.layer == 2}.name()
                    gui.listeners.x = event.proplistener(gui.data.data.axes{gui.data.data.layer == 1}, prop, 'PostSet', @gui.listenToAxes_Callback);
                    gui.listeners.y = event.proplistener(gui.data.data.axes{gui.data.data.layer == 2}, prop, 'PostSet', @gui.listenToAxes_Callback);
            end
        end
        function listenToAxes_Callback(gui, ~, ~)
            if isvalid(gui)
                axisX = gui.data.data.axes{gui.data.data.layer == 1};
%                 bx = axisX.name()

                x = axisX.getX();

                gui.posL.act.XData = [x x];
                gui.pos.act.XData = x;

                if gui.data.data.plotMode == 2
                    axisY = gui.data.data.axes{gui.data.data.layer == 2};
%                     by = axisY.name()

                    gui.pos.act.YData = axisY.getX();
                end
            end
        end
        
%                 x = event.IntersectionPoint(1)
%                 y = event.IntersectionPoint(2)
%                 
%                 xlist = (gui.i.XData - x) .* (gui.i.XData - x);
%                 ylist = (gui.i.YData - y) .* (gui.i.YData - y);
%                 xi = find(xlist == min(xlist), 1);
%                 yi = find(ylist == min(ylist), 1);
%                 xp = gui.i.XData(xi);
%                 yp = gui.i.YData(yi);
% 
%                 gui.pos.sel.XData = x;
%                 gui.pos.sel.YData = y;
%                 gui.pos.pix.XData = xp;
%                 gui.pos.pix.YData = yp;
% 
%                 axisX = gui.data.data.axes{gui.data.data.layer == 1};
%                 axisY = gui.data.data.axes{gui.data.data.layer == 2};
% 
%                 val = gui.i.CData(yi, xi);
% 
%                 if isnan(val)
%                     gui.menus.ctsMenu.Label = ' Value:    ----- cts/sec';
%                 else
%                     gui.menus.ctsMenu.Label = [' Value:    ' num2str(val, 4) ' '];
%                 end
% 
%                 gui.menus.posMenu.Label = [' Position: [ ' num2str(x, 4)  ' ' axisX.config.kind.extUnits ', ' num2str(y, 4)  ' ' axisY.config.kind.extUnits ' ]'];
%                 gui.menus.pixMenu.Label = [' Pixel:    [ '    num2str(xp, 4) ' ' axisX.config.kind.extUnits ', ' num2str(yp, 4) ' ' axisY.config.kind.extUnits ' ]'];
        
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
                        
                        dlist = (wp.config.waypoints{wp.config.xi} - x) .* (wp.config.waypoints{wp.config.xi} - x) + ...
                                (wp.config.waypoints{wp.config.yi} - y) .* (wp.config.waypoints{wp.config.yi} - y);
                        
                        ii = find(dlist == min(dlist), 1);
                        
                        wp.menus.currentWay = ii;
                        wp.menus.pos.name.Label = ['Position: [ ' num2str(x, 4)  ' ' wp.config.axes{wp.config.xi}.config.kind.extUnits ', ' num2str(y, 4)  ' ' wp.config.axes{wp.config.yi}.config.kind.extUnits ' ]'];
                        wp.menus.way.name.Label = ['Waypoint: ' num2str(ii)];
                        
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
    end
    
end

    function [white, black] = loadWhitelist()
        % Loads the file pointed at by the path in the Automation Task settings and returns whitelist
        % and blacklist cell arrays populated by lists of the form [dx, dy, x, y]. e.g. the list
        % [NaN, NaN, 1, 1] would mean Set 1 1. The NaNs denote that those values are not specified.
        % As another example, [1, NaN, NaN, NaN] would mean device or column 1, depending upon one's
        % choice of how the devices are arranged (i.e. in rows or columns)
        
%         path = 'C:\Users\phys\Desktop\whitelist.txt'
        path = get(c.autoTaskList, 'String');
        
        if exist(path) ~= 0     % If the whitelist path exists
            switch path(end-3:end)
                case '.txt'
                    file = fopen(path);
                    array = textscan(file, '%s', 'Delimiter', '\n');
                case {'.xls', 'xlsx'}
                    display('Excel whitelist files currently disabled');
%                     array = xlsread(path, 'A:A');
            end
            
            white = cell(1);    w = 1;
            black = cell(1);    b = 1;
            
            isBlack = false;    % Variable used to determine whether a line is part of the white or black list.
            
            for x = 1:max(size(array{1}))   % Scan through the lines in the file
%                 array{1}{x}
%                 array{1}{x}(1)
                if ~isempty(array{1}{x})    % If the line isn't empty:
                    switch array{1}{x}(1)
                        case {'#', '%', '\', '/', '!'}  % If line is commented out
                            % Nothing.
                        case {'w', 'W'}                 % Interprets subsequent lines as part of the whitelist
                            isBlack = false;
                        case {'b', 'B'}                 % Interprets subsequent lines as part of the blacklist
                            isBlack = true;
                        otherwise                       % Interpret line
    %                         array{1}{x}
                            list = interpretWhiteString([array{1}{x}, ' ']);    % Returns line in the form: [dx, dy, x, y]

                            if length(list) ~= 1    % If the list is nonempty (i.e. if the line made sense)
                                if isBlack          % Add line to the blacklist if it should be.
                                    black{b,1} = list; b = b + 1;
                                else
                                    white{w,1} = list;
                                    w = w + 1;
                                end
                            end
                    end
                end
            end
        else 
            white = {0};
            black = {0};
            return;
        end
        
        if w == 1   % If nothing was added...
            white = {0};
        end
        if b == 1
            black = {0};
        end
    end
    function list = interpretWhiteString(str)
        list = [NaN, NaN, NaN, NaN];

        ii = 1;
        
%         str
        
        while ii <= length(str)
%             list
            switch str(ii)
                case {'x'}
                    [list(1), ii] = getNum(str, list(1), ii);
                case {'y'}
                    [list(2), ii] = getNum(str, list(2), ii);
                case {'d', 'c', 'r', 'D', 'C', 'R'}
                    if (get(c.autoTaskRow, 'Value') == 1)
                        if str(ii) == 'd' || str(ii) == 'D'
                            [list(1), ii] = getNum(str, list(1), ii);
                        elseif str(ii) == 'r' || str(ii) == 'R'
                            [list(2), ii] = getNum(str, list(2), ii);
                        else
                            disp([str ' not understood - expected rows, not columns']);
                        end
                    else
                        if str(ii) == 'c' || str(ii) == 'C'
                            [list(1), ii] = getNum(str, list(1), ii);
                        elseif str(ii) == 'd' || str(ii) == 'D'
                            [list(2), ii] = getNum(str, list(2), ii);
                        else
                            disp([str ' not understood - expected columns, not rows']);
                        end
                    end
                case {'X'}
                    [list(3), ii] = getNum(str, list(3), ii);
                case {'Y'}
                    [list(4), ii] = getNum(str, list(4), ii);
                case {'s', 'S'}
                    if ii+1 <= length(str)
                        if str(ii+1) == 'x' || str(ii+1) == 'X'
                            [list(3), ii] = getNum(str, list(3), ii);
                        elseif str(ii+1) == 'y' || str(ii+1) == 'Y'
                            [list(4), ii] = getNum(str, list(4), ii);
                        else
                            [list(3), ii] = getNum(str, list(3), ii);
                            [list(4), ii] = getNum(str, list(4), ii);
                        end
                    else
                        [list(3), ii] = getNum(str, list(3), ii);
                        [list(4), ii] = getNum(str, list(4), ii);
                    end
            end
            
            if isnan(ii) == 1
                break;
            end
            
            ii = ii + 1;
        end
        
        if sum(isnan(list)) == 4
            list = 0;
        end
    end
    function [num, ii] = getNum(str, default, ii)
        jj = 0;
        
        while ii <= length(str);
            switch str(ii)
                case {'0','1','2','3','4','5','6','7','8','9'}
                    jj = ii;
                    break;
            end
            
            ii = ii + 1;
        end
        
        if jj == 0
            num = default;
            ii = NaN;
            return;
        end
        
        while jj <= length(str)
            switch str(jj)
                case {'0','1','2','3','4','5','6','7','8','9'}
                    jj = jj + 1;
                otherwise
%                     str(ii:(jj-1))
                    num = eval(str(ii:(jj-1)));
                    ii = jj;
                    return;
            end
        end
    end
    function setCurrent_Callback(hObject, ~)
        disableWarning = false;
                
        switch hObject
            case c.autoV1Get
                set(c.autoV1X, 'String', c.microActual(1));
                set(c.autoV1Y, 'String', c.microActual(2));
                set(c.autoV1Z, 'String', c.piezo(3));
                set(c.autoV1NX, 'String', c.Sx);
                set(c.autoV1NY, 'String', c.Sy);
                % c.autoV1DX = c.selcircle(1);
                % c.autoV1DY = c.selcircle(2);
            case c.autoV2Get
                set(c.autoV2X, 'String', c.microActual(1));
                set(c.autoV2Y, 'String', c.microActual(2));
                set(c.autoV2Z, 'String', c.piezo(3));
                set(c.autoV2NX, 'String', c.Sx);
                set(c.autoV2NY, 'String', c.Sy);
               % c.autoV2DX = c.selcircle(1);
               % c.autoV2DY = c.selcircle(2);
            case c.autoV3Get
                set(c.autoV3X, 'String', c.microActual(1));
                set(c.autoV3Y, 'String', c.microActual(2));
                set(c.autoV3Z, 'String', c.piezo(3));
                set(c.autoV3NX, 'String', c.Sx);
                set(c.autoV3NY, 'String', c.Sy);
                % c.autoV3DX = c.selcircle(1);
                % c.autoV3DY = c.selcircle(2);
                 disp('Disk Centroid ...')
%                 c.selcircle(1)
%                  c.selcircle(2)
                diskclear_Callback();
            case c.autoV4Get
                set(c.autoV4X, 'String', c.microActual(1));
                set(c.autoV4Y, 'String', c.microActual(2));
                set(c.autoV4Z, 'String', c.piezo(3));
                set(c.autoV4NX, 'String', c.Sx);
                set(c.autoV4NY, 'String', c.Sy);
                % c.autoV4DX = c.selcircle(1);
                % c.autoV4DY = c.selcircle(2);
            case c.autoV5Get
                set(c.autoV5X, 'String', c.microActual(1));
                set(c.autoV5Y, 'String', c.microActual(2));
                set(c.autoV5Z, 'String', c.piezo(3));
                set(c.autoV5NX, 'String', c.Sx);
                set(c.autoV5NY, 'String', c.Sy);
                % c.autoV4DX = c.selcircle(1);
                % c.autoV4DY = c.selcircle(2);
            case c.autoTaskG2S
                set(c.autoTaskG2X, 'String', c.galvo(1)*1000);
                set(c.autoTaskG2Y, 'String', c.galvo(2)*1000);
                
                disableWarning = true;
            case c.autoTaskG3S
                set(c.autoTaskG3X, 'String', c.galvo(1)*1000);
                set(c.autoTaskG3Y, 'String', c.galvo(2)*1000);
                
                disableWarning = true;
        end
        
        if ~disableWarning
            if (c.piezo(1) ~= 5 || c.piezo(2) ~= 5) && (c.galvo(1) ~= 0 || c.galvo(2) ~= 0)
                questdlg('The piezos are not set to [5,5] and the galvos are not set to [0,0]!', 'Warning!', 'Okay');
            elseif (c.piezo(1) ~= 5 || c.piezo(2) ~= 5)
                questdlg('The piezos are not set to [5,5]!', 'Warning!', 'Okay');
            elseif (c.galvo(1) ~= 0 || c.galvo(2) ~= 0)
                questdlg('The galvos are not set to [0,0]!', 'Warning!', 'Okay');
            end
        end
    end
    function V = getStoredV(d)
        switch d
            case 1
                V = [str2double(get(c.autoV1X, 'String')) str2double(get(c.autoV1Y, 'String')) str2double(get(c.autoV1Z, 'String'))]';
            case 2
                V = [str2double(get(c.autoV2X, 'String')) str2double(get(c.autoV2Y, 'String')) str2double(get(c.autoV2Z, 'String'))]';
            case 3
                V = [str2double(get(c.autoV3X, 'String')) str2double(get(c.autoV3Y, 'String')) str2double(get(c.autoV3Z, 'String'))]';
            case 4
                V = [str2double(get(c.autoV4X, 'String')) str2double(get(c.autoV4Y, 'String')) str2double(get(c.autoV4Z, 'String'))]';
            case 5
                V = [str2double(get(c.autoV5X, 'String')) str2double(get(c.autoV5Y, 'String')) str2double(get(c.autoV5Z, 'String'))]';
        end
    end
    function N = getStoredN(d)
        switch d
            case 1
                N = [str2double(get(c.autoV1NX, 'String')) str2double(get(c.autoV1NY, 'String'))]';
            case 2
                N = [str2double(get(c.autoV2NX, 'String')) str2double(get(c.autoV2NY, 'String'))]';
            case 3
                N = [str2double(get(c.autoV3NX, 'String')) str2double(get(c.autoV3NY, 'String'))]';
            case 4
                N = [str2double(get(c.autoV4NX, 'String')) str2double(get(c.autoV4NY, 'String'))]';
            case 5
                N = [str2double(get(c.autoV5NX, 'String')) str2double(get(c.autoV5NY, 'String'))]';
        end
    end
    function R = getStoredR(d)
        switch d
            case 'x'
                R = [str2double(get(c.autoNXRm, 'String')) str2double(get(c.autoNXRM, 'String'))]';
            case 'y'
                R = [str2double(get(c.autoNYRm, 'String')) str2double(get(c.autoNYRM, 'String'))]';
            case 'dx'
                R = [str2double(get(c.autonRm, 'String'))  str2double(get(c.autonRM, 'String'))]';
            case 'dy'
                R = [str2double(get(c.autonyRm, 'String')) str2double(get(c.autonyRM, 'String'))]';
        end
    end
    function autoPreview_Callback(~, ~)
%         if (get(c.autoTaskWB, 'Value') == 1)
%             generateGrid(true); 
%         else
            generateGrid(false);
%         end
    end
    function [p, color, name, len] = generateGrid(onlyGoodListed)
        nxrange = getStoredR('x');    % Range of the major grid
        nyrange = getStoredR('y');

        ndxrange = getStoredR('dx');    % Range of the minor grid
        ndyrange = getStoredR('dy');

        % These vectors will be used to make our major grid
        V1 = getStoredV(1);    n1 = getStoredN(1);    % [x y z] - the position of the device in um;
        V2 = getStoredV(2);    n2 = getStoredN(2);    % [nx ny] - the position of the device in the major grid.
        V3 = getStoredV(3);    n3 = getStoredN(3);    % Fill in later! All of these coordinates will be loaded from the GUI...

        % This vector will be used to determine our device spacing inside one
        % grid.
        V4 = getStoredV(4);    n4 = getStoredN(4);
        V5 = getStoredV(5);    n5 = getStoredN(5);

        nd123 = [str2double(get(c.autoV123n, 'String')) str2double(get(c.autoV123ny, 'String'))]';  % The number of the device in the minor grid for 1,2,3
        nd4 =   [str2double(get(c.autoV4n, 'String'))   str2double(get(c.autoV4ny, 'String'))]';    % The number of the device in the minor grid for 4
        nd5 =   [str2double(get(c.autoV5n, 'String'))   str2double(get(c.autoV5ny, 'String'))]';    % The number of the device in the minor grid for 4

        % Major Grid
        m =    [n1(1)   n1(2)   1;
                n2(1)   n2(2)   1;
                n3(1)   n3(2)   1];
            
        if max(max(inv(m))) == Inf
            error('Major grid has a non-orthoganal basis');
        end
        
        x1 = inv(m)*[V1(1) V2(1) V3(1)]';
        x2 = inv(m)*[V1(2) V2(2) V3(2)]';
        x3 = inv(m)*[V1(3) V2(3) V3(3)]';
        
        V =     [x1(1) x1(2); x2(1) x2(2); x3(1) x3(2)];
        V0 =    [x1(3) x2(3) x3(3)]';

        % Minor Grid
        m =    [nd123(1) nd123(2) 1;
                nd4(1)   nd4(2)   1;
                nd5(1)   nd5(2)   1];
        
        if max(max(inv(m))) == Inf
            error('Minor grid has a non-orthoganal basis');
        end
        
        V123 = [0 0 0]';
        V4m = V4 - V*n4 - V0; %;
        V5m = V5 - V*n5 - V0; %;
        
        x1 = inv(m)*[V123(1) V4m(1) V5m(1)]';
        x2 = inv(m)*[V123(2) V4m(2) V5m(2)]';
        x3 = inv(m)*[V123(3) V4m(3) V5m(3)]';
        
        v =     [x1(1) x1(2); x2(1) x2(2); x3(1) x3(2)];
        v0 =    [x1(3) x2(3) x3(3)]';
        
        V0 = V0 + v0;
        
%         v = (V4 - (V*n4 + V0))/(nd4 - nd123);   % Direction of the linear minor grid. Note that z might be off...
        
        [white, black] = loadWhitelist();

        if(get(c.autoTaskWB, 'Value') ~= 1)
            
            c.p = zeros(3, diff(nxrange)*diff(nyrange)*diff(ndxrange)*diff(ndyrange));
            color = zeros(diff(nxrange)*diff(nyrange)*diff(ndxrange)*diff(ndyrange), 3);    % (silly matlab)
            name = cell(diff(nxrange)*diff(nyrange)*diff(ndxrange)*diff(ndyrange),1);
        else
            
            c.p = zeros(3, length(white));
            color = zeros(length(white), 3);    % (silly matlab)
            name = cell(length(white),1);
        end
%         l = cell(1, diff(nxrange)*diff(nyrange)*diff(ndrange));

        i = 1;
        for x = nxrange(1):nxrange(2)
            for y = nyrange(1):nyrange(2)
                for dx = ndxrange(1):ndxrange(2)
                    for dy = ndyrange(1):ndyrange(2)
                        isWhite = -1;    % -1 = no list; 0 = not on list; 1 = on list; 2 = specific;
                        isBlack = -1;    % -1 = no list; 0 = not on list; 1 = on list; 2 = specific;
                        isGood = true;
                        
                        if ~(length(white{1}) == 1)
                            for w = 1:length(white)
                                match = (white{w} == [dx, dy, x, y]) & ~isnan(white{w});
                                
                                if sum(match) == 4
                                    isWhite = 2;
                                elseif sum(match) == sum(~isnan(white{w})) && isWhite ~= 2
                                    isWhite = 1;
                                elseif isWhite == -1
                                    isWhite = 0;
                                end
                            end
                        end
                        if ~(length(black{1}) == 1)
                            for b = 1:length(black)
                                match = (black{b} == [dx, dy, x, y]) & ~isnan(black{b});
                                
                                if sum(match) == 4
                                    isBlack = 2;
                                elseif sum(match) == sum(~isnan(black{b})) && isBlack ~= 2
                                    isBlack = 1;
                                elseif isBlack == -1
                                    isBlack = 0;
                                end
                            end
                        end
                            
                        %disp((get(c.autoTaskWB, 'Value') == 1))
%                         disp('B, W:')
%                         disp(isBlack)
%                         disp(isWhite)
%                         disp([dx, dy, x, y])
                        
                        if (get(c.autoTaskWB, 'Value') == 1) && ((isWhite == 0) || (isBlack > 0 && isWhite ~= 2))   % Disable device if it is not whitelisted, or if it is blacklisted and not specifically enabled by the whitelist.
                            isGood = false;
%                         else
%                             disp('True:')
%                             disp(isBlack)
%                             disp(isWhite)
%                             [dx, dy, x, y]
                        end
                        
                        if ~onlyGoodListed || (onlyGoodListed && isGood)
%                             [dx, dy, x, y]
                            c.p(:,i) = V*([x y]') + v*([dx dy]') + V0;

                            color(i,:) = [0 0 1];

                            if ((dx == nd123(1) && dy == nd123(2)) && (sum(n1 == [x y]') == 2 || sum(n2 == [x y]') == 2 || sum(n3 == [x y]') == 2))
                                color(i,:) = [0 1 0];
                            end
                            if ((dx == nd4(1) && dy == nd4(2)) && sum(n4 == [x y]') == 2)
                                color(i,:) = [1 .5 0];
                            end
                            if ((dx == nd5(1) && dy == nd5(2)) && sum(n5 == [x y]') == 2)
                                color(i,:) = [1 .5 0];
                            end
                            if (c.p(3,i) < c.piezoMin(3))
                                p(3,i) = c.piezoMin(3);
                                color(i,:) = [1 0 0];
                            end
                            if (c.p(3,i) > c.piezoMax(3))
                                p(3,i) = c.piezoMax(3);
                                color(i,:) = [1 0 0];
                            end
                            if ~isGood
                                color(i,:) = [.7 0 0];
                            end

        %                     name{i} = ['Device ' num2str(d) ' in set [' num2str(x) ', '  num2str(y) ']'];
                            name{i} = '';

                            if diff(ndyrange) == 0 && diff(ndxrange) ~= 0
                                name{i} = ['d_[' num2str(dx) ']_s_[' num2str(x) ','  num2str(y) ']'];
                            elseif diff(ndxrange) == 0 && diff(ndyrange) ~= 0
                                name{i} = ['d_[' num2str(dy) ']_s_[' num2str(x) ','  num2str(y) ']'];
                            elseif diff(ndyrange) == 0 && diff(ndxrange) == 0
                                name{i} = ['s_[' num2str(x) ','  num2str(y) ']'];
                            else
                                if (get(c.autoTaskRow, 'Value') == 1)
                                    name{i} = ['d_[' num2str(dx) ']_r_['  num2str(dy) ']_s_[' num2str(x) ','  num2str(y) ']'];
                                else
                                    name{i} = ['d_[' num2str(dy) ']_c_['  num2str(dx) ']_s_[' num2str(x) ','  num2str(y) ']'];
                                end
                            end

                            i = i + 1;
                        end
                    end
                end
            end
        end
        
        len = i-1;
        
        c.pv = c.p;           % Transportation variables
        p = c.p;
        c.pc = color;
        c.len = len;

%         xlim(c.upperAxes, [min(p(1,:)) max(p(1,:))]);
%         ylim(c.upperAxes, [min(p(2,:)) max(p(2,:))]);
%         scatter(c.upperAxes, p(1,:), p(2,:), 36, color);
    end
    function automate_Callback(~, ~)
        automate(false);
    end
    function autoTest_Callback(~, ~)
        automate(true);
    end
    function enabled = checkTask(ui)
        enabled = (get(ui, 'Value') == 1)  && ~c.globalStop && c.autoScanning;
    end
    function sayResult(string)
        if c.results
            for char = string
                switch char
                    case 'X'
                        fprintf(c.fhv, ['\tX:\t' num2str(c.old(1)) '\t==>\t'  num2str(c.piezo(1)) '\tV\r\n']);
                    case 'Y'
                        fprintf(c.fhv, ['\tY:\t' num2str(c.old(2)) '\t==>\t'  num2str(c.piezo(2)) '\tV\r\n']);
                    case 'Z'
                        fprintf(c.fhv, ['\tZ:\t' num2str(c.old(3)) '\t==>\t'  num2str(c.piezo(3)) '\tV\r\n']);
                    case 'x'
                        fprintf(c.fhv, ['\tGX:\t' num2str(c.old(4)*1000) '\t==>\t'  num2str(c.galvo(1)*1000) '\tmV\r\n']);
                    case 'y'
                        fprintf(c.fhv, ['\tGY:\t' num2str(c.old(5)*1000) '\t==>\t'  num2str(c.galvo(2)*1000) '\tmV\r\n']);
                end
            end
        end
    end
    function automate(onlyTest)
        c.autoScanning = true;          % 'Running' variable
        
        nxrange =   getStoredR('x');    % Range of the major grid
        nyrange =   getStoredR('y');

        ndrange =   getStoredR('dx');   % Range of the minor grid
        ndyrange =  getStoredR('dy');
        
        % Get the grid...
        [p, color, name, len] = generateGrid(true);
        
        c.results = false;
        
        if ~onlyTest    % Generate directory...
            clk = clock;
            ledSet(1);

            superDirectory = [c.directory '\' c.autoFolder];                                    % Setup the folders
            dateFolder =    [num2str(clk(1)) '_' num2str(clk(2)) '_' num2str(clk(3))];          % Today's folder is formatted in YYYY_MM_DD Form
            scanFolder =    ['Scan @ ' num2str(clk(4)) '-' num2str(clk(5)) '-' num2str(clk(6))];% This scan's folder is fomatted in @ HH-MM-SS.sss
            directory =     [superDirectory '\' dateFolder];
            subDirectory =  [directory '\' scanFolder];

            [status, message, messageid] = mkdir(superDirectory, dateFolder);                   % Make sure today's folder has been created.
            display(message);

            [status, message, messageid] = mkdir(directory, scanFolder);                        % Create a folder for this scan
            display(message);

            prefix = [subDirectory '\'];
            
            c.results = true;     % Record results?
            
            %Get mean centroid
%             disp('Mean Centroid ...')
%          
%             if exist('c.autoV4DX','var')
%                 Xi=mean([c.autoV1DX c.autoV2DX c.autoV3DX c.autoV4DX])
%                 Yi=mean([c.autoV1DY c.autoV2DY c.autoV3DY c.autoV4DY])
%             else
%                 Xi=mean([c.autoV1DX c.autoV2DX c.autoV3DX])
%                 Yi=mean([c.autoV1DY c.autoV2DY c.autoV3DY])
%             end
            if get(c.autoAutoProceed,'Value') == 1 && checkTask(c.autoTaskDiskI) && exist('c.autoV3DX') && exist('c.autoV3DY')
                c.autoDX=c.autoV3DX;
                c.autoDY=c.autoV3DY;

                Xi= c.autoV3DX;
                Yi= c.autoV3DY;

                %Load Piezo Calibration Data
                try
                    c.calib=load('piezo_calib.mat');
                catch err
                    disp(err.message)
                end

                %debug
                pX=c.calib.pX
                pY=c.calib.pY
            end
                
            try     % Try to setup the results files...
                fh =  fopen([prefix 'results.txt'],         'w');  c.fh = fh;
                fhv = fopen([prefix 'results_verbose.txt'], 'w');  c.fhv = fhv;
                fhb = fopen([prefix 'results_brief.txt'],   'w');  c.fhb = fhb;
                fhp = fopen([prefix 'results_power.txt'],   'w');  c.fhp = fhp;

                if (fh == -1 || fhv == -1 || fhb == -1) 
                    error('oops, file cannot be written'); 
                end 
            
                fprintf(fh,  '  Set  \t Info \r\n');
                fprintf(fh, [' [x,y] ' strjoin(arrayfun(@(num)(['\t',num2str(num)]), linspace(ndrange(1), ndrange(2), ndrange(2)-ndrange(1)+1), 'UniformOutput', 0), '') '\r\n']);
                % The above is incomplete, as it does not include dy

                fprintf(fhb,  '  Set  \t Counts \r\n');
                fprintf(fhb, [' [x,y] ' strjoin(arrayfun(@(num)(['\t',num2str(num)]), linspace(ndrange(1), ndrange(2), ndrange(2)-ndrange(1)+1), 'UniformOutput', 0), '') '\r\n']);

                fprintf(fhp,  '  Set  \t Powers \r\n');
                fprintf(fhp, [' [x,y] ' strjoin(arrayfun(@(num)(['\t',num2str(num)]), linspace(ndrange(1), ndrange(2), ndrange(2)-ndrange(1)+1), 'UniformOutput', 0), '') '\r\n']);

                fprintf(fhv, 'Welcome to the verbose version of the results summary...\r\n\r\n');
            catch err
                display('Failed to create results files...');
                display(err.message);
                c.results = false;    % Don't record results if the above fails.
            end
            
%             [fileNorm, pathNorm] = uigetfile('*.SPE','Select the bare-diamond spectrum');     % Normalization setup
% 
%             if isequal(fileNorm, 0)
%                 spectrumNorm = 0;
%             else
%                 spectrumNorm = readSPE([pathNorm fileNorm]);
%                 
%                 savePlotPng(1:512, spectrumNorm, [prefix 'normalization_spectrum.png']);
% 
%                 save([prefix 'normalization_spectrum.mat'], 'spectrumNorm');
%                 copyfile([pathNorm fileNorm], [prefix 'normalization_spectrum.SPE']);
%             end
%             
%             if results
%                 if spectrumNorm == 0
%                     fprintf(fhv, 'No bare-diamond normalization was selected.\r\n\r\n');
%                 else
%                     fprintf(fhv, ['Bare diamond normalization was selected from:\r\n  ' pathNorm fileNorm '\r\n\r\n']);
%                 end
%             end
        end
        
        original = c.micro; % Record the original position of the micrometers so we can return to it later...
        
        i = 1;
        resetGalvo_Callback(0,0);      
        dZ = 0;     % Variable to account for significant drift in Z.

        for x = nxrange(1):nxrange(2)
            for y = nyrange(1):nyrange(2)
                for d = ndrange(1):ndrange(2)
                    for dy = ndyrange(1):ndyrange(2)
                        if c.autoScanning && c.running && ~c.globalStop && (i <= size(p,2))
                            try
                                gotoMicro(p(1:2,i)' - [10 10]);     % Goto the current device, approaching from the lower left.
                                gotoMicro(p(1:2,i)');
                                
%                                 pause(.5);
                                
                                if ~onlyTest
                                    piezoOutSmooth([0 0 0]);
                                end
                                piezoOutSmooth([5 5 p(3,i) + dZ]);       % Reset the piezos and goto the proper height

                                display(['Arrived at ' name{i}]);

                                if ~onlyTest && ~c.globalStop && c.autoScanning
                                    c.old = [c.piezo c.galvo];        % Save the previous state of the galvos and piezos.

                                    if checkTask(c.autoTaskFocus)
                                        display('  Focusing...');
                                        focus_Callback(0, 0);
                                        
%                                         dZ = dZ + (c.piezo(3)- c.old(3))/2;     % Add any discrepentcy to dZ (over 2 to help prevent mistakes).
                                        % Disabled the above feature on 10/6 until autofocus is improved.
                                    end

                                    if c.results
                                        fprintf(fhv, ['We moved to ' name{i} '\r\n']);
                                        sayResult('Z');
                                    end

                                    c.old = [c.piezo c.galvo];

                                    if checkTask(c.autoTaskBlue)
                                        try
                                            start(c.vid);
                                            data = getdata(c.vid);
                                            img = data(360:-1:121, 161:480);    % Fixed flip...
                                        catch err
                                            display(err.message)
                                        end
                                    end

                                    display('  Optimizing...');
                                    
                                    if checkTask(c.autoTaskDiskI)
                                        %Running Blue Feedback
                                        
                                        
%                                         for ii = 1:4
%                                             [c.Xf,c.Yf] = diskcheck(1); % Check Centroid for inverted image 
%                                         end
                                        
                                        for ii = 1:4
                                            [c.Xf,c.Yf] = diskcheck(); % Check Centroid for positive image
                                        end
                                        
                                    end

                                    scan0 = 0;
                                    scan = 0;
                                    piezo0 = 0;
                                    
                                    if checkTask(c.autoTaskPiezoI)
                                        display('    XY...');       piezo0 = piezoOptimizeXY(c.piezoRange, c.piezoSpeed, c.piezoPixels);
                                    end

                                    if checkTask(c.autoTaskGalvoI)
                                        display('    Galvo...');    scan0 = galvoOptimize(c.galvoRange, c.galvoSpeed, round(c.galvoPixels/2));
                                        scan = scan0; % In case there is only one repeat tasked.
                                    end

                                    if c.results
                                        sayResult('XYxy');
                                        fprintf(fhv, ['    This gave us an inital countrate of ' num2str(round(max(max(scan0)))) ' counts/sec.\r\n']);
                                    end

                                    j = 1;

                                    while j <= round(str2double(get(c.autoTaskNumRepeat, 'String'))) && ~c.globalStop && c.autoScanning
                                        c.old = [c.piezo c.galvo];
                                        
                                        display('    XYZ...');   optAll_Callback(0,0);
                                        
                                        display('    Galvo...'); optimizeAxis(4, .025, 200, 50);  scan = optimizeAxis(5, .025, 200, 50);

                                        sayResult('XYZxy');
                                        
                                        if c.results
                                            fprintf(fhv, ['    This gives us a countrate of ' num2str(round(max(max(scan)))) ' counts/sec.\r\n']);
                                        end

                                        j = j + 1;
                                    end

                                    c.old = [c.piezo c.galvo];
                                    
                                    if checkTask(c.autoTaskGalvo)
                                            display('  Scanning...');
                                            scan = galvoOptimize(c.galvoRange, c.galvoSpeed, c.galvoPixels);
                                    end

                                    sayResult('xy');

                                    if checkTask(c.autoTaskSpectrum)
                                        display('  Taking Spectrum...');
                                        
                                        G = {[0, 0],...
                                             [str2double(get(c.autoTaskG2X, 'String')), str2double(get(c.autoTaskG2Y, 'String'))],...
                                             [str2double(get(c.autoTaskG3X, 'String')), str2double(get(c.autoTaskG3Y, 'String'))]};
                                         
                                         numG = 1 + (sum(G{1} == 0) ~= 2) + (sum(G{2} == 0) ~= 2);
                                        
                                        for g = 1:3
                                            if g == 1 || sum(G{g} == 0) ~= 2
                                                if numG > 1
                                                    galvoOutSmooth([.2 .2]);
                                                    galvoOutSmooth(G{g}/1000);
                                                end
                                                
                                                spectrum = -1;

                                                k = 0;
                                                
                                                if g == 1 && numG == 1
                                                    fname = [prefix name{i} '_spectrum'];
                                                else
                                                    fname = [prefix name{i} '_g_[' num2str(g) ']_spectrum'];
                                                end

                                                while sum(size(spectrum)) == 2 && k < 3 && ~c.globalStop && c.autoScanning
                                                    try
                                                        trig = sendSpectrumTrigger();

                                                        if g == 1 && checkTask(c.autoTaskPower)
                                                            try
                                                                fprintf(fh, ['\t' num2str(getPower())]);
                                                            catch err
                                                                display(['Power aquisition failed with message: ' err.message]);
                                                            end
                                                        end

                                                        spectrum = waitForSpectrum(fname, trig);
                                                    catch err
                                                        display(err.message);
                                                    end
                                                    k = k + 1;
                                                end

                                                if sum(size(spectrum)) ~= 2 && ~c.globalStop && c.autoScanning
                                                    try
                                                        savePlotPng(1:512, spectrum, [fname '.png']);
                                                        savePlotPng(1:512, spectrum, [fname '.png']);
                                                    catch err
                                                        display(err.message);
                                                    end
                                                else
                                                    fprintf(fhv, ['    Unfortunately, spectrum acquisition failed for this device (g=' num2str(g) ').\r\n']);
                                                end

            %                                     if spectrumNorm ~= 0 && spectrum ~= 0
            %                                         spectrumFinal = double(spectrum - min(spectrum))./double(spectrumNorm - min(spectrumNorm) + 50);
            %                                         save([prefix name{i} '_spectrumFinal' '.mat'], 'spectrumFinal');
            % 
            %                                         savePlotPng(1:512, spectrumFinal, [prefix name{i} '_spectrumFinal' '.png']);
            % 
            % 
            %     %                                     tempP = plot(1, 'Visible', 'off');
            %     %                                     tempA = get(tempP, 'Parent');
            %     %                                     png = plot(tempA, 1:512, spectrumNorm);
            %     %                                     xlim(tempA, [1 512]);
            %     %     %                                 png = plot(c.lowerAxes, 1:512, spectrumFinal);
            %     %     %                                 xlim(c.lowerAxes, [1 512]);
            %     %                                     saveas(png, [prefix name{i} '_spectrumFinal' '.png']);
            %                                     end
                                            end
                                        end
                                        
                                        if numG > 1
                                            resetGalvo_Callback(0,0)
                                        end
                                    end

                                    display('  Saving...');

    %                                 tempP = plot(1, 'Visible', 'off');
    %                                 tempA = get(tempP, 'Parent');
    %                                 png = plot(tempA, 1:512, spectrumNorm);
    %                                 xlim(tempA, [1 512]);
    %     %                             png = plot(c.lowerAxes, 1:512, spectrum);
    %     %                             xlim(c.lowerAxes, [1 512]);
    %                                 saveas(png, [prefix name{i} '_spectrum' '.png']);

                                    if scan0  ~= 0
                                        imwrite(rot90(scan0,2)/max(max(scan0)),   [prefix name{i} '_galvo_debug'  '.png']);  % rotate because the dims are flipped.
                                    end
                                    if scan   ~= 0
                                        save([prefix name{i} '_galvo' '.mat'], 'scan');
                                        imwrite(rot90(scan,2)/max(max(scan)),     [prefix name{i} '_galvo'        '.png']);
                                    end
                                    if piezo0 ~= 0
                                        imwrite(piezo0/max(max(piezo0)),   [prefix name{i} '_piezo_debug'  '.png']);
                                    end

                                    if checkTask(c.autoTaskBlue)
                                        imwrite(img, [prefix name{i} '_blue' '.png']);
                                        
                                        try
                                            start(c.vid);
                                            data = flipdim(getdata(c.vid),1);
                                            
                                            pos   = [c.autoDX c.autoDY; c.Xf c.Yf];
                                            color = {'red', 'green'};
                                            img = insertMarker(data, pos, 'x', 'color', color, 'size', 5); 

                                            img = imcrop(img,[161 121 320 240]);    % Crop...
                                        catch err
                                            display(err.message)
                                        end
                                        
                                        imwrite(img, [prefix name{i} '_blue_after' '.png']);
                                    end


                                    if c.results
                                        display('  Remarking...');

                                        counts = max(max(scan));
        %                                 counts2 = max(max(intitial));

%                                         works = true;
% 
%                                         if get(c.autoTaskGalvo, 'Value') == 1
%                                             J = imresize(scan, 5);
%                                             J = imcrop(J, [length(J)/2-25 length(J)/2-20 55 55]);
% 
%                                             level = graythresh(J);
%                                             IBW = im2bw(J, level);
%                                             [centers, radii] = imfindcircles(IBW, [15 60]);
% 
%                                             works = ~isempty(centers);
%                                         end

        %                                 IBW = im2bw(scan, graythresh(scan));
        %                                 [centers, radii] = imfindcircles(IBW,[5 25]);

                                        if d == ndrange(1)
                                            fprintf(fhb, ['\r\n [' num2str(x) ',' num2str(y) '] ']);
                                            fprintf(fh,  ['\r\n [' num2str(x) ',' num2str(y) '] ']);
                                            fprintf(fhp, ['\r\n [' num2str(x) ',' num2str(y) '] ']);
                                        end

%                                         if works
%                                             fprintf(fhb, ' W |');
%                                             fprintf(fh, [' W ' num2str(round(counts), '%07i') ' |']);
%                                             fprintf(fhv, '    Our program detects that this device works.\r\n\r\n');
%                                         else
%                                             fprintf(fhb, '   |');
%                                             fprintf(fh, ['   ' num2str(round(counts), '%07i') ' |']);
%                                             fprintf(fhv, '    Our program detects that this device does not work.\r\n\r\n');
%                                         end

                                        if c.autoSkipping
                                            fprintf(fhb, '\tS');
                                            fprintf(fh, ['\t' num2str(round(counts), '%07i')]);
                                            fprintf(fhv, '    This device was skipped.\r\n\r\n');
                                        else
                                            fprintf(fhb, '\t');
                                            fprintf(fh, ['\t' num2str(round(counts), '%07i')]);
                                        end
                                    end

                                    display('  Finished...');
                            
                                    resetGalvo_Callback(0,0);

                                    while ~(c.proceed || get(c.autoAutoProceed, 'Value'))
                                        pause(.5);
                                    end
                                else
                                    pause(.5);
                                end
                            catch err
                                ledSet(2);
                                if c.results
                                    try
                                        fprintf(fhb, '\tF');
                                        fprintf(fh, ['\t' num2str(round(counts), '%07i')]);
                                        fprintf(fhv, '    Our program failed durign this device...\r\n\r\n');
                                    catch err2
                                        display(['Something went horribly when trying to say that something went horribly wrong with device ' name{i}]);
                                        display(err2.message);
                                    end
                                end
                                display([name{i} ' failed... Here is the error message:']);
                                display(err.message);
                            end

                            i = i+1;

                            if c.autoSkipping
                                c.autoScanning = true;
                                c.globalStop = false;
                                c.autoSkipping = false;
                            end
                        end
                    end
                end
            end
        end
        
        if ~onlyTest && c.results
            fclose(fhb);
            fclose(fh);
            fclose(fhv);
            fclose(fhp);
        end
        
        if c.running
            display('Totally Finished!');

            c.micro = original;
            setPos();

            c.autoScanning = false;
            c.globalStop = false;
            ledSet(0);
        end
    end


function copyLabelToClipboard(src, ~)
    clipboard('copy', src.Label(11:end));
end


