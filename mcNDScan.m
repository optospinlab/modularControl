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




