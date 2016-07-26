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
        
        listeners = [];
        
        params1D = [];
        params2D = [];
        
        isRGB = 0;
        
        scaleMin = [0 0 0];
        scaleMax = [1 1 1];
    end
    
    methods
        function gui = mcDataViewer(varin)
            switch nargin
                case 0
                    gui.data = mcData();
                    gui.r = mcProcessedData(gui.data);
                    gui.g = mcProcessedData(gui.data);
                    gui.b = mcProcessedData(gui.data);
                case 1
                    gui.data = varin;
                    gui.r = mcProcessedData(gui.data);
                    gui.g = mcProcessedData(gui.data);
                    gui.b = mcProcessedData(gui.data);
                case 2
                    gui.data = varin;
                    gui.r = mcProcessedData(gui.data, varin{2});
                    gui.g = mcProcessedData(gui.data);
                    gui.b = mcProcessedData(gui.data);
                case 3
                    gui.data = varin;
                    gui.r = mcProcessedData(gui.data, varin{2});
                    gui.g = mcProcessedData(gui.data, varin{3});
                    gui.b = mcProcessedData(gui.data);
                case 4
                    gui.data = varin;
                    gui.r = mcProcessedData(gui.data, varin{2});
                    gui.g = mcProcessedData(gui.data, varin{3});
                    gui.b = mcProcessedData(gui.data, varin{4});
            end
            
            if true
                gui.cf = mcInstrumentHandler.createFigure('Data Viewer Manager (Generic)');
                gui.cf.Position = [100,100,300,500];
                
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
                
                utg = uitabgroup('Position', [0, .5, 1, .5], 'SelectionChangedFcn', @gui.upperTabSwitch_Callback);
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
                
                ltg = uitabgroup('Position', [0, 0, 1, .5], 'SelectionChangedFcn', @gui.lowerTabSwitch_Callback);
                gui.tabs.gray = uitab('Parent', ltg, 'Title', 'Gray');
                gui.tabs.rgb =  uitab('Parent', ltg, 'Title', 'RGB (Disabled)');
                
                gui.tabs.gray.Units = 'pixels';
                tabpos = gui.tabs.gray.Position;
                inputlist = cellfun(@(x)({x.name()}), gui.data.data.inputs)
                                            
                uicontrol('Parent', gui.tabs.gray, 'Style', 'text',         'String', 'Input: ', 'Units', 'pixels', 'Position', [0 tabpos(4)-3*bh tabpos(3)/3 bh], 'HorizontalAlignment', 'right');
                uicontrol('Parent', gui.tabs.gray, 'Style', 'popupmenu',    'String', inputlist, 'Units', 'pixels', 'Position', [tabpos(3)/3 tabpos(4)-3*bh 2*tabpos(3)/3 - bh bh], 'Value', 1);
                            
                mcScalePanel(gui.tabs.gray, [(tabpos(3) - 250)/2 tabpos(4)-150], gui.data);
            end
            
            gui.df = mcInstrumentHandler.createFigure('Data Viewer (Generic)');
            menu = uicontextmenu;

            gui.a = axes('Parent', gui.df, 'ButtonDownFcn', @gui.figureClickCallback, 'DataAspectRatioMode', 'manual', 'BoxStyle', 'full', 'Box', 'on'); %, 'Xgrid', 'on', 'Ygrid', 'on'
            colormap(gui.a,'gray')
            
            hold(gui.a, 'on');
            
            x = 1:50;
            y = 1:50;
            z = rand(1, 50);
            c = mod(magic(50),2); %ones(50);
            
            gui.i = image(gui.a, x, y, c, 'alphadata', c, 'ButtonDownFcn', @gui.figureClickCallback, 'UIContextMenu', menu, 'Visible', 'off');
            gui.pos.sel = scatter(gui.a, 0, 0, 'SizeData', 40, 'CData', [1 0 1], 'PickableParts', 'none', 'Linewidth', 2, 'Marker', 'x', 'Visible', 'off');
            gui.pos.pix = scatter(gui.a, 0, 0, 'SizeData', 40, 'CData', [1 1 0], 'PickableParts', 'none', 'Linewidth', 2, 'Marker', 'x', 'Visible', 'off');
            gui.pos.act = scatter(gui.a, 0, 0, 'SizeData', 40, 'CData', [0 1 1], 'PickableParts', 'none', 'Linewidth', 2, 'Marker', 'o', 'Visible', 'off');
            gui.pos.prv = scatter(gui.a, 0, 0, 'SizeData', 40, 'CData', [0 .5 .5], 'PickableParts', 'none', 'Linewidth', 2, 'Marker', 'o', 'Visible', 'off');
            
            gui.p = plot( gui.a, x, rand(1, 50), x, rand(1, 50), x, rand(1, 50), 'ButtonDownFcn', @gui.figureClickCallback, 'UIContextMenu', menu, 'Visible', 'off');
            gui.p(1).Color = [1 0 0];
            gui.p(2).Color = [0 1 0];
            gui.p(3).Color = [0 0 1];
            
            gui.posL.sel = plot(gui.a, [0 0], [-Inf Inf], 'Color', [1 0 1], 'PickableParts', 'none', 'Linewidth', 1, 'Visible', 'off');
            gui.posL.pix = plot(gui.a, [0 0], [-Inf Inf], 'Color', [1 1 0], 'PickableParts', 'none', 'Linewidth', 2, 'Visible', 'off');
            gui.posL.act = plot(gui.a, [0 0], [-Inf Inf], 'Color', [0 1 1], 'PickableParts', 'none', 'Linewidth', 2, 'Visible', 'off');
            gui.posL.prv = plot(gui.a, [0 0], [-Inf Inf], 'LineStyle', '--', 'Color', [0 .5 .5], 'PickableParts', 'none', 'Linewidth', 2, 'Visible', 'off');
            
            gui.a.YDir = 'normal';
            
            gui.menus.ctsMenu = uimenu(menu, 'Label', ' Value: ~~.~~ --', 'Enable', 'off');
            gui.menus.pixMenu = uimenu(menu, 'Label', ' Pixel: [ ~~.~~ --, ~~.~~ -- ]', 'Enable', 'off');
            gui.menus.posMenu = uimenu(menu, 'Label', ' Position: [ ~~.~~ --, ~~.~~ -- ]', 'Enable', 'off');
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
            
            gui.makeProperVisibility();
            gui.plotSetup();
                    
            gui.data.aquire();
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
                case 2
                    gui.i.XData = gui.data.data.scans{gui.data.data.layer == 1};
                    gui.i.YData = gui.data.data.scans{gui.data.data.layer == 2};
                    gui.a.XLim = [gui.i.XData(1) gui.i.XData(end)];         % Check to see if range is zero!
                    gui.a.YLim = [gui.i.YData(1) gui.i.YData(end)];         % Check to see if range is zero!
            end
        end
        function plotData_Callback(gui,~,~)
