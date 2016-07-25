classdef mcData < handle
% mcData is an object that encapsulates our generic data structure. This
%   allows the same data structure to be used by multiple classes.
%
% Syntax:
%   d = mcData()
%   d = mcData(data)                                                % Load old data into this class
%   d = mcData('data.mat')                                          % Load old data (from a .mat) into this class
%   d = mcData(axes_, scans, inputs, integrationTime)               % Load with cell arrays axes_ (contains the mcAxes to be used), scans (contains the paths, in numeric arrays, for these axes to take... e.g. linspace(0, 10, 50) is one such path from 0 -> 10 with 50 steps), and inputs (contains the mcInputs to be measured at each point). Also load the numeric array integration time (in seconds) which denotes (when applicable) how much time is spent measuring each input.
%   d = mcData(axes_, scans, inputs, integrationTime, inputTypes)   % In addition, inputTypes is a cell array defining whether each corresponding input should only be sampled at the begining and end of each scan or not. e.g. [1 0 1 0 0] means that all inputs except for the first and center will only be sampled at the beginning and end of each scan.
%

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
    end
    
    methods (Static)
        function data = defaultConfiguration()
            configPiezoX = mcAxis.piezoConfig(); configPiezoX.name = 'Piezo X'; configPiezoX.chn = 'ao0';       % Customize all of the default configs...
            configPiezoY = mcAxis.piezoConfig(); configPiezoY.name = 'Piezo Y'; configPiezoY.chn = 'ao1';
            configPiezoZ = mcAxis.piezoConfig(); configPiezoZ.name = 'Piezo Z'; configPiezoZ.chn = 'ao2';
            
            configCounter = mcInput.counterConfig(); configCounter.name = 'Counter'; configCounter.chn = 'ctr0';
            
            data.axes =     {mcAxis(configPiezoX), mcAxis(configPiezoY), mcAxis(configPiezoZ)};                 % Fill the...   ...axes...
            data.scans =    {linspace(-10,10,21), linspace(-10,10,21), linspace(-10,10,5)};                     %               ...scans...
            data.inputs =   {mcInput(configCounter)};                                                           %               ...inputs.
        end
        function str = README()
            str = ['This is a scan of struct.numInputs inputs over the struct.scans of struct.numAxes axes. '...
                   'struct.data is a cell array with a cell for each input. Inside each cell is the result of '...
                   'the measurement of that input for each point of the ND grid formed by the scans of the axes. '...
                   'If the measurement is singular (i.e. just a number like a voltage measurement), then the '...
                   'contents of the input cell is a numeric array. If the measurement is more complex (e.g. a '...
                   'vector like a spectra), then the contents of the input cell is a cell array.'];
        end
    end
    
    methods
        function d = mcData(varin)
