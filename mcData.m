classdef mcData < mcSavableClass
% mcData is an object that encapsulates our generic data structure. This allows the same data structure to be used by multiple
%   classes. For instance, the same mcData can be used by multiple mcProcessedDatas.
%
% Syntax:
%   d = mcData()
%   d = mcData(params)                                                              % Load old data (or just params if uninitialized) into this class
%   d = mcData('params.mat')                                                        % Load old data (from a .mat) into this class
%   d = mcData(axes_, scans, inputs, integrationTime)                               % Load with cell arrays axes_ (contains the mcAxes to be used), scans (contains the paths, in numeric arrays, for these axes to take... e.g. linspace(0, 10, 50) is one such path from 0 -> 10 with 50 steps), and inputs (contains the mcInputs to be measured at each point). Also load the numeric array integration time (in seconds) which denotes (when applicable) how much time is spent measuring each input.
%   d = mcData(axes_, scans, inputs, integrationTime, inputTypes)                   % In addition, inputTypes is a cell array defining whether each corresponding input should only be sampled at the begining and end of each scan or not. e.g. [1 0 1 0 0] means that all inputs except for the first and center will only be sampled at the beginning and end of each scan.
%   d = mcData(axes_, scans, inputs, integrationTime, inputTypes, shouldOptimize)   % In addition to the previous, shouldOptimize tells the mcData to optimize after finishing or not (only works for 1D and 2D scans with singular data) 
%
% Status: Mosly finished and commented. Loading needs finished.

    properties (SetObservable)
        data = [];                  % Our generic data structure.
    end

    properties
        dataViewer = [];            % 'Pointer' to the current data viewer.
%         isInitialized = false;      % Whether or not the computer-generated fields have been calculated.
        
%           These generated fields include:
%            - data.inputDimension         numeric array     % contains the number of dimensions that the data from each input has. e.g. a number would be 0, a vector 1, and an image 2.
%            - data.isInputNIDAQ           boolean array     % Self-explainitory
%            - data.isInputBeginEnd        boolean array     %         "
%            - data.inEmulation            boolean array     %         "
%            - data.canScanFast            boolean           % If all of the inputs and the axis are NIDAQ, then one can use daq methods to scan faster.
%
%            - data.numAxes                integer           % Number of axes overall.
%            - data.numInputs              integer           % Number of inputs overall.
%            - data.numBeginEnd            integer           % Number of inputs in 'beginend' mode.
%            - data.numNotBeginEnd         integer           % Number of inputs in 'everypoint' mode.
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
%            - data.plotMode               integer
%            - data.layer                  numeric array
%
%            - data.isInitialized          boolean
%            - data.scanMode               boolean
%
%            - data.shouldOptimize

    end
    
    methods (Static)
        function data = defaultConfiguration()
            configPiezoX = mcAxis.piezoConfig(); configPiezoX.name = 'Piezo X'; configPiezoX.chn = 'ao0';       % Customize all of the default configs...
            configPiezoY = mcAxis.piezoConfig(); configPiezoY.name = 'Piezo Y'; configPiezoY.chn = 'ao1';
            configPiezoZ = mcAxis.piezoConfig(); configPiezoZ.name = 'Piezo Z'; configPiezoZ.chn = 'ao2';
            
            configCounter = mcInput.counterConfig(); configCounter.name = 'Counter'; configCounter.chn = 'ctr0';
            
            data.axes =     {mcAxis(configPiezoX), mcAxis(configPiezoY), mcAxis(configPiezoZ)};                 % Fill the...   ...axes...
            data.scans =    {linspace(-10,10,21), linspace(-10,10,21), linspace(-10,10,2)};                     %               ...scans...
            data.inputs =   {mcInput(configCounter)};                                                           %               ...inputs.
            data.integrationTime = .005;
        end
        function data = optimizeConfiguration(axis, input, range, pixels, seconds)
            center = axis.getX();
            
            scan = linspace(center - range/2, center + range/2, pixels);
            scan = scan(scan <= max(axis.config.kind.extRange) & scan >= min(axis.config.kind.extRange));  % Truncate the scan.
            
            data.axes =     {axis};                     % Fill the...   ...axis...
            data.scans =    {scan};                     %               ...scan...
            data.inputs =   {input};                    %               ...input.
            data.integrationTime = seconds/pixels;
            data.shouldOptimize = true;
        end
        function str = README()
            str = ['This is a scan of struct.numInputs inputs over the struct.scans of struct.numAxes axes. '...
                   'struct.data is a cell array with a cell for each input. Inside each cell is the result of '...
                   'the measurement of that input for each point of the ND grid formed by the scans of the axes. '...
                   'If the measurement is singular (i.e. just a number like a voltage measurement), then the '...
                   'contents of the input cell is a numeric array with dimensions corresponding to the lengths of '...
                   'struct.scans. If the measurement is more complex (e.g. a vector like a spectra), then the'...
                   'contents of the input cell is a cell array with dimensions corresponding to the lengths of '...
                   'struct.scans. There also is the option to have an input only aquire data at the beginning and '...
                   'end of each 1D scan.'];
        end
    end
    
    methods
        function d = mcData(varin)
            switch nargin
                case 0
                    d.data = mcData.defaultConfiguration();     % If no vars are given, assume a 10x10um piezo scan centered at zero.
                case 1
                    if ischar(varin)
                        error('Unfinished');
