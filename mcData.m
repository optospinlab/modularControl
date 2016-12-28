classdef mcData < mcSavableClass
% mcData is an object that encapsulates our generic data structure. This allows the same data structure to be used by multiple
%   classes. For instance, the same mcData can be used by multiple mcProcessedDatas.
%
% Syntax:
%   d = mcData()
%   d = mcData(params)                                                  % Load old data (or just the d structure if uninitialized) into this class
%   d = mcData('params.mat')                                            % Load old data (from a .mat) into this class
%   d = mcData(axes_, scans, inputs, integrationTime)                   % Load with cell arrays axes_ (contains the mcAxes to be used), scans (contains the paths, in numeric arrays, for these axes to take... e.g. linspace(0, 10, 50) is one such path from 0 -> 10 with 50 steps), and inputs (contains the mcInputs to be measured at each point). Also load the numeric array integration time (in seconds) which denotes (when applicable) how much time is spent measuring each input.
%   d = mcData(axes_, scans, inputs, integrationTime, shouldOptimize)   % In addition to the previous, shouldOptimize tells the mcData to optimize after finishing or not (only works for 1D and 2D scans with singular data) 
%
% Status: Mosly finished and commented. Loading needs to be finished.
% Update: Going through process to make it work for input of any sizeInput. Parts are not functional.]
% Future: Organize .mat file. Remember positions of other axes. Fix loading.

    properties (SetObservable)
        d = [];     % Our generic data structure. d for data. It is this structure that is saved in the .mat file.
        
        % d contains:
        %
        % - d.name                  string              % Name of this mcData scan. If left empty or uninitiated, it is auto-generated.
        % - d.kind.name             string              % Always equals 'mcData' allows other parts of the program to distinguish it from other configs. (Change?)
        %
        % - d.axes                  cell array          % The configs for the axes. For n axes, this is 1xn.
        % - d.inputs                cell array          % The configs for the inputs. For m inputs, this is 1xm.
        % - d.scans                 cell array          % The points that each axis scans across. The ith entry in the cell array corresponds to the ith axis. Note that these are in external units.
        % - d.intTimes              numeric array       % Contains the integration time for each input. Thus this is 1xm. For NIDAQ devices which 'can scan fast' by scanning altogether, the maximum intTime is used.
        % - d.flags.shouldOptimize  boolean             % Whether or not the axes should be optimized on the brightest point of the 1st input. Only works for 1 or 2 axes. Note that this is not general and should be replaced by an mcOptimizationRoutine struct for a general optimization.
        %
        % - d.data                  cell array          % This is the 'meat' of this structure. Data is a 1xm cell array (each entry corresponding to each input). Each entry contains an (n+N)-dimensional matrix where N is the dimension of the input.
        %
        % - d.info.timestamp        string              % The file is, by default, named <d.info.timestamp d.name>.mat. This is generated every time the data is reset.
        % - d.info.fname            string              % Where the data should be saved (in the background). This is generated every time the data is reset.
        % - d.info.version          numeric array       % The version of modularControl that this data was taken with. This is generated every time the data is reset.
        % - d.info.other.axes       cell array          % configs for all the axes when the scan is started.
        % - d.info.other.status     numeric array       % status (e.g. x) of all of the above axes.
        %
        % - d.index                 numeric array       % Current 'position' of the axes in the scan.
        %
        % - d.flags.circTime        boolean             % Flags whether the data should be circshifted for infinite data aquisistion. If this is not set, assumes false. If time is not an axis, assumes false.
        
        % Also note that config (due to inheretence from mcSavableClass) is also a member. (change this?)
    end

    properties (SetObservable)
        dataViewer = [];        % 'Pointer' to the current data viewer.
        r = [];                 % Struct for runtime-generated info. r for runtime.
        
        % - r.isInitialized = false;      % Whether or not the computer-generated fields have been calculated.
        % 
        % RUNTIME-GENERATED INPUT INFO:
        % 
        % - r.i.num                 integer
        % 
        % The following are (1xd.i.num) arrays. The ith value in each array contains the info relevant to the ith input.
        % 
        % - r.i.i                   mcInput array           % Contains the objects that point to the appropriate inputs.
        % - r.i.dimension           numeric array           % The dimension of the input (0 for number, 1 for vector, 2 for image).
        % - r.i.length              numeric array           % Lengths of the inputs (prod of the dimensions) e.g. length of 16x16 input is 256
        % - r.i.name                cell array (strings)
        % - r.i.nameUnit            cell array (strings)    %
        % - r.i.unit                cell array (strings)
        % - r.i.isNIDAQ             boolean array           
        % - r.i.inEmulation         boolean array
        % - r.i.numInputAxes        numeric
        % - r.i.scans               cell array              % Contains the vectors corresponding to the edges of theinputs.
        % 
        % RUNTIME-GENERATED AXIS INFO:
        % 
        % - r.a.num                 integer
        % 
        % The following are (1xd.i.num) arrays. The ith value in each array contains the info relevant to the ith input.
        % 
        % - r.a.a                   mcAxis array            % Contains the objects that point to the appropriate axes.
        % - r.a.name                cell array (strings)
        % - r.a.nameUnit            cell array (strings)    %
        % - r.a.unit                cell array (strings)
        % - r.a.isNIDAQ             boolean array           
        % - r.a.inEmulation         boolean array
        % - r.a.scansInternalUnits  cell array              % Contains the info in data.scans, except in internal units.
        % - r.a.prev                numeric array           % Contains the positions of all of the loaded axes before the scan begins. This allows for returning to the same place.
        % - r.a.timeIsAxis          boolean
        % 
        % RUNTIME-GENERATED LAYER INFO:
        % 
        % - r.l.num                 integer
        % - r.l.layer               numeric array           % Current layer that any connected mcProcessedDatas should process.
        % - r.l.axis                numeric array           % 1 ==> mcAxis, positive nums ==> the num'th axis of an input
        % - r.l.type                numeric array           % 0 ==> mcAxis, positive nums imply the num'th input.
        % - r.l.weight              numeric array           % First d.a.num indices are the weights of each axis. (Weight needs better explaination!)
        % - r.l.scans               cell arrray             % Contains all the scans (for both axes and inputs). If no scans are given for the inputs, then 1:size(dim) pixels is used.
        % - r.l.lengths             numeric arrray          % 
        % - r.l.name                cell array (strings)    %
        % - r.l.nameUnit            cell array (strings)    %
        % - r.l.unit                cell array (strings)    %
        % 
        % OTHER RUNTIME-GENERATED INFO:
        % 
        % - r.plotMode              integer             % e.g. 1 = '1D', 2 = '2D', ...
        % - r.isInitialized         boolean             % Is created once the initialize() function has been called.
        % - r.scanMode              integer             % paused = -1; new = 0; running = 1; finished = 2.
        % - r.aquiring              boolean             % whether we are aquiring currently or not.
        % - r.s                     DAQ session         % Only used if all the inputs and the first axis are NIDAQ.
        % - r.canScanFast           boolean             % Variable that decides whether the above should be used.
        % - r.timeIsAxis            boolean             % Flagged if time is the last axis (not currently used).
    end
    
    methods (Static)
        function data = defaultConfiguration()  % The configuration that is used if no vars are given to mcData.
            data = mcData.singleSpectrumConfiguration();
