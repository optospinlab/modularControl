classdef mcePLE < mcExperiment
% mcExperiment is a generalization of experimental procedures.
%
% To use:
%
%   e = mcePLE(config)
%   e.measure()
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
            config = mcePLE.customConfig(2);
        end
        function config = customConfig(numScans)
            config.class = 'mcePLE';
            
            config.name = 'PLE Experiment';

            config.kind.kind =          'ple';
            config.kind.name =          'PLE';
            config.kind.extUnits =      'GHz';          % Outputs the FWHM of the PLE peak in GHz. Outputs NaN if no peak is found
            config.kind.shouldNormalize = false;        % (Not sure if this is functional.) If this variable is flagged, the measurement is subtracted from the previous and is divided by the time spent on a pixel. Not that this is done outside the measurement currently in mcData (individual calls to .measure() will not have this behavior currently)
            config.kind.sizeInput =     [1 1];          % Both the position of the peak and the FWHM of the peak are single numbers.
            
%             ghwpC = mcaAPT.rotatorConfig()
%             ghwp = mcaAPT(ghwpC);
%             
%             msgbox('Please rotate the green half-wave plate to the PLE position.');
%             ghwpPLE =   ghwp.getX();
%             msgbox('Please rotate the green half-wave plate to the optimization position.');
%             ghwpOpt =   ghwp.getX();

            ghwpC = mcaAPT.rotatorConfig();
%             ghwp = mcaAPT(ghwpC);
%             
%             msgbox('Please rotate the green half-wave plate to the PLE position.');
% %             ghwpPLE =   213.1726;   % 80uW
%             ghwpPLE =   ghwp.getX();   % 80uW
%             msgbox('Please rotate the green half-wave plate to the optimization position.');
% %             ghwpOpt =   207.2705;   % 1.4mW
%             ghwpOpt =   ghwp.getX();   % 1.4mW

            ghwpPLE =   139.9923;   % 80uW
            ghwpOpt =   135.2904;   % 1.4mW
            
            % Spectrometer
