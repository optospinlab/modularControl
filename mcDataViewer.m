classdef mcDataViewer < mcSavableClass
% mcDataViewer views data.
%
% Status: Mostly finished, but mostly uncommented. Future: display non-singular inputs, definitely RGB, maybe 3D?
    
    properties
        colorR = [1 0 0];
        colorG = [0 1 0];
        colorB = [0 0 1];
        
        colorSel = [1 0 1];  % Color of the lines and points denoting...     ...the currently-selected position
        colorPix = [1 1 0];  %                                               ...the pixel nearest to the currently-selected position
        colorAct = [0 1 1];  %                                               ...the actual (physical) position of the axes
        colorPrv = [0 .7 .7];  %                                             ...the previous (physical) position of the axes (e.g. for optimization).
    end

    properties
        data = [];          % mcData structure currently being plotted.
        
        r = [];             % Three channels of processed data.
        g = [];
        b = [];
        
        cf = [];            % Control figure.
        
        df = [];            % Data figure.
        a = [];             % Main axes in the data figure.
        
        p = [];             % plot() object (for 1D).
        i = [];             % image() object (for 2D).
        % s = [];             % surf() object (for 3D)?
        
        pos = [];           % Contains four scatter plots (each containing one point) that denote the selected point, the selected pixel, the current point (of the axes), and the previous point (e.g. before optimization).
        posL = [];          % Contains four lines plots (each containing one line...   "     "     "   ...
        patches = [];       % Contains four patches  (each containing four points; the corners of a rectangle...   "     "     "   ...
        
        menus = [];
        tabs = [];
        scanButton = [];
        scale = [];
        
        listeners = [];
        
        params = [];
        params1D = [];
        params2D = [];
        paramsGray = [];
        paramsRGB = [];
        
        isRGB = 0;
        
        selData = [0 0 0];
        
        scaleMin = [0 0 0]; % Unused?
        scaleMax = [1 1 1];
    end
    
    methods
        function gui = mcDataViewer(varin)
            shouldAquire = true;
            shouldMakeManager = true;
            
            switch nargin
                case 0
                    gui.data = mcData();
                    gui.data.dataViewer = gui;
                    gui.r = mcProcessedData(gui.data);
                    gui.g = mcProcessedData(gui.data);
                    gui.b = mcProcessedData(gui.data);
                case 1
                    if islogical(varin)
                        gui = mcDataViewer();
                        if ~varin
                            shouldMakeManager = false;
                        end
                    else
                        gui.data = varin;
                        gui.data.dataViewer = gui;
                        gui.r = mcProcessedData(gui.data);
                        gui.g = mcProcessedData(gui.data);
                        gui.b = mcProcessedData(gui.data);
                    end
                case 2
                    if islogical(varin{2})
                        gui = mcDataViewer(varin{1});
                        if ~varin{2}
                            shouldMakeManager = false;
                        end
                    else
                        gui.data = varin{1};
                        gui.data.dataViewer = gui;
                        gui.r = mcProcessedData(gui.data, varin{2});
                        gui.g = mcProcessedData(gui.data);
                        gui.b = mcProcessedData(gui.data);
                    end
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
            
            if gui.data.data.scanMode == 2 || gui.data.data.scanMode == -1
                shouldAquire = false;
            end
            
            if shouldMakeManager
                gui.cf = mcInstrumentHandler.createFigure(gui, 'saveopen');
                gui.cf.Position = [100,100,300,500];
                gui.cf.CloseRequestFcn = @gui.closeRequestFcn;
                
                jj = 1;
                kk = 1;
                
                inputNames1D = {};
                inputNames2D = {};
                
                for ii = 1:gui.data.data.numInputs
                    if gui.data.data.inputDimension(ii) == 1
                        inputNames1D{jj} = gui.data.data.inputNames{ii};
                        jj = jj + 1;
                    end
                    if gui.data.data.inputDimension(ii) == 2
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
                
                gui.params1D.chooseList = cell(1, gui.data.data.numAxes); % This will be longer, but we choose not to calculate.
                gui.params2D.chooseList = cell(1, gui.data.data.numAxes);
                
                ii = 0;
                
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

                        if ii == 1 && val > 1       % Sets the first and second axes (or inputs) to be the X and Y axes, while the rest are on the first layer
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
            
                        gui.data.data.layerType(ii) = 0;     % The layer is an axis.
                        gui.data.data.layerIndex(ii) = ii;
                        gui.data.data.layerDim(ii) = 1;
                    end
                end
                
                inputLetters = 'XYZUVW';
                
                for kk = 1:gui.data.data.numInputs
                    ii = ii + 1;    % Use the ii from the axis loop.
                    
                    if gui.data.data.inputDimension(kk) - 1 > length(inputLetters)
                        jj = 0;
                        
                        for sizeInput = gui.data.data.inputs{kk}.config.kind.sizeInput
                            if sizeInput ~= 1       % A vector, according to matlab, has size [1 N]. We don't want to count the 1.
                                jj = jj + 1;
                                
                                levellist = strcat('pixel ', strread(num2str(1:sizeInput), '%s')');  % Returns the pixels in 'pixel ##' form.

                                for tab = [gui.tabs.t1d gui.tabs.t2d]
                                    % Make the text in the form 'input_name X' where X can be any letter in inputLetters.
                                    uicontrol('Parent', tab, 'Style', 'text', 'String', [gui.data.data.inputs{kk}.nameShort() ' ' inputLetters(jj) ': '], 'Units', 'pixels', 'Position', [0 tabpos(4)-bh*ii-2*bh 2*tabpos(3)/3 bh], 'HorizontalAlignment', 'right');

                                    if tab == gui.tabs.t1d
                                        axeslist = {'X'};
                                    else
                                        axeslist = {'X', 'Y'};
                                    end

                                    val = length(axeslist)+1;

                                    if ii == 1 && val > 1       % Sets the first and second axes (or inputs) to be the X and Y axes, while the rest are on the first layer
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

                                    gui.data.data.layerType(ii) = 1;     % The layer is an input.
                                    gui.data.data.layerIndex(ii) = kk;
                                    gui.data.data.layerDim(ii) = 1;
                                end
                            end
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
                gui.paramsGray.choose = uicontrol('Parent', gui.tabs.gray, 'Style', 'popupmenu',    'String', inputlist, 'Units', 'pixels', 'Position', [tabpos(3)/3 tabpos(4)-3*bh 2*tabpos(3)/3 - bh bh], 'Value', 1);
                
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
            
            gui.df = mcInstrumentHandler.createFigure(gui, 'saveopen');
            gui.df.CloseRequestFcn = @gui.closeRequestFcn;
            menu = uicontextmenu;

            gui.a = axes('Parent', gui.df, 'ButtonDownFcn', @gui.figureClickCallback, 'DataAspectRatioMode', 'manual', 'BoxStyle', 'full', 'Box', 'on', 'UIContextMenu', menu); %, 'Xgrid', 'on', 'Ygrid', 'on'
            colormap(gui.a, gray(256));
            
            hold(gui.a, 'on');
            
            gui.r.process();
            if gui.isRGB
                gui.g.process();
                gui.b.process();
            end
            
            x = 1:50;
            y = 1:50;
            z = rand(1, 50);
            c = mod(magic(50),2); %ones(50);
            
            gui.i = imagesc(x, y, c, 'Parent', gui.a, 'alphadata', c, 'XDataMode', 'manual', 'YDataMode', 'manual', 'ButtonDownFcn', @gui.figureClickCallback, 'UIContextMenu', menu, 'Visible', 'off');
            gui.p = plot(x, rand(1, 50), x, rand(1, 50), x, rand(1, 50), 'Parent', gui.a, 'XDataMode', 'manual', 'YDataMode', 'manual', 'ButtonDownFcn', @gui.figureClickCallback, 'UIContextMenu', menu, 'Visible', 'off');
            
            gui.plotData_Callback(0,0);
            
            gui.pos.prv = scatter(0, 0, 'Parent', gui.a, 'SizeData', 40, 'XDataMode', 'manual', 'YDataMode', 'manual', 'CData', gui.colorPrv, 'PickableParts', 'none', 'Linewidth', 2, 'Marker', 'o', 'Visible', 'off');
            gui.pos.sel = scatter(0, 0, 'Parent', gui.a, 'SizeData', 40, 'XDataMode', 'manual', 'YDataMode', 'manual', 'CData', gui.colorSel, 'PickableParts', 'none', 'Linewidth', 2, 'Marker', 'x', 'Visible', 'off');
            gui.pos.pix = scatter(0, 0, 'Parent', gui.a, 'SizeData', 40, 'XDataMode', 'manual', 'YDataMode', 'manual', 'CData', gui.colorPix, 'PickableParts', 'none', 'Linewidth', 2, 'Marker', 'x', 'Visible', 'off');
            gui.pos.act = scatter(0, 0, 'Parent', gui.a, 'SizeData', 40, 'XDataMode', 'manual', 'YDataMode', 'manual', 'CData', gui.colorAct, 'PickableParts', 'none', 'Linewidth', 2, 'Marker', 'o', 'Visible', 'off');
            
            gui.p(1).Color = gui.colorR;
            gui.p(2).Color = gui.colorG;
            gui.p(3).Color = gui.colorB;
            
            gui.posL.prv = plot([0 0], [-100 100], 'Parent', gui.a, 'XDataMode', 'manual', 'YDataMode', 'manual', 'LineStyle', '--', 'Color', gui.colorPrv, 'PickableParts', 'none', 'Linewidth', 2, 'Visible', 'off');
            gui.posL.sel = plot([0 0], [-100 100], 'Parent', gui.a, 'XDataMode', 'manual', 'YDataMode', 'manual', 'Color', gui.colorSel, 'PickableParts', 'none', 'Linewidth', 1, 'Visible', 'off');
            gui.posL.pix = plot([0 0], [-100 100], 'Parent', gui.a, 'XDataMode', 'manual', 'YDataMode', 'manual', 'Color', gui.colorPix, 'PickableParts', 'none', 'Linewidth', 2, 'Visible', 'off');
            gui.posL.act = plot([0 0], [-100 100], 'Parent', gui.a, 'XDataMode', 'manual', 'YDataMode', 'manual', 'Color', gui.colorAct, 'PickableParts', 'none', 'Linewidth', 2, 'Visible', 'off');
            
            gui.a.YDir = 'normal';
            
            gui.menus.ctsMenu = uimenu(menu, 'Label', 'Value: ~~.~~ --',                'Callback', @copyLabelToClipboard); %, 'Enable', 'off');
            gui.menus.pixMenu = uimenu(menu, 'Label', 'Pixel: [ ~~.~~ --, ~~.~~ -- ]',  'Callback', @copyLabelToClipboard); %, 'Enable', 'off');
            gui.menus.posMenu = uimenu(menu, 'Label', 'Position: [ ~~.~~ --, ~~.~~ -- ]',  'Callback', @copyLabelToClipboard); %, 'Enable', 'off');
                mGoto = uimenu(menu, 'Label', 'Goto');
                mgPix = uimenu(mGoto, 'Label', 'Selected Pixel',    'Callback', {@gui.gotoPostion_Callback, 0});
                mgPos = uimenu(mGoto, 'Label', 'Selected Position', 'Callback', {@gui.gotoPostion_Callback, 1});
                mNorm = uimenu(menu, 'Label', 'Normalization'); %, 'Enable', 'off');
                panel = gui.scale.gray;
