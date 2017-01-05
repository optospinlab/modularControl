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

    properties
        aPLE
        aSpec
        
        aSpecPos
        aSpecIntensity
        
        aLineWid
        aIntensity
        
        aLineWidM
        aIntensityM
    end
    
    methods (Static)
        % Neccessary extra vars:
        %  - steps
        %  - results
        
        function config = defaultConfig()               % Static config that should be used if no configuration is provided upon intialization.
            config = mcePLE.customConfig(20);
        end
        function config = customConfig(numScans)
            config.class = 'mcePLE';
            
            config.name = 'PLE Experiment';

            config.kind.kind =          'ple';
            config.kind.name =          'PLE';
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
            
            I = mciPLE();
            
            config.numScans = numScans;
            config.upPixels = I.config.upPixels;
            
            % PLE input
            scansPLE =      mcData.inputConfig(I, numScans, 1);    % (Fake integrationTime)
            
            sl = 30;    % (seconds) = Spectrum Length
            
            config.overview =   'Overview should be used to describe a mcExperiment.';
            config.steps =      {   
                                    {'Green OD0',           greenOD2,       0,          'Make sure the OD2 filter is down.'};...
%                                     {'Green On',            greenDigital,   1,          'Turn the green on so we can take a spectrum.'};...
                                    {'Spec Mirror Down',    mirror,         0,          'Move the SPCM mirror down so that we can take a spectrum.'};...
                                    {'Spectrum',            spectrometer,   sl,         'Take a spectrum so that we know where to align the red laser.'};...
%                                     {'Green Off',           greenDigital,   0,          'For posterity, turn the green off while we play around with the red.'};...
%                                     {'Red On',              redSerial,      'on()',     'Turn the red laser on so we can use it.'};...
%                                     {'Align Red',           redSerial,      637.2,      'Set the wavelength of the red laser to be on the ZPL.'};...
%                                     {'Red at -3V',          redAnalog,      -Inf,       'Offset -3V from the basepoint so we can verify the scan will pass through the ZPL.'};...
%                                     {'-3V Spectrum',        spectrometer,   sl,         'Take a spectrum at -3V.'};...
%                                     {'Red at +3V',          redAnalog,      +Inf,       'Offset +3V from the basepoint so we can verify the scan will pass through the ZPL.'};...
%                                     {'+3V Spectrum',        spectrometer,   sl,         'Take a spectrum at +3V.'};...
                                    {'Spec Mirror Up',      mirror,         1,          'Move the SPCM mirror up so that we can use the SPCM again.'};...
                                    {'Green OD2',           greenOD2,       1,          'Move an OD2 filter in to attenuate the green (PLE requires weak green).'};...
%                                     {'Green On',            greenDigital,   1,          'Turn the green back on in preparation for PLE (is this neccessary?).'};...
                                    {'PLE',                 scansPLE,       NaN,        'Take scans of PLE!'};...
                                    {'Green OD0',           greenOD2,       0,          'Make sure the OD2 filter is down.'};...
%                                     {'Pause (.5s)',         'pause',        .5,          'Pause to make sure everything has time to flip.'};...
%                                     {'Green OD0',           greenOD2,       0,          'Remove the OD2 filter.'};...
%                                     {'Red Off',             redSerial,      'off()',    'Turn the red off'}  
                                    };
                                
            config.current =    1;                          % Current step
            config.autoProDef = true;                       % Default value for the autoproceed checkboxes.
            config.dname = '';                              % Name of directory to save to.
        end
    end
    
    methods
        function e = mcePLE(varin)
            e.extra = {'overview', 'steps'};
            if nargin == 0
                e.construct(e.defaultConfig());
            else
                e.construct(varin);
            end
            e.inEmulation = false;  % Never emulate.
            e = mcInstrumentHandler.register(e);
        end
    end
    
    methods
        function Step(e, ii)    % Proceed with the iith step of the experiment e. Overwrite this in mce subclasses.
%             switch ii
%                 case 0
%                     % Do something before step 1.
%                 case 1
%                     % Do something at the end of step 1.
%                 case 3  % After Initial Spectrum
% %                     spec = e.config.objects{ii};
%                     
% %                     [x, ~] = mcPeakFinder(spec.data, spec.xaxis, 0);
%                 %...
%             end
        end
        
        function data = Analysis(e)
            %
            e.aPLE =            e.objects{6}.d.data;
            e.aSpec =           e.objects{3}.d.data;

            %
            M =                 max(e.aSpec(e.aSpec < 200));    % thresh of 200 for cosmic ray...
            e.aSpecPos =        find(e.aSpec == M, 1);
            
            e.aSpecIntensity =  M;
        
            %
            x = 1:e.config.upPixels;
            
            finmean(:) =        fitLorentz(x, mean(e.aPLE(x), 2), ft);
            e.aLineWid =        finmean(3);
            e.aIntensity =      finmean(1);
            
            %
            findata =   zeros(3, tscans);
            
            for jj = 1:e.config.numScans
                d2 = e.aSpec(:, jj);

                findata(:, jj) = fitLorentz(x, d2(x), ft);
            end
            
            finmedian =         median(findata, 2);  

            e.aLineWidM   =     finmedian(3);
            e.aIntensityM =     finmedian(1);
        end
    end
    
end

function c = fitLorentz(x, y)
    ft = fitobject('a / ( 1 + ( (x - b)/c ).^2 )');
    
    M = max(y);
    b = find(y == M, 1);

    finfit = fit(x, y, ft, 'StartPoint', [M, b, 5]);
    c = coef(finfit);
end