%             spectrometer =  mciSpectrum.pyWinSpecConfig();
            
            sl = 60;    % (seconds) = Spectrum Length
            
            spectrometer =  mcData.inputConfig(mciSpectrum.pyWinSpecConfig(), 2, sl);
            
            % Counter
            counter =       mciDAQ.counterConfig();         counter.chn = 'ctr1';
            
            % Mirror for switching between SPCM and spectrometer.
            mirror =        mcaArduino.flipMirrorConfig();
            
            % Serial red NFLaser controls
            redSerial =        mcaNFLaser.defaultConfig();
            
            % -3 -> 3 V red freq control
            redAnalog =     mcaDAQ.redConfig();
            redDigital =    mcaDAQ.redDigitalConfig();
            
            % Green laser on/off
            greenDigital =  mcaDAQ.greenConfig();
            greenOD2 =      mcaDAQ.greenOD2Config();
            
            PLE = mciPLE.PLEConfig(0, 3, 240, 10, 1);
            
            config.numScans = numScans;
            config.upPixels = PLE.upPixels;
            
            % PLE input
            scansPLE =      mcData.inputConfig(PLE, numScans, 1);    % (Fake integrationTime)
            
            config.overview =   'Overview should be used to describe a mcExperiment.';
            config.steps =      {   
%                                     {'Green OD0',           greenOD2,       0,          'Make sure the OD2 filter is down.'};...
                                    {'Green Opt',           ghwpC,          ghwpOpt,    'Turn the half wave plate to opt position.'};...
                                    {'Green On',            greenDigital,   1,          'Turn the green on so we can take a spectrum.'};...
                                    {'Spec Mirror Down',    mirror,         0,          'Move the SPCM mirror down so that we can take a spectrum.'};...
                                    {'Pause (1s)',          'pause',        1,          'Pause to make sure everything has time to flip.'};...
                                    {'Spectrum x2',         spectrometer,   NaN,        'Take two spectra to determine whether we should see an NV with PLE.'};...
%                                     {'Spectrum 2',          spectrometer,   sl,         'Take a second spectrum to avoid cosmic rays.'};...
                                    {'Green Off',           greenDigital,   0,          'For posterity, turn the green off while we play around with the red.'};...
                                    {'Red On',              redDigital,     1,          'Turn the red laser on so we can use it.'};...
%                                     {'Align Red',           redSerial,      637.2,      'Set the wavelength of the red laser to be on the ZPL.'};...
%                                     {'Red at -3V',          redAnalog,      -Inf,       'Offset -3V from the basepoint so we can verify the scan will pass through the ZPL.'};...
%                                     {'-3V Spectrum',        spectrometer,   sl,         'Take a spectrum at -3V.'};...
%                                     {'Red at +3V',          redAnalog,      +Inf,       'Offset +3V from the basepoint so we can verify the scan will pass through the ZPL.'};...
%                                     {'+3V Spectrum',        spectrometer,   sl,         'Take a spectrum at +3V.'};...
                                    {'Spec Mirror Up',      mirror,         1,          'Move the SPCM mirror up so that we can use the SPCM again.'};...
                                    {'Green OD2',           ghwpC,          ghwpPLE,    'Turn the half wave plate to PLE position.'};...
%                                     {'Green On',            greenDigital,   1,          'Turn the green back on in preparation for PLE (is this neccessary?).'};...
                                    {'Pause (1s)',          'pause',         1,           'Pause to make sure everything has time to flip.'};...
                                    {'PLE',                 scansPLE,       NaN,        'Take scans of PLE!'};...
                                    {'Green Opt',           ghwpC,          ghwpOpt,    'Turn the half wave plate to opt position.'};...
                                    {'Green On',            greenDigital,   1,          'Turn the green on (Future: reset to original state?).'};...
                                    {'Pause (1s)',          'pause',        1,          'Pause to make sure everything has time to flip.'};...
%                                     {'Green OD0',           greenOD2,       0,          'Remove the OD2 filter.'};...
                                    {'Red Off',             redDigital,     0,          'Turn the red off.'}  
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
            pleNum = 11;
            specNum = 5;
            
            % Append the raw data
            e.aPLE =            e.objects{pleNum}.data.d.data{1};
            
            e.aSpec =           e.objects{specNum}.data.d.data{1};
            
            % Analysis of spectrum (should fit?)
%             size(e.aSpec)
            spec = min(e.aSpec, [], 1);
%             size(spec)
            M =                 max(spec(spec < 200));    % thresh of 200 for cosmic ray...
            e.aSpecPos =        find(spec == M, 1);
            e.aSpecIntensity =  mean(e.aSpec(:, e.aSpecPos));

            % Analysis of PLE
            ft = fittype('d + a / ( 1 + ( 2*(x - b)/c ).^2 )');

            sdata = e.aPLE;

            tscans = length(e.objects{pleNum}.data.d.scans{1});
    
%             finl = e.objects{7}.data.r.l.lengths(3);
            x = 1:e.config.upPixels;

            findata =   zeros(3, tscans);
            finmean =   zeros(3, 1);
            finmedian = zeros(3, 1);

            for jj = 1:tscans
                d2 = sdata(jj, :);
                
                findata(:, jj) = fitScan(x, d2(x), ft);
            end

%             max(mean(sdata(x, :), 2)) - min(mean(sdata(x, :), 2))
            z = 1;
            s = std(findata(2,:));
            m = mean(findata(2,:));
            s2 = std( findata(2, findata(2,:) > m - z*s & findata(2,:) < m + z*s) );
            
            finmean(:) =    fitScan(x, mean(sdata(:, x), 1), ft);
            finmedian(:) =  median(findata, 2);

            if s2 < 10 %max(mean(sdata(x, :), 2)) - min(mean(sdata(x, :), 2)) > 1e4
                e.aLineWid =        finmean(3);
                e.aIntensity =      finmean(1);

                e.aLineWidM   =     finmedian(3);
                e.aIntensityM =     finmedian(1);
            else
                e.aLineWid =        120;
                e.aIntensity =      0;

                e.aLineWidM   =     120;
                e.aIntensityM =     0;
            end
            
            % Use linewidth as the final data...
            data = e.aLineWidM;
        end
    end
    
end

function c = fitScan(x, y, ft)
    M = max(y);
    b = find(y == M, 1);
    
    y(isnan(y)) = 0;
    
    finfit = fit(x', y', ft, 'StartPoint', [M, b, 25, median(y)], 'Lower', [0, 0, 0, 0], 'Upper', [Inf, Inf, 120, Inf]);
    c = coeffvalues(finfit);
    
    c = c(1:3);
end




