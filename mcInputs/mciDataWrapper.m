classdef mciDataWrapper < mcInput
% mciDataWrapper allows the user to use mcData structure as an input. Using the config.makeDV flag, one can also make a GUI pop
% up when data is being aqcuired.
% Also see mcInput.

    properties
%         data =  [];     % mcData object
        dv =    [];     % Optional (persistant) mcDataViewer window.
    end

    methods (Static)    % The folllowing static configs are used to define the identity of input objects. configs can also be loaded from .mat files
        % Neccessary extra vars:
        %  - data       % d struct
        %  - makeDV     % Whether or not this mciDataWrapper should make an acompanying mcDataViewer
        
        function config = defaultConfig()               % Static config that should be used if no configuration is provided upon intialization.
            config = mciDataWrapper.dataConfig(mcData.defaultConfig()); 	% Make a mciDataWrapper wrapping the default mcData config.
        end
        function config = dataConfig(d)
            config.class = 'mciDataWrapper';
            
            config.name = 'Wrapper';

            config.kind.kind =          'wrapper';
            config.kind.name =          'mcData wrapper';
            
            if isprop(d.inputs{1}, 'config')
                I = d.inputs{1}.config; 
            else
                I = d.inputs{1};
            end
            
            config.kind.extUnits = I.kind.extUnits;
            
            config.kind.shouldNormalize = false;        % (Not sure if this is functional.) If this variable is flagged, the measurement is subtracted from the previous and is divided by the time spent on a pixel. Not that this is done outside the measurement currently in mcData (individual calls to .measure() will not have this behavior currently)
            
            config.kind.sizeInput = ones(1, length(d.scans));
            
            for ii = 1:length(d.scans)
                config.kind.sizeInput(ii) = length(d.scans{ii});
            end
            config.kind.sizeInput = [config.kind.sizeInput  I.kind.sizeInput(I.kind.sizeInput > 1)];
            
            if isempty(config.kind.sizeInput)
                config.kind.sizeInput =     [1 1];
            elseif length(config.kind.sizeInput) == 1
                config.kind.sizeInput =     [1 config.kind.sizeInput];
            end
            
            config.data =      d;
            config.makeDV = true;                      % Make a (persistant) dataViewer that pops up when this is called?
        end
    end
    
    methods             % Initialization method (this is what is called to make an input object).
        function I = mciDataWrapper(varin)
            I.extra = {'data', 'makeDV'};
            
            if nargin == 0          % If no arguments are provided, use the default config
                c = I.defaultConfig();
            elseif nargin <= 2      % Otherwise, we must figure out what exactly was given.
                if nargin == 2
                    c = varin{1};   % We expect the first argument to be the identity, either already an mciDataWrapper config, or a mcData object or data struct.
                else
                    c = varin;
                end
                
                % Now we must figure out what exactly c is out of the aforementioned choices, and make it into an mciDataWrapper config.
                if isstruct(c)                  % If it is a struct...
                    if isfield(c, 'class')      % ...with a class field, then perform according to the class.
                        if      strcmpi(c.class, 'mcData')
                            c = mciDataWrapper.dataConfig(c);
                        elseif  strcmpi(c.class, 'mciDataWrapper')
                            % Good to go!
                        else
                            error(['mcDataWrapper(): Invalid config struct of class "' c.class '" given. Expected either an mcData or mciDataWrapper'])
                        end
                    else                        % Without the class field (which may happen for old files)...
                        if      isfield(c, 'axes')  % ...check for defining features of an mcData.
                            c = mciDataWrapper.dataConfig(c);
                        else
                            error('mcDataWrapper(): Invalid config struct given. Expected either an mcData or mciDataWrapper')
                        end
                    end
                elseif isa(c, 'mcData')
                    c = mciDataWrapper.dataConfig(c.d);
                elseif ischar(c)                % If it is a string...
                    d = mcData(c);              % ...load using the mcData loader (Future: allow mciDataWrapper strings to be saved?). 
                    c = mciDataWrapper.dataConfig(d.d);
                end
            else
                error(['mciDataWrapper(): Number of arguments not understood. Expected <= 2, but recieved ' nargin])
            end
                
            d = mcData(c.data);     % Generate the other unrequired fields in the mcData config (e.g. d.name, which is neccessary).
            c.data = d.d;

            I.construct(c);
                
            I = mcInstrumentHandler.register(I);
            
            I.inEmulation = false;  % Never emulate.
        end
    end
    

    % These methods overwrite the empty methods defined in mcInput. These methods are used in the uncapitalized parent methods defined in mcInput.
    methods
        function scans = getInputScans(I)
            c = I.config.data.inputs{1};    % This will throw an error if we are given an object instead of a config.
            I2 = eval([c.class '(c)']);
            
            scans = [I.config.data.scans I2.getInputScans()];
        end
        
        function units = getInputScanUnits(I)
            units = cell(1, length(I.config.data.axes));
            
            for ii = 1:length(I.config.data.axes)
                a = I.config.data.axes{ii};
                
                if isstruct(a)
                    units{ii} = a.kind.extUnits;
                elseif isa(a, 'mcAxis')
                    units{ii} = a.config.kind.extUnits;
                end
            end
            
            c = I.config.data.inputs{1};    % This will throw an error if we are given an object instead of a config.
            I2 = eval([c.class '(c)']);
            
            units = [units I2.getInputScanUnits()];
        end
        
        function names = getInputScanNames(I)
            names = cell(1, length(I.config.data.axes));
            
            for ii = 1:length(I.config.data.axes)
                a = I.config.data.axes{ii};
                
                if isstruct(a)
                    names{ii} = a.name;
                elseif isa(a, 'mcAxis')
                    names{ii} = a.config.name;
                end
            end
            
            c = I.config.data.inputs{1};    % This will throw an error if we are given an object instead of a config.
            I2 = eval([c.class '(c)']);
            
            names = [names I2.getInputScanNames()];
        end
        
        % NAME ---------- The following functions define the names that the user should use for this input.
        function str = NameShort(I)     % 'short' name, suitable for UIs/etc.
            str = [I.config.name ' (' I.config.data.name ')'];
        end
        function str = NameVerb(I)      % 'verbose' name, suitable to explain the identity to future users.
            str = [I.config.name ' (an mciDataWrapper wrapping ' I.config.data.name ')'];
        end
        
        %EQ ------------- The function that should return true if the custom vars are the same (future: use i.extra for this?)
        function tf = Eq(I, b)          % Compares two mciDataWrappers
            tf = isequal(I.config.data, b.config.data);  % Compares the two structures
            %strcmpi(I.config.data.name,  b.config.data.name);
        end

        % OPEN/CLOSE ---- The functions that define how the input should init/deinitialize (these functions are not used in emulation mode).
        function Open(I)                % Do whatever neccessary to initialize the input.
