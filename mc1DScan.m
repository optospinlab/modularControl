function [data, params] = mc1DScan(params)
% mc1DScan scans across some axis, reading data from some array of inputs
% at each point or at the beginning and end of each scan.
%
% Syntax:
%
% [data, params] = mc1DScan(params)     % params contains all of the data parameters. Some of these 
%                                       %   parameters will be calculated (if they have not been 
%                                       %   already) by the program. The final params structure is
%                                       %   returned along with the data taken by the scan. 
%                                       % data.data is a cell array with dimension equivalent to the 
%                                       %   number of inputs given. If an input isSingular (if it 
%                                       %   reads a number, apposed to a vector/etc), then the  
%                                       %   content of the particular input cell is a numeric array 
%                                       %   with length equivalent to the length of the scan.  
%                                       %   Otherwise, the input cell is filled with another cell  
%                                       %   array (of length scanlength) which is filled with the  
%                                       %   non-singular data for each point.
%                                       % data.begin and data.end are also cell arrays, but with only one
%                                       %   data point in each input cell.
%                                       % If an input is, say, 'beginend', then its index in data.data 
%                                       %   is left as a singular NaN.
%
% VARIABLE                          TYPE        DESCRIPTION
% Variables needed:
%   - params.axis                   mcAxis      % The axis that will be scanned across.
%   - params.scan                   vector      % The data that will be scanned (e.g. [0 .25 .5 .75 1] is a scan from 0 to 1). This should be in external units.
%   - params.inputs                 cell        % The mcInput() objects that will be read either at...
%   - params.inputTypes (optional)  cell        % ...every point of the scan (if inputTypes{ii} == 1 or 'everypoint')... ...or only the begining and end of the scan (if inputTypes{ii} == 0 or 'beginend'). Note if this is left empty, every input will be assumed to be 'everypoint'.
%   - params.integrationTime        double      % Time spent integrating each input in seconds (i.e. if you have 5 non-NIDAQ inputs, then you will spend 5*params.integrationTime at each point of the scan)
%   - params.dataAvailibleHandle    function    % (Unused at moment)
%   - params.dontScan               boolean     % Set this to false if the calculation of the below variables is the desired result. Set to true if the scan should actually occur.
%
% Variables that will be filled by the program (don't you dare touch them):
%   - params.isInputSingular        boolean     % Self-explainitory
%   - params.isInputNIDAQ           boolean     %         "
%   - params.isInputBeginEnd        boolean     %         "
%   - params.canScanFast            boolean     % If all of the inputs and the axis are NIDAQ, then one can use daq methods to scan faster.
%   - params.numBeginEnd            integer     % Number of inputs in 'beginend' mode.
%   - params.numInputs              integer     % Number of inputs overall.
    
    if ~isfield(params, 'isInputSingular')      % If the variables that will be filled have not been calculated yet...
        params.isInputSingular =    false(1, params.numInputs);     % Make empty lists for future filling.
        params.isInputNIDAQ =       false(1, params.numInputs);
        params.isInputBeginEnd =    false(1, params.numInputs);
        
        params.numInputs = length(params.inputs);
        
        for ii = 1:params.numInputs                                 % Fill the empty lists
            params.isInputSingular(ii) =    sum(params.inputs{ii}.config.sizeInput > 1) > 0;
            
            params.isInputNIDAQ(ii) =       strcmpi('nidaq', params.inputs{ii}.config.kind.kind(1:5));
            
            if isfield(params, 'inputTypes')    
                switch lower(params.inputTypes{ii})
                    case {'everypoint', 1}      % The input is aquired at every point during the scan.
                        params.isInputBeginEnd(ii) = true;
                    case {'beginend', 0}     % The input is aquired only at the beginning and ending of the scan.
                        params.isInputBeginEnd(ii) = false;
                end
            else
                params.isInputBeginEnd(ii) = true;
            end
        end
            
        if all(params.isInputBeginEnd)
            error('Only begin and end to measure...');
        end

        allInputsNIDAQ = all(params.isInputBeginEnd | params.isInputNIDAQ);       % Are all 'everypoint'-mode inputs NIDAQ?
        params.canScanFast = strcmp('nidaq', params.axis.config.type.kind(1:5)) && allInputsNIDAQ; % Is the axis NIDAQ?

        if params.canScanFast && ~isfield(params, 's')     % If so, then make a NIDAQ session if it has not already been created.
            params.s = daq.createSession('ni');

            params.axis.addToSession(s);                    % First add the axis,

            inputsNIDAQ = params.inputs(params.isInputNIDAQ);

            for ii = 1:length(inputsNIDAQ)
                inputsNIDAQ{ii}.addToSession(params.s);     % Then add the inputs.
            end
        end

        params.numBeginEnd = sum(params.isInputBeginEnd);
        
        params.scanInternalUnits = arrayfun(params.axis.config.ext2intConv, params.scan);
    end
    
    if ~params.dontScan
        if params.numBeginEnd > 0                   % If there are some inputs on 'beginend'-mode...
            data.begin = cell(1,params.numInputs);     % ...then make the structure that will store the data.

            for ii = 1:params.numInputs                % ...and fill the structure with data...
                if params.isInputBeginEnd(ii)
                    data.begin{ii} = params.inputs{ii}.measure(params.integrationTime);   % Should measurment time be saved also?
                else
                    data.begin{ii} = NaN;           % ...inputs on 'everypoint'-mode are set to NaN.
                end
            end
        end

        if params.canScanFast
            data.data = cell(params.numInputs, 1); %NaN(params.numInputs, length(params.scan));

            params.s.Rate = 1/params.integrationTime;

            params.s.queueOutputData([params.scanInternalUnits  params.scanInternalUnits(end)]);   % The last point (a repeat of the final params.scan point) is to count for the last pixel.

            [data_, times] = params.s.startForeground();                % Should I startBackground() and use a listener?

            jj = 1;

            for ii = 1:params.numInputs     % Fill all of the inputs with data...
                if params.isInputBeginEnd(ii)
                    data.data{ii} = NaN;        % Inputs on 'beginend'-mode are set to NaN.
                else
                    if params.inputs{ii}.normalize  % If this input expects to be divided by the exposure time...
                        data.data{ii} = diff(double(data_(:, jj)))./diff(double(times));   % Should measurment time be saved also? Should I do diff beforehand instead of individually?
                    else
                        data.data{ii} = double(data_(1:end-1, jj));
                    end

                    jj = jj + 1;
                end
            end
        else
            data.data = cell(params.numInputs, 1);  % Initialize the data structure
            
            for ii = 1:params.numInputs             % Fill it with structures of the appropriate size and type.
                if params.isInputBeginEnd(ii)
                    data.data{ii} = NaN;
                else
                    if params.isInputSingular(ii)
                        data.data{ii} = NaN(1, length(params.scan));
                    else
                        data.data{ii} = cell(1, length(params.scan));
                    end
                end
            end

            jj = 1;

            for x = params.scan                     % Now take the data.
                params.axis.goto(x);                % Goto each point...
                params.axis.wait();                 % ...wait for the axis to arrive (for some types)...

                for ii = 1:params.numInputs         % ...for every input...
                    if ~params.isInputBeginEnd(ii)
                        if params.isInputSingular(ii)
                            data.data{ii}(jj) = params.inputs{ii}.measure(params.integrationTime);  % ...measure.
                        else
                            data.data{ii}{jj} = params.inputs{ii}.measure(params.integrationTime);  % ...measure.
                        end
                    end
                end

                jj = jj + 1;
            end
        end

        if params.numBeginEnd > 0                   % If there are some inputs on 'beginend'-mode...
            data.end = cell(1,params.numInputs);       % ...then make the structure that will store the data.

            for ii = 1:params.numInputs                % ...and fill the structure with data...
                if params.isInputBeginEnd(ii)
                    data.end{ii} = params.inputs{ii}.measure(params.integrationTime);     % Should measurment time be saved also?
                else
                    data.end{ii} = NaN;             % ...inputs on 'everypoint'-mode are set to NaN.
                end
            end
        end
    else
        params.dontScan = false;                    % Set params such that it will scan the next time.
    end
end




