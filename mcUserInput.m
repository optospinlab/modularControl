classdef mcUserInput < handle
% mcUserInputGUI returns the uitabgroup reference that contains three tabs:
%   - Goto:     Buttons to control the fields.
%   - Keyboard: which contains fields that customize wasdqe/udlr-+ keyboard input.
%   - Joystick: which contains fields that customize a single joystick (sorry, multiple joysticks are unsupported).
%
%   obj = mcUserInput()             % 
%   obj = mcUserInput(config)       % 
%   obj = mcUserInput('config.mat') % 
%
%   tabgroup = mcUserInputGUI()
%   tabgroup = mcUserInputGUI(f)
%   tabgroup = mcUserInputGUI(f)
    
    properties
        config = [];            % All static variables (e.g. valid range) go in config.
        
        gui = [];               % Variables for the gui.
        
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
            
            configPiezoX = mcAxis.piezoConfig(); configPiezoX.name = 'Piezo X'; configPiezoX.chn = 'ao0';       % Customize all of the default configs...
            configPiezoY = mcAxis.piezoConfig(); configPiezoY.name = 'Piezo Y'; configPiezoY.chn = 'ao1';
            configPiezoZ = mcAxis.piezoZConfig(); configPiezoZ.name = 'Piezo Z'; configPiezoZ.chn = 'ao2';
            
            configMicroX = mcAxis.microConfig(); configMicroX.name = 'Micro X'; configMicroX.port = 'COM5';
            configMicroY = mcAxis.microConfig(); configMicroY.name = 'Micro Y'; configMicroY.port = 'COM6';
            
            configGalvoX = mcAxis.galvoConfig(); configGalvoX.name = 'Galvo X'; configGalvoX.dev = 'cDAQ1Mod1'; configGalvoX.chn = 'ao0';
            configGalvoY = mcAxis.galvoConfig(); configGalvoY.name = 'Galvo Y'; configGalvoY.dev = 'cDAQ1Mod1'; configGalvoY.chn = 'ao1';
            
            config.axesGroups = { {'Piezos',        mcAxis(configPiezoX), mcAxis(configPiezoY), mcAxis(configPiezoZ) }, ...     % Arrange the axes into sets of {name, axisX, axisY, axisZ}.
                                  {'Micrometers',   mcAxis(configMicroX), mcAxis(configMicroY), mcAxis(configPiezoZ) }, ...
                                  {'Galvometers',   mcAxis(configGalvoX), mcAxis(configGalvoY), mcAxis(configPiezoZ) } };
                              
            config.numGroups = length(config.axesGroups);
            
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
                    obj.config = varin;                         % Otherwise, use the given config.
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
                    
                    f = mcInstrumentHandler.createFigure('mcUserInput');
                    
                    f.Resize =      'off';
                    f.Position =    [100, 100, fw, fh];
                    f.Visible =     'off';
                    f.MenuBar =     'none';
                    f.ToolBar =     'none';
                    
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
            
            obj.gui.tabgroup =  uitabgroup('Parent', f, 'Units', units, 'Position', pos);
            obj.gui.tabGoto =       uitab('Parent', obj.gui.tabgroup, 'Title', 'Goto', 'Units', 'pixels');
            obj.gui.tabInputs =     uitab('Parent', obj.gui.tabgroup, 'Title', 'Inputs', 'Units', 'pixels');
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
            
            
            %%%%%%%%%% INPUTS %%%%%%%%%%
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
            obj.gui.joyEnabled = uicontrol('Parent', obj.gui.tabInputs, 'Style', 'check', 'String', 'Joystick', 'Position', [2*pw/3, tabHeight - 2*bbh - 2*bh, pw/3, bh], 'Value', 1);
            
            uicontrol('Parent', obj.gui.tabInputs, 'Style', 'text', 'String', 'Keyboard Step', 'Position', [pw/3,   tabHeight - 2*bbh - 4*bh, pw/3, bh]);
            uicontrol('Parent', obj.gui.tabInputs, 'Style', 'text', 'String', 'Joystick Step', 'Position', [2*pw/3, tabHeight - 2*bbh - 4*bh, pw/3, bh]);
            
            y = tabHeight - 2*bbh - 5*bh;
            
            for axis_ = obj.config.axesList
                uicontrol('Parent', obj.gui.tabInputs, 'Style', 'text', 'String', [axis_{1}.config.name ' (' axis_{1}.config.kind.extUnits '): '], 'Position', [0,         y, pw/3, bh], 'HorizontalAlignment', 'right');
                uicontrol('Parent', obj.gui.tabInputs, 'Style', 'edit', 'String', axis_{1}.config.keyStep, 'Position', [pw/3,    y, pw/3, bh]);
                uicontrol('Parent', obj.gui.tabInputs, 'Style', 'edit', 'String', axis_{1}.config.joyStep, 'Position', [2*pw/3,  y, pw/3, bh]);
                
                y = y - bh;
            end
            
            f.Visible = 'on';
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
        
        function joyActionFunction(obj, ~, event)
            if isvalid(obj)
                
            else
                % Do something to stop the joystick.
            end
        end
        function keyPressFunction(obj, src, event)
%             obj
%             isvalid(obj)
            if isvalid(obj)
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
                            obj.userAction(1,1,multiplier);
                        case {'leftarrow', 'a'}
                            obj.userAction(1,-1,multiplier);
                        case {'uparrow', 'w'}
                            obj.userAction(2,1,multiplier);
                        case {'downarrow', 's'}
                            obj.userAction(2,-1,multiplier);
                        case {'equal', 'e'}
                            obj.userAction(3,1,multiplier);
                        case {'hyphen', 'q'}
                            obj.userAction(3,-1,multiplier);
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
            else
                mcInstrumentHandler.setGlobalWindowKeyPressFcn('');
            end
        end
        
        function userAction(obj, axis_, direction, multiplier)
            if obj.mode > 0 && obj.mode <= obj.config.numGroups
                a = obj.config.axesGroups{obj.mode}{axis_+1};
                if strcmpi(a.config.kind.kind, 'nidaqdigital')
                    if multiplier
                        val = a.getX() + direction;
                    else
                        val = a.getX() + direction;
                    end
                else
                    if multiplier
                        val = a.getX() + direction*multiplier*a.config.keyStep;
                    else
                        val = a.getX() + direction*a.config.joyStep;
                    end
                end
                
                if val >  max(a.config.kind.extRange)
                    val = max(a.config.kind.extRange);
                end
                if val <  min(a.config.kind.extRange)
                    val = min(a.config.kind.extRange);
                end
                
                if abs(val) < 1e-14
                    val = 0;            % Account for arithmatic error.
                end
                
                a.goto(val);
                
                obj.gui.keylist(2*axis_ + (direction-1)/2).BackgroundColor = [0.9400    0       0];         % Red
                pause(.05);
%                 drawnow;
                obj.gui.keylist(2*axis_ + (direction-1)/2).BackgroundColor = [0.9400    0.9400    0.9400];
%                 drawnow;
            else
                obj.gui.keylist(2*axis_ + (direction-1)/2).BackgroundColor = [0         0         0.9400];  % Blue
                pause(.05);
%                 drawnow;
                obj.gui.keylist(2*axis_ + (direction-1)/2).BackgroundColor = [0.9400    0.9400    0.9400];
%                 drawnow;
            end
        end
        function userAction_Callback(obj, src, ~, axis_, direction)
            src.Enable = 'off';
            drawnow;
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
    end
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
    if val > max(range)
        val = max(range);
    end
    if val < min(range)
        val = min(range);
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




