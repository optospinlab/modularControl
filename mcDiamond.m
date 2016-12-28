classdef mcDiamond
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
        function dc = mcDiamond()
            dc.video = mcVideo();
            dc.input = mcUserInput(mcUserInput.diamondConfig());
%             mcAxisListener();
            
            mcaManual(mcaManual.polarizationConfig());
            
            configCounter = mciDAQ.counterConfig(); configCounter.name = 'Counter'; configCounter.chn = 'ctr2';
            dc.counter = mciDAQ(configCounter);
            
            dc.spectrum = mciSpectrum();
            
            dc.f = mcInstrumentHandler.createFigure(dc, 'saveopen');
            dc.f.Resize =      'off';
            dc.f.Position = [100, 100, dc.pw, dc.ph];
            
            bh = 20;
            ii = 1.5;

            % GALVO SCAN
            uicontrol(                  'Parent', dc.f,...
                                        'Style', 'text',... 
                                        'String', 'Galvos: ',... 
                                        'HorizontalAlignment', 'left',...
                                        'Position', [dc.pw/6, dc.ph - ii*bh, dc.pw/3, bh]);     ii = ii + 1;
            uicontrol(                  'Parent', dc.f,...
                                        'Style', 'text',... 
                                        'String', ['Range (' dc.input.config.axesGroups{3}{2}.config.kind.extUnits '): '],... 
                                        'HorizontalAlignment', 'right',...
                                        'Position', [dc.pw/6, dc.ph - ii*bh, dc.pw/3, bh]);
            dc.gscan.range = uicontrol(  'Parent', dc.f,...
                                        'Style', 'edit',... 
                                        'String', abs(diff(dc.input.config.axesGroups{3}{2}.config.kind.extRange)),...        % MAKE THESE VARS LOAD FROM .mat CONFIG!
                                        'Position', [dc.pw/2, dc.ph - ii*bh, dc.pw/3, bh]);     ii = ii + 1;
                                    
            uicontrol(                  'Parent', dc.f,...  
                                        'Style', 'text',... 
                                        'String', 'Range (pixels): ',... 
                                        'HorizontalAlignment', 'right',...
                                        'Position', [dc.pw/6, dc.ph - ii*bh, dc.pw/3, bh]);
            dc.gscan.pixels = uicontrol('Parent', dc.f,...
                                        'Style', 'edit',... 
                                        'String', 50,...
                                        'Position', [dc.pw/2, dc.ph - ii*bh, dc.pw/3, bh]);     ii = ii + 1;
                                    
            uicontrol(                  'Parent', dc.f,...  
                                        'Style', 'text',... 
                                        'String', ['Speed (' dc.input.config.axesGroups{3}{2}.config.kind.extUnits '/s): '],... 
                                        'HorizontalAlignment', 'right',...
                                        'Position', [dc.pw/6, dc.ph - ii*bh, dc.pw/3, bh]);
            dc.gscan.speed = uicontrol( 'Parent', dc.f,...
                                        'Style', 'edit',... 
                                        'String', abs(diff(dc.input.config.axesGroups{3}{2}.config.kind.extRange)),...
                                        'Position', [dc.pw/2, dc.ph - ii*bh, dc.pw/3, bh]);     ii = ii + 1.25;
                    
            uicontrol(  'Parent', dc.f,...  
                        'Style', 'push',... 
                        'String', 'Galvo Scan',... 
                        'Position', [dc.pw/6, dc.ph - ii*bh, 2*dc.pw/3, bh],... 
                        'Callback', @dc.galvoScan_Callback);                      ii = ii + 2;

            % SCAN
            uicontrol(                  'Parent', dc.f,...
                                        'Style', 'text',... 
                                        'String', 'Piezos: ',... 
                                        'HorizontalAlignment', 'left',...
                                        'Position', [dc.pw/6, dc.ph - ii*bh, dc.pw/3, bh]);     ii = ii + 1;
            uicontrol(                  'Parent', dc.f,...
                                        'Style', 'text',... 
                                        'String', ['Range (' dc.input.config.axesGroups{2}{2}.config.kind.extUnits '): '],... 
                                        'HorizontalAlignment', 'right',...
                                        'Position', [dc.pw/6, dc.ph - ii*bh, dc.pw/3, bh]);
            dc.scan.range = uicontrol(   'Parent', dc.f,...
                                        'Style', 'edit',... 
                                        'String', abs(diff(dc.input.config.axesGroups{2}{2}.config.kind.extRange)),...        % MAKE THESE VARS LOAD FROM .mat CONFIG!
                                        'Position', [dc.pw/2, dc.ph - ii*bh, dc.pw/3, bh]);     ii = ii + 1;
                                    
            uicontrol(                  'Parent', dc.f,...  
                                        'Style', 'text',... 
                                        'String', 'Range (pixels): ',... 
                                        'HorizontalAlignment', 'right',...
                                        'Position', [dc.pw/6, dc.ph - ii*bh, dc.pw/3, bh]);
            dc.scan.pixels = uicontrol( 'Parent', dc.f,...
                                        'Style', 'edit',... 
                                        'String', 50,...
                                        'Position', [dc.pw/2, dc.ph - ii*bh, dc.pw/3, bh]);     ii = ii + 1;
                                    
            uicontrol(                  'Parent', dc.f,...  
                                        'Style', 'text',... 
                                        'String', ['Speed (' dc.input.config.axesGroups{2}{2}.config.kind.extUnits '/s): '],... 
                                        'HorizontalAlignment', 'right',...
                                        'Position', [dc.pw/6, dc.ph - ii*bh, dc.pw/3, bh]);
            dc.scan.speed = uicontrol(  'Parent', dc.f,...
                                        'Style', 'edit',... 
                                        'String', abs(diff(dc.input.config.axesGroups{2}{2}.config.kind.extRange)),...
                                        'Position', [dc.pw/2, dc.ph - ii*bh, dc.pw/3, bh]);     ii = ii + 1.25;
                    
            uicontrol(  'Parent', dc.f,...  
                        'Style', 'push',... 
                        'String', 'Piezo Scan',... 
                        'Position', [dc.pw/6, dc.ph - ii*bh, 2*dc.pw/3, bh],... 
                        'Callback', @dc.piezoScan_Callback);                      ii = ii + 2;

            % OPTIMIZE
            uicontrol(                  'Parent', dc.f,...
                                        'Style', 'text',... 
                                        'String', ['Range XY (' dc.input.config.axesGroups{2}{2}.config.kind.extUnits '): '],... 
                                        'HorizontalAlignment', 'right',...
                                        'Position', [dc.pw/6, dc.ph - ii*bh, dc.pw/3, bh]);
            dc.opt.range = uicontrol(   'Parent', dc.f,...
                                        'Style', 'edit',... 
                                        'String', 10,...        % MAKE THESE VARS LOAD FROM .mat CONFIG!
                                        'Position', [dc.pw/2, dc.ph - ii*bh, dc.pw/3, bh]);     ii = ii + 1;
                                    
            uicontrol(                  'Parent', dc.f,...  
                                        'Style', 'text',... 
                                        'String', ['Range Z (' dc.input.config.axesGroups{2}{4}.config.kind.extUnits '): '],... 
                                        'HorizontalAlignment', 'right',...
                                        'Position', [dc.pw/6, dc.ph - ii*bh, dc.pw/3, bh]);
            dc.opt.rangeZ = uicontrol(   'Parent', dc.f,...
                                        'Style', 'edit',... 
                                        'String', 10,...        % MAKE THESE VARS LOAD FROM .mat CONFIG!
                                        'Position', [dc.pw/2, dc.ph - ii*bh, dc.pw/3, bh]);     ii = ii + 1;
                                    
            uicontrol(                  'Parent', dc.f,...  
                                        'Style', 'text',... 
                                        'String', 'Length (pixels): ',... 
                                        'HorizontalAlignment', 'right',...
                                        'Position', [dc.pw/6, dc.ph - ii*bh, dc.pw/3, bh]);
            dc.opt.pixels = uicontrol(  'Parent', dc.f,...
                                        'Style', 'edit',... 
                                        'String', 100,...
                                        'Position', [dc.pw/2, dc.ph - ii*bh, dc.pw/3, bh]);     ii = ii + 1;
                                    
            uicontrol(                  'Parent', dc.f,...  
                                        'Style', 'text',... 
                                        'String', 'Time/scan (s): ',... 
                                        'HorizontalAlignment', 'right',...
                                        'Position', [dc.pw/6, dc.ph - ii*bh, dc.pw/3, bh]);
            dc.opt.seconds = uicontrol( 'Parent', dc.f,...
                                        'Style', 'edit',... 
                                        'String', 1,...
                                        'Position', [dc.pw/2, dc.ph - ii*bh, dc.pw/3, bh]);     ii = ii + 1.25;
                    
            uicontrol(  'Parent', dc.f,...  
                        'Style', 'push',... 
                        'String', 'Optimize X',... 
                        'Position', [dc.pw/6, dc.ph - ii*bh, 2*dc.pw/3, bh],... 
                        'Callback', @(e,h)(dc.optimizeX_Callback));             ii = ii + 1;
                    
            uicontrol(  'Parent', dc.f,...  
                        'Style', 'push',... 
                        'String', 'Optimize Y',... 
                        'Position', [dc.pw/6, dc.ph - ii*bh, 2*dc.pw/3, bh],... 
                        'Callback', @(e,h)(dc.optimizeY_Callback));             ii = ii + 1;
                    
            uicontrol(  'Parent', dc.f,...  
                        'Style', 'push',... 
                        'String', 'Optimize Z',... 
                        'Position', [dc.pw/6, dc.ph - ii*bh, 2*dc.pw/3, bh],... 
                        'Callback', @dc.optimizeZ_Callback);             ii = ii + 2;
                    
            uicontrol(  'Parent', dc.f,...  
                        'Style', 'push',... 
                        'String', 'Spectrum',... 
                        'Position', [dc.pw/6, dc.ph - ii*bh, 2*dc.pw/3, bh],... 
                        'Callback', @dc.spectrum_Callback);             ii = ii + 2;
                    
