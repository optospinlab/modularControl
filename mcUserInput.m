classdef mcUserInput < mcSavableClass
% mcUserInputGUI returns the uitabgroup reference that contains three tabs:
%   - Goto:     Buttons and edit fields to control the axes.
%   - Keyboard: which contains fields that customize wasdqe/udlr-+ keyboard input.
%   - Joystick: which contains fields that customize a single joystick (sorry, multiple joysticks are unsupported).
%
%   obj = mcUserInput()                 % 
%   obj = mcUserInput(config)           % 
%   obj = mcUserInput('config.mat')     % 
%
%   tabgroup = obj.mcUserInputGUI()
%   tabgroup = obj.mcUserInputGUI(f)
%   tabgroup = obj.mcUserInputGUI(f)
%
% Status: Finished; Mostly commented.
    
    properties
%         config = [];            % Defined in mcSavableClass. All static variables (e.g. valid range) go in config.
        
        gui = [];               % Variables for the gui.
        
        wp = [];
        
        mode = 1;               % userInput mode, i.e. which set of axes the commands are sent to.
    end
      
    methods (Static)  
        function config = defaultConfig()
            config = mcUserInput.diamondConfig();
        end
        function config = diamondConfig()
            % Default configuration for the diamond microscope, in which
            % the piezos, the galvos, and the micrometers are the axes
            % groups (with z being piezo z for all of them).
            
            config.name =               'Default User Input';
            
            configPiezoX = mcaDAQ.piezoConfig();    configPiezoX.name = 'Piezo X'; configPiezoX.chn = 'ao0';       % Customize all of the default configs...
            configPiezoY = mcaDAQ.piezoConfig();    configPiezoY.name = 'Piezo Y'; configPiezoY.chn = 'ao1';
            configPiezoZ = mcaDAQ.piezoZConfig();   configPiezoZ.name = 'Piezo Z'; configPiezoZ.chn = 'ao2';
            
            configMicroX = mcaMicro.microConfig();  configMicroX.name = 'Micro X'; configMicroX.port = 'COM5';
            configMicroY = mcaMicro.microConfig();  configMicroY.name = 'Micro Y'; configMicroY.port = 'COM6';
            
%             configGalvoX = mcaDAQ.galvoConfig();    configGalvoX.name = 'Galvo X'; configGalvoX.dev = 'cDAQ1Mod1'; configGalvoX.chn = 'ao0';
%             configGalvoY = mcaDAQ.galvoConfig();    configGalvoY.name = 'Galvo Y'; configGalvoY.dev = 'cDAQ1Mod1'; configGalvoY.chn = 'ao1';

            configV1 = mcaDAQ.PIE616Config();       configV1.name = 'H Voltage 1';  configV1.chn = 'ao0';
            configV2 = mcaDAQ.PIE616Config();       configV2.name = 'H Voltage 2';  configV2.chn = 'ao1';
            configV3 = mcaDAQ.PIE616Config();       configV3.name = 'H Voltage 3';  configV3.chn = 'ao2';

             configGalvoX = mcaDAQ.galvoConfig();    configGalvoX.name = 'Galvo X'; configGalvoX.dev = 'cDAQ1Mod1'; configGalvoX.chn = 'ao0';
             configGalvoY = mcaDAQ.galvoConfig();    configGalvoY.name = 'Galvo Y'; configGalvoY.dev = 'cDAQ1Mod1'; configGalvoY.chn = 'ao1';
            
            configDoor =   mcaDAQ.digitalConfig();   configDoor.name =  'Door LED'; configDoor.chn =  'Port0/Line7';
            configGreen =  mcaDAQ.greenConfig();
            configRed =    mcaDAQ.redConfig();
            
            flipConfig =        mcaDAQ.digitalConfig();
            flipConfig.chn = 	'Port0/Line1';
            flipConfig.name = 	'Flip Mirror';
            
            config.axesGroups = { {'Micrometers',   mcaMicro(configMicroX), mcaMicro(configMicroY), mcaDAQ(configPiezoZ) }, ...     % Arrange the axes into sets of {name, axisX, axisY, axisZ}.
                                  {'Piezos',        mcaDAQ(configPiezoX),   mcaDAQ(configPiezoY),   mcaDAQ(configPiezoZ) }, ...
                                  {'High Voltage',  mcaDAQ(configV1),       mcaDAQ(configV2),       mcaDAQ(configV3) }, ...
                                  {'Lasers',        mcaDAQ(configDoor),     mcaDAQ(configGreen),    mcaDAQ(flipConfig) } };                 % Eventually put red power on here...
                              
            config.axesGroups{4}{4}.open(); 
                              
            config.numGroups = length(config.axesGroups);
            
            config.joyEnabled = false;
            
