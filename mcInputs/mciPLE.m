classdef mciPLE < mcInput
% mciDAQ is the subclass of mcInput that manages all NIDAQ devices. This includes:
%  - generic digital, analog, and counter outputs.

%     properties
%         xMin = 636;
%         xMax = 637;
% 
%         upSpeed =    1;
%         downSpeed =  4;
% 
%         upPixels =   1000;
%         downPixels = 250;
%     end

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
            config = mciTemplate.PLEConfig(636, 637, 1000, 1, 4);
        end
        function config = PLEConfig(xMin, xMax, upPixels, upSpeed, downSpeed)
            config.name = 'PLE ';

            config.kind.kind =          'PLE';
            config.kind.name =          'PLE';
            config.kind.extUnits =      'cts/sec';          % 'External' units.
            config.kind.shouldNormalize = true;             % If this variable is flagged, the measurement is subtracted from the previous and is divided by the time spent on a pixel. Not that this is done outside the measurement currently in mcData (individual calls to .measure() will not have this behavior currently)
            
            config.axes.red =       mcaNFLaser();
            
            greenConfig = mcaDAQ.digitalConfig(); 
            greenConfig.dev =           'Dev1';
            greenConfig.chn =           'Port0/Line0';
            config.axes.green =     mcaDAQ(greenConfig);
            
            config.counter =        mciDAQ(mciDAQ.counterConfig());
            
            config.xMin =       xMin;
            config.xMax =       xMax;
            
            config.upSpeed =    upSpeed;
            config.downSpeed =  downSpeed;
            
            config.upPixels =   upPixels;
            config.downPixels = round(upPixels*downSpeed/upSpeed);
            
            config.kind.sizeInput =    [1 upPixels + config.downPixels];
            
            config.output = [zeros(1, upPixels) ones(1, config.downPixels + 1)];    % One extra point for diff'ing.
            config.xaxis =  [linspace(xMin, xMax, upPixels) linspace(xMax, xMax + (xMax - xMin)*downPixels/upPixels, downPixels)];
        end
    end
    
    methods
        function I = mciPLE(varin)
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
                 I.config.axes.green    == b.config.axes.green;
        end
        
        % NAME
        function str = NameShort(I)
            % This is the reccommended a.nameShort().
            str = [I.config.name ' (' I.config.axes.red.name() ':' I.config.axes.green.name() ')'];
        end
        function str = NameVerb(I)
            str = [I.config.name ' ( with red laser ' I.config.axes.red.name() ' and green laser ' I.config.axes.green.name() ')'];
        end
        
        % OPEN/CLOSE
        function Open(I)
            I.config.axes.red.open();
            
            I.s = daq.createSession('ni');
            I.config.counter.addToSession(I.s);
            I.config.axes.green.addToSession(I.s);
        end
        function Close(I)
            I.config.axes.red.close();
            
            release(I.s);
        end
        
        % MEASURE
        function data = MeasureEmulation(I, ~)
            data = [3+rand(1, I.config.upPixels) 10+2*rand(1, I.config.downPixels)];
        end
        function data = Measure(I, ~)
            I.s.queueOutputData(I.config.output);
            I.config.axes.red.scanOnce(config.xMin, config.xMax, config.upSpeed, config.downSpeed)
            [d, t] = startForeground(I.s);  % Fix timing?
            
            data = diff(d)./diff(t);
        end
    end
end




