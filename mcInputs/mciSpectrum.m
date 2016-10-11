classdef mciSpectrum < mcInput
% mciSpectrum is the subclass of mcInput that reads our old spectra via a shoddy matlab-python handshake.
%
% Future: Generalize this to a mciPyTrigger?

    properties
        prevIntegrationTime;
    end

    methods (Static)
        % Neccessary extra vars:
        %  - triggerfile
        %  - datafile
        
        function config = defaultConfig()
            config = mciSpectrum.pyWinSpecConfig();
        end
        function config = pyWinSpecConfig()
            config.name =               'Default Spectrometer Input';

            config.kind.kind =          'pyWinSpectrum';
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
            I.extra = {'triggerfile', 'datafile'};
            if nargin == 0
                I.construct(I.defaultConfig());
            else
                I.construct(varin);
            end
            I = mcInstrumentHandler.register(I);
%             if nargin == 0
%                 varin = mciSpectrum.defaultConfig();
%             end
%             
%             I = I@mcInput(varin);
            I.prevIntegrationTime = NaN;
        end
        
        function axes_ = getInputAxes(I)
            if isfield(I.config, 'Ne')
                axes_ = {interpretNeSpectrum(I.config.Ne)};
            else
                axes_ = {1:512};    % Make general?
            end
        end
    end
    
    % These methods overwrite the empty methods defined in mcInput. mcInput will use these. The capitalized methods are used in
    %   more-complex methods defined in mcInput.
    methods
        % EQ
        function tf = Eq(I, b)  % Check if a foriegn object (b) is equal to this input object (a).
            tf = strcmp(I.config.triggerfile,   b.config.triggerfile) && ... % ...then check if all of the other variables are the same.
                 strcmp(I.config.datafile,      b.config.datafile);
        end
        
        % NAME
        function str = NameShort(I)
            str = I.config.name;
        end
        function str = NameVerb(I)
            str = [I.config.name '(with triggerfile ' I.config.triggerfile ' and datafile ' I.config.datafile];
        end
        
        % OPEN/CLOSE not neccessary
        
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
            
            exposure = NaN;

            while i < integrationTime + 60 && all(data == -1)   % Is 60 sec wiggle room enough?
                try
%                     disp(['Waiting ' num2str(i)]);
                    d = dir(I.config.datafile);

                    if d.datenum > t - 4/(24*60*60)
                        [data, exposure] = readSPE(I.config.datafile);
                    end
                catch
                    
                end

                pause(1);
                i = i + 1;
            end
            
            if isnan(exposure)
                questdlg(['Request for spectrum timed out; sorry. Is the exposure time greater than the expetected ' num2str(integrationTime) ' seconds?'], 'Done', 'Done');
                return;
            end
            
            if integrationTime ~= exposure && I.prevIntegrationTime ~= integrationTime
                questdlg(['Expected exposure of ' num2str(integrationTime) ' seconds, but received ' num2str(exposure) ' second exposure. Is this correct?'], ['Unexpected Exposure'], 'Done', 'Done');
                return;
            end

            if ~all(data == -1)     % If we found the spectrum....
                i = 0;
                
                while i < 20
                    try             % ...try to move it to our save directory.
                        movefile(I.config.datafile, ['C:\Users\Tomasz\Desktop\Stark\spec' datestr(now,'HH_MM_SS_FFF') '.SPE']);
                        break;
                    catch err
                        disp(err.message)
                    end
                    
                    i = i + 1;
                end
            else                    % ...otherwise, return NaN.
                data = NaN(I.config.kind.sizeInput);
            end
        end
    end
    
end