%             config.axesGroups = { {'Piezos',        mcAxis('configPiezoX.mat'), mcAxis('configPiezoY.mat'), mcAxis('configPiezoZ.mat') }, ...
%                                   {'Micrometers',   mcAxis('configMicroX.mat'), mcAxis('configMicroY.mat'), mcAxis('configPiezoZ.mat') }, ...
%                                   {'Galvometers',   mcAxis('configGalvoX.mat'), mcAxis('configGalvoY.mat'), mcAxis('configPiezoZ.mat') } };
        end
    end
    
    methods
        function obj = mcUserInput(varin)
            switch nargin
                case 0
                    obj.config = mcUserInput.defaultConfig();   % If no config is given, assume default config.
                case 1
                    obj.interpretConfig(varin);                 % Otherwise, use the given config (inherited from mcSavableClass).
                otherwise
                    error('NotImplemented');
            end
            
            obj.makeGUI();                                      % Then make the GUI.
        end
        
        function makeGUI(varin)
            fw = 300;               % Figure width
            fh = 500;               % Figure height
            
            pp = 5;                 % Panel padding
            pw = fw - 30;           % Panel width
            ph = 200;               % Panel height
            
            bh = 20;                % Button Height
            
            switch nargin
                case 1
                    obj = varin;
                    mcInstrumentHandler.setGlobalWindowKeyPressFcn(@obj.keyPressFunction);
                    
                    f = mcInstrumentHandler.createFigure(obj, 'saveopen');
                    
                    f.Resize =      'off';
                    f.Position =    [100, 100, fw, fh];
                    f.Visible =     'off';
                    f.MenuBar =     'none';
%                     f.ToolBar =     'none';
                    
                    units = 'normalized';
                    pos = [0 0 1 1];
                case 3
                    obj = varin{1};
                    mcInstrumentHandler.setGlobalWindowKeyPressFcn(@obj.keyPressFunction);
                    
                    f =   varin{2};
                    units = 'pixels';
                    pos = varin{3};
                otherwise
                    error('Use either mcUserInput.makeGUI() or mcUserInput.makeGUI(f, position)');
            end
            
            obj.gui.f = f;
            obj.gui.f.CloseRequestFcn = @obj.closeRequestFcn;
            
            obj.gui.tabgroup =  uitabgroup('Parent', f, 'Units', units, 'Position', pos);
            obj.gui.tabGoto =       uitab('Parent', obj.gui.tabgroup, 'Title', 'Goto', 'Units', 'pixels');
            obj.gui.tabInputs =     uitab('Parent', obj.gui.tabgroup, 'Title', 'User Input', 'Units', 'pixels');
%             obj.gui.tabJoystick =   uitab('Parent', obj.gui.tabgroup, 'Title', 'Joystick', 'Units', 'pixels');
            
            
            %%%%%%%%%% GOTO %%%%%%%%%%
            obj.gui.gotoPanels = {};
            
            pause(.01);
            
            tabHeight = obj.gui.tabGoto.Position(4);
            tabHeightInput = obj.gui.tabInputs.Position(4) - 3.5*bh;
            