%                 @panel.normalize_Callback
%                 @gui.scale.gray.normalize_Callback
                mnNorm= uimenu(mNorm, 'Label', 'Normalize', 'Callback',    @panel.normalize_Callback);
                mnMin = uimenu(mNorm, 'Label', 'Set as Minimum', 'Callback',    {@gui.minmax_Callback, 0});
                mnMax = uimenu(mNorm, 'Label', 'Set as Maximum',  'Callback',   {@gui.minmax_Callback, 1});
            
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
        
        function saveGUI_Callback(gui, ~, ~)
            [FileName,PathName,FilterIndex] = uiputfile({'*.mat', 'Full Data File (*.mat)'; '*.png', 'Current Image (*.png)'; '*.png', 'Current Image With Axes (*.png)'}, 'Save As', gui.data.data.fnameManual);
            
            if all(FileName ~= 0)
                switch FilterIndex
                    case 1  % .mat
                        % This case is covered below (saves in all cases).
                    case 2  % .png
                        if gui.data.data.plotMode == 1      % 1D
                            imwrite(repmat(gui.p(1).YData, 3, 3),   [PathName FileName], 'Alpha', isnan(gui.p(1).YData));
                        else
                            imwrite(repmat(gui.i.CData, 3, 3),      [PathName FileName], 'Alpha', gui.i.AlphaData);
                        end
                    case 3  % .png (axes)
                        imwrite(frame2im(getframe(gui.df)), [PathName FileName]);
                end
                
                pause(.05);                         % Pause to give time for the file to save.
                
                data = gui.data.data;               % Always save the .mat file, even if the user doen't want to... (change?)
                save([PathName FileName], 'data');
            else
                disp('No file given...');
            end
        end
        function loadGUI_Callback(gui, ~, ~)
            
        end
        function closeRequestFcnDF(gui, ~, ~)
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
        function closeRequestFcnCF(gui, ~, ~)
            toggleCF_Callback(gui, ~, ~)
        end
        function toggleCF_Callback(gui, ~, ~)
            
        end
        
        function scanButton_Callback(gui, ~, ~)
            switch gui.data.data.scanMode   % -1 = paused, 0 = new, 1 = scanning, 2 = finished
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
        
        % Right-click menu callbacks
        function gotoPostion_Callback(gui, ~, ~, isSel)
            if gui.data.data.plotMode == 1
                axisX = gui.data.data.axes{gui.data.data.layer == 1};
                
                if isSel        % If the user wants to go to the selected position
                    axisX.goto(gui.posL.sel.XData(1));
                else            % If the user wants to go to the selected pixel
                    axisX.goto(gui.posL.pix.XData(1));
                end
            elseif gui.data.data.plotMode == 2
                axisX = gui.data.data.axes{gui.data.data.layer == 1};
                axisY = gui.data.data.axes{gui.data.data.layer == 2};
                
                
                if isSel        % If the user wants to go to the selected position
                    axisX.goto(gui.pos.sel.XData(1));
                    axisY.goto(gui.pos.sel.YData(1));
                else            % If the user wants to go to the selected pixel
                    axisX.goto(gui.pos.pix.XData(1));
                    axisY.goto(gui.pos.pix.YData(1));
                end
            end
        end
        function minmax_Callback(gui, ~, ~, isMax)
            gui.scale.gray.gui.normAuto.Value = 0;
            if isMax
                gui.scale.gray.gui.maxEdit.String = gui.selData(1);
                gui.scale.gray.edit_Callback(gui.scale.gray.gui.maxEdit, 0);
            else
                gui.scale.gray.gui.minEdit.String = gui.selData(1);
                gui.scale.gray.edit_Callback(gui.scale.gray.gui.minEdit, 0);
            end
        end
        function openCounter_Callback(gui, ~, ~)
            mcDataViewer(mcData('counter'), false);
        end
        function openCounterAtPoint_Callback(gui, ~, ~, isSel)
            gui.gotoPostion_Callback(0, 0, isSel);
            gui.openCounter_Callback(0, 0);
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
%             gui.posL.prv.Visible =   pvis;
            
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
            gui.a.Title.String = gui.data.data.name;
            
            switch gui.data.data.plotMode
                case 1
