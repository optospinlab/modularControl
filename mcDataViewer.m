classdef mcDataViewer < handle
% mcDataViewer views data.
    
    properties
        data = [];          % mcData structure currently being plotted.
        
        r = [];             % Three channels of processed data.
        g = [];
        b = [];
        
        cf = [];            % Control figure.
        
        df = [];            % Data figure.
        a = [];             % Main axes.
        
        p = [];             % plot() object.
        i = [];             % image() object.
        
        pos = [];           % Contains four scatter plots (each containing one point) that denote the selected point, the selected pixel, the current point (of the axes), and the previous point (e.g. before optimization).
        posL = [];          % Contains four lines plots (each containing one line...   "     "     "   ...
        
        menus = [];
        tabs = [];
        scanButton = [];
        scale = [];
        
        listeners = [];
        
        params1D = [];
        params2D = [];
        
        isRGB = 0;
        
        scaleMin = [0 0 0];
        scaleMax = [1 1 1];
    end
    
    methods
        function gui = mcDataViewer(varin)
            shouldAquire = true;
            
            switch nargin
                case 0
                    gui.data = mcData();
                    gui.data.dataViewer = gui;
                    gui.r = mcProcessedData(gui.data);
                    gui.g = mcProcessedData(gui.data);
                    gui.b = mcProcessedData(gui.data);
                case 1
                    gui.data = varin{1};
                    gui.data.dataViewer = gui;
                    gui.r = mcProcessedData(gui.data);
                    gui.g = mcProcessedData(gui.data);
                    gui.b = mcProcessedData(gui.data);
                case 2
                    gui.data = varin{1};
                    gui.data.dataViewer = gui;
                    gui.r = mcProcessedData(gui.data, varin{2});
                    gui.g = mcProcessedData(gui.data);
                    gui.b = mcProcessedData(gui.data);
                case 3
                    gui.data = varin{1};
                    gui.data.dataViewer = gui;
                    gui.r = mcProcessedData(gui.data, varin{2});
                    gui.g = mcProcessedData(gui.data, varin{3});
                    gui.b = mcProcessedData(gui.data);
                case 4
                    gui.data = varin{1};
                    gui.data.dataViewer = gui;
                    gui.r = mcProcessedData(gui.data, varin{2});
                    gui.g = mcProcessedData(gui.data, varin{3});
                    gui.b = mcProcessedData(gui.data, varin{4});
            end
            
            if gui.data.data.scanMode == 2 || gui.data.data.scanMode == -1 || true
                shouldAquire = false;
            end
            
            if true
                gui.cf = mcInstrumentHandler.createFigure('Data Viewer Manager (Generic)');
                gui.cf.Position = [100,100,300,500];
                gui.cf.CloseRequestFcn = @gui.closeRequestFcn;
                
                jj = 1;
                kk = 1;
                
                inputNames1D = {};
                inputNames2D = {};
                
                for ii = 1:gui.data.data.numInputs
                    if gui.data.data.inputDimension == 1
                        inputNames1D{jj} = gui.data.data.inputNames{ii};
                        jj = jj + 1;
                    end
                    if gui.data.data.inputDimension == 2
                        inputNames2D{kk} = gui.data.data.inputNames{ii};
                        kk = kk + 1;
                    end
                end
                
                utg = uitabgroup('Position', [0, .525, 1, .475], 'SelectionChangedFcn', @gui.upperTabSwitch_Callback);
                gui.tabs.t1d = uitab('Parent', utg, 'Title', '1D');
%                 uicontrol('Parent', gui.tabs.t1d, 'Style', 'text',      'String', 'X:', 'Units', 'normalized', 'Position', [0 .5 .5 .5], 'HorizontalAlignment', 'right');
%                 uicontrol('Parent', gui.tabs.t1d, 'Style', 'popupmenu', 'String', [{'Choose', 'Time'}, gui.data.data.axisNames, inputNames1D], 'Units', 'normalized', 'Position', [.5 .5 .5 .5]);
                
                gui.tabs.t2d = uitab('Parent', utg, 'Title', '2D');
                gui.tabs.t3d = uitab('Parent', utg, 'Title', '3D (Disabled)');
                
                
                switch gui.data.data.plotMode
                    case 1
                        utg.SelectedTab = gui.tabs.t1d;
                    case 2
                        utg.SelectedTab = gui.tabs.t2d;
                end
                
                gui.tabs.t1d.Units = 'pixels';
                tabpos = gui.tabs.t1d.Position;
                
                bh = 20;

                uicontrol('Parent', gui.tabs.t3d, 'Style', 'text', 'String', 'Sometime?', 'HorizontalAlignment', 'center', 'Units', 'normalized', 'Position', [0 0 1 .95]);
                
                gui.params1D.chooseList = cell(1, gui.data.data.numAxes);
                gui.params2D.chooseList = cell(1, gui.data.data.numAxes);
                
                for ii = 1:gui.data.data.numAxes
                    levellist = strcat(strread(num2str(gui.data.data.scans{ii}), '%s')', [' ' gui.data.data.axes{ii}.config.kind.extUnits]);  % Returns the numbers in scans in '##.## unit' form.
                    
                    for tab = [gui.tabs.t1d gui.tabs.t2d]
                        uicontrol('Parent', tab, 'Style', 'text', 'String', [gui.data.data.axes{ii}.nameShort() ': '], 'Units', 'pixels', 'Position', [0 tabpos(4)-bh*ii-2*bh 2*tabpos(3)/3 bh], 'HorizontalAlignment', 'right');

                        if tab == gui.tabs.t1d
                            axeslist = {'X'};
                        else
                            axeslist = {'X', 'Y'};
                        end

                        val = length(axeslist)+1;

                        if ii == 1 && val > 1
                            val = 1;
                        elseif ii == 2 && val > 2
                            val = 2;
                        end
                        
                        choose = uicontrol('Parent', tab, 'Style', 'popupmenu', 'String', [axeslist, levellist], 'Units', 'pixels', 'Position', [2*tabpos(3)/3 tabpos(4)-bh*ii-2*bh tabpos(3)/3 - bh bh], 'Value', val, 'Callback', @gui.updateLayer_Callback);
                        
                        if tab == gui.tabs.t1d
                            gui.params1D.chooseList{ii} = choose;
                        else
                            gui.params2D.chooseList{ii} = choose;
                        end
                    end
                end
                
                ltg = uitabgroup('Position', [0, .05, 1, .475], 'SelectionChangedFcn', @gui.lowerTabSwitch_Callback);
                gui.tabs.gray = uitab('Parent', ltg, 'Title', 'Gray');
                gui.tabs.rgb =  uitab('Parent', ltg, 'Title', 'RGB (Disabled)');
                
                gui.tabs.gray.Units = 'pixels';
                tabpos = gui.tabs.gray.Position;
                inputlist = cellfun(@(x)({x.name()}), gui.data.data.inputs);
                                            
                uicontrol('Parent', gui.tabs.gray, 'Style', 'text',         'String', 'Input: ', 'Units', 'pixels', 'Position', [0 tabpos(4)-3*bh tabpos(3)/3 bh], 'HorizontalAlignment', 'right');
                uicontrol('Parent', gui.tabs.gray, 'Style', 'popupmenu',    'String', inputlist, 'Units', 'pixels', 'Position', [tabpos(3)/3 tabpos(4)-3*bh 2*tabpos(3)/3 - bh bh], 'Value', 1);
                            
                gui.scale.gray =    mcScalePanel(gui.tabs.gray, [(tabpos(3) - 250)/2 tabpos(4)-150], gui.r);
                gui.scale.r =       mcScalePanel(gui.tabs.rgb,  [(tabpos(3) - 250)/2 tabpos(4)-150], gui.r);
                gui.scale.g =       mcScalePanel(gui.tabs.rgb,  [(tabpos(3) - 500)/2 tabpos(4)-150], gui.g);
                gui.scale.b =       mcScalePanel(gui.tabs.rgb,  [(tabpos(3) - 750)/2 tabpos(4)-150], gui.b);
                
                gui.scanButton = uicontrol('Parent', gui.cf, 'Style', 'push', 'Units', 'normalized', 'Position', [0, 0, 1, .05], 'Callback', @gui.scanButton_Callback);
                
                if shouldAquire     % Expand upon this in the future
                    gui.data.data.scanMode = 1;                      % Set as scanning
                    gui.scanButton.String = 'Pause';
                else
                    if gui.data.data.scanMode == 0                   % If new
                        gui.scanButton.String = 'Scan';
                    elseif gui.data.data.scanMode == -1              % If paused
                        gui.scanButton.String = 'Continue'; 
                    elseif gui.data.data.scanMode == 2               % If finished
                        gui.scanButton.String = 'Rescan';
                    end
                end
            end
            
            gui.df = mcInstrumentHandler.createFigure('Data Viewer (Generic)');
            gui.df.CloseRequestFcn = @gui.closeRequestFcn;
            menu = uicontextmenu;

            gui.a = axes('Parent', gui.df, 'ButtonDownFcn', @gui.figureClickCallback, 'DataAspectRatioMode', 'manual', 'BoxStyle', 'full', 'Box', 'on'); %, 'Xgrid', 'on', 'Ygrid', 'on'
            colormap(gui.a, gray(256));
            
            hold(gui.a, 'on');
            
            x = 1:50;
            y = 1:50;
            z = rand(1, 50);
            c = mod(magic(50),2); %ones(50);
            
            gui.i = imagesc(x, y, c, 'Parent', gui.a, 'alphadata', c, 'XDataMode', 'manual', 'YDataMode', 'manual', 'ButtonDownFcn', @gui.figureClickCallback, 'UIContextMenu', menu, 'Visible', 'off');
            gui.pos.sel = scatter(0, 0, 'Parent', gui.a, 'SizeData', 40, 'XDataMode', 'manual', 'YDataMode', 'manual', 'CData', [1 0 1], 'PickableParts', 'none', 'Linewidth', 2, 'Marker', 'x', 'Visible', 'off');
            gui.pos.pix = scatter(0, 0, 'Parent', gui.a, 'SizeData', 40, 'XDataMode', 'manual', 'YDataMode', 'manual', 'CData', [1 1 0], 'PickableParts', 'none', 'Linewidth', 2, 'Marker', 'x', 'Visible', 'off');
            gui.pos.act = scatter(0, 0, 'Parent', gui.a, 'SizeData', 40, 'XDataMode', 'manual', 'YDataMode', 'manual', 'CData', [0 1 1], 'PickableParts', 'none', 'Linewidth', 2, 'Marker', 'o', 'Visible', 'off');
            gui.pos.prv = scatter(0, 0, 'Parent', gui.a, 'SizeData', 40, 'XDataMode', 'manual', 'YDataMode', 'manual', 'CData', [0 .5 .5], 'PickableParts', 'none', 'Linewidth', 2, 'Marker', 'o', 'Visible', 'off');
            
            gui.p = plot(x, rand(1, 50), x, rand(1, 50), x, rand(1, 50), 'Parent', gui.a, 'XDataMode', 'manual', 'YDataMode', 'manual', 'ButtonDownFcn', @gui.figureClickCallback, 'UIContextMenu', menu, 'Visible', 'off');
            gui.p(1).Color = [1 0 0];
            gui.p(2).Color = [0 1 0];
            gui.p(3).Color = [0 0 1];
            
            gui.posL.sel = plot([0 0], [-Inf Inf], 'Parent', gui.a, 'XDataMode', 'manual', 'YDataMode', 'manual', 'Color', [1 0 1], 'PickableParts', 'none', 'Linewidth', 1, 'Visible', 'off');
            gui.posL.pix = plot([0 0], [-Inf Inf], 'Parent', gui.a, 'XDataMode', 'manual', 'YDataMode', 'manual', 'Color', [1 1 0], 'PickableParts', 'none', 'Linewidth', 2, 'Visible', 'off');
            gui.posL.act = plot([0 0], [-Inf Inf], 'Parent', gui.a, 'XDataMode', 'manual', 'YDataMode', 'manual', 'Color', [0 1 1], 'PickableParts', 'none', 'Linewidth', 2, 'Visible', 'off');
            gui.posL.prv = plot([0 0], [-Inf Inf], 'Parent', gui.a, 'XDataMode', 'manual', 'YDataMode', 'manual', 'LineStyle', '--', 'Color', [0 .5 .5], 'PickableParts', 'none', 'Linewidth', 2, 'Visible', 'off');
            
            gui.a.YDir = 'normal';
            
            gui.menus.ctsMenu = uimenu(menu, 'Label', ' Value:    ~~.~~ --',                'Callback', @copyLabelToClipboard); %, 'Enable', 'off');
            gui.menus.pixMenu = uimenu(menu, 'Label', ' Pixel:    [ ~~.~~ --, ~~.~~ -- ]',  'Callback', @copyLabelToClipboard); %, 'Enable', 'off');
            gui.menus.posMenu = uimenu(menu, 'Label', ' Position: [ ~~.~~ --, ~~.~~ -- ]',  'Callback', @copyLabelToClipboard); %, 'Enable', 'off');
                mGoto = uimenu(menu, 'Label', 'Goto');
                mgPix = uimenu(mGoto, 'Label', 'Selected Pixel',    'Callback', {@gui.gotoPostion_Callback, gui.pos.pix});
                mgPos = uimenu(mGoto, 'Label', 'Selected Position', 'Callback', {@gui.gotoPostion_Callback, gui.pos.sel});
                mNorm = uimenu(menu, 'Label', 'Normalization', 'Enable', 'off');
                mnMin = uimenu(mNorm, 'Label', 'Set as Minimum', 'Callback',@d);
                mnMax = uimenu(mNorm, 'Label', 'Set as Maximum',  'Callback',@b);
            
