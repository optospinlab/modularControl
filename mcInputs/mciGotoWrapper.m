classdef mciGotoWrapper < mcInput
% mciGoto 
% Also see mcInput.

    methods (Static)    % The folllowing static configs are used to define the identity of input objects. configs can also be loaded from .mat files
        % Neccessary extra vars:
        %  - configs        % Cell array containing mcAxis configs.
        %  - positions      % Numeric array conatining the postions that the mcAxes should move to.
        %  - axesnames      % String containing the nameShort()s of all of the axes (generated in dataConfig()).
        
        function config = defaultConfig()               % Static config that should be used if no configuration is provided upon intialization.
            config = mciDataWrapper.dataConfig(mcData.defaultConfig()); 	% Make a mciDataWrapper wrapping the default mcData config.
        end
        function config = dataConfig(configs, positions)
            config.class = 'mciGotoWrapper';
            
            config.name = 'GotoWrapper';

            config.kind.kind =          'gotowrapper';
            config.kind.name =          'mcAxes Goto Wrapper';
            config.kind.extUnits =      'success/fail';
            config.kind.shouldNormalize = false;        % (Not sure if this is functional.) If this variable is flagged, the measurement is subtracted from the previous and is divided by the time spent on a pixel. Not that this is done outside the measurement currently in mcData (individual calls to .measure() will not have this behavior currently)
            
            if length(configs) ~= length(positions)
                error('mciGotoWrapper.dataConfig(configs, positions): configs and positions must have the same length.');
            end
            
            if isempty(configs)
                error('mciGotoWrapper.dataConfig([], []): There must be at least one axis to wrap...');
            end
            
            config.kind.sizeInput = [1, length(configs)];
            
            config.axesnames = '';
            
            for ii = 1:(length(configs) -1)
                config.axesnames = [config.axesnames configs{ii}.name ', '];
            end
            
            config.axesnames = [config.axesnames configs{end}.name];
            
            config.configs =    configs;      
            config.positions =  positions;
        end
        function config = pleModeConfig()
%             ghwpPLE =   213.1726;   % 80uW
%             ghwpOpt =   207.2705;   % 1.4mW

            apt = mcaAPT(mcaAPT.rotatorConfig());
            
            questdlg('Please rotate the green half-wave plate to the *PLE* position.', 'Please Rotate...', 'I Have Finished Rotating', 'I Have Finished Rotating');
            
            c = {mcaDAQ.redDigitalConfig(),     mcaAPT.rotatorConfig(),     mcaArduino.flipMirrorConfig()};
            p = [1,                             apt.getX(),                 1];
            
            config = mciGotoWrapper.dataConfig(c, p);
            
            config.name = 'PLE Mode';
        end
        function config = optModeConfig()
%             ghwpPLE =   213.1726;   % 80uW
%             ghwpOpt =   207.2705;   % 1.4mW

            apt = mcaAPT(mcaAPT.rotatorConfig());
            
            questdlg('Please rotate the green half-wave plate to the *optimization* position.', 'Please Rotate...', 'I Have Finished Rotating', 'I Have Finished Rotating');
            
            c = {mcaDAQ.redDigitalConfig(),     mcaAPT.rotatorConfig(),     mcaArduino.flipMirrorConfig()};
            p = [0,                             apt.getX(),                 1];
            
            config = mciGotoWrapper.dataConfig(c, p);
            
            config.name = 'Optimization Mode';
        end
        function config = specModeConfig()
            c = {mcaDAQ.redDigitalConfig(),     mcaArduino.flipMirrorConfig()};
            p = [0,                             0];
            
            config = mciGotoWrapper.dataConfig(c, p);
            
            config.name = 'Spectrometer Mode';
        end
    end
    
    methods             % Initialization method (this is what is called to make an input object).
        function I = mciGotoWrapper(varin)
            I.extra = {'configs', 'positions'};
            if nargin == 0
                I.construct(I.defaultConfig());
            else
                I.construct(varin);
            end
            I = mcInstrumentHandler.register(I);
            
            I.inEmulation = false;  % Never emulate.
        end
    end
    
    % These methods overwrite the empty methods defined in mcInput. These methods are used in the uncapitalized parent methods defined in mcInput.
    methods
        % NAME ---------- The following functions define the names that the user should use for this input.
        function str = NameShort(I)     % 'short' name, suitable for UIs/etc.
            str = [I.config.name ' (' I.config.axesnames ')'];
        end
        function str = NameVerb(I)      % 'verbose' name, suitable to explain the identity to future users.
            str = [I.config.name ' (an mciDataWrapper wrapping ' I.config.axesnames ')'];
        end
        
        %EQ ------------- The function that should return true if the custom vars are the same (future: use i.extra for this?)
        function tf = Eq(I, b)          % Compares two mciDataWrappers
            tf =    strcmpi(I.config.axesnames,  b.config.axesnames) &&...
                    length(I.config.positions) == length(b.config.positions) &&...
                    all(I.config.positions == b.config.positions);  % Change?
        end

        % OPEN/CLOSE ---- The functions that define how the input should init/deinitialize (these functions are not used in emulation mode).
        function Open(I)                % Do whatever neccessary to initialize the input.
            l = length(I.config.configs);
            
            if isempty(I.s)
                I.s = cell(1, l);

                for ii = 1:l
                    c = I.config.configs{ii};
                    I.s{ii} = eval([c.class '(c)']);
                end
            end
            
            for ii = 1:l
                I.s{ii}.open();
            end
        end
        function Close(~)               % Do whatever neccessary to deinitialize the input.
            % Don't close the axes because some other part of the program might be using them.
%             for ii = 1:length(I.config.configs)
%                 I.s{ii}.close();
%             end
        end
        
        % MEASURE ------- The 'meat' of the input: the funtion that actually does the measurement and 'inputs' the data. Ignore integration time (with ~) if there should not be one.
        function data = MeasureEmulation(I, integrationTime)
            data = I.Measure(integrationTime);
        end
        function data = Measure(I, ~)
            l = length(I.config.configs);
            data = zeros(1, l);
            
            for ii = 1:length(I.config.configs)
                data(ii) = I.s{ii}.goto(I.config.positions(ii));
            end
            
            pause(1);   % Quick fix. Change this!
        end
    end
    
%     methods
%         % EXTRA --------- Any additional functionality this input should have (remove if there is none).
%         function specificFunction(I)    % ** Rename to a descriptive name for the additional functionality.
%             specific(I);                % ** Change to the appropriate code for this additional functionality.
%         end
%     end
end