%                     gui.data.data.layer == 1
%                     disp('here1');
                    gui.p(1).XData = gui.data.data.scans{gui.data.data.layer == 1};
                    gui.p(2).XData = gui.data.data.scans{gui.data.data.layer == 1};
                    gui.p(3).XData = gui.data.data.scans{gui.data.data.layer == 1};
                    gui.a.XLim = [min(gui.p(1).XData) max(gui.p(1).XData)];         % Check to see if range is zero!
                    gui.a.XLabel.String = gui.data.data.axes{gui.data.data.layer == 1}.nameUnits();
                    gui.a.YLabel.String = gui.data.data.inputs{gui.data.data.input}.nameUnits();
%                     disp('there1');
                case 2
                    gui.i.XData = gui.data.data.scans{gui.data.data.layer == 1};
                    gui.i.YData = gui.data.data.scans{gui.data.data.layer == 2};
%                     [min(gui.i.XData) max(gui.i.XData)]
                    gui.a.XLim = [min(gui.i.XData) max(gui.i.XData)];         % Check to see if range is zero!
                    gui.a.YLim = [min(gui.i.YData) max(gui.i.YData)];         % Check to see if range is zero!
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
                        gui.a.DataAspectRatioMode = 'auto';
                        data = gui.r.data
                        gui.p(1).YData = gui.r.data;
                        gui.scale.gray.dataChanged_Callback(0,0);
                    end
                case 2
                    if gui.isRGB
                    else
                        gui.a.DataAspectRatioMode = 'manual';
                        gui.a.DataAspectRatio = [1 1 1];
