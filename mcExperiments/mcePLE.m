classdef mcePLE < mcExperiment
% mcExperiment is a generalization of experimental procedures.
%
% To use:
%
%   e = mcePLE(config)
%   e.measure()
%
%
%
% Also see mcExperiment and mcInput.
    
    methods (Static)
        % Neccessary extra vars:
        %  - steps
        %  - results
        
        function config = defaultConfig()               % Static config that should be used if no configuration is provided upon intialization.
            config = mcePLE.customConfig(0, 2, 100, 1, .25);
        end
        function config = customConfig(xMin, xMax, upPixels, upTime, downTime)
            config.class = 'mcePLE';
            
            config.name = 'PLE Experiment';             % ** Change this to the UI name for this identity of mci<MyNewInput>.

            config.kind.kind =          'ple';          % ** Change this to the programatic name that the program should use for this identity of mci<MyNewInput>.
            config.kind.name =          'PLE';          % ** Change this to the technical name (e.g. name of device) for this identity of mci<MyNewInput>.
            config.kind.intUnits =      'GHz';          % Outputs the FWHM of the PLE peak in GHz. Outputs NaN if no peak is found
            config.kind.shouldNormalize = false;        % (Not sure if this is functional.) If this variable is flagged, the measurement is subtracted from the previous and is divided by the time spent on a pixel. Not that this is done outside the measurement currently in mcData (individual calls to .measure() will not have this behavior currently)
            config.kind.sizeInput =     [1 1];          % Both the position of the peak and the FWHM of the peak are single numbers.
            
            % Spectrometer
            spectrometer =  mciSpectrum.pyWinSpecConfig();
%             specData =      mcData.inputConfig(spectrometer);
            
            % Counter
            counter =       mciDAQ.counterConfig();         counter.chn = 'ctr1';
            
            % Mirror for switching between SPCM and spectrometer.
            mirror =        mcaArduino.flipMirrorConfig();  mirror.port = 'COM7';
            
            % Serial red NFLaser controls
            redSerial =        mcaNFLaser.defaultConfig();
            
            % -3 -> 3 V red freq control
            redAnalog =     mcaDAQ.redConfig();
            
            % Green laser on/off
            greenDigital =  mcaDAQ.greenConfig();
            greenOD2 =      mcaDAQ.greenConfig();   greenOD2.name = 'Green OD2';    greenOD2.chn = 'Port0/Line2';
            
            % PLE input
            inputPLE =      mciPLE.PLEConfig(xMin, xMax, upPixels, upTime, downTime);
            scansPLE =      mcData.inputConfig(inputPLE, 10, 1);    % (Fake integrationTime)
            
            sl = 30;    % (seconds) = Spectrum Length
            
            config.overview =   'Overview should be used to describe a mcExperiment.';
            config.steps =      {   {'Green On',            greenDigital,   1,          'Turn the green on so we can take a spectrum.'};...
                                    {'Green OD0',           greenOD2,       0,          'Make sure the OD2 filter is down.'};...
                                    {'Spec Mirror Down',    mirror,         0,          'Move the SPCM mirror down so that we can take a spectrum.'};...
                                    {'Initial Spectrum',    spectrometer,   sl,         'Take a spectrum so that we know where to align the red laser.'};...
                                    {'Green Off',           greenDigital,   0,          'For posterity, turn the green off while we play around with the red.'};...
                                    {'Red On',              redSerial,      'on()',     'Turn the red laser on so we can use it.'};...
                                    {'Align Red',           redSerial,      637.2,      'Set the wavelength of the red laser to be on the ZPL.'};...
                                    {'Red at -3V',          redAnalog,      -Inf,       'Offset -3V from the basepoint so we can verify the scan will pass through the ZPL.'};...
                                    {'-3V Spectrum',        spectrometer,   sl,         'Take a spectrum at -3V.'};...
                                    {'Red at +3V',          redAnalog,      +Inf,       'Offset +3V from the basepoint so we can verify the scan will pass through the ZPL.'};...
                                    {'+3V Spectrum',        spectrometer,   sl,         'Take a spectrum at +3V.'};...
                                    {'Mirror Up',           mirror,         1,          'Move the SPCM mirror up so that we can use the SPCM again.'};...
                                    {'Green OD2',           greenOD2,       1,          'Move an OD2 filter in to attenuate the green (PLE requires weak green).'};...
                                    {'Green On',            greenDigital,   1,          'Turn the green back on in preparation for PLE (is this neccessary?).'};...
                                    {'PLE',                 scansPLE,       NaN,        'Take 10 scans of PLE!'};...
                                    {'Pause (.5s)',         'pause',        .5,          'Pause to make sure everything has time to flip.'};...
                                    {'Green OD0',           greenOD2,       0,          'Remove the OD2 filter.'};...
                                    {'Red Off',             redSerial,      'off()',    'Turn the red off'}  };
                                
            config.current =    1;                          % Current step
            config.autoProDef = true;                       % Default value for the autoproceed checkboxes.
            config.dname = '';                              % Name of directory to save to.
        end
    end
    
    methods
        function Step(e, ii)    % Proceed with the iith step of the experiment e. Overwrite this in mce subclasses.
%             switch ii
%                 case 0
%                     % Do something at the end of step 0.
%                 case 1
%                     % Do something at the end of step 1.
%                 %...
%             end
        end
    end
    
end