%                         d.data = load(varin); % Unfinished!
                    else
                        d.data = varin;
                    end
                case 4
                    d.data.axes =               varin{1};               % Otherwise, assume the three variables are axes, scans, inputs...
                    d.data.scans =              varin{2};
                    d.data.inputs =             varin{3};
                    d.data.integrationTime =    varin{4};
                case 5
                    d.data.axes =               varin{1};               % And if a 4th var is given, assume it is inputTypes
                    d.data.scans =              varin{2};
                    d.data.inputs =             varin{3};
                    d.data.integrationTime =    varin{4};
                    d.data.inputTypes =         varin{5};
                case 5
                    d.data.axes =               varin{1};               % And if a 5th var is given, assume it is optimize
                    d.data.scans =              varin{2};
                    d.data.inputs =             varin{3};
                    d.data.integrationTime =    varin{4};
                    d.data.inputTypes =         varin{5};
            end
            
            d.initialize();
        end
        
        function save(d, fname)
            switch (lower(fname(end-2:end)))
                case 'mat'
                    save(fname, 'd.data');  % Not sure if this works.
                otherwise
                    error('Saving filetypes other than .mat NotImplemented');
            end
        end
        
        function initialize(d)
            if ~isfield(d.data, 'isInitialized')     % If not initialized, then intialize.
                d.data.README = d.README();
                
                %%% HANDLE THE INPUTS %%%
                d.data.numInputs = length(d.data.inputs);
                
                d.data.inputDimension =     zeros(1, d.data.numInputs);     % Make empty lists for future filling.
                d.data.isInputNIDAQ =       false(1, d.data.numInputs);
                d.data.isInputBeginEnd =    false(1, d.data.numInputs);
                d.data.inEnmulation =       false(1, d.data.numInputs);
                
                d.data.inputNames =         cell(1, d.data.numInputs);
                d.data.inputNamesUnits =    cell(1, d.data.numInputs);

                for ii = 1:d.data.numInputs                                 % Now fill the empty lists
                    d.data.inputDimension(ii) =    sum(d.data.inputs{ii}.config.kind.sizeInput > 1);

                    d.data.isInputNIDAQ(ii) =       strcmpi('nidaq', d.data.inputs{ii}.config.kind.kind(1:5));
                    
                    d.data.inEmulation(ii) =       d.data.inputs{ii}.inEmulation;

                    if isfield(d.data, 'inputTypes')                % If inputTypes is specified...
                        switch lower(d.data.inputTypes{ii})
                            case {'everypoint', 1}                  % If the input is aquired at every point during the scan.
                                d.data.isInputBeginEnd(ii) = true;
                            case {'beginend', 0}                    % If the input is aquired only at the beginning and ending of the scan.
                                d.data.isInputBeginEnd(ii) = false;
                        end
                    else
                        d.data.isInputBeginEnd(ii) = false;         % If inputTypes is not specified, then assume 'everypoint' mode.
                    end
                    
                    if d.data.isInputBeginEnd(ii)
                        d.data.inputNames{ii} =         [d.data.inputs{ii}.nameShort() ' (BeginEnd)'];  % Generate the name of the inputs in... ...e.g. 'name (dev:chn) (BeginEnd)' form
                        d.data.inputNamesUnits{ii} =    [d.data.inputs{ii}.nameUnits() ' (BeginEnd)'];  %                                            ...'name (units) (BeginEnd)' form
                    else
                        d.data.inputNames{ii} =         d.data.inputs{ii}.nameShort();  % Generate the name of the inputs in... ...e.g. 'name (dev:chn)' form
                        d.data.inputNamesUnits{ii} =    d.data.inputs{ii}.nameUnits();  %                                            ...'name (units)' form
                    end
                end

                if all(d.data.isInputBeginEnd)  % Pass an error if there isn't any input on everypoint mode (the user needs to rethink thier request).
                    error('At least one input must not be BeginEnd');
                end

                d.data.numBeginEnd =    sum(d.data.isInputBeginEnd);
                d.data.numNotBeginEnd = d.data.numInputs - d.data.numBeginEnd;

                %%% HANDLE THE AXES %%%
                d.data.numAxes =   length(d.data.axes);
                
                if ~isfield(d.data, 'plotMode')
                    d.data.plotMode = min(2, d.data.numAxes);
                    d.data.layer = ones(1, d.data.numAxes)*(1 + d.data.plotMode);
                    d.data.layer(1:min(d.data.plotMode, d.data.numAxes)) = 1:min(d.data.plotMode, d.data.numAxes);
                    
                    d.data.input = 1;
                end

                d.data.lengths =        zeros(1, d.data.numAxes);   % The length of 
                d.data.indexWeight =    ones(1,  d.data.numAxes);   % Index weight is best described by an example:
                                                                    %   If one has a 5x4x3 matrix, then incrimenting the x axis
                                                                    %   increases the linear index (the index if the matrix was
                                                                    %   streached out) by one. Incrimenting the y axis increases
                                                                    %   the linear index by 5. And incrimenting the z axis increases
                                                                    %   the linear index by 20 = 5*4. So the index weight in this case
                                                                    %   is [1 5 20].
                
                d.data.axisNames =         cell(1, d.data.numAxes);   % Same as input name generation above.
                d.data.axisNamesUnits =    cell(1, d.data.numAxes);
                d.data.axisPrev =          zeros(1, d.data.numAxes);

                for ii = 1:d.data.numAxes
                    d.data.lengths(ii) =            length(d.data.scans{ii});
                    
                    d.data.axisNames{ii} =         d.data.axes{ii}.nameShort();
                    d.data.axisNamesUnits{ii} =    d.data.axes{ii}.nameUnits();
                end
            
                if ~isfield(d.data, 'shouldOptimize')
                    d.data.shouldOptimize = false;
                end
                
                d.data.title = '';
                
                for ii = 1:d.data.numInputs
                    d.data.title = [d.data.title d.data.inputs{ii}.name() ', '];
                end
                
                d.data.title = [d.data.title ' vs'];
                
                for ii = 1:(d.data.numAxes-1)
                    d.data.title = [d.data.title d.data.axes{ii}.name() ', '];
                end
                
                d.data.title = [d.data.title d.data.axes{d.data.numAxes}.name()];

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

                allInputsFast = all(d.data.isInputBeginEnd | (d.data.isInputNIDAQ & ~d.data.inEmulation));       % Are all 'everypoint'-mode inputs NIDAQ?
                d.data.canScanFast = strcmpi('nidaq', d.data.axes{1}.config.kind.kind(1:5)) && ~d.data.axes{1}.inEmulation && allInputsFast;   % Is the first axis NIDAQ? If so, then everything important is NIDAQ if allInputsNIDAQ also.

                d.resetData();
                d.data.isInitialized = true;
            end
        end
        
        function resetData(d)
            %%% INITIALIZE THE DATA TO NAN %%%
            d.data.data =   cell([1, d.data.numInputs]);  % d.data.numInputs layers of data (one layer per input)
            d.data.begin =  cell([1, d.data.numInputs]);
            d.data.end =    cell([1, d.data.numInputs]);

            for ii = 1:d.data.numInputs
                if d.data.inputDimension(ii) == 0                                               % If the input is singular (if it outputs just a number)
                    if d.data.isInputBeginEnd(ii)    
                        d.data.begin{ii} = NaN([d.data.lengths(2:end) 1]);
                        d.data.end{ii} = NaN([d.data.lengths(2:end) 1]);
                    else
                        d.data.data{ii} = NaN([d.data.lengths 1]);                              % Then the layer is a numeric array of NaN.
                    end
                else                                                                            % Otherwise, if the input is more complex,
                    if d.data.isInputBeginEnd(ii)    
                        d.data.begin{ii} = cell([d.data.lengths(2:end) 1]);                     % Then the layer is a cell array containing...
                        d.data.begin{ii}(:) = {NaN(d.data.inputs{ii}.config.kind.sizeInput)};   % ...numeric arrays of NaN corresponding to the input's dimension.
                        d.data.end{ii} = cell([d.data.lengths(2:end) 1]);                       % Then the layer is a cell array containing...
                        d.data.end{ii}(:) = {NaN(d.data.inputs{ii}.config.kind.sizeInput)};     % ...numeric arrays of NaN corresponding to the input's dimension.
                    else
                        d.data.data{ii} = cell([d.data.lengths 1]);                             % Then the layer is a cell array containing...
                        d.data.data{ii}(:) = {NaN(d.data.inputs{ii}.config.kind.sizeInput)};    % ...numeric arrays of NaN corresponding to the input's dimension.
                    end
                end
            end

            d.data.index =          ones(1, d.data.numAxes);
            d.data.currentIndex =   2;
            d.data.index(1) =       d.data.lengths(1);
                
            d.data.scanMode = 0;
        end
        
        function aquire(d)
