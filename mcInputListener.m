function mcInputListener(varin)
    % mcInputListener is the equivalent of what was previously called
    % 'the counter'. It reads and plots data from a single mcInput. This is
    % unfinished.
    
    switch nargin
        case 0
            params.input = mcInstrumentHandler.register(mcInput());
            params.pixels = 100;
            params.exposure = .05;
        case 1
            params = varin;
        otherwise
            error('mcInputListener unfinished');
    end
    
    f = mcInstrumentHandler.createFigure(['mcInputListener - ' params.input.nameShort()]);
            
%     f.Resize =      'off';
%     f.Visible =     'off';
    f.MenuBar =     'none';
%     f.ToolBar =     'none';
    
    axes_ = axes(f, 'Position', [.1, 0, .9, 1]); %, 'Title', ['Listener - ' input.nameShort()]
    ylabel(axes_, params.input.nameUnits()); %
    
    dims = sum(params.input.config.kind.sizeInput > 1);
    
    if dims == 0
        p = plot(axes_, NaN(1, params.pixels));
    elseif dims == 1 && params.pixels == 0
        error('Viewing vector NotImplimented...');
        p = plot(axes_, NaN(1, max(params.input.config.kind.sizeInput)));
    elseif dims == 1
        error('Scrolling image NotImplimented...');
        p = image(axes_, NaN(max(params.input.config.kind.sizeInput), params.pixels));
    elseif dims == 2
        error('Viewing image NotImplimented...');
        p = image(axes_, NaN(params.input.config.kind.sizeInput));
    else
        error('The dimension of the input must be 0 (singular), 1 (vector), or 2 (image)');
    end
    
    p.UserData = params;
    
    p.UserData.prevTime = NaN;
    p.UserData.prevCount = NaN;
    
    axes_.XLimMode =        'manual';
    axes_.XLim =            [1, 100];
    axes_.YLabel.String =   params.input.nameUnits();
    
    isInputNIDAQ = strcmpi('nidaq', params.input.config.kind.kind(1:5));
    
    if ~params.input.config.kind.isSingular
        error('Non-singular inputs currently not supported.')
    end
    
    if isInputNIDAQ && ~params.input.inEmulation
        s = daq.createSession('ni');
        params.input.addToSession(s);   % For counters, need to add an input also...
        
        s.Rate =                                    1/params.exposure;
        s.isContinuous =                            true;
        s.IsNotifyWhenDataAvailableExceedsAuto =    false;
        s.NotifyWhenDataAvailableExceeds =          1;
        s.NumberOfScans =                           s.Rate;
        
        lh = addListener(s, 'DataAvailable', @getData);
        
        startBackground(s);
        
    else
        t = timer('TimerFcn', {@getData, p}, 'Period', params.exposure, 'ExecutionMode', 'fixedRate', 'TasksToExecute', Inf);
        start(t);
    end

end

function getData(src, event, p)
%     event
    
    if ~isvalid(p)
        stop(src);
        delete(src);
    else
        if isa(src, 'timer')
            data = p.UserData.input.measure(p.UserData.exposure);   % Not sure if exposing is the best decision...
        else
            src.NumberOfScans = 5;
            
            [d,t] = src.inputSingleScan();
            
            data = (d - p.UserData.prevCount)/(t - p.UserData.prevTime);
            
            p.UserData.prevCount = d;
            p.UserData.prevTime = t;
        end
        
        p.YData = [p.YData(2:end) data];
    end
end
% 
% function closeFigure(src, data, lh)
%     delete(src);
%     delete(lh);
% end