%             d.isInitialized = false;
            
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
                    d.data.axes =               varin{1};                   % Otherwise, assume the three variables are axes, scans, inputs...
                    d.data.scans =              varin{2};
                    d.data.inputs =             varin{3};
                    d.data.integrationTime =    varin{4};
                case 5
                    d.data.axes =               varin{1};               % And if a 4th var is given, assume it is input types
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
                
                d.data.inputNames =         cell(1, d.data.numInputs);
                d.data.inputNamesUnits =    cell(1, d.data.numInputs);

                for ii = 1:d.data.numInputs                                 % Now fill the empty lists
                    d.data.inputDimension(ii) =    sum(d.data.inputs{ii}.config.kind.sizeInput > 1);

                    d.data.isInputNIDAQ(ii) =       strcmpi('nidaq', d.data.inputs{ii}.config.kind.kind(1:5));

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

                for ii = 1:d.data.numAxes
                    d.data.lengths(ii) =            length(d.data.scans{ii});
                    
                    d.data.axisNames{ii} =         d.data.axes{ii}.nameShort();
                    d.data.axisNamesUnits{ii} =    d.data.axes{ii}.nameUnits();
                end

                if d.data.numAxes > 2
                    for ii = 2:d.data.numAxes-1
                        d.data.indexWeight(ii+1:end) = d.data.indexWeight(ii+1:end)*d.data.lengths(ii);
                    end
                end

                d.data.indexWeight(1) = 0;
                
                for ii = 1:d.data.numAxes                                 % Fill the empty lists
                    d.data.scansInternalUnits{ii} = arrayfun(d.data.axes{ii}.config.kind.ext2intConv, d.data.scans{ii});
                end

                allInputsNIDAQ = all(d.data.isInputBeginEnd | d.data.isInputNIDAQ);       % Are all 'everypoint'-mode inputs NIDAQ?
                d.data.canScanFast = strcmp('nidaq', d.data.axes{1}.config.kind.kind(1:5)) && allInputsNIDAQ; % Is the first axis NIDAQ? If so, then everything important is NIDAQ if allInputsNIDAQ also.

                %%% INITIALIZE THE DATA TO NAN %%%
                d.data.data =   cell([1, d.data.numInputs]);  % d.data.numInputs layers of data (one layer per input)
                d.data.begin =  cell([1, d.data.numInputs]);
                d.data.end =    cell([1, d.data.numInputs]);
                
                for ii = 1:d.data.numInputs
                    if d.data.inputDimension(ii) == 0                                               % If the input is singular (if it outputs just a number)
                        if d.data.isBeginEnd(ii)    
                            d.data.begin{ii} = NaN(d.data.lengths(2:end));
                            d.data.end{ii} = NaN(d.data.lengths(2:end));
                        else
                            d.data.data{ii} = NaN(d.data.lengths);                                  % Then the layer is a numeric array of NaN.
                        end
                    else                                                                            % Otherwise, if the input is more complex,
                        if d.data.isBeginEnd(ii)    
                            d.data.begin{ii} = cell(d.data.lengths(2:end));                         % Then the layer is a cell array containing...
                            d.data.begin{ii}(:) = {NaN(d.data.inputs{ii}.config.kind.sizeInput)};   % ...numeric arrays of NaN corresponding to the input's dimension.
                            d.data.end{ii} = cell(d.data.lengths(2:end));                           % Then the layer is a cell array containing...
                            d.data.end{ii}(:) = {NaN(d.data.inputs{ii}.config.kind.sizeInput)};     % ...numeric arrays of NaN corresponding to the input's dimension.
                        end
                            d.data.data{ii} = cell(d.data.lengths);                                 % Then the layer is a cell array containing...
                            d.data.data{ii}(:) = {NaN(d.data.inputs{ii}.config.kind.sizeInput)};    % ...numeric arrays of NaN corresponding to the input's dimension.
                        else
                            
                    end
                end
                
                %%% CREATE THE SESSION, IF NECCESSARY %%%
                if d.data.canScanFast && ~isfield(d.data, 's')     % If so, then make a NIDAQ session if it has not already been created.
                    d.data.s = daq.createSession('ni');

                    d.data.axes{1}.addToSession(s);                    % First add the axis,

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
                
                params.index =          ones(1, params.numAxes);
                params.currentIndex =   2;
                params.index(1) =       params.lengths(1);
                
                d.data.isInitialized = true;
            end
        end
        
        function aquire(d)
            while true  % Infinite loop problems? Better solution?
                if d.data.canScanFast
                    
                end
                
                jj = params.indexWeight .* (params.index - 1);

                if isempty(jj)                
                    jj = params.index(2);
                else
                    jj = params.index(2) + jj;
                end

                for ii = 1:params.numAxes
                    if params.isInputSingular(ii)
                        if params.isInputBeginEnd(ii)
                            data.begin{ii}(jj:jj+params.lengths(1)) =   data1D.begin{ii};
                            data.end{ii}(jj:jj+params.lengths(1)) =     data1D.end{ii};
                        else
                            data.data{ii}(jj:jj+params.lengths(1)) =    data1D.data{ii};
                        end
                    else
                        if params.isInputBeginEnd(ii)
                            data.data{ii} =     NaN;
                            data.begin{ii} =    cell(params.lengths(2:end));
                            data.end{ii} =      cell(params.lengths(2:end));
                        else
                            data.data{ii} =     cell(params.lengths);
                            data.begin{ii} =    NaN;
                            data.end{ii} =      NaN;
                        end
                    end

                    if params.isInputSingular(ii)
                        data.data{ii}(jj:jj+params.lengths(1)) = data1D.data{ii};   % Because we don't know our dimension, we must index linearly.
                    else
                        data.data{ii}{jj:jj+params.lengths(1)} = data1D.data{ii};
                    end
                end

                currentlyMax = params.index == params.lengths;
                toIncriment = [false currentlyMax(1:end-1)] & ~currentlyMax;
                currentlyMax(1) = false;

                params.index = params.index + toIncriment;  % Incriment all the indices that were after a maximized index and not maximized.
                params.index(currentlyMax) = 1;             % Reset all the indices that were maxed (except the first) to one.

                if all(params.index == params.lengths)
                    break;
                end
            end
        end
        
%         function tf = isPlottable(d)
%             tf = isfield(data, 'data');
%         end
    end
end

function [data, params] = mcNDScan(params)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

    %   - params.axes               cell containing mcAxis() objects
    %   - params.scans              cell containg vectors corresponding to the ranges of each of the axes.
    %   - params.inputs             cell containing mcInput() objects
    %   - params.inputTypes         cell, optional
    %   - params.integrationTime    double
    