%             data = mcData.counterConfiguration(mciSpectrum(), 10, 1);
%             data = mcData.xyzConfiguration2();
%             data = mcData.testConfiguration();
        end
        function data = xyzConfiguration()      % Just a test configuration.
            configPiezoX = mcaDAQ.piezoConfig(); configPiezoX.name = 'Piezo X'; configPiezoX.chn = 'ao0';       % Customize all of the default configs...
            configPiezoY = mcaDAQ.piezoConfig(); configPiezoY.name = 'Piezo Y'; configPiezoY.chn = 'ao1';
            configPiezoZ = mcaDAQ.piezoZConfig(); configPiezoZ.name = 'Piezo Z'; configPiezoZ.chn = 'ao2';
            
            configCounter = mciDAQ.counterConfig(); configCounter.name = 'Counter'; configCounter.chn = 'ctr2';
            
            data.axes =     {configPiezoX, configPiezoY, configPiezoZ};                         % Fill the...   ...axes...
            data.scans =    {linspace(-10,10,21), linspace(-10,10,21), linspace(-10,10,2)};     %               ...scans...
            data.inputs =   {configCounter};                                                    %               ...inputs.
            data.intTimes = .05;
        end
        function data = xyzConfiguration2()      % Just a test configuration.
            configPiezoX = mcaDAQ.piezoConfig(); configPiezoX.name = 'Piezo X'; configPiezoX.chn = 'ao0';       % Customize all of the default configs...
            configPiezoY = mcaDAQ.piezoConfig(); configPiezoY.name = 'Piezo Y'; configPiezoY.chn = 'ao1';
            configPiezoZ = mcaDAQ.piezoZConfig(); configPiezoZ.name = 'Piezo Z'; configPiezoZ.chn = 'ao2';
            
            configTest = mciFunction.randConfig();
            
            data.axes =     {configPiezoX, configPiezoY, configPiezoZ};                         % Fill the...   ...axes...
            data.scans =    {linspace(-10,10,21), linspace(-10,10,21), linspace(-10,10,2)};     %               ...scans...
            data.inputs =   {configTest};                                                       %               ...inputs.
            data.intTimes = .05;
        end
        function data = squareScanConfiguration(axisX, axisY, input, range, speedX, pixels)                 % Square version of the below.
            data = mcData.scanConfiguration(axisX, axisY, input, range, range, speedX, pixels, pixels); 
        end
        function data = scanConfiguration(axisX, axisY, input, rangeX, rangeY, speedX, pixelsX, pixelsY)    % Rectangular 2D scan with arbitrary axes and input.
            if length(rangeX) == 1
                center = axisX.getX();
                rangeX = [center - rangeX/2 center + rangeX/2];
            elseif length(rangeX) ~= 2
                error('mcData.scanConfiguration(): Not sure how to use rangeX');
            end
            if length(rangeY) == 1
                center = axisY.getX();
                rangeY = [center - rangeY/2 center + rangeY/2];
            elseif length(rangeY) ~= 2
                error('mcData.scanConfiguration(): Not sure how to use rangeY');
            end
            
            if diff(rangeX) == 0
                error('mcData.scanConfiguration(): rangeX(1) should not equal rangeX(2)');
            end
            if diff(rangeY) == 0
                error('mcData.scanConfiguration(): rangeY(1) should not equal rangeY(2)');
            end
            
            if abs(diff(rangeX)) > abs(diff(axisX.config.kind.extRange))
                warning('mcData.scanConfiguration(): rangeX is too wide, setting to maximum');
                rangeX = axisX.config.kind.extRange;
            end
            if abs(diff(rangeY)) > abs(diff(axisY.config.kind.extRange))
                warning('mcData.scanConfiguration(): rangeY is too wide, setting to maximum');
                rangeY = axisY.config.kind.extRange;
            end
            
            if min(rangeX) < min(axisX.config.kind.extRange)
                warning('mcData.scanConfiguration(): rangeX is below range, shifting up');
