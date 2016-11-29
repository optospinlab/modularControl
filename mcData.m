classdef mcData < mcSavableClass
% mcData is an object that encapsulates our generic data structure. This allows the same data structure to be used by multiple
%   classes. For instance, the same mcData can be used by multiple mcProcessedDatas.
%
% Syntax:
%   d = mcData()
%   d = mcData(params)                                                  % Load old data (or just params if uninitialized) into this class
%   d = mcData('params.mat')                                            % Load old data (from a .mat) into this class
%   d = mcData(axes_, scans, inputs, integrationTime)                   % Load with cell arrays axes_ (contains the mcAxes to be used), scans (contains the paths, in numeric arrays, for these axes to take... e.g. linspace(0, 10, 50) is one such path from 0 -> 10 with 50 steps), and inputs (contains the mcInputs to be measured at each point). Also load the numeric array integration time (in seconds) which denotes (when applicable) how much time is spent measuring each input.
%   d = mcData(axes_, scans, inputs, integrationTime, shouldOptimize)   % In addition to the previous, shouldOptimize tells the mcData to optimize after finishing or not (only works for 1D and 2D scans with singular data) 
%
% Status: Mosly finished and commented. Loading needs to be finished.

    properties (SetObservable)
        data = [];                  % Our generic data structure.
    end

    properties
        dataViewer = [];            % 'Pointer' to the current data viewer.
%         isInitialized = false;      % Whether or not the computer-generated fields have been calculated.
        
%           These generated fields include:
%            - data.inputDimension         numeric array     % contains the number of dimensions that the data from each input has. e.g. a number would be 0, a vector 1, and an image 2.
%            - data.isInputNIDAQ           boolean array     % Self-explainitory
%            - data.inEmulation            boolean array     %         "
%            - data.canScanFast            boolean           % If all of the inputs and the axis are NIDAQ, then one can use daq methods to scan faster.
%
%            - data.numAxes                integer           % Number of axes overall.
%            - data.numInputs              integer           % Number of inputs overall.
%
%            - data.axisNames              char cell array   % Names of inputs and axes
%            - data.axisNamesUnits         char cell array
%            - data.inputNames             char cell array
%            - data.inputNamesUnits        char cell array
%
%            - data.scansInternalUnits     cell array        % Contains the info in data.scans, except in internal units.
%
%            - data.posStart               numeric array     % Contains the positions of all of the axes before the scan begins. This allows for returning to the same place.
%
%            - data.README                 string            % Instructions about how to use the data.
%
%            - data.plotMode               integer           % e.g. 1 = '1D', 2 = '2D', ...
%            - data.layer                  numeric array     % Current layer that any connected mcProcessedDatas should process.
%            - data.layerType              numeric array     % 0 = axis, positive nums imply the num'th axis of an input
%            - data.layerIndex             numeric array     % 0 = axis, positive nums imply the num'th input.
%            - d.data.inputLength
%
%            - data.lengths
%            - data.indexWeight
%
%            - data.isInitialized          boolean           % Is created once 
%            - data.scanMode               boolean
%
%            - data.shouldOptimize
%
%            - data.fname
%
%            - data.name

    end
    
    methods (Static)
        function data = defaultConfiguration()  % The configuration that is used if no vars are given to mcData.
            data = mcData.xyzConfiguration();