%             disp('here');
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
                        caxis(gui.a, [0 100]);
                        gui.i.CData =       gui.r.data;
                        gui.i.AlphaData =   ~isnan(gui.r.data);
                    end
            end
        end
        function testPlot(gui)
            x = 1:100;
            y = 1:100;

            lx = length(x);
            ly = length(y);

        %     params.a.DataAspectRatio = [lx ly 1];
            params.a.DataAspectRatio = [1 1 1];
        %     params.a.PlotBoxAspectRatio = [lx ly 1];

            m = rand(ly, lx);
            m(1:50, 1:50) = NaN;

            c = repmat(m, 1, 1, 3);

            c(:,:,2) = rand(ly, lx);
            c(:,:,3) = rand(ly, lx);

            params.i = image(params.a, x, y, c, 'alphadata', ~isnan(m), 'ButtonDownFcn', @figureClickCallback, 'UIContextMenu', menu);
            params.a.XLim = [min(x), max(x)]; 
            params.a.YLim = [min(y), max(y)];

            params.a.YDir = 'reverse';


            daspect(params.a, [1 1 1]);

            hold(params.a,'on')
            params.pos = scatter(params.a, 0, 0, 'SizeData', 40, 'CData', [1 0 0], 'PickableParts', 'none', 'Linewidth', 2, 'Marker', 'x');
            params.s = scatter(params.a, [0 0 0], [0 0 0], 40, [1 0 0; 0 1 0; 0 0 1], 'PickableParts', 'none', 'Linewidth', 2);
            hold(params.a,'off')

            params.a.YDir = 'reverse';
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
                            gui.menus.ctsMenu.Label = ' Value: ----- cts/sec';
                        else
                            gui.menus.ctsMenu.Label = [' Value: ' num2str(val, 4) ' '];
                        end
                        
                        gui.menus.posMenu.Label = [' Position: [ ' num2str(x, 4)  ' ' axisX.config.kind.extUnits ', ' num2str(y, 4)  ' ' axisY.config.kind.extUnits ' ]'];
                        gui.menus.pixMenu.Label = [' Pixel: [ '    num2str(xp, 4) ' ' axisX.config.kind.extUnits ', ' num2str(yp, 4) ' ' axisY.config.kind.extUnits ' ]'];
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
                    gui.listeners.x = event.proplistener(gui.data.data.axes{gui.data.data.layer == 1}, prop, 'PostSet', @gui.listenToAxes_Callback);
                    gui.listeners.y = event.proplistener(gui.data.data.axes{gui.data.data.layer == 2}, prop, 'PostSet', @gui.listenToAxes_Callback);
            end
        end
        function listenToAxes_Callback(gui, ~, ~)
            if isvalid(gui.posL.act)
                axisX = gui.data.data.axes{gui.data.data.layer == 1};

                x = axisX.getX();

                gui.posL.act.XData = [x x];
                gui.pos.act.XData = axisX.getX();

                if gui.data.data.plotMode == 2
                    axisY = gui.data.data.axes{gui.data.data.layer == 2};

                    gui.pos.act.YData = axisY.getX();
                end
            end
        end
        
        function updateLayer_Callback(gui, ~, ~)
            switch gui.data.data.plotMode   % Make this reference a list instead of a switch
                case 1
                    gui.data.data.layer = cellfun(@(x)(x.Value), gui.params1D.chooseList)
                case 2
                    gui.data.data.layer = cellfun(@(x)(x.Value), gui.params2D.chooseList)
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