%             obj.config.axesGroups
            
            obj.config.axesList = {};
            
            for ii = 1:obj.config.numGroups
                obj.gui.gotoPanels{ii} =  uipanel('Parent', obj.gui.tabGoto, 'Title', [num2str(ii) ' : ' obj.config.axesGroups{ii}{1}], 'Units', 'pixels', 'ButtonDownFcn', {@obj.setUserInputMode, ii});
                obj.gui.inputPanels{ii} = uipanel('Parent', obj.gui.tabInputs, 'Units', 'pixels', 'Position', [pp + (ii-1)*((pw-2*pp)/obj.config.numGroups + pp), tabHeightInput, pw/obj.config.numGroups, bh], 'ButtonDownFcn', {@obj.setUserInputMode, ii});
                uicontrol('Parent', obj.gui.inputPanels{ii}, 'Style', 'text', 'String', [num2str(ii) ' : ' obj.config.axesGroups{ii}{1}], 'Units', 'normalized', 'Position', [0 0 1 1], 'Enable', 'inactive', 'ButtonDownFcn', {@obj.setUserInputMode, ii});
                
                y = pp + 2*bh;
                
                for jj = 2:(length(obj.config.axesGroups{ii}))
%                     disp(jj)
                    tf = obj.makeAxisControls(obj.config.axesGroups{ii}{jj}, obj.gui.gotoPanels{ii}, y, ii);
                    
                    if tf
                        y = y - bh;
                    end
                end
                
                for jj = 2:(length(obj.config.axesGroups{ii}))
%                     cellfun(@(a)(a == obj.config.axesGroups{ii}{jj}), obj.config.axesList)
                    if sum(cellfun(@(a)(a == obj.config.axesGroups{ii}{jj}), obj.config.axesList)) == 0
%                         obj.config.axesGroups{ii}{jj}
                        obj.config.axesList{length(obj.config.axesList) + 1} = obj.config.axesGroups{ii}{jj};
                        
%                         obj.config.axesGroups{ii}{jj}
%                         obj.config.axesList{length(obj.config.axesList)}
                    end
                end
                
%                 obj.gui.gotoPanels{ii}.Position = [pp, pp, pw, y + bh];
                tabHeight = tabHeight - y -5*bh;
                obj.gui.gotoPanels{ii}.Position = [pp+1, tabHeight - 2*bh, pw, y + 5*bh - pp];
%                 obj.gui.gotoPanels{ii}.Position = [pp, tabHeight - y, y, pw];
%                 disp(ii);
            end
            
            obj.refreshUserInputMode();
            
            
            %%%%%%%%%% USER INPUTS %%%%%%%%%%
            tabHeight = obj.gui.tabInputs.Position(4) - 5*bh;
            
            bbh = (pw+10)/7; % Big button height
            
            obj.gui.keyUp =     uicontrol('Parent', obj.gui.tabInputs, 'Style', 'push', 'String', 'A', 'Position', [2*bbh, tabHeight - 1*bbh, bbh, bbh], 'Callback', {@obj.userAction_Callback, 2, 1});
            obj.gui.keyLeft =   uicontrol('Parent', obj.gui.tabInputs, 'Style', 'push', 'String', '<', 'Position', [1*bbh, tabHeight - 2*bbh, bbh, bbh], 'Callback', {@obj.userAction_Callback, 1, -1});
            obj.gui.keyDown =   uicontrol('Parent', obj.gui.tabInputs, 'Style', 'push', 'String', 'V', 'Position', [2*bbh, tabHeight - 2*bbh, bbh, bbh], 'Callback', {@obj.userAction_Callback, 2, -1});
            obj.gui.keyRight =  uicontrol('Parent', obj.gui.tabInputs, 'Style', 'push', 'String', '>', 'Position', [3*bbh, tabHeight - 2*bbh, bbh, bbh], 'Callback', {@obj.userAction_Callback, 1, 1});
            
            obj.gui.keyPlus =   uicontrol('Parent', obj.gui.tabInputs, 'Style', 'push', 'String', '+', 'Position', [5*bbh, tabHeight - 1*bbh, bbh, bbh], 'Callback', {@obj.userAction_Callback, 3, 1});
            obj.gui.keyMinus =  uicontrol('Parent', obj.gui.tabInputs, 'Style', 'push', 'String', '-', 'Position', [5*bbh, tabHeight - 2*bbh, bbh, bbh], 'Callback', {@obj.userAction_Callback, 3, -1});
            
            obj.gui.keylist = [obj.gui.keyLeft, obj.gui.keyRight, obj.gui.keyDown, obj.gui.keyUp, obj.gui.keyMinus, obj.gui.keyPlus];
            