%             data = mcData.testConfiguration();
        end
        function data = xyzConfiguration()      % Just a test configuration.
            configPiezoX = mcaDAQ.piezoConfig(); configPiezoX.name = 'Piezo X'; configPiezoX.chn = 'ao0';       % Customize all of the default configs...
            configPiezoY = mcaDAQ.piezoConfig(); configPiezoY.name = 'Piezo Y'; configPiezoY.chn = 'ao1';
            configPiezoZ = mcaDAQ.piezoZConfig(); configPiezoZ.name = 'Piezo Z'; configPiezoZ.chn = 'ao2';
            
            configCounter = mciDAQ.counterConfig(); configCounter.name = 'Counter'; configCounter.chn = 'ctr2';
            
            data.axes =     {mcaDAQ(configPiezoX), mcaDAQ(configPiezoY), mcaDAQ(configPiezoZ)};                 % Fill the...   ...axes...
            data.scans =    {linspace(-10,10,21), linspace(-10,10,21), linspace(-10,10,2)};                     %               ...scans...
            data.inputs =   {mciDAQ(configCounter)};                                                            %               ...inputs.
            data.integrationTime = .05;
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
            data.integrationTime = (diff(rangeX)/speedX)/pixelsX;
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
            data.integrationTime = seconds/pixels;
            data.shouldOptimize = true;
        end
        function data = counterConfiguration(input, length, integrationTime)    
            data.axes =     {mcAxis()};                 % This is the time axis.
            data.scans =    {1:abs(round(length))};     % range of 'scans ago'.
            data.inputs =   {input};                    % input.
            data.integrationTime = integrationTime;
        end
        function data = testConfiguration() % Not sure what I was doing here
            data.axes =     {};
            data.scans =    {};
            data.inputs =   {mciFunction(mciFunction.testConfig())};
            data.integrationTime = 1;
        end
        function str = README()
            % This is outdated.
            str = ['This is a scan of struct.numInputs inputs over the struct.scans of struct.numAxes axes. '...
                   'struct.data is a cell array with a cell for each input. Inside each cell is the result of '...
                   'the measurement of that input for each point of the ND grid formed by the scans of the axes. '...
                   'If the measurement is singular (i.e. just a number like a voltage measurement), then the '...
                   'contents of the input cell is a numeric array with dimensions corresponding to the lengths of '...
                   'struct.scans. If the measurement is more complex (e.g. a vector like a spectra), then the '...
                   'contents of the input cell is a cell array with dimensions corresponding to the lengths of '...
                   'struct.scans.'];
        end
    end
    
    methods
        function d = mcData(varin)
            switch nargin
                case 0
                    d.data = mcData.defaultConfiguration();     % If no vars are given, assume a 10x10um piezo scan centered at zero.
                case 1
                    if ischar(varin)
                        error('Unfinished loadign protocol');
%                         d.data = load(varin); % Unfinished!
                    else
                        d.data = varin;
                    end
                case 4
                    d.data.axes =               varin{1};               % Otherwise, assume the four variables are axes, scans, inputs, integration time...
                    d.data.scans =              varin{2};
                    d.data.inputs =             varin{3};
                    d.data.integrationTime =    varin{4};
                case 5
                    d.data.axes =               varin{1};               % And if a 5th var is given, assume it is inputTypes
                    d.data.scans =              varin{2};
                    d.data.inputs =             varin{3};
                    d.data.integrationTime =    varin{4};
%                 case 6
%                     d.data.axes =               varin{1};               % And if a 5th var is given, assume it is optimize
%                     d.data.scans =              varin{2};
%                     d.data.inputs =             varin{3};
%                     d.data.integrationTime =    varin{4};
%                     d.data.inputTypes =         varin{5};
            end
            
            % Need more checks!
            
%             d.data.scans
            
            isScanEmpty = false;        % Do this in a MATLAB way...
            for scan = d.data.scans
                isScanEmpty = isScanEmpty || isempty(scan{1});
            end
            
            if ~isScanEmpty
                if isempty(d.data.inputs)
                    error('mcData: Cannot do a scan without inputs...');
                else
                    d.initialize();
                end
            else
                error('mcData: At lease one of the proposed scans is empty...');
            end
        end
        
