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
            hwpConfig =     mcaHwpRotator.defaultConfig();
            
            %                     Style     String              Variable    TooltipString                                                                       Optional: Limit [min max round] (only for edit)
            config.controls = { { 'title',  'Galvos:  ',        NaN,        'Confocal scanning for the galvo mirrors.' },...
                                { 'edit',   'Range (um): ',     200,        'The range of the scan (in X and Y), centered on the current position. If this scan goes out of bounds, it is shifted to be in bounds.',                                        [0 abs(diff(galvoConfig.kind.int2extConv(galvoConfig.kind.intRange)))]},...
                                { 'edit',   'Pixels (#): ',     50,         'The number of points (in each dimension) which should be sampled over the scan range.',                                                                                        [1 Inf 1]},...
                                { 'edit',   'Speed (um/s): ',   200,        'The speed at which the range should be scanned over. Each scan will take [range/speed] seconds and [range/(speed*pixels)] seconds will be spent at each point of the scan.',   [0 Inf]},...
                                { 'push',   'Galvo Scan',       'galvo',    'Push to active a scan with the above parameters.' },...
                                { 'edit',   'Range XY (um): ',  1,          'The range of the scan (in X or Y), centered on the current position. If this scan goes out of bounds, it is shifted to be in bounds.',                                         [0 abs(diff(galvoConfig.kind.int2extConv(galvoConfig.kind.intRange)))]},...
                                { 'edit',   'Range Z (um): ',   5,          'The range of the scan (in Z), centered on the current position. If this scan goes out of bounds, it is shifted to be in bounds.',                                              [0 abs(diff(zConfig.kind.int2extConv(zConfig.kind.intRange)))]},...
                                { 'edit',   'Pixels (#): ',     50,         'The number of points which should be sampled over the scan range.',                                                                                                            [1 Inf 1]},...
                                { 'edit',   'Time (s): ',       2,          'The time taken for an optimization. The speed in this case will be [range/time].',                                                                                             [0 Inf]},...
                                { 'push',   'Optimize X',      'optX',      'Push to active an optimization in the X direction with the above parameters.' },...
                                { 'push',   'Optimize Y',      'optY',      'Push to active an optimization in the Y direction with the above parameters.' },...
                                { 'push',   'Optimize Z',      'optZ',      'Push to active an optimization in the Z direction with the above parameters.' },...
                                { 'edit',   'Range HWP (deg): ', 30,        'The range of the scan (in HWP deg), centered on the current position. If this scan goes out of bounds, it is shifted to be in bounds.',   [0 abs(diff(hwpConfig.kind.int2extConv(hwpConfig.kind.intRange)))]},...                                                              
                                { 'push',   'Optimize HWP',    'opthwp',    'Push to active an optimization over the HWP.' },...
                                { 'title',  'Large Micro Scan:', NaN,       'Take many galvo scans over a large area by moving the micrometers between scans.' },... % Added by Kelsey
                                { 'edit',   'Scans (#): ',       2,         'Total number of scanned positions in X and Y directions.',                                                                                                                                 [0 Inf 1]},...
                                { 'edit',   'Separation (um): ', 150,       'Separation between adjacent scans in um.',},...
                                { 'edit',   'HWP scans (#): ',   2,         'Number of scans to run at each location for different HWP angles.',                                                                                                          [1 200 1]},...
                                { 'push',   'Large MicroScan', 'lmscan',    'Push to run a series of galvo scans.' },...
                              };
        end
    end
    
    methods
        function gui = mcgBrynn(varin)
            switch nargin
                case 0
                    gui.load();                             % Attempt to load a previous config from configs/computername/classname/config.mat
                    
                    if isempty(gui.config)                  % If the file did not exist or the loading failed...
                        gui.config = gui.defaultConfig();   % ...then use the defaultConfig() as a backup.
                    end
                case 1
                    gui.config = varin;
            end
            
            gui.buildGUI();
        end
        
        function Callbacks(gui, ~, ~, cbName)
            if ~isfield(gui.objects, 'isSetup')
                gui.setupObjects();
            end
            
            switch lower(cbName)
                case 'galvo'
                    data = mcData(mcData.squareScanConfig(  gui.objects.galvos(1),...
                                                            gui.objects.galvos(2),...
                                                            gui.objects.counter,...
                                                            gui.controls{1}.Value,...
                                                            gui.controls{3}.Value,...
                                                            gui.controls{2}.Value));
                                                                
                    mcDataViewer(data, false);  % Open mcDataViewer to view this data, but do not open the control figure
                case 'optx'
                    data = mcData(mcData.optimizeConfig(    gui.objects.galvos(1),...
                                                            gui.objects.counter,...
                                                            gui.controls{4}.Value,...
                                                            gui.controls{6}.Value,...
                                                            gui.controls{7}.Value));
                    mcDataViewer(data, false);  % Open mcDataViewer to view this data, but do not open the control figure
                case 'opty'
                    data = mcData(mcData.optimizeConfig(    gui.objects.galvos(2),...
                                                            gui.objects.counter,...
                                                            gui.controls{4}.Value,...
                                                            gui.controls{6}.Value,...
                                                            gui.controls{7}.Value));
                    mcDataViewer(data, false);  % Open mcDataViewer to view this data, but do not open the control figure
                case 'optz'
                    data = mcData(mcData.optimizeConfig(    gui.objects.piezo,...
                                                            gui.objects.counter,...
                                                            gui.controls{5}.Value,...
                                                            gui.controls{6}.Value,...
                                                            gui.controls{7}.Value));
                    mcDataViewer(data, false);  % Open mcDataViewer to view this data, but do not open the control figure
                case 'opthwp'
                    data = mcData(mcData.optimizeConfig(    gui.objects.hwp,...
                                                            gui.objects.counter,...
                                                            gui.controls{8}.Value,...                      % range
                                                            gui.controls{6}.Value,...
                                                            gui.controls{7}.Value));
                    mcDataViewer(data, false);  % Open mcDataViewer to view this data, but do not open the control figure
                case 'spec'
                    data = mcData(mcData.singleSpectrumConfig());
                    mcDataViewer(data, false);  % Open mcDataViewer to view this data, but do not open the control figure
                case 'lmscan' % Added by Kelsey
                    range = (gui.controls{9}.Value - 1) * gui.controls{10}.Value;
                    hwpPos = linspace(0,90,gui.controls{11}.Value+1);
                    hwpPos = hwpPos(1:gui.controls{11}.Value)+gui.controls{8}.Value;
                    if range + getX(gui.objects.micros(1)) > 12000 || range + getX(gui.objects.micros(2)) > 16000
                        warning('Number of scans puts micrometers out of range. Removing problem scans.');
                        numScans = floor(min([12000 - getX(gui.objects.micros(1)) 16000 - getX(gui.objects.micros(2))])/gui.controls{10}.Value) + 1;
                    else
                        numScans = gui.controls{9}.Value;
                    end
                    
                    % Sets up optz input
                    configOptz = mcData.optimizeConfig(     gui.objects.piezo,...
                                                            gui.objects.counter,...
                                                            gui.controls{5}.Value,...
                                                            gui.controls{6}.Value,...
                                                            gui.controls{7}.Value); % axis, input, range, pixels, seconds
                    configWrapOptz = mciDataWrapper.dataConfig(configOptz);
                    optz = mciDataWrapper(configWrapOptz);
                    
                    % Sets up galvo input
                    configGalvo = mcData.squareScanConfig(  gui.objects.galvos(1),...
                                                            gui.objects.galvos(2),...
                                                            gui.objects.counter,...
                                                            gui.controls{1}.Value,...
                                                            gui.controls{3}.Value,...
                                                            gui.controls{2}.Value);
                    configGalvo.axes = {gui.objects.hwp configGalvo.axes{1} configGalvo.axes{2}}; % Append hwp to galvo arrays
                    configGalvo.scans = [hwpPos configGalvo.scans];
                    configWrapGalvo = mciDataWrapper.dataConfig(configGalvo);
                    galvo = mciDataWrapper(configWrapGalvo);
%                     galvo.config.name = 'MyName';
                    
                    % Defines inputs for mcData
                    d.axes = {gui.objects.micros(1),gui.objects.micros(2)};
                    d.scans = {(0:numScans - 1) * gui.controls{10}.Value + getX(gui.objects.micros(1)),...
                               (0:numScans - 1) * gui.controls{10}.Value + getX(gui.objects.micros(2))};
                    d.inputs = {optz, galvo};
                    d.intTimes = [NaN NaN];

                    % Creates data structure and takes data
                    data = mcData(d);
                    mcDataViewer(data);
                    
                    close(optz);
                    close(galvo);
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
            
            gui.objects.hwp       = mcaHwpRotator;
            
            gui.objects.counter   = mciDAQ(configCounter);
        
            % Added by Kelsey {
            configMicroX = mcaMicro.microXBrynnConfig();
            configMicroY = mcaMicro.microYBrynnConfig();
            
            gui.objects.micros(1) = mcaMicro(configMicroX);
            gui.objects.micros(2) = mcaMicro(configMicroY);
            % }
        end
    end
end