%                         data = gui.r.data
                        gui.i.CData =       gui.r.data;
                        gui.i.AlphaData =   ~isnan(gui.r.data);
                        gui.scale.gray.dataChanged_Callback(0,0);
                    end
            end
        end

        function figureClickCallback(gui, ~, event)
            if event.Button == 3
                x = event.IntersectionPoint(1);
                y = event.IntersectionPoint(2);
                
                switch gui.data.data.plotMode
                    case 1
                        xlist = (gui.p(1).XData - x) .* (gui.p(1).XData - x);
                        xi = find(xlist == min(xlist), 1);
                        xp = gui.p(1).XData(xi);
%                         xprv = gui.data.data.axisPrev(gui.data.data.layer == 1);
                        
%                         gui.posL
%                         gui.posL.sel
%                         gui.posL.sel.Visible
                        
                        axisX = gui.data.data.axes{gui.data.data.layer == 1};
                        
                        gui.posL.sel.XData = [x x];
                        gui.posL.pix.XData = [xp xp];
%                         gui.posL.prv.XData = [xprv xprv];
                        
%                         gui.posL.sel.YData = [-100 100];
%                         gui.posL.pix.XData = [-100 100];

                        valr = gui.p(1).YData(xi);
                        
                        gui.selData(1) = valr;

                        if isnan(valr)
                            gui.menus.ctsMenu.Label = 'Value: ----- cts/sec';
                        else
