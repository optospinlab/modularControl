classdef (Sealed) mcaNFLaser < mcAxis
% mcaTemplate aims to explain the essentials for making a custom mcAxis.
    
    properties
        key = 0;
        keyChar = '0';
    end

    methods (Static)
        % Neccessary extra vars:
        %  - isLambda
        
        function config = defaultConfig()
            config = mcaNFLaser.lambdaConfig();
        end
        function config = lambdaConfig()
            config.name = 'NF Red';

            config.kind.kind =          'NFLaser';
            config.kind.name =          'New Focus Tunable Red Laser';
            config.kind.intRange =      [636 639];
            config.kind.int2extConv =   @(x)(x);                % Conversion from 'internal' units to 'external'.
            config.kind.ext2intConv =   @(x)(x);                % Conversion from 'external' units to 'internal'.
            config.kind.intUnits =      'nm';                   % 'Internal' units.
            config.kind.extUnits =      'nm';                   % 'External' units.
            config.kind.base =          636;
            
            config.keyStep =            .1;
            config.joyStep =            1;
            
            config.details =            'Not Loaded';
        end
%         function config = powerConfig()   % Eventually...
%             config.name = 'NF Laser';
% 
%             config.kind.kind =          'NFLaser';
%             config.kind.name =          'New Focus Tunable Red Laser';
%             config.kind.intRange =      [636 639];
%             config.kind.int2extConv =   @(x)(x);                % Conversion from 'internal' units to 'external'.
%             config.kind.ext2intConv =   @(x)(x);                % Conversion from 'external' units to 'internal'.
%             config.kind.intUnits =      'nm';                   % 'Internal' units.
%             config.kind.extUnits =      'nm';                   % 'External' units.
%             config.kind.base =          636;
%             
%             config.keyStep =            .1;
%             config.joyStep =            1;
%             
%             config.details =            'Not Loaded';
%         end
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
            str = [a.config.name ' (' a.config.details ')'];
        end
        function str = NameVerb(a)
            str = [a.config.name ' (' a.config.details ')'];
        end
        
        %EQ
        function tf = Eq(~, ~)          % Compares two mcaNFLasers
            tf = true;
        end
        
        % OPEN/CLOSE
        function Open(a)            
            if (~libisloaded('npusb'))    
                    loadlibrary('usbdll.dll', 'NewpDll.h', 'alias', 'npusb');   % usbdll.lib
            else
                    disp('Note: npusb was already loaded');
            end
            
            calllib('npusb', 'newp_usb_init_product', 0);
            
%             if fail == 0
                [~, str] = calllib('npusb', 'newp_usb_get_device_info', blanks(256));
                
%                 disp(['Found devices: ' str]);
                
                split = strsplit(str, {',', ';'});
                
                a.keyChar = split{1};                       % Get the key of the first device.
                a.key =     int32(str2double(a.keyChar));
                
                a.config.details = split{2}(1:end-2);       % Name of the laser (plus details) minus CR LF
                
%                 a.s = serial(a.config.port);        % Open the serial session.
% 
%                 fopen(a.s);

%                 identificationStr = a.listen('*IDN?');                  % Spit out some vars.
%                 usageTime =         a.listen('SYSTem:ENTIME?') 
%                 modelNumber =       a.listen('SYSTem:LASer:MODEL?')
%                 SerialNumber =      a.listen('SYSTem:LASer:SN?')
%                 revisionNumber =    a.listen('SYSTem:LASer:REV?')
%                 calibrationDate =   a.listen('SYSTem:LASer:CALDATE?')

                a.speak('SYSTem:MCONtrol REM');     % Disables user input to the controller panel.
                a.speakWithVar('OUTPut:STATe', 1);  % Turn the laser on.
                a.speakWithVar('OUTPut:TRACk', 1);  % Turn lambda track on
                a.speakWithVar('HWCONFIG', 16);     % Set HWCONFIG to keep lambda track on even after the laser has reached the desired wavelength.

                a.read();
%             end
        end
        function Close(a)
            a.speak('SYSTem:MCONtrol LOC');     % Enables user input to the controller panel.
            a.speakWithVar('OUTPut:STATe', 0);  % Turn the laser off.
            
            calllib('npusb', 'newp_usb_uninit_system');  % Close the session.
        end
        
        % READ
        function ReadEmulation(a)
            a.x = a.xt;
        end
        function Read(a)
            a.x = str2double(a.listen('SENSe:WAVElength'));
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
                warning(['mcaNFLaser: Laser returns error: ' reply]);
                a.beep();       % Infinite recursion?
            end
        end
        function speakWithVar(a, str, var)
            a.speak([str ' ' num2str(var)]); % Fix precision on num2str?
        end
        function reply = listen(a, str)
            disp('Sending message to laser...');
            tic
            fail =              calllib('npusb', 'newp_usb_send_ascii',   a.key, libpointer('cstring', str), length(str));
            toc
            
            if fail == 0
                disp('Waiting for reply...');
                tic
                [~, reply, ~] = calllib('npusb', 'newp_usb_get_ascii',    a.key, blanks(256), 256, libpointer('uint32Ptr'));    % Receiving reply takes 2 seconds!?!
                toc

                disp('Reply received.');
                
                split = strsplit(reply, ['' 13]);
                reply = split{1};
            end
        end
        
        function time = scan(a, xMin, xMax, vFor, vRet, nScans)
            if ~a.listen('*OPC?')   % If some long term [OP]eration is not [C]omplete...
                error('mcaNFLaser: Some operation is still ongoing.');
            end
            
            vMax = str2double(a.listen('SOURce:WAVE:MAXVEL?'));
            
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
        
        function setCurrent(a, current)
            a.speakWithVar('SOURce:CURRent:DIODe', current);
        end
        function setPower(a, power)
            a.speakWithVar('SOURce:POWer:DIODe', power);
        end
        
        function current = getCurrent(a)
            current =   str2double(a.listen('SENSe:CURRent:DIODe'));
        end
        function power = getPower(a)
            power =     str2double(a.listen('SENSe:POWer:DIODe'));
        end
        function temp = getDiodeTemp(a)
            temp =     str2double(a.listen('SENSe:TEMPerature:DIODe'));
        end
        function temp = getCavityTemp(a)
            temp =     str2double(a.listen('SENSe:TEMPerature:CAVity'));
        end
        
        function beep(a)
            a.speakWithVar('BEEP', 2);
        end
    end
end