%             uicontrol('Parent', obj.gui.tabInputs, 'Style', 'text', 'String', 'Keyboard', 'Position', [pw/3,   tabHeight - 2*bbh - 2*bh, pw/3, bh]);
%             uicontrol('Parent', obj.gui.tabInputs, 'Style', 'text', 'String', 'Joystick', 'Position', [2*pw/3, tabHeight - 2*bbh - 2*bh, pw/3, bh]);
            
            uicontrol('Parent', obj.gui.tabInputs, 'Style', 'text', 'String', 'Enable:', 'Position', [0,   tabHeight - 2*bbh - 2*bh, pw/3, bh]); %, 'HorizontalAlignment', 'right');
            obj.gui.keyEnabled = uicontrol('Parent', obj.gui.tabInputs, 'Style', 'check', 'String', 'Keyboard', 'Position', [pw/3,   tabHeight - 2*bbh - 2*bh, pw/3, bh], 'Value', 1);
            obj.gui.joyEnabled = uicontrol('Parent', obj.gui.tabInputs, 'Style', 'check', 'String', 'Joystick', 'Position', [2*pw/3, tabHeight - 2*bbh - 2*bh, pw/3, bh], 'Value', obj.config.joyEnabled, 'Callback', @obj.joyEnableFunction); %, 'Enable', 'off');
            
            uicontrol('Parent', obj.gui.tabInputs, 'Style', 'text', 'String', 'Keyboard Step', 'Position', [pw/3,   tabHeight - 2*bbh - 4*bh, pw/3, bh]);
            uicontrol('Parent', obj.gui.tabInputs, 'Style', 'text', 'String', 'Joystick Step', 'Position', [2*pw/3, tabHeight - 2*bbh - 4*bh, pw/3, bh]);
            
            y = tabHeight - 2*bbh - 5*bh;
            
            for axis_ = obj.config.axesList
                uicontrol('Parent', obj.gui.tabInputs, 'Style', 'text', 'String', [axis_{1}.config.name ' (' axis_{1}.config.kind.extUnits '): '], 'Position', [0,         y, pw/3, bh], 'HorizontalAlignment', 'right');
                uicontrol('Parent', obj.gui.tabInputs, 'Style', 'edit', 'String', axis_{1}.config.keyStep, 'Position', [pw/3,    y, pw/3, bh], 'Callback', {@setAxisKeyStep_Callback, axis_{1}});
                uicontrol('Parent', obj.gui.tabInputs, 'Style', 'edit', 'String', axis_{1}.config.joyStep, 'Position', [2*pw/3,  y, pw/3, bh], 'Callback', {@setAxisJoyStep_Callback, axis_{1}});
                
                y = y - bh;
            end
            
            obj.gui.joy.throttle = 0;
            obj.gui.joyState = -1;
            obj.gui.axisState = [0 0 0];
            
            obj.openListener();
            obj.openWaypoints();
            
            f.Visible = 'on';
            pause(.1);
            obj.joyEnableFunction(0,0);
        end
        
        function openListener(obj)
            fl = mcAxisListener(obj.config.axesList);
            fl.Position(2) = 670;
        end
        function openWaypoints(obj)
            obj.wp = mcWaypoints();
            obj.wp.f.Position(2) = 400;
        end
        
        function setUserInputMode(obj, ~, ~, mode)
            obj.mode = mode;
            obj.refreshUserInputMode();
        end
        function refreshUserInputMode(obj)
            ii = 1;
            for panel = obj.gui.gotoPanels
                if obj.mode == ii
                    panel{1}.HighlightColor = 'red';
                else
                    panel{1}.HighlightColor = 'white';
                end
                
                ii = ii + 1;
            end
            ii = 1;
            for panel = obj.gui.inputPanels
                if obj.mode == ii
                    panel{1}.HighlightColor = 'red';
                else
                    panel{1}.HighlightColor = 'white';
                end
                
                ii = ii + 1;
            end
        end
        
        function joyEnableFunction(obj, ~, ~)
            if isvalid(obj)
