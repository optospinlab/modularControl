classdef mciPLE < mcInput
% mciPLE takes one PLE scan when .measure() is called. Use mcData to take many PLE scans (e.g. mciPLE vs Time). Use mcePLE for
% automated PLE scans (taking spectrum first and aligning the laser with the ZPL in the spectrum).

    methods (Static)
        % Neccessary extra vars:
        %  - axes.red
        %  - axes.green
        %  - counter
        %  - xMin
        %  - xMax
        %  - upPixels
        %  - upTime
        %  - downTime
        
        function config = defaultConfig()
            config = mciPLE.PLEConfig(0, 2, 1000, 2, .25);
        end
        function config = PLEConfig(xMin, xMax, upPixels, upTime, downTime)
            config.class = 'mciPLE';
            
            config.name = 'PLE with NFLaser';

            config.kind.kind =          'PLE';
            config.kind.name =          'PLE with NFLaser';
            config.kind.extUnits =      'cts/sec';          % 'External' units.
            config.kind.shouldNormalize = true;             % If this variable is flagged, the measurement is subtracted from the previous and is divided by the time spent on a pixel. Not that this is done outside the measurement currently in mcData (individual calls to .measure() will not have this behavior currently)
            
%             config.axes.red =       mcaNFLaser();
            
%             greenConfig =           mcaDAQ.digitalConfig(); 
%             greenConfig.dev =       'Dev1';
%             greenConfig.chn =       'Port0/Line1';
%             config.axes.green =     mcaDAQ(greenConfig);

%             greenConfig =           mcaDAQ.analogConfig(); 
%             greenConfig.chn =       'ao3';
%             config.axes.green =     mcaDAQ(greenConfig);

            config.axes.red =       mcaDAQ.redConfig();
            config.axes.green =     mcaDAQ.greenConfig();
            
            config.counter =        mciDAQ.counterConfig();
            
%             xMin
%             xMax
            
            % Error checks on xMin and xMax:
            if xMin > xMax
                temp = xMin;
                xMin = xMax;
                xMax = temp;
                warning('mciPLE.PLEConfig(): xMin > xMax! Switching them.');
            end
            
            if xMin == xMax
                error('mciPLE.PLEConfig(): xMin == xMax! Cannot scan over zero range.');
            end
            
            m = min(config.axes.red.kind.intRange);
            M = max(config.axes.red.kind.intRange);
            
            if m > xMin
                xMin = m;
                warning('mciPLE.PLEConfig(): xMin below range of red freq axis.')
            end
            if M < xMax
                xMax = M;
                warning('mciPLE.PLEConfig(): xMax above range of red freq axis.')
            end
            
            if m > xMax
                error('mciPLE.PLEConfig(): xMax out of range');
            end
            if M < xMin
                error('mciPLE.PLEConfig(): xMin out of range');
            end
            
            config.xMin =       xMin;
            config.xMax =       xMax;
            
            % Error checks on upTime and downTime
            if upTime == 0
                error('mciPLE.PLEConfig(): upTime is zero! We will never get there on time...');
            elseif upTime < 0
                upTime = -upTime;
            end
            if downTime == 0
                error('mciPLE.PLEConfig(): downTime is zero! We will never get there on time...');
            elseif downTime < 0
                downTime = -downTime;
            end
            
            config.upTime =    upTime;
            config.downTime =  downTime;
            
            config.upPixels =   upPixels;
            config.downPixels = round(upPixels*downTime/upTime);
            
%             s = upPixels + config.downPixels
            config.kind.sizeInput =    [upPixels + config.downPixels, 1];
%             config.kind
            
            config.output = [[linspace(xMin, xMax, upPixels) linspace(xMax, xMin, config.downPixels + 1)]' [ones(1, upPixels) zeros(1, config.downPixels + 1)]'];    % One extra point for diff'ing.
            config.xaxis =  linspace(xMin, xMax + (xMax - xMin)*config.downPixels/upPixels, upPixels + config.downPixels);  % x Axis with fake units
        end
    end
    
    methods
        function I = mciPLE(varin)
            I.extra = {'xMin', 'xMax', 'upPixels', 'upTime'};
            if nargin == 0
                I.construct(I.defaultConfig());
            else
                I.construct(varin);
            end
            I = mcInstrumentHandler.register(I);
        end
        
        function axes_ = getInputAxes(I)
            axes_ = {I.config.xaxis};
        end
    end
    
    % These methods overwrite the empty methods defined in mcInput. mcInput will use these. The capitalized methods are used in
    %   more-complex methods defined in mcInput.
    methods
        % EQ
        function tf = Eq(I, b)  % Check if a foriegn object (b) is equal to this input object (a).
            tf = strcmpi(I.config.axes.red.name,    b.config.axes.red.name) && ... % ...then check if all of the other variables are the same.
                 strcmpi(I.config.axes.green.name,  b.config.axes.green.name) && ...
                 I.config.xMin == b.config.xMin && ...
                 I.config.xMax == b.config.xMax && ...
                 I.config.upPixels ==   b.config.upPixels && ...
                 I.config.downPixels == b.config.downPixels && ...
                 I.config.upTime ==     b.config.upTime && ...
                 I.config.downTime ==   b.config.downTime;
        end
        
        % NAME
        function str = NameShort(I)
            str = [I.config.name ' (' I.config.axes.red.name() ':' I.config.axes.green.name() ')'];
        end
        function str = NameVerb(I)
            str = [I.config.name ' (with red laser ' I.config.axes.red.name() ' and green laser ' I.config.axes.green.name() ')'];
        end
        
        % OPEN/CLOSE
        function Open(I)
%             I.config.axes.red.open();
            I.s = daq.createSession('ni');
            
            c = mciDAQ(I.config.counter);
            c.addToSession(I.s);
            
            r = mcaDAQ(I.config.axes.red);
            r.addToSession(I.s);
            g = mcaDAQ(I.config.axes.green);
            g.addToSession(I.s);
            
            I.s.Rate = I.config.upPixels/I.config.upTime;
        end
        function Close(I)
%             I.config.axes.red.close();
            
            release(I.s);
        end
        
        % MEASURE
        function data = MeasureEmulation(I, ~)
%             I.config.upPixels
%             I.config.downPixels
            data = [3+rand(I.config.upPixels, 1); 10+2*rand(I.config.downPixels, 1)];
%             size(data)
%             t = I.config.upTime + I.config.downTime
            pause(I.config.upTime + I.config.downTime);
        end
        function data = Measure(I, ~)
%             I.s
            I.s.queueOutputData(I.config.output);
%             I.config.axes.red.scanOnce(I.config.xMin, I.config.xMax, I.config.upTime, I.config.downTime)
            [d, t] = startForeground(I.s);  % Fix timing?
            
            data = (diff(d)./diff(t))';
            
            I.close();  % Inefficient, but otherwise mciPLE never gives the couter up...
        end
    end
end