%                             gui.data.data.inputs{gui.paramsGray.choose.Value}.extUnits
                            gui.menus.ctsMenu.Label = ['Value: ' num2str(valr, 4) ' ' gui.data.data.inputs{gui.paramsGray.choose.Value}.config.kind.extUnits];
                        end
                        
                        gui.menus.posMenu.Label = ['Position: ' num2str(x, 4)  ' ' axisX.config.kind.extUnits];
                        gui.menus.pixMenu.Label = ['Pixel: '    num2str(xp, 4) ' ' axisX.config.kind.extUnits];
                    case 2
                        xlist = (gui.i.XData - x) .* (gui.i.XData - x);
                        ylist = (gui.i.YData - y) .* (gui.i.YData - y);
                        xi = find(xlist == min(xlist), 1);
                        yi = find(ylist == min(ylist), 1);
                        xp = gui.i.XData(xi);
                        yp = gui.i.YData(yi);
                        
%                         prev = gui.data.data.axisPrev
                        
                        gui.pos.sel.XData = x;
                        gui.pos.sel.YData = y;
                        gui.pos.pix.XData = xp;
                        gui.pos.pix.YData = yp;
%                         gui.pos.prv.XData = gui.data.data.axisPrev(gui.data.data.layer == 1);
%                         gui.pos.prv.YData = gui.data.data.axisPrev(gui.data.data.layer == 2);
                        
                        axisX = gui.data.data.axes{gui.data.data.layer == 1};
                        axisY = gui.data.data.axes{gui.data.data.layer == 2};

                        val = gui.i.CData(yi, xi);
                        
                        gui.selData(1) = val;

                        if isnan(val)
                            gui.menus.ctsMenu.Label = 'Value: ----- cts/sec';
                        else
                            gui.menus.ctsMenu.Label = ['Value: ' num2str(val, 4) ' ' gui.data.data.inputs{gui.paramsGray.choose.Value}.config.kind.extUnits];
                        end
                        
                        gui.menus.posMenu.Label = ['Position: [ ' num2str(x, 4)  ' ' axisX.config.kind.extUnits ', ' num2str(y, 4)  ' ' axisY.config.kind.extUnits ' ]'];
                        gui.menus.pixMenu.Label = ['Pixel: [ '    num2str(xp, 4) ' ' axisX.config.kind.extUnits ', ' num2str(yp, 4) ' ' axisY.config.kind.extUnits ' ]'];
                end
            end
        end
        
        % Functions to update the current position of the axes
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
                