%                 check = obj.gui.joyEnabled.Value
                if obj.gui.joyEnabled.Value
                    mcJoystickDriver(@obj.joyActionFunction);
                else
                    
                end
            else
                % Do something to stop the joystick.
            end
        end
        function shouldContinue = joyActionFunction(obj, ~, event)
            shouldContinue = 1;
            
%             event
            
            if isvalid(obj)
%                 check = obj.gui.joyEnabled.Value
                
                if obj.gui.joyEnabled.Value
                    switch event.type
                        case 0      % Debug
%                             src
                            obj.gui.joyState = event.axis;      % -1:off, 0:can't find id, 1:running
                        case 1      % Button
                            if event.value == 1
                                num = obj.config.numGroups+1;

                                switch event.axis
                                    case 1
                                        if ~isempty(obj.wp) && isvalid(obj.wp)
                                            obj.wp.dropAtAxes_Callback(0, 0);
                                        else
                                            disp('No waypoints connected; not sure what to do...');
                                        end
                                    case 2
                                        'Side'
                                    case 3
                                        '3'
                                    case 4
                                        obj.userAction(3, -1, 1);
                                    case 5
                                        '5'
                                    case 6
                                        obj.userAction(3, 1, 1);
                                    case 7
                                        num = 1;
                                    case 8
                                        num = 4;
                                    case 9
                                        num = 2;
                                    case 10
                                        num = 5;
                                    case 11
                                        num = 3;
                                    case 12
                                        num = 6;
                                end

                                if num <= obj.config.numGroups
                                    obj.setUserInputMode(0, 0, num);
                                end
                            end
                        case 2      % POV
                            if event.value < 360
%                                 event.value
                                x = sind(event.value);
                                y = cosd(event.value);
                                
                                obj.userAction(1, x, 1);
                                obj.userAction(2, y, 1);
                            end
                        case 3      % Axis
%                             event
                            
                            obj.gui.axisState(event.axis) = event.value;
%                             state = obj.gui.axisState
                            
                            if event.axis ~= 3 || sum(obj.gui.axisState(1:2).*obj.gui.axisState(1:2)) < .25     % If XY is displaced by more than .25, block Z.
                                userAction(obj, event.axis, event.value*event.value*event.value, 0)     % Note the cube...
                            end
                        case 4      % Throttle
                            obj.gui.joy.throttle = event.value;
                    end
                else
                    shouldContinue = 0;
                end
            else
                % Do something to stop the joystick.
                shouldContinue = 0;
            end
        end
        function keyPressFunction(obj, src, event)