%             if isfield(d.data, 'isFinished')
%                 shouldContinue = ~d.data.isFinished;
%             else
%                 shouldContinue = true;
%             end

            d.data.aquiring = true;
            d.data.scanMode = 1;
            
            if d.data.aquiring % shouldContinue
                %%% CREATE THE SESSION, IF NECCESSARY %%%
                if d.data.canScanFast && (~isfield(d.data, 's') || isempty(d.data.s))     % If so, then make a NIDAQ session if it has not already been created.
                    
%                     disp('Creating Session')
                    d.data.s = daq.createSession('ni');

                    d.data.axes{1}.addToSession(d.data.s);            % First add the axis,

%                     inputsNIDAQ = d.data.inputs(d.data.isInputNIDAQ);

%                     for ii = 1:length(inputsNIDAQ)
%                         inputsNIDAQ{ii}.addToSession(d.data.s);     % Then add the inputs.
%                     end

                    for ii = 1:d.data.numInputs  
                        if ~d.data.isInputBeginEnd(ii)
                            d.data.inputs{ii}.addToSession(d.data.s);     % Then add the non-beginend inputs.
                        end
                    end
                end 
            end
            
            jj = [];

            nums = 1:d.data.numAxes;

            for ii = nums
                d.data.axisPrev(ii) = d.data.axes{ii}.getX();
                d.data.axes{ii}.goto(d.data.scans{ii}(d.data.index(ii)));
            end
            
            while d.data.aquiring
                d.aquire1D(d.data.indexWeight * (d.data.index -1)' - d.data.index(1) + 2);
                drawnow limitrate;
                
                if all(d.data.index == d.data.lengths)
                    d.data.scanMode = 2;
%                     shouldContinue = false;
                    break;
                end

                currentlyMax =  d.data.index == d.data.lengths;
                toIncriment =   [false currentlyMax(1:end-1)] & ~currentlyMax;
                toReset =       [false currentlyMax(1:end-1)] &  currentlyMax;
                
                if ~d.data.aquiring
%                     if d.data.scanMode == 1     % If stopping was unexpected...
%                         d.data.scanMode = 3;
%                     end
                    break;
                end

                d.data.index = d.data.index + toIncriment;  % Incriment all the indices that were after a maximized index and not maximized.
                d.data.index(toReset) = 1;                  % Reset all the indices that were maxed (except the first) to one.

                for ii = [1 nums(toIncriment | toReset)]
                    d.data.axes{ii}.goto(d.data.scans{ii}(d.data.index(ii)));
                end
            end
            
            if d.data.shouldOptimize
%                 disp('begin opt');
%                 d.data.data{1}
                switch length(d.data.axes)
                    case 1
                        [x, ~] = mcPeakFinder(d.data.data{1}, d.data.scans{1}, 0);
                        
                        d.data.axes{1}.goto(d.data.scans{1}(1));
                        
                        d.data.axes{1}.goto(x);
                    case 2
                        [x, y] = mcPeakFinder(d.data.data{1}, d.data.scans{1}, d.data.scans{2});
                        
                        d.data.axes{1}.goto(d.data.scans{1}(1));
                        d.data.axes{2}.goto(d.data.scans{2}(1));
                        
                        d.data.axes{1}.goto(x);
                        d.data.axes{2}.goto(y);
                end 
%                 disp('end opt');
            end
            
            if false
                for ii = nums
                    d.data.axes{ii}.goto(d.data.axisPrev(ii));
                end
            end
            
            %%% DESTROY THE SESSION, IF NECCESSARY %%%
            if d.data.canScanFast
                release(d.data.s);
                delete(d.data.s);
                d.data.s = [];
            end 
        end
        function aquire1D(d, jj)
            if d.data.numBeginEnd > 0                       % If there are some inputs on 'beginend'-mode...
                for ii = 1:d.data.numInputs                 % ...then aquire this data...
                    if d.data.isInputBeginEnd(ii)
                        d.data.begin{ii} = d.data.inputs{ii}.measure(d.data.integrationTime(ii));   % Should measurement time be saved also?
                    end
                end
            end

            if d.data.canScanFast
                d.data.s.Rate = 1/max(d.data.integrationTime);   % Whoops; integration time has to be the same for all inputs... Taking the max for now...

                d.data.s.queueOutputData([d.data.scansInternalUnits{1}  d.data.scansInternalUnits{1}(end)]');   % The last point (a repeat of the final params.scan point) is to count for the last pixel.

                [data_, times] = d.data.s.startForeground();                % Should I startBackground() and use a listener?

                kk = 1;

                for ii = 1:d.data.numInputs     % Fill all of the inputs with data...
                    if ~d.data.isInputBeginEnd(ii)
                        if d.data.inputs{ii}.config.kind.shouldNormalize  % If this input expects to be divided by the exposure time...
%                             jj:jj+d.data.lengths(1)-1
%                             (diff(double(data_(:, kk)))./diff(double(times)))'
                            d.data.data{ii}(jj:jj+d.data.lengths(1)-1) = (diff(double(data_(:, kk)))./diff(double(times)))';   % Should measurment time be saved also? Should I do diff beforehand instead of individually?
                        else
                            d.data.data{ii}(jj:jj+d.data.lengths(1)-1) = double(data_(1:end-1, kk))';
                        end

                        kk = kk + 1;
                    end
                end
            else
                kk = 0;

                for x = d.data.scans{1}                 % Now take the data.
                    d.data.axes{1}.goto(x);             % Goto each point...
                    d.data.axes{1}.wait();              % ...wait for the axis to arrive (for some types)...

                    for ii = 1:d.data.numInputs         % ...for every input...
                        if ~d.data.isInputBeginEnd(ii)
                            if d.data.inputDimension(ii) == 0
                                d.data.data{ii}(jj+kk) = d.data.inputs{ii}.measure(d.data.integrationTime(ii));  % ...measure.
                            else
                                d.data.data{ii}{jj+kk} = d.data.inputs{ii}.measure(d.data.integrationTime(ii));  % ...measure.
                            end
                        end
                    end

                    kk = kk + 1;
                end
            end

            if d.data.numBeginEnd > 0                       % If there are some inputs on 'beginend'-mode...
                for ii = 1:d.data.numInputs                 % ...then aquire this data...
                    if d.data.isInputBeginEnd(ii)
                        d.data.end{ii} = d.data.inputs{ii}.measure(d.data.integrationTime(ii));     % Should measurment time be saved also?
                    else
                        d.data.end{ii} = NaN;               % ...inputs on 'everypoint'-mode are set to NaN.
                    end
                end
            end
        end
    end
end