%         function save(d, fname)
%             switch (lower(fname(end-2:end)))
%                 case 'mat'
%                     save(fname, 'd.data');  % Not sure if this works.
%                 otherwise
%                     error('Saving filetypes other than .mat NotImplemented');
%             end
%         end
        
        function initialize(d)
            if ~isfield(d.data, 'isInitialized')     % If not initialized, then intialize.
                d.data.README = d.README();
                
                %%% HANDLE THE INPUTS %%%
                d.data.numInputs = length(d.data.inputs);
                
                d.data.inputDimension =     zeros(1, d.data.numInputs);     % Make empty lists for future filling.
                d.data.sizeInput =          cell( 1, d.data.numInputs);
                d.data.inputLength =     	zeros(1, d.data.numInputs);
                d.data.isInputNIDAQ =       false(1, d.data.numInputs);
                d.data.inEnmulation =       false(1, d.data.numInputs);
                
                d.data.inputNames =         cell( 1, d.data.numInputs);
                d.data.inputNamesUnits =    cell( 1, d.data.numInputs);
                
                d.data.numInputAxes =   0;
                d.data.layerType =      [];
                d.data.layerIndex =     [];
                d.data.lengths =        [];
                d.data.indexWeight =    [];

                for ii = 1:d.data.numInputs                                 % Now fill the empty lists
                    d.data.inputDimension(ii) =     sum(d.data.inputs{ii}.config.kind.sizeInput > 1);
                    d.data.sizeInput{ii} =          d.data.inputs{ii}.config.kind.sizeInput(d.data.inputs{ii}.config.kind.sizeInput > 1);   % Poor naming.
                    d.data.inputLength(ii) =        prod(d.data.inputDimension(ii));
%                     d.data.numInputAxes = d.data.numInputAxes + d.data.inputDimension(ii);
                    d.data.layerType =  [d.data.layerType   1:d.data.inputDimension(ii)];
                    d.data.layerIndex = [d.data.layerIndex  ones(1, d.data.inputDimension(ii))*ii];
                    
                    for s = d.data.sizeInput{ii}
                        d.data.scans = [d.data.scans {1:s}];
                    end
                    
                    lengths = d.data.sizeInput{ii};
                    d.data.lengths =    [d.data.lengths     lengths];
                    
                    iwAdd = ones(1, d.data.inputDimension(ii)); % Temporary variable: 'indexWeightAdd' because it will be added to d.data.indexWeight.
                    for jj = 2:length(iwAdd)
                        iwAdd(jj:end) = iwAdd(jj:end)*d.data.sizeInput{ii}(jj-1);
                    end
                    
                    d.data.indexWeight = [d.data.indexWeight iwAdd];

                    d.data.isInputNIDAQ(ii) =       strcmpi('nidaq', d.data.inputs{ii}.config.kind.kind(1:5));
                    d.data.inEmulation(ii) =        d.data.inputs{ii}.inEmulation;
                    d.data.inputConfigs{ii} =       d.data.inputs{ii}.config;
                    
                    d.data.inputNames{ii} =         d.data.inputs{ii}.nameShort();  % Generate the name of the inputs in... ...e.g. 'name (dev:chn)' form
                    d.data.inputNamesUnits{ii} =    d.data.inputs{ii}.nameUnits();  %                                            ...'name (units)' form
                end
                    
                d.data.numInputAxes = sum(d.data.inputDimension(ii));

                %%% HANDLE THE AXES %%%
                d.data.numAxes =   length(d.data.axes);
                
                if ~isfield(d.data, 'plotMode')
                    d.data.plotMode = max(min(2, d.data.numAxes + d.data.numInputAxes),1);
                end
                
                if ~isfield(d.data, 'layer')
                    d.data.layer = ones(1, d.data.numAxes + d.data.numInputAxes)*(1 + d.data.plotMode);
                    d.data.layer(1:min(d.data.plotMode, d.data.numAxes)) = 1:min(d.data.plotMode, d.data.numAxes);
                    
                    d.data.input = 1;
                end
                
                d.data.layerType =  [zeros(d.data.numAxes) d.data.layerType];  % Appropraitely pad the arrays...
                d.data.layerIndex = [ones(d.data.numAxes)  d.data.layerIndex];

                d.data.lengths =        [zeros(1, d.data.numAxes) d.data.lengths];
                d.data.indexWeight =    [ones(1,  d.data.numAxes) d.data.indexWeight];  % Index weight is best described by an example:
                                                                                        %   If one has a 5x4x3 matrix, then incrimenting the x axis
                                                                                        %   increases the linear index (the index if the matrix was
                                                                                        %   streached out) by one. Incrimenting the y axis increases
                                                                                        %   the linear index by 5. And incrimenting the z axis increases
                                                                                        %   the linear index by 20 = 5*4. So the index weight in this case
                                                                                        %   is [1 5 20].

                d.data.axisNames =         cell(1, d.data.numAxes);   % Same as input name generation above.
                d.data.axisNamesUnits =    cell(1, d.data.numAxes);
                d.data.axisPrev =          NaN( 1, d.data.numAxes);

                for ii = 1:d.data.numAxes
                    d.data.lengths(ii) =            length(d.data.scans{ii});
                    
                    d.data.axisNames{ii} =          d.data.axes{ii}.nameShort();
                    d.data.axisNamesUnits{ii} =     d.data.axes{ii}.nameUnits();
                    d.data.axisConfigs{ii} =        d.data.axes{ii}.config;
                end
                
                
            
                if ~isfield(d.data, 'shouldOptimize')
                    d.data.shouldOptimize = false;
                end
                
                d.data.name = '';
                
                for ii = 1:(d.data.numInputs-1)
                    d.data.name = [d.data.name d.data.inputs{ii}.config.name ', '];
                end
                
                d.data.name = [d.data.name d.data.inputs{d.data.numInputs}.config.name];
                    
                if ~isempty(d.data.axes)
                    d.data.name = [d.data.name ' vs '];

                    for ii = 1:(d.data.numAxes-1)
                        d.data.name = [d.data.name d.data.axes{ii}.config.name ', '];
                    end

                    d.data.name = [d.data.name d.data.axes{d.data.numAxes}.config.name];
                end