%                 rangeX
                rangeX = rangeX + (min(axisX.config.kind.extRange) - min(rangeX));
            end
            if min(rangeY) < min(axisY.config.kind.extRange)
                warning('mcData.scanConfiguration(): rangeY is below range, shifting up');
%                 rangeY
                rangeY = rangeY + (min(axisY.config.kind.extRange) - min(rangeY));
            end
            
            if max(rangeX) > max(axisX.config.kind.extRange)
                warning('mcData.scanConfiguration(): rangeX is above range, shifting down');
%                 rangeX
                rangeX = rangeX + (max(axisX.config.kind.extRange) - max(rangeX));
            end
            if max(rangeY) > max(axisY.config.kind.extRange)
                warning('mcData.scanConfiguration(): rangeY is above range, shifting down');
%                 rangeY
                rangeY = rangeY + (max(axisY.config.kind.extRange) - max(rangeY));
            end
            
            
            if speedX < 0
                speedX = -speedX;
            elseif speedX == 0
                error('mcData.scanConfiguration(): It will take quite a long time to finish the scan if speedX == 0...');
            end
            
            
            if pixelsX ~= round(pixelsX)
                warning(['mcData.scanConfiguration(): pixelsX (' num2str(pixelsX) ') was not an integer, rounding to ' num2str(round(pixelsX)) '...']);
                pixelsX = round(pixelsX);
            end
            if pixelsX < 0
                pixelsX = -pixelsX;
            elseif pixelsX == 0
                error('mcData.scanConfiguration(): pixelsX should not equal zero...');
            end
            
            if pixelsY ~= round(pixelsY)
                warning(['mcData.scanConfiguration(): pixelsY (' num2str(pixelsY) ') was not an integer, rounding to ' num2str(round(pixelsY)) '...']);
                pixelsY = round(pixelsY);
            end
            if pixelsY < 0
                pixelsY = -pixelsY;
            elseif pixelsY == 0
                error('mcData.scanConfiguration(): pixelsY should not equal zero...');
            end
            
            
            data.axes =     {axisX, axisY};                                                                     % Fill the...   ...axes...
            data.scans =    {linspace(rangeX(1), rangeX(2), pixelsX), linspace(rangeY(1), rangeY(2), pixelsY)}; %               ...scans...
            data.inputs =   {input};                                                                            %               ...inputs.
            data.intTimes = (diff(rangeX)/speedX)/pixelsX;
        end
        function data = optimizeConfiguration(axis_, input, range, pixels, seconds)                         % Optimizes 'input' over 'range' of 'axis_'