%             params.a.XLim = [min(x), max(x)]; 
%             params.a.YLim = [min(y), max(y)];
            
            hold(gui.a, 'off');
            
%             edit.UserData = addlistener(axis_{1}, 'x', 'PostSet', @(s,e)(axisChanged_Callback(s, e, edit)));

            gui.listeners.x = [];
            gui.listeners.y = [];
            gui.resetAxisListeners();
            
            prop = findprop(mcProcessedData, 'data');
            gui.listeners.r = event.proplistener(gui.r, prop, 'PostSet', @gui.plotData_Callback);
            gui.listeners.g = event.proplistener(gui.g, prop, 'PostSet', @gui.plotData_Callback);
            gui.listeners.b = event.proplistener(gui.b, prop, 'PostSet', @gui.plotData_Callback);
            
            gui.plotData_Callback(0,0);
            gui.plotSetup();
            gui.makeProperVisibility();
            
            pause(1);
                    
            if shouldAquire
                gui.data.aquire();
            end
        end
        
        function closeRequestFcn(gui, ~, ~)
            % gui.data.save();
            gui.data.data.aquiring = false;
            
            delete(gui.listeners.x);
            delete(gui.listeners.y);
            delete(gui.listeners.r);
            delete(gui.listeners.g);
            delete(gui.listeners.b);
            
            delete(gui.cf);
            delete(gui.df);
            
            delete(gui.data);
            
            delete(gui);
        end
        
        function scanButton_Callback(gui, ~, ~)
            switch gui.data.data.scanMode
                case {0, -1}                                % If new or paused
                    gui.scanButton.String = 'Pause';
                    gui.data.data.scanMode = 1;
                    gui.data.aquire();
                case 1                                      % If scanning
                    gui.data.data.aquiring = false;
                    gui.data.data.scanMode = -1;
                    gui.scanButton.String = 'Continue';
                case 2                                      % If finished
                    gui.data.resetData();
                    gui.scanButton.String = 'Pause';
                    gui.data.data.scanMode = 1;
                    gui.data.aquire();
            end
        end
        
        function gotoPostion_Callback(gui, ~, ~, scatter)
            axisX = gui.data.data.axes{gui.data.data.layer == 1};
            axisX.goto(scatter.XData(1));
            
            if gui.data.data.plotMode == 2
                axisY = gui.data.data.axes{gui.data.data.layer == 2};
                axisY.goto(scatter.YData(1));
            end
        end
        
        function makeProperVisibility(gui)
            switch gui.data.data.plotMode
                case 1
                    pvis = 'on';
                    ivis = 'off';
                case 2
                    pvis = 'off';
                    ivis = 'on';
            end
            
            gui.p(1).Visible =       pvis;
            gui.posL.sel.Visible =   pvis;
            gui.posL.pix.Visible =   pvis;
            gui.posL.act.Visible =   pvis;
            gui.posL.prv.Visible =   pvis;
            
            if gui.isRGB
                gui.p(2).Visible =       pvis;
                gui.p(3).Visible =       pvis;
            else
                gui.p(2).Visible =       'off';
                gui.p(3).Visible =       'off';
            end
            
            gui.i.Visible =         ivis;
            gui.pos.sel.Visible =   ivis;
            gui.pos.pix.Visible =   ivis;
            gui.pos.act.Visible =   ivis;
            gui.pos.prv.Visible =   ivis;
        end
        
        function plotSetup(gui)
            switch gui.data.data.plotMode
                case 1
                    gui.p.XData = gui.data.data.scans{gui.data.data.layer == 1};
                    gui.a.XLim = [gui.p.XData(1) gui.p.XData(end)];         % Check to see if range is zero!
                    gui.a.XLabel.String = gui.data.data.axes{gui.data.data.layer == 1}.nameUnits();
                case 2
                    gui.i.XData = gui.data.data.scans{gui.data.data.layer == 1};
                    gui.i.YData = gui.data.data.scans{gui.data.data.layer == 2};
                    gui.a.XLim = [gui.i.XData(1) gui.i.XData(end)];         % Check to see if range is zero!
                    gui.a.YLim = [gui.i.YData(1) gui.i.YData(end)];         % Check to see if range is zero!
                    gui.a.XLabel.String = gui.data.data.axes{gui.data.data.layer == 1}.nameUnits();
                    gui.a.YLabel.String = gui.data.data.axes{gui.data.data.layer == 2}.nameUnits();
            end
            
            gui.resetAxisListeners();
        end
        function plotData_Callback(gui,~,~)
