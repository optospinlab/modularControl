classdef mciSpectrum < mcInput
% mciSpectrum is the subclass of mcInput that reads our old spectra via a shoddy matlab-python handshake.
%
% Future: Generalize this to a mciPyTrigger?

    methods (Static)
        % Neccessary extra vars:
        %  - triggerfile
        %  - datafile
        
        function config = defaultConfig()
            config = mciSpectrum.pyWinSpecConfig();
        end
        function config = pyWinSpecConfig()
            config.name =               'Default Spectrometer Input';

            config.kind.kind =          'function';
            config.kind.name =          'Default Spectrum Input';
            config.kind.extUnits =      'cts';                  % 'External' units.
            config.kind.normalize =     false;                  % Should we normalize?
            config.kind.sizeInput =     [1 512];                 % This input returns a vector, not a number...
            
            config.triggerfile =        'Z:\WinSpec_Scan\matlabfile.txt';
            config.datafile =           'Z:\WinSpec_Scan\spec.SPE';
        end
    end
    
    methods
        function I = mciSpectrum(varin)
            I = I@mcInput(varin);
        end
    end
    
    % These methods overwrite the empty methods defined in mcInput. mcInput will use these. The capitalized methods are used in
    %   more-complex methods defined in mcInput.
    methods (Access = private)
        % EQ
        function tf = Eq(I, b)  % Check if a foriegn object (b) is equal to this input object (a).
            if strcmp(I.config.kind.kind, b.config.kind.kind)               % If they are the same kind...
                switch lower(I.config.kind.kind)
                    case {'nidaqanalog', 'nidaqdigital', 'nidaqcounter'}
                        tf = strcmp(I.config.dev,  b.config.dev) && ... % ...then check if all of the other variables are the same.
                             strcmp(I.config.chn,  b.config.chn) && ...
                             strcmp(I.config.type, b.config.type);
                    case 'function'
                        tf = isequal(I.config.fnc,  b.config.fnc);      % Note that the function handles have to be the same; the equations can't merely be the same.
                    otherwise
                        warning('Specific equality conditions not written for this sort of axis.')
                        tf = true;
                end
            else
                tf = false;
            end
        end
        
        % NAME
        function str = NameShort(I)
            str = [I.config.name ' (' I.config.dev ':' I.config.chn ':' I.config.type ')'];
        end
        function str = NameVerb(I)
            switch lower(I.config.kind.kind)
                case 'nidaqanalog'
                    str = [I.config.name ' (analog ' I.config.type ' input on '  I.config.dev ', channel ' I.config.chn ')'];
                case 'nidaqdigital'
                    str = [I.config.name ' (digital input on ' I.config.dev ', channel ' I.config.chn ')'];
                case 'nidaqcounter'
                    str = [I.config.name ' (counter ' I.config.type ' input on ' I.config.dev ', channel ' I.config.chn ')'];
            end
        end
        
        % OPEN/CLOSE
        function Open(I)
            switch lower(I.config.kind.kind)
                case 'nidaqanalog'
                    I.s = daq.createSession('ni');
                    addAnalogInputChannel(  I.s, I.config.dev, I.config.chn, I.config.type);
                case 'nidaqdigital'
                    I.s = daq.createSession('ni');
                    addDigitalChannel(      I.s, I.config.dev, I.config.chn, 'InputOnly');
                case 'nidaqcounter'
                    I.s = daq.createSession('ni');
                    addCounterInputChannel( I.s, I.config.dev, I.config.chn, I.config.type);
            end
        end
        function Close(I)
            release(I.s);
        end
        
        % MEASURE
        function data = MeasureEmulation(I, integrationTime)
            pause(integrationTime);
            
            cosmicray = (1000 + 500*rand)*(rand > .9);      % Insert cosmic ray in 10% of scans (make this scale with integrationTime?)
            
            data = round(100 + 20*rand(I.config.kind.sizeInput) + cosmicray*exp(-((1:512 - rand*512)/3)^2));    % Background + cosmic ray
        end
        function data = Measure(I, integrationTime)
            data = -1;
            t = now;

            fh = fopen(I.config.triggerfile, 'w');               % Create the trigger file.
            
            if (fh == -1)
                warning('mciSpectrum.measure(): oops, file cannot be written'); 
                data = NaN(I.config.kind.sizeInput);
                return;
            end 
            
            fprintf(fh, 'Trigger Spectrum\n');                  % Change this?
            fclose(fh);

            i = 0;

            while i < integrationTime + 20 && all(data == -1)   % Is 20 sec wiggle room enough?
                try
%                     disp(['Waiting ' num2str(i)]);
                    d = dir(I.config.datafile);

                    if d.datenum > t - 4/(24*60*60)
                        data = readSPE(I.config.datafile);
                    end
                catch
                    
                end

                pause(1);
                i = i + 1;
            end

            if ~all(data == -1)     % If we found the spectrum....
                i = 0;
                
                while i < 20
                    try             % ...try to move it to our save directory.
                        movefile(I.config.datafile, [mcInstrumentHandler.timestamp() '.SPE']);
                        break;
                    catch
                        
                    end
                    
                    i = i + 1;
                end
            else                    % ...otherwise, return NaN.
                data = NaN(1, 512);
            end
        end
    end
    
end