%             axis_
%             input
%             range
%             pixels
%             seconds
            center = axis_.getX();
            
            scan = linspace(center - range/2, center + range/2, pixels);
            scan = scan(scan <= max(axis_.config.kind.extRange) & scan >= min(axis_.config.kind.extRange));  % Truncate the scan.
            
            data.axes =     {axis_};                    % Fill the...   ...axis...
            data.scans =    {scan};                     %               ...scan...
            data.inputs =   {input};                    %               ...input.
            data.intTimes = seconds/pixels;
            data.flags.shouldOptimize = true;
        end
        function data = counterConfiguration(input, length, integrationTime)    
            data.axes =     {mcAxis()};                 % This is the time axis.
            data.scans =    {1:abs(round(length))};     % range of 'scans ago'.
            data.inputs =   {input};                    % input.
            data.intTimes = integrationTime;
            data.flags.circTime = true;
        end
        function data = testConfiguration() % Not sure what I was doing here
            data.axes =     {};
            data.scans =    {};
            data.inputs =   {mciFunction(mciFunction.testConfig())};
            data.intTimes = 1;
        end
        function data = singleSpectrumConfiguration() % Not sure what I was doing here
            data.axes =     {};
            data.scans =    {};
            data.inputs =   {mciSpectrum()};
            data.intTimes = 1;
        end
    end
    
    methods
        function d = mcData(varin)  % Intilizes the mcData object d. Checks the d.d struct for errors.
            switch nargin
                case 0
                    d.d = mcData.defaultConfiguration();    % If no vars are given, assume a 10x10um piezo scan centered at zero.
                case 1
                    if ischar(varin)
                        error('Unfinished loading protocol');
                    else
                        d.d = varin;
                    end
                case 4
                    d.d.axes =              varin{1};       % Otherwise, assume the four variables are axes, scans, inputs, integration time...
                    d.d.scans =             varin{2};
                    d.d.inputs =            varin{3};
                    d.d.intTimes =          varin{4};
                    d.d.flags.shouldOptimize =    false;
                case 5          
                    d.d.axes =              varin{1};       % And if a 5th var is given, assume it is shouldOptimize
                    d.d.scans =             varin{2};
                    d.d.inputs =            varin{3};
                    d.d.intTimes =          varin{4};
                    d.d.flags.shouldOptimize =    varin{5};
            end
            
            if ~isfield(d.d, 'flags')
                d.d.flags = [];
            end
            
            if ~isfield(d.d.flags, 'shouldOptimize')
                d.d.flags.shouldOptimize = false;
            end
            
            if ~isfield(d.d.flags, 'circTime')
                d.d.flags.circTime = false;
            end
            
            % Check lengths of axes and scans...
            if length(d.d.axes) ~= length(d.d.scans)
                error('mcData(): Expected axes and scans to have the same length.');
            end
            
            % Checking the axes...
            if iscell(d.d.axes)
                for ii = 1:length(d.d.axes)
                    if isa(d.d.axes{ii}, 'mcAxis')
                        c = class(d.d.axes{ii});
                        d.d.axes{ii} = d.d.axes{ii}.config;
                        d.d.axes{ii}.class = c;                 % Store the class of the axis (e.g. mcaDAQ) if it isn't already...
                    elseif isstruct(d.d.axes{ii})
                        % Do nothing.
                    else
                        error(['mcData(): Unknown data type for the ' getSuffix(ii) ' axis: ' class(d.d.axes{ii})]);
                    end
                end
            else
                error('mcData(): d.d.axes must be a cell array.');
            end
            
            % Checking the scans...
            if iscell(d.d.scans)
                for ii = 1:length(d.d.scans)
                    if ~isnumeric(d.d.scans{ii})
                        error(['mcData(): Expected numeric array for the scan of the ' getSuffix(ii) ' axis. Got: ' class(d.d.scans{ii})]);
                    end
                    if min(size(d.d.scans{ii})) ~= 1 && length(size(d.d.scans{ii})) ~= 2    % If d.d.scans{ii} isn't a 1xn or nx1 vector...
                        error(['mcData(): Expected a 1xn or nx1 vector for the scan of the ' getSuffix(ii) ' axis. Got a matrix of dimension [ ' size(d.d.scans{ii}) ' ].']);
                    end
                end
            else
                error('mcData(): d.d.scans must be a cell array.');
            end
            
            % Check lengths of inputs and intTimes...
            if length(d.d.inputs) ~= length(d.d.intTimes)
                error('mcData(): Expected inputs and intTimes to have the same length.');
            end
            
            % Checking the inputs...
            if isempty(d.d.inputs)
                error('mcData(): d.d.inputs is empty. Cannot do a scan without inputs.');
            end
            
            if iscell(d.d.inputs)
                for ii = 1:length(d.d.inputs)
                    if isa(d.d.inputs{ii}, 'mcInput')
                        c = class(d.d.inputs{ii});
                        d.d.inputs{ii} = d.d.inputs{ii}.config;
                        d.d.inputs{ii}.class = c;               % Store the class of the input (e.g. mciDAQ) if it isn't already...
                    elseif isstruct(d.d.inputs{ii})
                        % Do nothing.
                    else
                        error(['mcData(): Unknown data type for the ' getSuffix(ii) ' input: ' class(d.d.inputs{ii})]);
                    end
                end
            else
                error('mcData(): d.d.inputs must be a cell array');
            end
            
            % Checking the intTimes...
            if isnumeric(d.d.intTimes)
                if any(d.d.intTimes < 0)
                    error('mcData(): Integration times cannot be negative.');
                end
            else
                error('mcData(): d.d.intTimes must be a numeric array.');
            end
            
            d.initialize();
            
            % Need more checks?!
        end
        
        function save(d)            % Background-saves the .mat file. Note that manual saving is done in mcDataViewer. (make a console command for manual saving, eventually?).
            data = d.d; %#ok
            save([d.d.info.fname ' ' d.d.name], 'data');
        end
        
        function initialize(d)      % Initializes the d.r (r for runtime) variables in the mcData object.
            if ~isfield(d.r, 'isInitialized')     % If not initialized, then intialize.
                
                % GENERATE INPUT RUNTIME DATA ==================================================================================
                
                % First, figure out how many inputs we have.
                d.r.i.num =             length(d.d.inputs);
                
                % Then, initialize empty lists.
                d.r.i.i =               cell( 1, d.r.i.num);
                
                d.r.i.dimension =       zeros(1, d.r.i.num);
                d.r.i.length =          zeros(1, d.r.i.num);
                d.r.i.size =            cell( 1, d.r.i.num);
                
                d.r.i.name =            cell( 1, d.r.i.num);
                d.r.i.nameUnit =        cell( 1, d.r.i.num);
                d.r.i.unit =            cell( 1, d.r.i.num);
                
                d.r.i.isNIDAQ =         false(1, d.r.i.num);
                d.r.i.inEnmulation =    false(1, d.r.i.num);
                
                % And initialize empty variables.
                d.r.l.axis =            [];
                d.r.l.type =            [];
                d.r.l.weight =          [];
                d.r.l.scans =           [];
                d.r.l.lengths =         [];
                d.r.l.name =            [];
                d.r.l.nameUnit =        [];
                d.r.l.unit =            [];
                    
                inputLetters = 'XYZUVW';

                for ii = 1:d.r.i.num        % Now fill the empty lists
                    c = d.d.inputs{ii};     % Get the config for the iith input.
                    
                    if isfield(c, 'class')
                        d.r.i.i{ii} = eval([c.class '(c)']);    % Make a mcInput (subclass) object based on that config),
                    else
                        error('mcData(): Config given without class. ');
                    end
                    
                    % Extract some info from the config.
                    d.r.i.dimension(ii) =   sum(c.kind.sizeInput > 1);
                    d.r.i.size{ii} =        c.kind.sizeInput(c.kind.sizeInput > 1);   % Poor naming.
                    d.r.i.length(ii) =      prod(d.r.i.size{ii});
                    
                    d.r.i.name{ii} =            d.r.i.i{ii}.nameShort();        % Generate the name of the inputs in... ...e.g. 'name (dev:chn)' form
                    d.r.i.nameUnit{ii} =        d.r.i.i{ii}.nameUnits();        %                                       ...'name (units)' form
                    d.r.i.unit{ii} =            d.d.inputs{ii}.kind.extUnits;   %                                       ...'units'

                    d.r.i.isNIDAQ(ii) =         strcmpi('nidaq', c.kind.kind(1:min(5,end)));
                    d.r.i.inEmulation(ii) =     d.r.i.i{ii}.inEmulation;
                    
                    % For inputs which have dimension (e.g. a vector input like a spectrum vs a number like a voltage), fill in some info so we can display data over these input axes.
                    d.r.l.axis =    [d.r.l.axis     1:d.r.i.dimension(ii)];             % If an input has dimension dim, then 1:dim is added, representing the 'dim' axes that this input has.
                    d.r.l.type =    [d.r.l.type     ones(1, d.r.i.dimension(ii))*ii];   % To identify which input the above belongs to, the index is tagged with the number of the axis.
                    d.r.l.scans =   [d.r.l.scans    d.r.i.i{ii}.getInputScans()];
                    d.r.l.lengths = [d.r.l.lengths  d.r.i.size{ii}];                    % Will this be a cell?
                    
                    if d.r.i.dimension(ii) > length(inputLetters)
                        error('mcData.initialize(): Too many dimensions on this input. Not enough letters to describe each dimension.')
                    end
                    
                    inUnits = d.r.i.i{ii}.getInputScanUnits();
                    
                    for jj = 1:d.r.i.dimension(ii)
                        d.r.l.name =        [d.r.l.name     {[d.d.inputs{ii}.name ' ' inputLetters(jj)]}];
                        d.r.l.nameUnit =    [d.r.l.nameUnit {[d.d.inputs{ii}.name ' ' inputLetters(jj) ' (' inUnits{jj} ')']}];
                        d.r.l.unit =        [d.r.l.unit     inUnits(jj)];
                    end
                    
                    iwAdd = ones(1, d.r.i.dimension(ii));       % Temporary variable: 'indexWeightAdd' because it will be added to d.r.l.weight.
                    for jj = 2:length(iwAdd)
                        iwAdd(jj:end) = iwAdd(jj:end)*d.r.i.size{ii}(jj-1);
                    end
                    d.r.l.weight =              [d.r.l.weight iwAdd];
                end
                
                % And gather some statistics based on the filled lists.
                d.r.i.numInputAxes = sum(d.r.i.dimension);
                

                % GENERATE AXIS RUNTIME DATA ===================================================================================
                
                % Again, first figure out how many axes we have.
                d.r.a.num =         length(d.d.axes);
                
                % Make some empty lists...
                d.r.a.length =          zeros(1, d.r.a.num);
                
                d.r.a.a =               cell(1, d.r.a.num);
                justname =              cell(1, d.r.a.num);
                d.r.a.name =            cell(1, d.r.a.num);
                d.r.a.nameUnit =        cell(1, d.r.a.num);
                d.r.a.unit =            cell(1, d.r.a.num);
                
                d.r.a.isNIDAQ =         false(1, d.r.a.num);
                d.r.a.inEnmulation =    false(1, d.r.a.num);
                
                d.r.a.prev =            NaN( 1, d.r.a.num);

                % ...and fill them.
                for ii = 1:d.r.a.num
                    c = d.d.axes{ii};     % Get the config for the iith axis.
                    
                    if isfield(c, 'class')
                        d.r.a.a{ii} = eval([c.class '(c)']);    % Make a mcInput (subclass) object based on that config),
                    else
                        error('mcData(): Config given without class. ');
                    end
                    
                    d.r.a.length(ii) =      length(d.d.scans{ii});
                    
                    justname{ii} =          d.d.axes{ii}.name;
                    d.r.a.name{ii} =        d.r.a.a{ii}.nameShort();
                    d.r.a.nameUnit{ii} =    d.r.a.a{ii}.nameUnits();
                    d.r.a.unit{ii} =        d.d.axes{ii}.kind.extUnits;
                    
                    d.r.a.isNIDAQ(ii) =     strcmpi('nidaq', c.kind.kind(1:min(5,end)));
                    d.r.a.inEmulation(ii) = d.r.a.a{ii}.inEmulation;
                    
