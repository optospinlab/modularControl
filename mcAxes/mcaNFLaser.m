classdef (Sealed) mcaNFLaser < mcAxis
% mcaTemplate aims to explain the essentials for making a custom mcAxis.
    
    methods (Static)
        % Neccessary extra vars:
        %  - port
        
        function config = defaultConfig()
            config = mcaTemplate.customConfig();
        end
        function config = customConfig()
            config.name = 'New Focus Tunable Red Laser';

            config.kind.kind =          'NFLaser';
            config.kind.name =          'New Focus Laser';
            config.kind.intRange =      [636 639];
            config.kind.int2extConv =   @(x)(x);                % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)(x);                % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      'nm';                   % 'Internal' units.
            config.kind.extUnits =      'nm';                   % 'External' units.
            config.kind.base =          636;
            
            config.keyStep =            .1;
            config.joyStep =            1;
            
            config.port = 'COM1???';
        end
    end
    
    methods
        function a = mcaNFLaser(varin)     % Insert mca[Custom] name here...
            if nargin == 0
                a.construct(mcaNFLaser.defaultConfig());
            else
                a.construct(varin);
            end
            a = mcInstrumentHandler.register(a);
        end
    end
    
    % These methods overwrite the empty methods defined in mcAxis. mcAxis will use these.
    methods %(Access = ?mcAxis)
        % NAME
        function str = NameShort(a)
            % This is the reccommended a.nameShort().
            str = [a.config.name ' (' a.config.port ')'];
        end
        function str = NameVerb(a)
            str = [a.config.name ' (using port ' a.config.port ')'];
        end
        
        %EQ
        function tf = Eq(a, b)          % Compares two mcaTemplates
            tf = strcmpi(a.config.port,  b.config.port);
        end
        
        % OPEN/CLOSE
        function Open(a)            
            if (~libisloaded('npusb'))    
                    loadlibrary('usbdll.lib', 'NewpDll.h', 'alias', 'npusb');   % UsbDllWrap.dll
            else
                    disp('Note: npusb was already loaded\n');
            end
            
            fail = calllib('npusb', 'newp_usb_init_product', 0);
            
            if ~fail
                str = calllib('npusb', 'newp_usb_event_get_key_from_handle');
                
                disp(['Found devices: ' str]);
                
                split = strsplit(str, ',');
                
                key = int32(split{1});      % Get the key of the first device.
                
                
                
%                 a.s = serial(a.config.port);        % Open the serial session.
% 
%                 fopen(a.s);

                identificationStr = a.listen('*IDN?');                  % Spit out some vars.
                usageTime =         a.listen('SYSTem:ENTIME?') 
                modelNumber =       a.listen('SYSTem:LASer:MODEL?')
                SerialNumber =      a.listen('SYSTem:LASer:SN?')
                revisionNumber =    a.listen('SYSTem:LASer:REV?')
                calibrationDate =   a.listen('SYSTem:LASer:CALDATE?')

                a.speak('SYSTem:MCONtrol REM');     % Disables user input to the controller panel.
                a.speakWithVar('OUTPut:STATe', 1);  % Turn the laser on.

                a.read();
            end
        end
        function Close(a)
            a.speak('SYSTem:MCONtrol LOC');     % Enables user input to the controller panel.
            a.speakWithVar('OUTPut:STATe', 0);  % Turn the laser off.
            
            fclose(a.s);                        % Close the serial session.
        end
        
        % READ
        function ReadEmulation(a)
            a.x = a.xt;
        end
        function Read(a)
            a.x = a.listen('SENSe:WAVElength');
        end
        
        % GOTO
        function GotoEmulation(a, x)
            a.xt = x;
        end
        function Goto(a, x)
            a.xt = x;
            a.speakWithVar('SOURce:WAVElength', x);
        end
    end
        
    methods
        % EXTRA
        function speak(a, str)
            reply = a.listen(str);  % There are some commands that do not reply... Not sure how these will behave without testing.
            
            if ~strcmp(reply, 'OK')
                a.beep();
                error(['mcaNFLaser: Laser returns error: ' reply]);
            end
        end
        function speakWithVar(a, str, var)
            a.speak([str ' ' num2str(var)]); % Fix precision on num2str?
        end
        function reply = listen(a, str)
            fprintf(a.s, [str 13 10]);
            reply = fscanf(a.s);
        end
        
        function time = scan(a, xMin, xMax, vFor, vRet, nScans)
            if ~a.listen('*OPC?')   % If some long term [OP]eration is not [C]omplete...
                error('mcaNFLaser: Some operation is still ongoing.');
            end
            
            vMax = a.listen('SOURce:WAVE:MAXVEL?');
            
            if vFor <= 0
                warning('mcaNFLaser: Forward velocity cannot be negative or zero. Setting to max velocity.');
                vFor = vMax;
            end
            if vRet <= 0
                warning('mcaNFLaser: Forward velocity cannot be negative or zero. Setting to max velocity.');
                vRet = vMax;
            end
            
            if vMax < vFor
                warning(['mcaNFLaser: Forward velocity of ' num2str(vFor) ' nm/sec is greater than the max velocity of ' num2str(vMax) ' nm/sec... Setting to max velocity.']);
                vFor = vMax;
            end
            if vMax < vRet
                warning(['mcaNFLaser: Return velocity of ' num2str(vRet) ' nm/sec is greater than the max velocity of ' num2str(vMax) ' nm/sec... Setting to max velocity.']);
                vRet = vMax;
            end
            
            if ~a.inRange(xMin)
                warning(['mcaNFLaser: Min wavelength of ' num2str(xMin) ' nm is out of range. Setting to min wavelength.']);
                xMin = min(a.config.kind.intRange);
            end
            if ~a.inRange(xMax)
                warning(['mcaNFLaser: Max wavelength of ' num2str(xMax) ' nm is out of range. Setting to max wavelength.']);
                xMax = max(a.config.kind.intRange);
            end
            
            if nScans < 0 || nScans ~= round(nScans)
                warning(['mcaNFLaser: ' num2str(nScans) ' is an invalid number of scans. Setting to ' num2str(ceil(abs(nScans))) '.']);
                nScans = ceil(abs(nScans));
            end
            
            a.speakWithVar('SOURce:WAVE:SLEW:RETurn',   vRet);      % Apply the appropriate settings.
            a.speakWithVar('SOURce:WAVE:SLEW:FORWard',  vFor);
            
            a.speakWithVar('SOURce:WAVE:START',         xMin);
            a.speakWithVar('SOURce:WAVE:STOP',          xMax);
            
            a.speakWithVar('SOURce:WAVE:DESSCANS',      nScans);
            
            a.speak('OUTPut:SCAN:START');                           % Start the scan.
            
            time = (1/vFor + 1/vRet)*abs(xMax - xMin);
        end
        function time = scanOnce(a, xMin, xMax, vFor, vRet)
            time = scan(a, xMin, xMax, vFor, vRet, 1);
        end
        
        function setPower(a, power)
            a.speakWithVar('SOURce:POWer:DIODe', power);
        end
        
        function current = getCurrent(a)
            current =   a.listen('SENSe:CURRent:DIODe');
        end
        function power = getPower(a)
            power =     a.listen('SENSe:POWer:DIODe');
        end
        function temp = getDiodeTemp(a)
            temp =     a.listen('SENSe:TEMPerature:DIODe');
        end
        function temp = getCavityTemp(a)
            temp =     a.listen('SENSe:TEMPerature:CAVity');
        end
        
        function beep(a)
            a.speakWithVar('BEEP', 2);
        end
    end
end