%             disp('here');
            
            if gui.data.data.scanMode == 2
                gui.scanButton.String = 'Rescan (Will Overwrite Data)';
            end

            switch gui.data.data.plotMode
                case 1
                    if gui.isRGB
                        
                    else
                        gui.p(1).YData = gui.r.data;
                    end
                case 2
                    if gui.isRGB
                        
                    else
%                         length(gui.r.data)
%                         gui.r.data
                        gui.i.CData =       gui.r.data;
                        gui.i.AlphaData =   ~isnan(gui.r.data);
                        gui.scale.gray.dataChanged_Callback(0,0);
                        
%                         gui.a.CLimMode = 'manual';
%                         gui.a.CLim = [0 50];
%                         caxis(gui.a, [0 25]);
                    end
            end
        end

        function figureClickCallback(gui, src, event)
            if event.Button == 3
                x = event.IntersectionPoint(1);
                y = event.IntersectionPoint(2);
                
                switch gui.data.data.plotMode
                    case 1
                        xlist = (gui.p.XData - x) .* (gui.p.XData - x);
                        xi = find(xlist == min(xlist), 1);
                        xp = gui.i.XData(xi);
                        
                        gui.posL.sel.XData = [x x];
                        gui.posL.pix.XData = [xp xp];
                    case 2
                        xlist = (gui.i.XData - x) .* (gui.i.XData - x);
                        ylist = (gui.i.YData - y) .* (gui.i.YData - y);
                        xi = find(xlist == min(xlist), 1);
                        yi = find(ylist == min(ylist), 1);
                        xp = gui.i.XData(xi);
                        yp = gui.i.YData(yi);
                        
                        gui.pos.sel.XData = x;
                        gui.pos.sel.YData = y;
                        gui.pos.pix.XData = xp;
                        gui.pos.pix.YData = yp;
                        
                        axisX = gui.data.data.axes{gui.data.data.layer == 1};
                        axisY = gui.data.data.axes{gui.data.data.layer == 2};

                        val = gui.i.CData(yi, xi);

                        if isnan(val)
                            gui.menus.ctsMenu.Label = ' Value:    ----- cts/sec';
                        else
                            gui.menus.ctsMenu.Label = [' Value:    ' num2str(val, 4) ' '];
                        end
                        
                        gui.menus.posMenu.Label = [' Position: [ ' num2str(x, 4)  ' ' axisX.config.kind.extUnits ', ' num2str(y, 4)  ' ' axisY.config.kind.extUnits ' ]'];
                        gui.menus.pixMenu.Label = [' Pixel:    [ '    num2str(xp, 4) ' ' axisX.config.kind.extUnits ', ' num2str(yp, 4) ' ' axisY.config.kind.extUnits ' ]'];
                end
            end
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
        
        function updateLayer_Callback(gui, src, ~)
            layerPrev = gui.data.data.layer;
            
            switch gui.data.data.plotMode   % Make this reference a list instead of a switch
                case 1
                    layer = cellfun(@(x)(x.Value), gui.params1D.chooseList);