%                     d.r.a.prev =            d.r.a.a{ii}.getX();
                    
                    d.r.a.scansInternalUnits{ii} = arrayfun(d.r.a.a{ii}.config.kind.ext2intConv, d.d.scans{ii});
                end
                
                % GENERATE LAYER RUNTIME DATA ==================================================================================
                
                d.r.l.name =        [justname       d.r.l.name];
                d.r.l.nameUnit =    [d.r.a.nameUnit d.r.l.nameUnit];
                d.r.l.unit =        [d.r.a.unit     d.r.l.unit];
                
                d.r.l.num = d.r.a.num + d.r.i.numInputAxes;
                
                % Then, figure out how we should initially display the data, based on the total number of axes we have.
                d.r.plotMode = max(min(2, d.r.a.num + d.r.i.numInputAxes),1);   % Plotmode takes in 0 = histogram (no axes); 1 = 1D (1 axis); ...
                
                % And choose which axes to initially display.
                d.r.l.layer = ones(1,  d.r.a.num + d.r.i.numInputAxes)*(2 + d.r.plotMode);  % e.g. for 2D, the layer is initially set to all 3s.
                n = min(d.r.plotMode, d.r.a.num + d.r.i.numInputAxes);
                d.r.l.layer(1:n) = 1:n;                                                     % Then the first two axes are set to 1 and 2 (for 2D).
                
                % Then, add mcAxis info to the layer information...
                d.r.l.axis =    [ones( 1, d.r.a.num) d.r.l.axis];
                d.r.l.type =    [zeros(1, d.r.a.num) d.r.l.type];