%             uicontrol(  'Parent', dc.f,...  
%                         'Style', 'push',... 
%                         'String', 'Y High Voltage Spectra Scan',... 
%                         'Position', [dc.pw/6, dc.ph - ii*bh, 2*dc.pw/3, bh],... 
%                         'Callback', @dc.YVoltageSpectra);               ii = ii + 2;
        end
        
        function galvoScan_Callback(dc,~,~)
            dc.input.config.axesGroups{3}{2}
            dc.input.config.axesGroups{3}{3}
            data = mcData(mcData.squareScanConfiguration(   dc.input.config.axesGroups{3}{2},...
                                                            dc.input.config.axesGroups{3}{3},...
                                                            dc.counter,...
                                                            str2double(dc.gscan.range.String),...
                                                            str2double(dc.gscan.speed.String),...
                                                            str2double(dc.gscan.pixels.String)));
            mcDataViewer(data, false);  % Open mcDataViewer to view this data, but do not open the control figure
        end
        
        
        function piezoScan_Callback(dc,~,~)
            data = mcData(mcData.squareScanConfiguration(   dc.input.config.axesGroups{2}{2},...
                                                            dc.input.config.axesGroups{2}{3},...
                                                            dc.counter,...
                                                            str2double(dc.scan.range.String),...
                                                            str2double(dc.scan.speed.String),...
                                                            str2double(dc.scan.pixels.String)));
            mcDataViewer(data, false);  % Open mcDataViewer to view this data, but do not open the control figure
        end
        
        function optimizeX_Callback(dc,~,~)
            data = mcData(mcData.optimizeConfiguration( dc.input.config.axesGroups{2}{2},...
                                                        dc.counter,...
                                                        str2double(dc.opt.range.String),...
                                                        str2double(dc.opt.pixels.String),...
                                                        str2double(dc.opt.seconds.String)));
            mcDataViewer(data, false);  % Open mcDataViewer to view this data, but do not open the control figure
        end
        function optimizeY_Callback(dc,~,~)
            data = mcData(mcData.optimizeConfiguration( dc.input.config.axesGroups{2}{3},...
                                                        dc.counter,...
                                                        str2double(dc.opt.range.String),...
                                                        str2double(dc.opt.pixels.String),...
                                                        str2double(dc.opt.seconds.String)));
            mcDataViewer(data, false);  % Open mcDataViewer to view this data, but do not open the control figure
        end
        function optimizeZ_Callback(dc,~,~)
            data = mcData(mcData.optimizeConfiguration( dc.input.config.axesGroups{2}{4},...
                                                        dc.counter,...
                                                        str2double(dc.opt.rangeZ.String),...
                                                        str2double(dc.opt.pixels.String),...
                                                        str2double(dc.opt.seconds.String)));
            mcDataViewer(data, false);  % Open mcDataViewer to view this data, but do not open the control figure
        end
        
        function spectrum_Callback(~,~,~)
            data = mcData(mcData.singleSpectrumConfiguration());
            mcDataViewer(data, false);  % Open mcDataViewer to view this data, but do not open the control figure
        end
        
        function YVoltageSpectra(dc,~,~)
            laser = mcaDAQ(mcaDAQ.greenConfig); % Turn the laser on.
            laser.goto(1)
            
            configHV = mcaDAQ.PIE616Config();
            configHV.chn = 'ao0';
            v0 = mcaDAQ(configHV);
            
            configHV.chn = 'ao1';
            v1 = mcaDAQ(configHV);
            
            spec = mciSpectrum();
            
            V = -100:10:100;
            
            data = NaN(512, length(V));
            ii = 1;
            
            f = figure;
            a = axes(f);
            hold on
            
            for v = V
                if isvalid(f)
                    disp(v)

                    if v < 0
                        v0.goto(-v);
                        v1.goto(0);
                    else
                        v0.goto(0);
                        v1.goto(v);
                    end

                    pause(1);

                    data(:, ii) = spec.measure(120);
                    plot(a, data(:, ii));

                    ii = ii + 1;
                end
            end
            
            hold off
            
            save('C:\Users\Tomasz\Desktop\Stark\StarkData.mat', 'data');
        end
        
        
%         function galvoScan_Callback(dc,~,~)
%             
%         end
    end
end