%     PREV

    params.numAxes =   length(params.axes);
    
    params.lengths =        zeros(1, params.numAxes);
    params.indexWeight =    ones(1, params.numAxes);
    
    for ii = 1:params.numAxes
        params.lengths(ii) =            length(params.scans{ii});
    end
    
    if params.numAxes > 2
        for ii = 2:params.numAxes-1
            params.indexWeight(ii+1:end) = params.indexWeight(ii+1:end)*params.lengths(ii);
        end
    end
    
    params.indexWeight(1) = 0;
    
    
    params1D.axis =                 params.axes{1};
    params1D.scan =                 params.scans{1};
    params1D.inputTypes =           params.inputTypes;
    params1D.integrationTime =      params.integrationTime;
%     params1D.dataAvailibleHandle =  TBD
    params1D.dontScan =             true;                       % This variable is set to false when passed through mcmc1DScan(params)1DScan
    
    [~, params1D] = mc1DScan(params1D);                         % Calaculates the other variables without scanning.
    
    params.isInputSingular =    params1D.isInputSingular;
    params.isInputNIDAQ =       params1D.isInputNIDAQ;
    params.isInputBeginEnd =    params1D.isInputBeginEnd;
    params.numInputs =          params1D.numInputs;
    
    params.index =          ones(1, params.numAxes);
    params.currentIndex =   2;
    params.index(1) =       params.lengths(1);
    
    
    if all(params.index == params.lengths)
        data = mc1DScan(params1D);
    else
        data.axisNames =        cell(params.numAxes, 1);
        data.inputNames =       cell(params.numAxes, 1);
        
        for ii = 1:params.numAxes
            data.axisNames{ii} =    params.axes{ii}.nameShort();
            data.inputNames{ii} =   params.inputs{ii}.nameShort();
        end

        data.positionInfo = mcInstrumentHandler.getAxesState();
        data.range = params.scans;
    
        data.data = cell(params.numInputs, 1);

        for ii = 1:params.numAxes
            if params.isInputSingular(ii)
                if params.isInputBeginEnd(ii)
                    data.data{ii} =     NaN;
                    data.begin{ii} =    NaN(params.lengths(2:end));
                    data.end{ii} =      NaN(params.lengths(2:end));
                else
                    data.data{ii} =     NaN(params.lengths);
                    data.begin{ii} =    NaN;
                    data.end{ii} =      NaN;
                end
            else
                if params.isInputBeginEnd(ii)
                    data.data{ii} =     NaN;
                    data.begin{ii} =    cell(params.lengths(2:end));
                    data.end{ii} =      cell(params.lengths(2:end));
                else
                    data.data{ii} =     cell(params.lengths);
                    data.begin{ii} =    NaN;
                    data.end{ii} =      NaN;
                end
            end
        end
        
        while true  % Infinite loop problems? Better solution?
            dataID = mc1DScan(params1D);

            jj = params.indexWeight .* (params.index - 1);
            
            if isempty(jj)                
                jj = params.index(2);
            else
                jj = params.index(2) + jj;
            end

            for ii = 1:params.numAxes
                if params.isInputSingular(ii)
                    if params.isInputBeginEnd(ii)
                        data.begin{ii}(jj:jj+params.lengths(1)) =   data1D.begin{ii};
                        data.end{ii}(jj:jj+params.lengths(1)) =     data1D.end{ii};
                    else
                        data.data{ii}(jj:jj+params.lengths(1)) =    data1D.data{ii};
                    end
                else
                    if params.isInputBeginEnd(ii)
                        data.data{ii} =     NaN;
                        data.begin{ii} =    cell(params.lengths(2:end));
                        data.end{ii} =      cell(params.lengths(2:end));
                    else
                        data.data{ii} =     cell(params.lengths);
                        data.begin{ii} =    NaN;
                        data.end{ii} =      NaN;
                    end
                end
            
                if params.isInputSingular(ii)
                    data.data{ii}(jj:jj+params.lengths(1)) = data1D.data{ii};   % Because we don't know our dimension, we must index linearly.
                else
                    data.data{ii}{jj:jj+params.lengths(1)} = data1D.data{ii};
                end
            end
            
            currentlyMax = params.index == params.lengths;
            toIncriment = [false currentlyMax(1:end-1)] & ~currentlyMax;
            currentlyMax(1) = false;
            
            params.index = params.index + toIncriment;  % Incriment all the indices that were after a maximized index and not maximized.
            params.index(currentlyMax) = 1;             % Reset all the indices that were maxed (except the first) to one.
            
            if all(params.index == params.lengths)
                break;
            end
        end
    end
end