%                 type = d.r.l.type
%                 d.r.l.length =  [d.r.a.length d.r.i.length];    % Not sure why this is here...
                d.r.l.lengths = [d.r.a.length  d.r.l.lengths];
                d.r.l.scans =   [d.d.scans d.r.l.scans];
                
                % Index weight is best described by an example: If one has a 5x4x3 matrix, then incrimenting the x axis
                %   increases the linear index (the index if the matrix was streached out) by one. Incrimenting the y axis
                %   increases the linear index by 5. And incrimenting the z axis increases the linear index by 20 = 5*4. So the
                %   index weight in this case is [1 5 20].
                d.r.l.weight =  [ones(1,  d.r.a.num) d.r.l.weight];    
                
                % Make index weight according to the above specification.
                for ii = 2:(d.r.a.num + d.r.i.numInputAxes)
                    d.r.l.weight(ii:end) = d.r.l.weight(ii:end) * d.r.a.length(ii-1);
                end
                
                if ~isempty(d.d.axes)
                    d.d.flags.circTime = d.d.flags.circTime && strcmpi('time', d.d.axes{end}.kind.kind);
                
                    d.r.canScanFast = d.r.a.isNIDAQ(1) && ~d.r.a.inEmulation(1) && all(d.r.i.isNIDAQ & ~d.r.a.inEmulation);
                else
                    d.r.canScanFast = false;
                    d.d.flags.circTime = false;
                end
                
                % MCDATA NAMING ================================================================================================
                
                % Now, figure out what this mcData should be named.
                if ~isfield(d.d, 'name')
                    d.d.name = '';
                end
                
                % If there isn't already a name, generate one:
                if isempty(d.d.name)
                    for ii = 1:(d.r.i.num-1)
                        d.d.name = [d.d.name d.d.inputs{ii}.name ', '];
                    end

                    d.d.name = [d.d.name d.d.inputs{d.r.i.num}.name];
                    
                    if ~isempty(d.r.a.a)
                        d.d.name = [d.d.name ' vs '];

                        for ii = 1:(d.r.a.num-1)
                            d.d.name = [d.d.name d.r.l.name{ii} ', '];
                        end

                        d.d.name = [d.d.name d.r.l.name{d.r.a.num}];
                    end
                end
                
                % FINAL ========================================================================================================
                
                if ~isfield(d.d, 'index')
                    d.resetData();
                    d.r.scanMode = 0;
                else
                    d.r.scanMode = -1;      % Check for finished?
                end
                
                d.r.isInitialized = true;
            end
        end
        
        function resetData(d)
            % INITIALIZE THE DATA TO NAN 
            data =   cell([1, d.r.i.num]);      % d.r.i.num layers of data (one layer per input)

            for ii = 1:d.r.i.num
                % [d.r.l.lengths(d.r.l.type == 0 | d.r.l.type == ii) 1]
                data{ii} =      NaN([d.r.l.lengths(d.r.l.type == 0 | d.r.l.type == ii) 1]);
            end
            
            d.d.data = data;

            % Make the variable that keeps track of where we are in 
            d.d.index =          ones(1, d.r.a.num);
