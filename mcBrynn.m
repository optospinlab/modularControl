classdef mcBrynn
% mcDiamond is a class specifically for the diamond room. It starts up certain essential features and provides a GUI with useful
%   functions.
    
    properties
        pw = 300;
        ph = 500;
        
        f = [];
        input = [];
        video = [];
        counter = [];
        spectrum= [];
        
        opt = [];
        scan = [];
        gscan = [];
    end
    
    methods
        function gui = mcBrynn()
            % Open some GUIs:
            gui.video = mcVideo(mcVideo.brynnConfig());
            gui.input = mcUserInput(mcUserInput.diamonguionfig());
            gui.input.openListener();        
            gui.input.openWaypoints();
            
            % Additionally, open these instruments:
            mcaManual(mcaManual.polarizationConfig());
            
            configCounter = mciDAQ.counterConfig(); configCounter.name = 'Counter'; configCounter.chn = 'ctr0';
            gui.counter = mciDAQ(configCounter);
            
            gui.spectrum = mciSpectrum();
            
            % Next, make the figure:
            gui.f = mcInstrumentHandler.createFigure(gui, 'saveopen');
            gui.f.Resize =      'off';
            gui.f.Position = [100, 100, gui.pw, gui.ph];
            
            bh = 20;
            ii = 1.5;

            % GALVO SCAN
            uicontrol(                  'Parent', gui.f,...
                                        'Style', 'text',... 
                                        'String', 'Galvos: ',... 
                                        'HorizontalAlignment', 'left',...
                                        'Position', [gui.pw/6, gui.ph - ii*bh, gui.pw/3, bh]);     ii = ii + 1;
            uicontrol(                  'Parent', gui.f,...
                                        'Style', 'text',... 
                                        'String', ['Range (' gui.input.config.axesGroups{3}{2}.config.kind.extUnits '): '],... 
                                        'HorizontalAlignment', 'right',...
                                        'Position', [gui.pw/6, gui.ph - ii*bh, gui.pw/3, bh]);
            gui.gscan.range = uicontrol(  'Parent', gui.f,...
                                        'Style', 'edit',... 
                                        'String', abs(diff(gui.input.config.axesGroups{3}{2}.config.kind.extRange)),...        % MAKE THESE VARS LOAD FROM .mat CONFIG!
                                        'Position', [gui.pw/2, gui.ph - ii*bh, gui.pw/3, bh]);     ii = ii + 1;
                                    
            uicontrol(                  'Parent', gui.f,...  
                                        'Style', 'text',... 
                                        'String', 'Range (pixels): ',... 
                                        'HorizontalAlignment', 'right',...
                                        'Position', [gui.pw/6, gui.ph - ii*bh, gui.pw/3, bh]);
            gui.gscan.pixels = uicontrol('Parent', gui.f,...
                                        'Style', 'edit',... 
                                        'String', 50,...
                                        'Position', [gui.pw/2, gui.ph - ii*bh, gui.pw/3, bh]);     ii = ii + 1;
                                    
            uicontrol(                  'Parent', gui.f,...  
                                        'Style', 'text',... 
                                        'String', ['Speed (' gui.input.config.axesGroups{3}{2}.config.kind.extUnits '/s): '],... 
                                        'HorizontalAlignment', 'right',...
                                        'Position', [gui.pw/6, gui.ph - ii*bh, gui.pw/3, bh]);
            gui.gscan.speed = uicontrol( 'Parent', gui.f,...
                                        'Style', 'edit',... 
                                        'String', abs(diff(gui.input.config.axesGroups{3}{2}.config.kind.extRange)),...
                                        'Position', [gui.pw/2, gui.ph - ii*bh, gui.pw/3, bh]);     ii = ii + 1.25;
                    
            uicontrol(  'Parent', gui.f,...  
                        'Style', 'push',... 
                        'String', 'Galvo Scan',... 
                        'Position', [gui.pw/6, gui.ph - ii*bh, 2*gui.pw/3, bh],... 
                        'Callback', @gui.galvoScan_Callback);                      ii = ii + 2;

            % SCAN
            uicontrol(                  'Parent', gui.f,...
                                        'Style', 'text',... 
                                        'String', 'Piezos: ',... 
                                        'HorizontalAlignment', 'left',...
                                        'Position', [gui.pw/6, gui.ph - ii*bh, gui.pw/3, bh]);     ii = ii + 1;
            uicontrol(                  'Parent', gui.f,...
                                        'Style', 'text',... 
                                        'String', ['Range (' gui.input.config.axesGroups{2}{2}.config.kind.extUnits '): '],... 
                                        'HorizontalAlignment', 'right',...
                                        'Position', [gui.pw/6, gui.ph - ii*bh, gui.pw/3, bh]);
            gui.scan.range = uicontrol(   'Parent', gui.f,...
                                        'Style', 'edit',... 
                                        'String', abs(diff(gui.input.config.axesGroups{2}{2}.config.kind.extRange)),...        % MAKE THESE VARS LOAD FROM .mat CONFIG!
                                        'Position', [gui.pw/2, gui.ph - ii*bh, gui.pw/3, bh]);     ii = ii + 1;
                                    
            uicontrol(                  'Parent', gui.f,...  
                                        'Style', 'text',... 
                                        'String', 'Range (pixels): ',... 
                                        'HorizontalAlignment', 'right',...
                                        'Position', [gui.pw/6, gui.ph - ii*bh, gui.pw/3, bh]);
            gui.scan.pixels = uicontrol( 'Parent', gui.f,...
                                        'Style', 'edit',... 
                                        'String', 50,...
                                        'Position', [gui.pw/2, gui.ph - ii*bh, gui.pw/3, bh]);     ii = ii + 1;
                                    
            uicontrol(                  'Parent', gui.f,...  
                                        'Style', 'text',... 
                                        'String', ['Speed (' gui.input.config.axesGroups{2}{2}.config.kind.extUnits '/s): '],... 
                                        'HorizontalAlignment', 'right',...
                                        'Position', [gui.pw/6, gui.ph - ii*bh, gui.pw/3, bh]);
            gui.scan.speed = uicontrol(  'Parent', gui.f,...
                                        'Style', 'edit',... 
                                        'String', abs(diff(gui.input.config.axesGroups{2}{2}.config.kind.extRange)),...
                                        'Position', [gui.pw/2, gui.ph - ii*bh, gui.pw/3, bh]);     ii = ii + 1.25;
                    
            uicontrol(  'Parent', gui.f,...  
                        'Style', 'push',... 
                        'String', 'Piezo Scan',... 
                        'Position', [gui.pw/6, gui.ph - ii*bh, 2*gui.pw/3, bh],... 
                        'Callback', @gui.piezoScan_Callback);                      ii = ii + 2;

            % OPTIMIZE
            uicontrol(                  'Parent', gui.f,...
                                        'Style', 'text',... 
                                        'String', ['Range XY (' gui.input.config.axesGroups{2}{2}.config.kind.extUnits '): '],... 
                                        'HorizontalAlignment', 'right',...
                                        'Position', [gui.pw/6, gui.ph - ii*bh, gui.pw/3, bh]);
            gui.opt.range = uicontrol(   'Parent', gui.f,...
                                        'Style', 'edit',... 
                                        'String', 10,...        % MAKE THESE VARS LOAD FROM .mat CONFIG!
                                        'Position', [gui.pw/2, gui.ph - ii*bh, gui.pw/3, bh]);     ii = ii + 1;
                                    
            uicontrol(                  'Parent', gui.f,...  
                                        'Style', 'text',... 
                                        'String', ['Range Z (' gui.input.config.axesGroups{2}{4}.config.kind.extUnits '): '],... 
                                        'HorizontalAlignment', 'right',...
                                        'Position', [gui.pw/6, gui.ph - ii*bh, gui.pw/3, bh]);
            gui.opt.rangeZ = uicontrol(   'Parent', gui.f,...
                                        'Style', 'edit',... 
                                        'String', 10,...        % MAKE THESE VARS LOAD FROM .mat CONFIG!
                                        'Position', [gui.pw/2, gui.ph - ii*bh, gui.pw/3, bh]);     ii = ii + 1;
                                    
            uicontrol(                  'Parent', gui.f,...  
                                        'Style', 'text',... 
                                        'String', 'Length (pixels): ',... 
                                        'HorizontalAlignment', 'right',...
                                        'Position', [gui.pw/6, gui.ph - ii*bh, gui.pw/3, bh]);
            gui.opt.pixels = uicontrol(  'Parent', gui.f,...
                                        'Style', 'edit',... 
                                        'String', 100,...
                                        'Position', [gui.pw/2, gui.ph - ii*bh, gui.pw/3, bh]);     ii = ii + 1;
                                    
            uicontrol(                  'Parent', gui.f,...  
                                        'Style', 'text',... 
                                        'String', 'Time/scan (s): ',... 
                                        'HorizontalAlignment', 'right',...
                                        'Position', [gui.pw/6, gui.ph - ii*bh, gui.pw/3, bh]);
            gui.opt.seconds = uicontrol( 'Parent', gui.f,...
                                        'Style', 'edit',... 
                                        'String', 1,...
                                        'Position', [gui.pw/2, gui.ph - ii*bh, gui.pw/3, bh]);     ii = ii + 1.25;
                    
            uicontrol(  'Parent', gui.f,...  
                        'Style', 'push',... 
                        'String', 'Optimize X',... 
                        'Position', [gui.pw/6, gui.ph - ii*bh, 2*gui.pw/3, bh],... 
                        'Callback', @(e,h)(gui.optimizeX_Callback));             ii = ii + 1;
                    
            uicontrol(  'Parent', gui.f,...  
                        'Style', 'push',... 
                        'String', 'Optimize Y',... 
                        'Position', [gui.pw/6, gui.ph - ii*bh, 2*gui.pw/3, bh],... 
                        'Callback', @(e,h)(gui.optimizeY_Callback));             ii = ii + 1;
                    
            uicontrol(  'Parent', gui.f,...  
                        'Style', 'push',... 
                        'String', 'Optimize Z',... 
                        'Position', [gui.pw/6, gui.ph - ii*bh, 2*gui.pw/3, bh],... 
                        'Callback', @gui.optimizeZ_Callback);             ii = ii + 2;
                    
            uicontrol(  'Parent', gui.f,...  
                        'Style', 'push',... 
                        'String', 'Spectrum',... 
                        'Position', [gui.pw/6, gui.ph - ii*bh, 2*gui.pw/3, bh],... 
                        'Callback', @gui.spectrum_Callback);             ii = ii + 2;
                    