%             obj
%             isvalid(obj)
%             event
            if isvalid(obj)
                if  obj.gui.keyEnabled.Value
                    focus = gco; %(obj.gui.f);

                    if isprop(focus, 'Style')
                        proceed = (~strcmpi(focus.Style, 'edit') && ~strcmpi(focus.Style, 'choose')) || ~strcmpi(focus.Enable, 'on');    % Don't continue if we are currently changing the value of a edit uicontrol...
                    else
                        proceed = true;
                    end

                    if proceed
                        multiplier = 1;
                        if ismember(event.Modifier, 'shift')
                            multiplier = multiplier*10;
                        end
                        if ismember(event.Modifier, 'alt')
                            multiplier = multiplier/10;
                        end

                        switch event.Key
                            case {'rightarrow', 'd'}
                                obj.userAction(1,  multiplier, 1);
                            case {'leftarrow', 'a'}
                                obj.userAction(1, -multiplier, 1);
                            case {'uparrow', 'w'}
                                obj.userAction(2,  multiplier, 1);
                            case {'downarrow', 's'}
                                obj.userAction(2, -multiplier, 1);
                            case {'equal', 'add', 'e'}
                                obj.userAction(3,  multiplier, 1);
                            case {'hyphen', 'subtract', 'q'}
                                obj.userAction(3, -multiplier, 1);
                            case {'1', '2', '3', '4', '5', '6', '7', '8', '9'}
                                num = str2double(event.Key);

                                if num <= obj.config.numGroups
                                    obj.mode = num;
                                else
                                    obj.mode = 0;
                                end

                                obj.refreshUserInputMode();
                            case {'backquote', '0'}
                                obj.mode = 0;
                                obj.refreshUserInputMode();
                        end
                    end
                end
            else
                mcInstrumentHandler.setGlobalWindowKeyPressFcn('');
            end
        end
        
        function userAction(obj, axis_, value, isKey)
            if value ~= 0
                if obj.mode > 0 && obj.mode <= obj.config.numGroups
                    a = obj.config.axesGroups{obj.mode}{axis_+1};

                    if strcmpi(a.config.kind.kind, 'nidaqdigital')
                        dVal = sign(value);
                    else
                        if isKey
                            dVal = value*a.config.keyStep;
                        else
                            dVal = value*a.config.joyStep*obj.gui.joy.throttle;
                        end
                    end

                    if dVal ~= 0                                                        % If there was a change...
                        val = a.getX() + dVal;                                          % ...calculate the result.

                        if abs(val - a.getXt()) > abs(5*dVal)                           % If the axis is lagging too far behind...
                            obj.flashKey(2*axis_ + (sign(value)-1)/2, [0 0.9400 0], isKey);    % ...then flash green
                        else
                            if iscell(a.config.kind.extRange)
                                switch val
                                    case a.config.kind.extRange
                                        % nothing
                                    otherwise
                                        l = [a.config.kind.extRange{:}] - val;
                                        val = a.config.kind.extRange{find(l.*l == min(l.*l), 1)};     % Change?
                                end
                            else
                                if val >  max(a.config.kind.extRange)                       % Make sure the axis doesn't go out of bounds
                                    val = max(a.config.kind.extRange);
                                end
                                if val <  min(a.config.kind.extRange)
                                    val = min(a.config.kind.extRange);
                                end
                            end

                            if abs(val) < 1e-14
                                val = 0;                                                % Account for arithmatic error.
                            end

                            a.goto(val);                                                % Finally, go to the new position.

                            obj.flashKey(2*axis_ + (sign(value)-1)/2, [0.9400 0 0], isKey);    % ...then flash red
                        end
                    else                                                                % If there wasn't a change...
                        obj.flashKey(2*axis_ + (sign(value)-1)/2, [0.9400 0.9400 0], isKey);   % ...then flash yellow
                    end
                else
                    obj.flashKey(2*axis_ + (sign(value)-1)/2, [0 0 0.9400], isKey);            % ...then flash blue
                end
            end
        end
        function flashKey(obj, key, color, isKey)
            if isKey
                obj.gui.keylist(key).BackgroundColor = color;
                pause(.016);
                obj.gui.keylist(key).BackgroundColor = [0.9400    0.9400    0.9400];
            end
        end
        function userAction_Callback(obj, src, ~, axis_, direction)
            src.Enable = 'off';
%             drawnow;
            src.Enable = 'on';  % This is to remove focus on whatever object may be focused.
            obj.userAction(axis_, direction, 1);
        end

        function tf = makeAxisControls(obj, axis_, parent, y, ii)
%             disp('Making axis');
            fw = 300;               % Figure width
            fh = 500;               % Figure height

            pp = 5;                 % Panel padding
            pw = fw-40;           % Panel width
            ph = 200;               % Panel height

            bh = 20;                % Button Height

            text = uicontrol(   'Parent', parent,...
                                'Style', 'text',...
                                'String', [axis_.config.name ' (' axis_.config.kind.extUnits '): '],...
                                'Position', [pp, y, pw/3, bh],...
                                'HorizontalAlignment', 'right',...
                                'tooltipString', axis_.name());%,...