%                 xprv = gui.data.data.axisPrev(gui.data.data.layer == 1);
                
                x = gui.data.data.axisPrev(gui.data.data.layer == 1);
                if x ~= gui.pos.prv.XData
                    gui.posL.prv.XData = [x x];
                    gui.pos.prv.XData = x;
                end

                if gui.data.data.plotMode == 2
                    axisY = gui.data.data.axes{gui.data.data.layer == 2};
%                     by = axisY.name()

                    gui.pos.act.YData = axisY.getX();
                
                    y = gui.data.data.axisPrev(gui.data.data.layer == 2);
                    if y ~= gui.pos.prv.YData
                        gui.pos.prv.YData = y;
                    end
                end
                
            end
        end
        
        function updateLayer_Callback(gui, src, ~)
            layerPrev = gui.data.data.layer;
            
            switch gui.data.data.plotMode   % Make this reference a list instead of a switch
                case 1
                    layer = cellfun(@(x)(x.Value), gui.params1D.chooseList);
%                     disp(layer);
                    
                    if sum(layer == 1) == 0     % If X->num, switch back to X (we need at least one X).
                        changed = cellfun(@(x)(x == src), gui.params1D.chooseList);
                        
                        layer(changed) = 1;
                    end
                    
                    if sum(layer == 1) > 1      % If num->X, swich the previous X to the first num.
                        changed = cellfun(@(x)(x == src), gui.params1D.chooseList);
                        
                        layer(layer == 1 & ~changed) = 2;
                    end
                    
                    for ii = 1:length(layer)
%                         if layer(ii) ~= layerPrev(ii) || changed(ii)
                        gui.params1D.chooseList{ii}.Value = layer(ii);
%                         end
                    end
                case 2
                    layer = cellfun(@(x)(x.Value), gui.params2D.chooseList);
%                     disp(layer);
                    changed = cellfun(@(x)(x == src), gui.params2D.chooseList);
                    
                    if sum(layer == 1) == 0 && sum(layer == 2) == 2 && layer(changed) == 2      % If X->Y, switch Y->X.
                        layer(layer == 2 & ~changed) = 1;
                    end
                    if sum(layer == 1) == 2 && sum(layer == 2) == 0 && layer(changed) == 1      % If Y->X, switch X->Y.
                        layer(layer == 1 & ~changed) = 2;
                    end
                    
                    if sum(layer == 1) == 0     % If X->num, switch back to X.
                        layer(changed) = 1;
                    end
                    if sum(layer == 2) == 0     % If Y->num, switch back to Y.
                        layer(changed) = 2;
                    end
                    if sum(layer == 1) > 1      % If num->X, switch X to first num
                        layer(layer == 1 & ~changed) = 3;
                    end
                    if sum(layer == 2) > 1      % If num->Y, switch Y to first num
                        layer(layer == 2 & ~changed) = 3;
                    end
                    
                    if gui.data.data.layerIndex(changed) && gui.data.data.layer(changed) < 3    % If an input axis was changed to X or Y,
                        % If the other axis (Y or X) is an input axis from a different input...
                        otherAxis = ~changed & layer < 3;
                        
                        if ~all(otherAxis)
                            % Next check if the changed input axis is compatible with 2D
                            if layerIndex(1) == 0
                                layer(1) = layer(otherAxis);
                                layer(otherAxis) = 3;
                            elseif sum(layerIndex == layerIndex(changed)) > 1
                                layer(find(layerIndex == layerIndex(changed) & ~changed, 1)) = layer(otherAxis);
                                layer(otherAxis) = 3;
                            else
                                error('2D incompatible with this layer input. Fix not implemented.');
                            end
                        end
                    end
                    
                    for ii = 1:length(layer)
                        if layer(ii) ~= layerPrev(ii) || changed(ii)
                            gui.params2D.chooseList{ii}.Value = layer(ii);
                        end
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
            
            gui.updateLayer_Callback(0, 0);
            gui.makeProperVisibility();
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

function drawSquarePatch(p, x1, y1, x2, y2)
    p.XData = [x1 x1 x2 x2];
    p.YData = [y1 y2 y2 y1];
end

function copyLabelToClipboard(src, ~)
    split = strsplit(src.Label, ': ');
    clipboard('copy', split{end});
end