%                 if d.data.numAxes > 2
%                     for ii = 2:d.data.numAxes-1
%                         d.data.indexWeight(ii+1:end) = d.data.indexWeight(ii+1:end)*d.data.lengths(ii);
%                     end
%                 end
% 
%                 d.data.indexWeight(1) = 0;

                for ii = 2:d.data.numAxes
                    d.data.indexWeight(ii:end) = d.data.indexWeight(ii:end)*d.data.lengths(ii-1);
                end
                
                for ii = 1:d.data.numAxes                                 % Fill the empty lists
                    d.data.scansInternalUnits{ii} = arrayfun(d.data.axes{ii}.config.kind.ext2intConv, d.data.scans{ii});
                end

                allInputsFast = all(d.data.isInputNIDAQ & ~d.data.inEmulation);       % Are all 'everypoint'-mode inputs NIDAQ?
                if ~isempty(d.data.axes)
                    d.data.canScanFast = (strcmpi('nidaq', d.data.axes{1}.config.kind.kind(1:min(5,end))) || strcmpi('time', d.data.axes{1}.config.kind.kind)) && ~d.data.axes{1}.inEmulation && allInputsFast;   % Is the first axis NIDAQ? If so, then everything important is NIDAQ if allInputsNIDAQ also.
                    d.data.timeIsAxis = strcmpi('time', d.data.axes{end}.config.kind.kind);
                else
                    d.data.canScanFast = true;  % or false?
                    d.data.timeIsAxis = false;
                end
                
%                 d.data.canScanFast = false
                    
                d.resetData();
                d.data.isInitialized = true;
            end
        end
        
        function resetData(d)
            %%% INITIALIZE THE DATA TO NAN %%%
            d.data.data =   cell([1, d.data.numInputs]);  % d.data.numInputs layers of data (one layer per input)

            for ii = 1:d.data.numInputs
                if d.data.inputDimension(ii) == 0                                               % If the input is singular (if it outputs just a number)
                    d.data.data{ii} = NaN([d.data.lengths 1]);                              % Then the layer is a numeric array of NaN.
                else                                                                            % Otherwise, if the input is more complex,
                    % Changed 9/13.
                    d.data.lengths
                    d.data.layerIndex
                    relevantLengths = d.data.lengths(d.data.layerIndex == 0 | d.data.layerIndex == ii);

                    d.data.data{ii} = NaN([relevantLengths 1]);
                        
%                         d.data.data{ii} = cell([d.data.lengths 1]);                             % Then the layer is a cell array containing...
%                         d.data.data{ii}(:) = {NaN(d.data.inputs{ii}.config.kind.sizeInput)};    % ...numeric arrays of NaN corresponding to the input's dimension.
                end
            end

            d.data.index =          ones(1, d.data.numAxes);
            d.data.currentIndex =   2;
            if ~isempty(d.data.index)
                d.data.index(1) =       d.data.lengths(1);
            end
            
            d.data.fnameManual =        mcInstrumentHandler.timestamp(0);
            d.data.fnameBackground =    mcInstrumentHandler.timestamp(1);
            