%                     disp(layer);
                    
                    if sum(layer == 1) == 0
                        changed = cellfun(@(x)(x == src), gui.params1D.chooseList);
                        
                        layer(changed) = 1;
%                         disp(layer);
                    end
                    
                    if sum(layer == 1) > 1
                        changed = cellfun(@(x)(x == src), gui.params1D.chooseList);
                        
                        layer(layer == 1 & ~changed) = 2;
%                         disp(layer);
                    end
                    
                    for ii = 1:length(layer)
                        gui.params1D.chooseList{ii}.Value = layer(ii);
                    end
                case 2
                    layer = cellfun(@(x)(x.Value), gui.params2D.chooseList);
%                     disp(layer);
                    changed = cellfun(@(x)(x == src), gui.params2D.chooseList);
                    
                    if sum(layer == 1) == 0 && sum(layer == 2) == 2 && layer(changed) == 2
                        layer(layer == 2 & ~changed) = 1;
                    end
                    if sum(layer == 1) == 2 && sum(layer == 2) == 0 && layer(changed) == 1
                        layer(layer == 1 & ~changed) = 2;
                    end
                    
                    if sum(layer == 1) == 0
                        layer(changed) = 1;
                    end
                    if sum(layer == 2) == 0
                        layer(changed) = 2;
                    end
                    if sum(layer == 1) > 1
                        layer(layer == 1 & ~changed) = 3;
                    end
                    if sum(layer == 2) > 1
                        layer(layer == 2 & ~changed) = 3;
                    end
                    
                    for ii = 1:length(layer)
                        gui.params2D.chooseList{ii}.Value = layer(ii);
                    end
                otherwise
                    layer = 0;
            end
            
            gui.data.data.layer = layer;
            
            if ~all(layer == layerPrev)
                gui.plotSetup();
            end
        end
        
        function upperTabSwitch_Callback(gui, src, event)
            switch event.NewValue
                case gui.tabs.t1d
                    gui.data.data.plotMode = 1;
                case gui.tabs.t2d
                    if gui.data.data.numAxes < 2
                        src.SelectedTab = event.OldValue;
                    else
                        gui.data.data.plotMode = 2;
                    end
                case gui.tabs.t3d
                    if true
                        src.SelectedTab = event.OldValue;
                    else
                        gui.data.data.plotMode = 3;
                    end
            end
            
            gui.makeProperVisibility()
        end
        function lowerTabSwitch_Callback(gui, src, event)
            switch event.NewValue
                case gui.tabs.gray
                    gui.isRGB = 0;
                case gui.tabs.rgb
                    src.SelectedTab = event.OldValue;
            end
        end
    end
end

function copyLabelToClipboard(src, ~)
    clipboard('copy', src.Label(12:end));
end




