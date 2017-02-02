classdef mcgBrynn < mcGUI
    % Template to explain how to make a custom mcGUI (unfinished).
    
    properties
        objects = []
    end
    
    methods (Static)
        function config = defaultConfig()
            config = mcgBrynn.diamondConfig();
        end
        function config = diamondConfig()
            galvoConfig =   mcaDAQ.galvoXBrynnConfig();
            zConfig =       mcaEO.brynnObjConfig();
            
            %                     Style     String              Variable    TooltipString                                                                       Optional: Limit [min max round] (only for edit)
            config.controls = { { 'title',  'Galvos:  ',        NaN,        'Confocal scanning for the galvo mirrors.' },...
                                { 'edit',   'Range (um): ',     200,        'The range of the scan (in X and Y), centered on the current position. If this scan goes out of bounds, it is shifted to be in bounds.',                                        [0 abs(diff(galvoConfig.kind.int2extConv(galvoConfig.kind.intRange)))]},...
                                { 'edit',   'Pixels (#): ',     50,         'The number of points (in each dimension) which should be sampled over the scan range.',                                                                                        [1 Inf 1]},...
                                { 'edit',   'Speed (um/s): ',   200,        'The speed at which the range should be scanned over. Each scan will take [range/speed] seconds and [range/(speed*pixels)] seconds will be spent at each point of the scan.',   [0 Inf]},...
                                { 'push',   'Galvo Scan',       'galvo',    'Push to active a scan with the above parameters.' },...
                                { 'edit',   'Range XY (um): ',  1,          'The range of the scan (in X or Y), centered on the current position. If this scan goes out of bounds, it is shifted to be in bounds.',                                         [0 abs(diff(galvoConfig.kind.int2extConv(galvoConfig.kind.intRange)))]},...
                                { 'edit',   'Range Z (um): ',   5,          'The range of the scan (in Z), centered on the current position. If this scan goes out of bounds, it is shifted to be in bounds.',                                              [0 abs(diff(zConfig.kind.int2extConv(zConfig.kind.intRange)))]},...
                                { 'edit',   'Pixels (#): ',     50,         'The number of points which should be sampled over the scan range.',                                                                                                            [1 Inf 1]},...
                                { 'edit',   'Time (s): ',       2,          'The speed at which the range should be scanned over. Each scan will take [range/speed] seconds and [range/(speed*pixels)] seconds will be spent at each point of the scan.',   [0 Inf]},...
                                { 'push',   'Optimize X',      'optX',      'Push to active an optimization in the X direction with the above parameters.' },...
                                { 'push',   'Optimize Y',      'optY',      'Push to active an optimization in the Y direction with the above parameters.' },...
                                { 'push',   'Optimize Z',      'optZ',      'Push to active an optimization in the Z direction with the above parameters.' },...
                              };
        end
    end
    
    methods
        function Callbacks(gui, ~, ~, cbName)
            if ~isfield(gui.objects, 'isSetup')
                gui.setupObjects();
            end
            
            switch lower(cbName)
                case 'galvo'
                    data = mcData(mcData.squareScanConfiguration(   gui.objects.galvos(1),...
                                                                    gui.objects.galvos(2),...
                                                                    gui.objects.counter,...
                                                                    gui.controls{1}.Value,...
                                                                    gui.controls{3}.Value,...
                                                                    gui.controls{2}.Value));
                                                                
                    mcDataViewer(data, false);  % Open mcDataViewer to view this data, but do not open the control figure
                case 'optx'
                    data = mcData(mcData.optimizeConfiguration( gui.objects.galvos(1),...
                                                                gui.objects.counter,...
                                                                gui.controls{4}.Value,...
                                                                gui.controls{6}.Value,...
                                                                gui.controls{7}.Value));
                    mcDataViewer(data, false);  % Open mcDataViewer to view this data, but do not open the control figure
                case 'opty'
                    data = mcData(mcData.optimizeConfiguration( gui.objects.galvos(2),...
                                                                gui.objects.counter,...
                                                                gui.controls{4}.Value,...
                                                                gui.controls{6}.Value,...
                                                                gui.controls{7}.Value));
                    mcDataViewer(data, false);  % Open mcDataViewer to view this data, but do not open the control figure
                case 'optz'
                    data = mcData(mcData.optimizeConfiguration( gui.objects.piezo,...
                                                                gui.objects.counter,...
                                                                gui.controls{5}.Value,...
                                                                gui.controls{6}.Value,...
                                                                gui.controls{7}.Value));
                    mcDataViewer(data, false);  % Open mcDataViewer to view this data, but do not open the control figure
                case 'spec'
                    data = mcData(mcData.singleSpectrumConfiguration());
                    mcDataViewer(data, false);  % Open mcDataViewer to view this data, but do not open the control figure
                otherwise
                    if ischar(cbName)
                        disp([class(gui) '.Callbacks(s, e, cbName): No callback of name ' cbName '.']);
                    else
                        disp([class(gui) '.Callbacks(s, e, cbName): Did not understand cbName; not a string.']);
                    end
            end
        end
    end
    
    methods
        function setupObjects(gui)
            gui.objects.isSetup =   true;
            
            configGalvoX =          mcaDAQ.galvoXBrynnConfig();
            configGalvoY =          mcaDAQ.galvoYBrynnConfig();
            
            configCounter =         mciDAQ.counterBrynnConfig();
            
            gui.objects.piezo =     mcaEO;
            
            gui.objects.galvos(1) = mcaDAQ(configGalvoX);
            gui.objects.galvos(2) = mcaDAQ(configGalvoY);
            
            gui.objects.counter   = mciDAQ(configCounter);
        end
    end
end