%                                 'ButtonDownFcn', {@obj.setUserInputMode, ii});
%             jButton= findjobj(text);
%             set(jButton,'Enabled',false);
%             set(jButton,'ToolTipText', axis_.name());

            edit = uicontrol(   'Parent', parent,...
                                'Style', 'edit',...
                                'String', axis_.getX(),...
                                'Value',  axis_.getX(),...
                                'Position', [pp+pw/3, y, pw/4, bh],...
                                'Callback', {@limit_Callback, axis_.config.kind.extRange},...
                                'tooltipString', axis_.nameRange());
            get = uicontrol(    'Parent', parent,...
                                'Style', 'push',...
                                'String', 'Get',...
                                'Position', [2*pp+pw/3 + pw/4, y, pw/6, bh],...
                                'Callback', {@setEditWithValue_Callback, @axis_.getX, edit});
            goto = uicontrol(   'Parent', parent,...
                                'Style', 'push',...
                                'String', 'Goto',...
                                'Position', [2*pp+3*pw/4, y, pw/6, bh],...
                                'Callback', {@evalFuncWithEditValue_Callback, @axis_.goto, edit});

            tf = 1;

        %     l = event.proplistener(axis_, 'inUse', 'PostSet', {@makeUIControlsInactive, [text, edit, get, goto]});
        end
        
        function closeRequestFcn(obj,~,~)
            obj.gui.joyEnabled.Enable = 'off';      % Stop the joystick
            obj.gui.joyEnabled.Value = 0;
            
            % If this mcUserInput's keyPressFunction is used as the globalWindowKeyPressFcn...
            if mcInstrumentHandler.isOpen() && isequal(@obj.keyPressFunction, mcInstrumentHandler.globalWindowKeyPressFcn())
                mcInstrumentHandler.setGlobalWindowKeyPressFcn([]);     % Then remove this from every figure.
            end
            
            pause(1);               % Give the joystick a chance to keep up...
            
            delete(obj.gui.f);      % Then delete everything.
            delete(obj);
        end
    end
end

function setAxisKeyStep_Callback(src, ~, axis_)
    val = str2double(src.String);

    if isnan(val)
        val = axis_.config.keyStep;
    end

    src.String = val;
    axis_.config.keyStep = val;
end
function setAxisJoyStep_Callback(src, ~, axis_)
    val = str2double(src.String);

    if isnan(val)
        val = axis_.config.joyStep;
    end

    src.String = val;
    axis_.config.joyStep = val;
end

function limit_Callback(src, event, range)
    val = str2double(src.String);

    if isnan(val)                   % If it's NaN (if str2double fails), check if it's an equation (eval is ~20 times slower so we only want to use it if it is neccessary)
        try
            val = eval(src.String); % Try to interpret string with eval...
        catch
            val = src.Value;        % If this fails, set to the previous value (stored in Value).
        end
    end

    if isnan(val)                   % If it's still NaN, set to the previous value (stored in Value).
        val = src.Value;
    end
    
    % Now truncate value to the range...
    if iscell(range)
        switch val
            case range
                % nothing
            otherwise
                l = [range{:}] - val;
                val = range{find(l.*l == min(l.*l), 1)};     % Change?
        end
    else
        if val > max(range)
            val = max(range);
        end
        if val < min(range)
            val = min(range);
        end
    end
    
    src.String = val;
    src.Value = val;
end

function setEditWithValue_Callback(src, ~, val, edit)
    src.Enable = 'off';
    drawnow;
    src.Enable = 'on';
    edit.String = val();
end

% function makeUIControlsInactive(src, event, controls)
%     set(controls, 'Active'
% end

function evalFuncWithEditValue_Callback(src, ~, func, edit)
    src.Enable = 'off';
    drawnow;
    src.Enable = 'on';
    func(str2double(edit.String));
end