%             a = d.data.fnameManual
%             b = d.data.fnameBackground
                
            d.data.scanMode = 0;
        end
        
        function aquire(d)
            d.data.aquiring = true;
            d.data.scanMode = 1;

            nums = 1:d.data.numAxes;

            if all(isnan(d.data.axisPrev))  % If the previous positions of the axes have not already been set...
                for ii = nums               % For every axis,
                    d.data.axisPrev(ii) = d.data.axes{ii}.getX();               % Remember the pre-scan positions of the axes.
                    d.data.axes{ii}.goto(d.data.scans{ii}(d.data.index(ii)));   % And goto the starting position.
                end
                
                for ii = nums               % Then, again for every axis,
                    d.data.axes{ii}.wait(); % Wait for the axis to reach the starting position (only relevant for micros/etc).
                end
            end
            
            if d.data.aquiring
                if d.data.canScanFast && (~isfield(d.data, 's') || isempty(d.data.s))     % If neccessary, then make a NIDAQ session if it has not already been created.
%                     disp('Creating Session')
                    d.data.s = daq.createSession('ni');
                    
                    d.data.axes{1}.close();
                    d.data.axes{1}.addToSession(d.data.s);            % First add the axis,

                    for ii = 1:d.data.numInputs
                        d.data.inputs{ii}.addToSession(d.data.s);     % Then add the inputs
                    end
                    
                    d.data.s
                end 
            end
            
            while d.data.aquiring
                d.aquire1D(d.data.indexWeight * (d.data.index -1)' - d.data.index(1) + 2);
%                 drawnow limitrate;
                
                if all(d.data.index == d.data.lengths)  % If the scan has finished...
                    d.data.scanMode = 2;
                    break;
                end

                currentlyMax =  d.data.index == d.data.lengths;                 % Variables to figure out which indices need incrimenting/etc.
                toIncriment =   [false currentlyMax(1:end-1)] & ~currentlyMax;
                toReset =       [false currentlyMax(1:end-1)] &  currentlyMax;
                
                if ~d.data.aquiring                     % If the scan was stopped...
%                     if d.data.scanMode == 1     % If stopping was unexpected...
%                         d.data.scanMode = 3;
%                     end
                    break;
                end
                
                if d.data.timeIsAxis && toIncriment(end)    % If the last axis is time and we have run out of bounds,...
                    for ii = 1:d.data.numInputs         % ...for every input, circshift the data forward one.
                        if isnan(d.data.inputDimension(ii)) || d.data.inputDimension(ii) == 0   % If the data is contained in the cell or contained in one index of a numeric array,
                            circshift(d.data.data{ii}, [0, d.data.indexWeight(end)]);  	
                        else                                                                    % Otherwise, if the data is long (e.g. a vector), we need to circshift by more:
                            circshift(d.data.data{ii}, [0, d.data.indexWeight(end)*d.data.inputLength(ii)]);
                        end
                    end
                    
                    toIncriment(end) = false;   % and pretend that the time axis does not need to be incrimented.
                end

                d.data.index = d.data.index + toIncriment;  % Incriment all the indices that were after a maximized index and not maximized.
                d.data.index(toReset) = 1;                  % Reset all the indices that were maxed (except the first) to one.
                
                for ii = nums(toIncriment | toReset)
                    d.data.axes{ii}.goto(d.data.scans{ii}(d.data.index(ii)));
                end
            end
            
            if d.data.canScanFast   % Destroy the session, if a session was created.
                release(d.data.s);
                delete(d.data.s);
                d.data.s = [];
            end 
            
            if d.data.shouldOptimize        % If there should be a post-scan optimization...
                switch length(d.data.axes)
                    case 1
                        [x, ~] = mcPeakFinder(d.data.data{1}, d.data.scans{1}, 0);  % First find the peak.
                        
                        d.data.axes{1}.goto(d.data.scans{1}(1));    % Approaching from the same direction...
                        
                        d.data.axes{1}.goto(x);                     % ...goto the peak.
                    case 2
                        [x, y] = mcPeakFinder(d.data.data{1}, d.data.scans{1}, d.data.scans{2});    % First find the peak.
                        
                        d.data.axes{1}.goto(d.data.scans{1}(1));    % Approaching from the same direction...
                        d.data.axes{2}.goto(d.data.scans{2}(1));
                        
                        d.data.axes{1}.goto(x);                     % ...goto the peak.
                        d.data.axes{2}.goto(y);
                    otherwise
                        display('optimization on more than 2 axes not currently supported...');
                end 
            elseif d.data.scanMode == 2     % Should the axes goto the original values after the scan finishes?
                for ii = nums
                    d.data.axes{ii}.goto(d.data.axisPrev(ii));  % Then goto the stored previous values.
                end
            end
        end
        function aquire1D(d, jj)

            if d.data.canScanFast
                d.data.s.Rate = 1/max(d.data.integrationTime);   % Whoops; integration time has to be the same for all inputs... Taking the max for now...
                
                d.data.s.queueOutputData([d.data.scansInternalUnits{1}  d.data.scansInternalUnits{1}(end)]');   % The last point (a repeat of the final params.scan point) is to count for the last pixel (counts are differences).
                
%                 d.data.s
%                 d.data.axes{1}
                
                d.data.s

                [data_, times] = d.data.s.startForeground();                % Should I startBackground() and use a listener?

                kk = 1;

                for ii = 1:d.data.numInputs     % Fill all of the inputs with data...
                    if d.data.inputs{ii}.config.kind.shouldNormalize  % If this input expects to be divided by the exposure time...
%                             jj:jj+d.data.lengths(1)-1
%                             (diff(double(data_(:, kk)))./diff(double(times)))'
                        d.data.data{ii}(jj:jj+d.data.lengths(1)-1) = (diff(double(data_(:, kk)))./diff(double(times)))';   % Should measurment time be saved also? Should I do diff beforehand instead of individually?
                    else
                        d.data.data{ii}(jj:jj+d.data.lengths(1)-1) = double(data_(1:end-1, kk))';
                    end

                    kk = kk + 1;
                end
            elseif strcmpi(d.data.axes{end}, 'time')  % If time happens to be the last axis...
                while d.data.aquiring
                    % Aquire the data.
                    for ii = 1:d.data.numInputs         % ...for every input...
                        if isnan(d.data.inputDimension(ii))
                            d.data.data{ii}{jj+kk} = d.data.inputs{ii}.measure(d.data.integrationTime(ii));  % ...measure.
                        elseif d.data.inputDimension(ii) == 0
                            d.data.data{ii}(jj+kk) = d.data.inputs{ii}.measure(d.data.integrationTime(ii));  % ...measure.
                        else
                            base = (jj+kk)*d.data.inputLength(ii);
                            d.data.data{ii}(base:base+d.data.inputLength(ii)-1) = d.data.inputs{ii}.measure(d.data.integrationTime(ii));  % ...measure.
                        end
                    end
                end
            else
                kk = 0;

                for x = d.data.scans{1}                 % Now take the data.
                    if d.data.aquiring
                        d.data.axes{1}.goto(x);             % Goto each point...
                        d.data.axes{1}.wait();              % ...wait for the axis to arrive (for some types)...

                        for ii = 1:d.data.numInputs         % ...for every input...
                            if isnan(d.data.inputDimension(ii))
                                d.data.data{ii}{jj+kk} = d.data.inputs{ii}.measure(d.data.integrationTime(ii));  % ...measure.
                            elseif d.data.inputDimension(ii) == 0
                                d.data.data{ii}(jj+kk) = d.data.inputs{ii}.measure(d.data.integrationTime(ii));  % ...measure.
                            else
                                base = (jj+kk)*d.data.inputLength(ii);
                                d.data.data{ii}(base:base+d.data.inputLength(ii)-1) = d.data.inputs{ii}.measure(d.data.integrationTime(ii));  % ...measure.
                            end
                        end

                        kk = kk + 1;
                    end
                end
            end
        end
%         
%         function incriment()
%             
%         end
%         
%         function aquire1DListener()
%             
%         end
    end
end