function b(src, event)
    'b'
end

function d(src, event)
    'd'
end

function axisChanged_Callback(~, event, edit)
%     src
%     event
    edit.String = num2str(event.AffectedObject.getX(), '%.02f');
end

% function output_txt = labeldtips(src, event)
%     pos = get(event,'Position');
%     x = pos(1); y = pos(2);
% 
% %     global xaxis yaxis raxis gaxis baxis zaxis isRGB plotMode
% 
%     switch lower(plotMode)
%         case {1, '1d'}
%             output_txt =   {[xaxis.label() ': ' num2str(x)], ...
%                             [yaxis.label() ': ' num2str(y)]};
%         case {2, '2d'}
%             if isRGB
%                 output_txt =   {[xaxis.label() ': ' num2str(x)], ...
%                                 [yaxis.label() ': ' num2str(y)], ...
%                                 [raxis.label() ': ' num2str(z)], ...
%                                 [gaxis.label() ': ' num2str(z)], ...
%                                 [baxis.label() ': ' num2str(z)]};
%             else
%                 output_txt =   {[xaxis.label() ': ' num2str(x)], ...
%                                 [yaxis.label() ': ' num2str(y)], ...
%                                 [zaxis.label() ': ' num2str(z)]};
%             end
%         case {3, '3d'}
%             error('3D plotMode Not Implimented');
%         otherwise
%             error('plotMode not understood');
%     end
% 
% 
%     idx = find(xydata == x,1);  % Find index to retrieve obs. name
% 
% % The find is reliable only if there are no duplicate x values
% % [row,col] = ind2sub(size(xydata),idx);
% 
% end