%             uicontrol(  'Parent', gui.f,...  
%                         'Style', 'push',... 
%                         'String', 'Y High Voltage Spectra Scan',... 
%                         'Position', [gui.pw/6, gui.ph - ii*bh, 2*gui.pw/3, bh],... 
%                         'Callback', @gui.YVoltageSpectra);               ii = ii + 2;
        end
        
        function galvoScan_Callback(gui,~,~)
            data = mcData(mcData.squareScanConfiguration(   gui.input.config.axesGroups{2}{2},...
                                                            gui.input.config.axesGroups{2}{3},...
                                                            gui.counter,...
                                                            str2double(gui.gscan.range.String),...
                                                            str2double(gui.gscan.speed.String),...
                                                            str2double(gui.gscan.pixels.String)));
            mcDataViewer(data, false);  % Open mcDataViewer to view this data, but do not open the control figure
        end
        
        function optimizeX_Callback(gui,~,~)
            data = mcData(mcData.optimizeConfiguration( gui.input.config.axesGroups{2}{2},...
                                                        gui.counter,...
                                                        str2double(gui.opt.range.String),...
                                                        str2double(gui.opt.pixels.String),...
                                                        str2double(gui.opt.seconds.String)));
            mcDataViewer(data, false);  % Open mcDataViewer to view this data, but do not open the control figure
        end
        function optimizeY_Callback(gui,~,~)
            data = mcData(mcData.optimizeConfiguration( gui.input.config.axesGroups{2}{3},...
                                                        gui.counter,...
                                                        str2double(gui.opt.range.String),...
                                                        str2double(gui.opt.pixels.String),...
                                                        str2double(gui.opt.seconds.String)));
            mcDataViewer(data, false);  % Open mcDataViewer to view this data, but do not open the control figure
        end
        function optimizeZ_Callback(gui,~,~)
            data = mcData(mcData.optimizeConfiguration( gui.input.config.axesGroups{2}{4},...
                                                        gui.counter,...
                                                        str2double(gui.opt.rangeZ.String),...
                                                        str2double(gui.opt.pixels.String),...
                                                        str2double(gui.opt.seconds.String)));
            mcDataViewer(data, false);  % Open mcDataViewer to view this data, but do not open the control figure
        end
    end
end