%             I.s
            I.s = mcData(I.config.data);
            if I.config.makeDV
                I.dv = mcDataViewer(I.s, false, false, false);
                I.dv.isPersistant = true;
            end
%             I.s
        end
        function Close(I)               % Do whatever neccessary to deinitialize the input.
            delete(I.s);
            delete(I.data);
        end
        
        % MEASURE ------- The 'meat' of the input: the funtion that actually does the measurement and 'inputs' the data. Ignore integration time (with ~) if there should not be one.
        function data = MeasureEmulation(I, integrationTime)
            data = I.Measure(integrationTime);
        end
        function data = Measure(I, ~)
            I.s.resetData();
            
            if I.config.makeDV
                I.dv.df.Visible = 'on';
                I.dv.scanButton_Callback(0, 0);
            else
                I.s.aquire();
            end
            
            while I.s.r.scanMode ~= 2  % While the scan hasn't ended (this handles pausing, etc)...
%                 'waiting...'
                waitfor(I.s, 'r');
%                 I.s
%                 I.s.r
%                 I.s.r.scanMode
            end

            if I.config.makeDV
                I.dv.cf.Visible = 'off';
                I.dv.cfToggle.State = 'off';

                I.dv.df.Visible = 'off';
            end

            data = I.s.d.data{1};
%             'fin'
%             size(data)
        end
    end
    
%     methods
%         % EXTRA --------- Any additional functionality this input should have (remove if there is none).
%         function specificFunction(I)    % ** Rename to a descriptive name for the additional functionality.
%             specific(I);                % ** Change to the appropriate code for this additional functionality.
%         end
%     end
end




