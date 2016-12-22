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
        %  - upSpeed
        %  - downSpeed
        
        function config = defaultConfig()
            config = mciPLE.PLEConfig(636, 637, 1000, 1, 4);
        end
        function config = PLEConfig(xMin, xMax, upPixels, upSpeed, downSpeed)
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

            config.axes.red =       mcaDAQ(mcaDAQ.redConfig());
            config.axes.green =     mcaDAQ(mcaDAQ.greenConfig());
            
            config.counter =        mciDAQ(mciDAQ.counterConfig());
            
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
            
            m = min(config.axes.red.extRange);
            M = max(config.axes.red.extRange);
            
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
            
            % Error checks on upSpeed and Downspeed
            if upSpeed == 0
                error('mciPLE.PLEConfig(): upSpeed is zero! We will never get there on time...');
            elseif upSpeed < 0
                upSpeed = -upSpeed;
            end
            if downSpeed == 0
                error('mciPLE.PLEConfig(): downSpeed is zero! We will never get there on time...');
            elseif downSpeed < 0
                downSpeed = -downSpeed;
            end
            
            config.upSpeed =    upSpeed;
            config.downSpeed =  downSpeed;
            
            config.upPixels =   upPixels;
            config.downPixels = round(upPixels*downSpeed/upSpeed);
            
            config.kind.sizeInput =    [1 upPixels + config.downPixels];
            
            config.output = [[linspace(xMin, xMax, upPixels) linspace(xMax, xMin, config.downPixels + 1)]' [zeros(1, upPixels) ones(1, config.downPixels + 1)]'];    % One extra point for diff'ing.
            config.xaxis =  linspace(xMin, xMax + (xMax - xMin)*config.downPixels/upPixels, upPixels + config.downPixels);  % x Axis with fake units
        end
    end
    
    methods
        function I = mciPLE(varin)
            I.extra = {'xMin', 'xMax', 'upPixels', 'upSpeed'};
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
            tf = I.config.axes.red      == b.config.axes.red && ... % ...then check if all of the other variables are the same.
                 I.config.axes.green    == b.config.axes.green && ...
                 I.config.counter       == b.config.counter;
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
            
            I.config.counter.addToSession(I.s);
            
            I.config.axes.red.addToSession(I.s);
            I.config.axes.green.addToSession(I.s);
            
            I.s.Rate = 1/upspeed;
        end
        function Close(I)
%             I.config.axes.red.close();
            
            release(I.s);
        end
        
        % MEASURE
        function data = MeasureEmulation(I, ~)
            data = [3+rand(1, I.config.upPixels) 10+2*rand(1, I.config.downPixels)];
        end
        function data = Measure(I, ~)
            I.s.queueOutputData(I.config.output');
%             I.config.axes.red.scanOnce(I.config.xMin, I.config.xMax, I.config.upSpeed, I.config.downSpeed)
            [d, t] = startForeground(I.s);  % Fix timing?
            
            data = (diff(d)./diff(t))';
        end
    end
end




