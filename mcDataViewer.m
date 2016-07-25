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
                gui.tabs.t3d = uitab('Parent', utg, 'Title', '3D');
                
                gui.tabs.t1d.Units = 'pixels';
                tabpos = gui.tabs.t1d.Position
                
                bh = 20;

                uicontrol('Parent', gui.tabs.t3d, 'Style', 'text', 'String', 'Sometime?', 'HorizontalAlignment', 'center', 'Units', 'normalized', 'Position', [0 0 1 1]);
                
                for ii = 1:gui.data.data.numAxes
                    levellist = strcat(strread(num2str(gui.data.data.scans{ii}), '%s')', [' ' gui.data.data.axes{ii}.config.kind.extUnits]);  % Returns the numbers in scans in '##.## unit' form.
                    
                    for tab = [gui.tabs.t1d gui.tabs.t2d]
                            uicontrol('Parent', tab, 'Style', 'text', 'String', [gui.data.data.axes{ii}.nameShort() ':'], 'Units', 'pixels', 'Position', [0 tabpos(4)-bh*ii-3*bh tabpos(3)/2 bh], 'HorizontalAlignment', 'right');

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
                            
                            uicontrol('Parent', tab, 'Style', 'popupmenu', 'String', [axeslist, levellist], 'Units', 'pixels', 'Position', [tabpos(3)/2 tabpos(4)-bh*ii-3*bh tabpos(3)/2 - 2*bh bh], 'Value', val);
                            
                    end
                end
                
                ltg = uitabgroup('Position', [0, 0, 1, .5]);
                gui.tabs.tgray = uitab('Parent', ltg, 'Title', 'Gray');
                gui.tabs.trgb =  uitab('Parent', ltg, 'Title', 'RGB');
                
            end
            
            gui.df = mcInstrumentHandler.createFigure('Data Viewer (Generic)');
            menu = uicontextmenu;
            gui.menus.ctsMenu = uimenu(menu, 'Label', ' Value: ~~.~~ --');
            gui.menus.pixMenu = uimenu(menu, 'Label', ' Pixel: [ ~~.~~ --, ~~.~~ -- ]');
            gui.menus.posMenu = uimenu(menu, 'Label', ' Position: [ ~~.~~ --, ~~.~~ -- ]');
                mGoto = uimenu(menu, 'Label', 'Goto');
                mgPix = uimenu(mGoto, 'Label', 'Selected Pixel',    'Callback',@d);
                mgPos = uimenu(mGoto, 'Label', 'Selected Position', 'Callback',@b);
                mNorm = uimenu(menu, 'Label', 'Normalization');
                mnMin = uimenu(mNorm, 'Label', 'Set as Minimum', 'Callback',@d);
                mnMax = uimenu(mNorm, 'Label', 'Set as Maximum',  'Callback',@b);

            gui.a = axes('Parent', gui.df, 'DataAspectRatioMode', 'manual', 'BoxStyle', 'full', 'Box', 'on'); %, 'Xgrid', 'on', 'Ygrid', 'on'
            
            hold(gui.a, 'on');
            
            x = 1:50;
            y = 1:50;
            z = rand(1, 50);
            c = mod(magic(5),2); %ones(50);
            
            gui.i = image(gui.a, x, y, c, 'alphadata', c, 'ButtonDownFcn', @figureClickCallback, 'UIContextMenu', menu, 'Visible', 'off');
            gui.pos.sel = scatter(gui.a, 0, 0, 'SizeData', 40, 'CData', [1 0 1], 'PickableParts', 'none', 'Linewidth', 2, 'Marker', 'x', 'Visible', 'off');
            gui.pos.pix = scatter(gui.a, 0, 0, 'SizeData', 40, 'CData', [1 1 0], 'PickableParts', 'none', 'Linewidth', 2, 'Marker', 'x', 'Visible', 'off');
            gui.pos.act = scatter(gui.a, 0, 0, 'SizeData', 40, 'CData', [0 1 1], 'PickableParts', 'none', 'Linewidth', 2, 'Marker', 'o', 'Visible', 'off');
            gui.pos.prv = scatter(gui.a, 0, 0, 'SizeData', 40, 'CData', [0 .5 .5], 'PickableParts', 'none', 'Linewidth', 2, 'Marker', 'o', 'Visible', 'off');
            
            gui.p = plot( gui.a, x, rand(1, 50), x, rand(1, 50), x, rand(1, 50),                'ButtonDownFcn', @figureClickCallback, 'UIContextMenu', menu, 'Visible', 'off');
            gui.p(1).Color = [1 0 0];
            gui.p(2).Color = [0 1 0];
            gui.p(3).Color = [0 0 1];
            
            gui.posL.sel = plot(gui.a, [0 0], [-Inf Inf], 'Color', [1 0 1], 'PickableParts', 'none', 'Linewidth', 1, 'Visible', 'off');
            gui.posL.pix = plot(gui.a, [0 0], [-Inf Inf], 'Color', [1 1 0], 'PickableParts', 'none', 'Linewidth', 2, 'Visible', 'off');
            gui.posL.act = plot(gui.a, [0 0], [-Inf Inf], 'Color', [0 1 1], 'PickableParts', 'none', 'Linewidth', 2, 'Visible', 'off');
            gui.posL.prv = plot(gui.a, [0 0], [-Inf Inf], 'LineStyle', '--', 'Color', [0 .5 .5], 'PickableParts', 'none', 'Linewidth', 2, 'Visible', 'off');
            

            gui.a.YDir = 'normal';
            
%             params.a.XLim = [min(x), max(x)]; 
%             params.a.YLim = [min(y), max(y)];
            
            
            hold(gui.a, 'off');
            
%             edit.UserData = addlistener(axis_{1}, 'x', 'PostSet', @(s,e)(axisChanged_Callback(s, e, edit)));

        end
        
        function plot(gui)
            
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

            params.i = image(params.a, x, y, c, 'alphadata', ~isnan(m), 'ButtonDownFcn', @figureClickCallback, 'UIContextMenu', menu)
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
            global params

            if src == params.i && event.Button == 3
                x = event.IntersectionPoint(1);
                y = event.IntersectionPoint(2);

                xlist = (params.i.XData - x) .* (params.i.XData - x);
                ylist = (params.i.YData - y) .* (params.i.YData - y);

                xi = min(find(xlist == min(xlist)));
                yi = min(find(ylist == min(ylist)));

                params.s.XData = [x params.i.XData(xi)];
                params.s.YData = [y params.i.XData(yi)];

                val = params.i.CData(yi, xi);

                if isnan(val)
                    params.ctsMenu.Label = ' Value: ----- cts/sec';
                else
                    params.ctsMenu.Label = [' Value: ' num2str(val, 4) ' cts/sec'];
                end
                params.posMenu.Label = [' Position: [ ' num2str(x, 4) ' mV, ' num2str(y, 4) ' mV ]'];
                params.pixMenu.Label = [' Pixel: [ ' num2str(params.i.XData(xi), 4) ' mV, ' num2str(params.i.YData(yi), 4) ' mV ]'];
            end
        end
        
        function upperTabSwitch_Callback(gui, src, event)
            switch event.NewValue
                case gui.tabs.t1d
                    newPlotMode = 1;
                case gui.tabs.t2d
                    newPlotMode = 2;
                case gui.tabs.t3d
                    newPlotMode = 3;
            end


            gui.r.params.plotMode = newPlotMode;
            gui.g.params.plotMode = newPlotMode;
            gui.b.params.plotMode = newPlotMode;
        end
        
        function lowerTabSwitch_Callback(gui, src, event)
            
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