%             d.d.currentIndex =   2;
            
            d.d.info.version = mcInstrumentHandler.version();
            [d.d.info.fname, d.d.info.timestamp] =  mcInstrumentHandler.timestamp(1);
                
            d.r.scanMode = 0;
            
            [~, ~, d.d.other.axes, d.d.other.status] = mcInstrumentHandler.getAxes();
        end
        
        function aquire(d)
            d.r.aquiring = true;
            d.r.scanMode = 1;
            
            if any(mcInstrumentHandler.version() ~= d.d.info.version)
                mcDialog(  ['Warning! This data was initalized with modular Control version [ ' num2str(d.d.info.version)... 
                            ' ]. The current version is [ ' num2str(mcInstrumentHandler.version()) ' ].'], 'Warning!');
            end
            
            % Check d.d.other.axes, d.d.other.status...
            
            if d.r.a.num == 0   % A simple case if we have no axes...
                for ii = 1:d.r.i.num
                    d.d.data{ii} = d.r.i.i{ii}.measure(d.d.intTimes(ii));
                end
                
                d.r.scanMode = 2;
            else
                nums = 1:d.r.a.num;

                if all(isnan(d.r.a.prev))       % If the previous positions of the axes have not already been set...
                    for ii = nums               % For every axis,
                        d.r.a.prev(ii) = d.r.a.a{ii}.getX();                % Remember the pre-scan positions of the axes.
                        d.r.a.a{ii}.goto(d.d.scans{ii}(d.d.index(ii)));     % And goto the starting position.
                    end

                    for ii = nums               % Then, again for every axis,
                        d.r.a.a{ii}.wait();     % Wait for the axis to reach the starting position (only relevant for micros/etc).
                    end
                end

                if d.r.aquiring
                    % Make a NIDAQ session if it is neccessary and has not already been created.
                    if d.r.canScanFast && (~isfield(d.r, 's') || isempty(d.r.s) || ~isvalid(d.r.s))
                        d.r.s = daq.createSession('ni');

                        d.r.a.a{1}.close();
                        d.r.a.a{1}.addToSession(d.r.s);         % First add the axis,

                        for ii = 1:d.r.i.num
                            d.r.i.i{ii}.addToSession(d.r.s);    % Then add the inputs
                        end
                    end 
                end

                while d.r.aquiring
                    d.aquire1D(d.r.l.weight(1:d.r.a.num) * (d.d.index - 1)' + 1);
                    
                    drawnow

                    currentlyMax =  d.d.index == d.r.a.length;  % Variables to figure out which indices need incrimenting/etc.

                    if all(currentlyMax) && ~d.d.flags.circTime       % If the scan has finished...
                        d.r.scanMode = 2;
                        break;
                    end

                    toIncriment =   [true currentlyMax(1:end-1)] & ~currentlyMax;
                    toReset =       [true currentlyMax(1:end-1)] &  currentlyMax;

                    if ~d.r.aquiring                % If the scan was stopped...
%                         display('Scan stopped...');
                        break;
                    end

                    if d.d.flags.circTime && toIncriment(end)     % If we have run out of bounds and need to circshift...
                        disp('Time is axis and overrun!');

                        for ii = 1:d.r.i.num        % ...for every input, circshift the data forward one 'time' forward.
                            d.d.data{ii} = circshift(d.d.data{ii}, [0, max(d.l.weight(d.r.l.type == 0 | d.r.l.type == ii))]);
                        end

                        toIncriment(end) = false;   % and pretend that the time axis does not need to be incrimented.
                    end

                    d.d.index = d.d.index + toIncriment;    % Incriment all the indices that were after a maximized index and not maximized.
                    d.d.index(toReset) = 1;                 % Reset all the indices that were maxed (except the first) to one.

                    for ii = nums(toIncriment | toReset)
                        d.r.a.a{ii}.goto(d.d.scans{ii}(d.d.index(ii)));
                    end
                end
                
%                 display('Exited loop...');

                if d.r.canScanFast   % Destroy the session, if a session was created.
                    release(d.r.s);
                    delete(d.r.s);
                    d.r.s = [];
                end
                
                d.save()
                    
                if d.r.scanMode == -2       % If dataviewer was quit.
                    delete(d);
                elseif d.r.scanMode ~= 2                % If the scan was unexpectantly stopped.
%                     display('...set to paused...');
                    d.r.scanMode = -1;
%                     display('...now.');
                elseif d.d.flags.shouldOptimize     % If there should be a post-scan optimization...
                    switch length(d.r.a.a)
                        case 1
                            [x, ~] = mcPeakFinder(d.d.data{1}, d.d.scans{1}, 0);    % First find the peak.

                            d.r.a.a{1}.goto(d.d.scans{1}(1));                       % Approaching from the same direction...

                            d.r.a.a{1}.goto(x);                                     % ...goto the peak.
                        case 2
                            [x, y] = mcPeakFinder(d.d.data{1}, d.d.scans{1}, d.d.scans{2});     % First find the peak.

                            d.r.a.a{1}.goto(d.d.scans{1}(1));                                   % Approaching from the same direction...
                            d.r.a.a{2}.goto(d.d.scans{2}(1));

                            d.r.a.a{1}.goto(x);                                                 % ...goto the peak.
                            d.r.a.a{2}.goto(y);
                        otherwise
                            disp('mcData.aquire(): Optimization on more than 2 axes not currently supported...');
                    end 
                elseif d.r.scanMode == 2            % Should the axes goto the original values after the scan finishes?
                    for ii = nums
                        d.r.a.a{ii}.goto(d.r.a.prev(ii));  % Then goto the stored previous values.
                    end
                end
            end
        end
        function aquire1D(d, jj)
            if length(d.d.axes) == 1 && d.d.flags.circTime    % If time happens to be the current axis and we should circshift...
%                 disp('Time is only axis')
                
                while d.r.aquiring
                    for ii = 1:d.r.i.num
                        len = max(d.r.l.weight(d.r.l.type == 0 | d.r.l.type == ii));
                        
                        nums = 1:d.r.l.num;
                        
                        data = circshift(d.d.data{ii}, round(nums == d.r.a.num));
                        
                        if len == 1
                            data(1) =                   d.r.i.i{ii}.measure(d.d.intTimes(ii));
                        else
                            w = d.r.l.weight(d.r.a.num + 1);
                            data(1:w:(w*d.r.i.length(ii))) =  d.r.i.i{ii}.measure(d.d.intTimes(ii));
                        end
                        
                        d.d.data{ii} = data;
                    end
                end
            elseif d.r.canScanFast
                d.r.s.Rate = 1/max(d.data.intTimes);     % Whoops; integration time has to be the same for all inputs... Taking the max for now...
                
                d.r.s.queueOutputData([d.data.scansInternalUnits{1}  d.data.scansInternalUnits{1}(end)]');   % The last point (a repeat of the final params.scan point) is to count for the last pixel (counts are differences).

                [data_, times] = d.r.s.startForeground();       % Should I startBackground() and use a listener? (Do this in the future!)

                kk = 1;

                for ii = 1:d.r.i.num     % Fill all of the inputs with data...
                    if d.d.inputs{ii}.kind.shouldNormalize  % If this input expects to be divided by the exposure time...
                        d.data.data{ii}(jj:jj+d.data.lengths(1)-1) = (diff(double(data_(:, kk)))./diff(double(times)))';   % Should measurment time be saved also? Should I do diff beforehand instead of individually?
                    else
                        d.data.data{ii}(jj:jj+d.data.lengths(1)-1) = double(data_(1:end-1, kk))';
                    end

                    kk = kk + 1;
                end
                
                if ~isempty(d.d.index)
                    d.d.index(1) = d.r.a.length(1);
                end
            else
                for kk = d.d.index(1):d.r.a.length(1)
                    if d.r.aquiring
                        d.r.a.a{1}.goto(d.d.scans{1}(kk));             % Goto each point...
                        d.r.a.a{1}.wait();              % ...wait for the axis to arrive (for some types)...

                        for ii = 1:d.r.i.num         % ...for every input...
                            if d.r.i.dimension(ii) == 0
                                d.d.data{ii}(jj+kk-1) = d.r.i.i{ii}.measure(d.d.intTimes(ii));  % ...measure.
                            else
                                base = (jj+kk)*d.r.i.length(ii) - 1;  % This is a guess.
                                d.d.data{ii}(base:base+d.r.i.length(ii)-1) = d.r.i.i{ii}.measure(d.d.intTimes(ii));  % ...measure.
                            end
                        end
                    end
                    d.d.index(1) = kk;
                end
            end
        end
    end
end




