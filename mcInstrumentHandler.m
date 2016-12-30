classdef mcInstrumentHandler < handle
% mcInstrumentHandler, as its name suggests, handles all the instruments to make sure that none of 
% them are open at the same time. The mcInstrumentHandler itself is a Static class (i.e. only one 
% instance) and only one copy of its variable 'params' will be stored via exploitation of persistant.
%
% Syntax:
%
% (Private)
%   params = mcInstrumentHandler.Params()           % Returns the persistant params.
%   params = mcInstrumentHandler.Params(newparams)  % Sets the persistant params to newparams; again returns params.
%
% (Public)
%   tf = mcInstrumentHandler.open()                 % If params has not been initiated, then initiate params... ...with default values (will search for [params.hostname].mat). Returns whether mcInstrumentHandler was open before calling this.
%
% % (Not currently enabled)
% % tf = mcInstrumentHandler.open(config)           %                                                           ...with the contents of config (instruments, etc are overwritten).
% % tf = mcInstrumentHandler.open('config.mat')     %                                                           ...with the contents of config.mat (instruments, etc are overwritten).
%
%   params = mcInstrumentHandler.getParams()                % Returns the structure params.
%   instruments = mcInstrumentHandler.getInstruments()      % Returns the cell array params.instruments.
%   [axes_, names, states] = mcInstrumentHandler.getAxes()  % Returns a matrix axes_ containing the mcAxis oject for every axis, a cell array names containing the mcAxis.nameShort() for every axis, and a matrix states containing the mcAxis.x of every axis.
%   [inputs, names] = mcInstrumentHandler.getInputs()       % Returns a matrix inputs containing the mcAxis oject for every axis and a cell array names containing the mcInput.nameShort() for every axis.
%
%   obj2 = mcInstrumentHandler.register(obj)        % If obj already exists in params.instruments as obj2 (perhaps in another form or under a different name), then return obj2. Otherwise, add obj to params.instruments and return obj.
%
% Status: Mostly finished, but needs commenting.

    properties
        % No properties.
    end

    methods (Static, Access=private)
        function val = params(newval)
            persistent params;      % Apparently, this persistent workaround is the best way to get one instance of a variable for an entire class.
            if nargin > 0           % If we are setting params
                params = newval;
            end
            val = params;
        end
    end

    methods (Static)
        function ver = version()
            ver = [0 51];
        end
        function tf = open()
            tf = true;
            
            params = mcInstrumentHandler.params();
            
            if ~isfield(params, 'open')
                disp('Opening mcInstrumentHandler');
                delete(instrfind)
%                 clear all
%                 close all
                if ~ismac       % Change eventually...
                    daqreset
                end
                
                if ~usejava('swing')
                    error('mcInstrumentHandler: Java Swing import failed. Not sure what to do if this happens.');
                end
                
                params.open =                       true;
                
                params.instruments =                {};
                params.shouldEmulate =              false;
                params.saveDirManual =              '';
                params.saveDirBackground =          '';
                params.globalWindowKeyPressFcn =    [];
                params.figures =                    {};
                params.registeredInstruments =      [];
                
                params.warningLight =               [];     % Future...
                params.defaultVideo =               [];
                
                tf = false;                                         % Return whether the mcInstrumentHandler was open...
                
                [~, params.hostname] = system('hostname');          % A quick way to identify which system we are on.
                
                params.hostname(params.hostname < 32 | params.hostname >= 127) = '';    % Make sure only sensible characters are used (e.g. no \0)
                
                params.hostname = strrep(params.hostname, '.', '_');    % Not sure if this is the best way to do this...
                params.hostname = strrep(params.hostname, ':', '_');

                params.mcFolder = pwd;                                              % Get the current directory
                
                while isempty(params.mcFolder) || ~strcmp(params.mcFolder(end-13:end), 'modularControl')        % Get the current directory
                    mcDialog('For everything to function properly, mcInstrumentHandler must know where the modularControl folder is. Press OK to select that folder.', 'Need modularControl folder');
                    
                    params.mcFolder = uigetdir(params.mcFolder, 'Please choose the modularControl folder.');
                end

                mcInstrumentHandler.params(params);                 % Load persistant params with this so that we don't risk infinite recursion when we try to add the time axis (see below).
                
                params.instruments = {mcAxis(mcAxis.timeConfig())}; % Initialize with only time (which is special)
                
                mcInstrumentHandler.params(params);                 % Finally, load persistant params with this.
                
                folder = mcInstrumentHandler.getConfigFolder();
                if ~exist(folder, 'file')
                    mkdir(folder);
                end
                
                mcInstrumentHandler.loadParams();
                
                if isempty(params.saveDirManual)
                    mcInstrumentHandler.setSaveDir(false);
                end
                if isempty(params.saveDirBackground)
                    mcInstrumentHandler.setSaveDir(true);
                end
            end
        end
        function tf = isOpen()
            params = mcInstrumentHandler.params();
            
            tf = isfield(params, 'open');
        end
        
        function str = getConfigFolder()
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            str = [params.mcFolder filesep 'configs' filesep params.hostname filesep];
        end
        
        function saveParams()
            mcInstrumentHandler.open();
            params2 = mcInstrumentHandler.params();
            
            params.saveDirManual = params2.saveDirManual;           % only save saveDirManual and saveDirBackground...
            params.saveDirBackground = params2.saveDirBackground;
            
            save([mcInstrumentHandler.getConfigFolder() 'params.mat'], 'params');
        end
        function loadParams()
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            
            fname = [mcInstrumentHandler.getConfigFolder() 'params.mat'];
            
            if exist(fname, 'file')
                p = load(fname);
                params.saveDirManual = p.params.saveDirManual;       % only load saveDirManual and saveDirBackground...
                params.saveDirBackground = p.params.saveDirBackground;
            end
            
            mcInstrumentHandler.params(params);
        end
        function setSaveDir(isBackground)
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            
            if isBackground
                while all(params.saveDirBackground == 0)
                    mcDialog('Every mcData scan saves its data in the background once the scan has finished. Press OK to select which folder this background data should be saved in.', 'Need background saving folder');

                    params.saveDirBackground =  uigetdir(params.mcFolder, 'Please choose the background saving folder.');
                end
            else
                while all(params.saveDirManual == 0)
                    mcDialog('When the user manually chooses to save data, they are prompted with a folder selection UI. Press OK to select the folder that the folder selection UI should start in.', 'Need manual saving folder');

                    params.saveDirManual =  uigetdir(params.mcFolder, 'Please choose the manual saving folder.');
                end
            end
            
%             if ~isempty(params.saveDirManual) && ~exist(params.saveDirManual, 'dir')
%                 mkdir(params.saveDirManual);
%             end
%             if ~isempty(params.saveDirBackground) && ~exist(params.saveDirBackground, 'dir')
%                 mkdir(params.saveDirBackground);
%             end
            
            mcInstrumentHandler.params(params);
            
            mcInstrumentHandler.saveParams()
        end
        
        function setSaveFolder(isBackground, str)
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            
            mkdir(str);
            
            if isBackground
                params.saveDirBackground = str;
            else
                params.saveDirManual = str;
            end
            
            mcInstrumentHandler.params(params);
            mcInstrumentHandler.saveParams();
        end
        function str = getSaveFolder(isBackground)
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            
            if isBackground
                str = params.saveDirBackground;
            else
                str = params.saveDirManual;
            end
        end
        function [str, stamp] = timestamp(varin)
%             name = '';
%             if iscell(varin)
%                 name = [' ' varin{2}];
%                 varin = varin{1};
%             end
            
            if ischar(varin)                                % If varin is a string, folder = '<manualsavedir>\<string>\<yyyy_mm_dd>'
                folder = [mcInstrumentHandler.getSaveFolder(0) filesep varin filesep datestr(now,'yyyy_mm_dd')];
            elseif isnumeric(varin) || islogical(varin)     % If varin is a number or t/f, folder = '<manualsavedir>\<yyyy_mm_dd>' or '<backgroundsavedir>\<yyyy_mm_dd>' depending upon whether varin evaluates as true or false
                folder = [mcInstrumentHandler.getSaveFolder(varin) filesep datestr(now,'yyyy_mm_dd')];
            else
                error('mcInstrumentHandler: timestamp varin not understood');
            end
            
            if ~exist(folder, 'dir')                       % Make this directory if it does not already exist.
                mkdir(folder);
            end
            
            stamp = datestr(now,'HH_MM_SS_FFF');
            
            str = [folder filesep stamp];   % Then return the string '<folder>\HH_MM_SS_FFF' (i.e. the file is saved as the time inside the date folder)
        end
        
        
%         function tf = save(data)
%             mcInstrumentHandler.open();
%         end
%         function tf = saveBackground(data)
%             mcInstrumentHandler.open();
%         end
        
        % GETTING FUNCTIONS
        function params = getParams()
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
        end
        function instruments = getInstruments()
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            instruments = params.instruments;
        end
        function [axes_, names, configs, states] = getAxes()
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            
            axes_ =     {};     % Initialize empty lists.
            names =     {};
            states =    [];
            
            ii = 1;
            
            for instrument = params.instruments
                if isa(instrument{1}, 'mcAxis')                 % If an instrument is an axis...
                    axes_{ii} =     instrument{1};              % ...Then append its information.
                    names{ii} =     instrument{1}.nameShort();
                    configs{ii} =   instrument{1}.config;
                    states(ii) =    instrument{1}.getX();
                    ii = ii + 1;
                end
            end
        end
        function [inputs, names] = getInputs()
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            
            inputs =    {};     % Initialize empty lists.
            names =     {};
            ii = 1;
            
            for instrument = params.instruments
                if isa(instrument{1}, 'mcInput')                % If an instrument is a axis...
                    inputs{ii} = instrument{1};                 % ...Then append its information.
                    names{ii} = instrument{1}.nameShort();
                    ii = ii + 1;
                end
            end
        end
        
        % INSTRUMENT REGISTRATION
        function obj2 = register(obj)
            mcInstrumentHandler.open();
%             if ~isfield(obj, 'config')
%                 error('All instruments must have a config field');
%             else
%                 if ~isfield(obj.config, 'kind')
%                     error('All instruments must have a config.kind field');
%                 else
%                     if ~isfield(obj.config.kind, 'kind')
%                         error('All instruments must have a config.kind.kind field');
%                     end
%                 end
%             end
            
            obj2 = obj;
            
            params = mcInstrumentHandler.params();
            
            for instrument = params.instruments
                if (isa(instrument{1}, 'mcAxis') && isa(obj, 'mcAxis')) || (isa(instrument{1}, 'mcInput') && isa(obj, 'mcInput'))
                    if instrument{1} == obj
                        obj2 = instrument{1};
%                         warning(['The attempted addition "' obj.name() '" is identical to the already-registered "' obj2.name() '." We will use the latter.']); % ' the latter will not be registered, and the former will be used instead.']);
                        return;
                    end
                end
            end
            
            params.instruments{length(params.instruments) + 1} = obj2;
            if isa(obj2, 'mcAxis') && ~strcmpi(obj2.config.kind.kind, 'manual')
                obj2.read();
                obj2.goto(obj2.getX());
            end
            
            mcInstrumentHandler.params(params);
        end 
        
        % UICONTROL REGISTRATION (Unfinished feature!)
        function registerControl(control, controlledInstruments)    % In: uicontrol and cell array of controlled instruments.
            mcInstrumentHandler.open();
            
            params = mcInstrumentHandler.params();
            
            if ~isa(control, 'matlab.ui.control.UIControl')
                error('mcInstrumentHandler.registerControl(control, controlledInstruments): Expected a UIControl as first input...');
            end
            
            if isempty(params.registeredInstruments)
                params.registeredInstruments = containers.Map('UniformValues', false);
            end
            
            for instrument = controlledInstruments
                str = instrument{1}.name();
                
                if params.registeredInstruments.isKey(str)
                    params.registeredInstruments(str) = [params.registeredInstruments(str) {control}];
                else
                    params.registeredInstruments(str) = {control};
                end
            end
            
            mcInstrumentHandler.params(params);
        end
        function setRegisteredControls(instrument, state)
            mcInstrumentHandler.open();
            
            params = mcInstrumentHandler.params();
            
            if ~ischar(state)       % Convert a boolean state to 'on'/'off'...
                if state
                    state = 'on';
                else
                    state = 'off';
                end
            end
            
            if isempty(params.registeredInstruments)
                % No controls to disable...
            else
                str = instrument{1}.name();
                
                if params.registeredInstruments.isKey(str)
                    for control = params.registeredInstruments(str)
                        control{1}.Enable = state;
                    end
                else
                    % No controls to disable...
                end
            end
        end
        
        % CLEAR PARAMS
        function clearAll() % Resets params; Usage not recommended.
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            
            for instrument = params.instruments
                if isa(instrument{1}, 'mcAxis')% && isa(obj, 'mcAxis')) || (isa(instrument{1}, 'mcInput') && isa(obj, 'mcInput'))
                    instrument{1}.close();
                end
            end
            
            mcInstrumentHandler.params([]);
        end
        
        % KEYPRESSFCN
        function setGlobalWindowKeyPressFcn(fcn)
            mcInstrumentHandler.open();
            
%             mcInstrumentHandler.removeDeadFigures();
            params = mcInstrumentHandler.params();
            params.globalWindowKeyPressFcn = fcn;
            
            for fig = params.figures
                if isvalid(fig{1})
%                 fig.WindowKeyPressFcn = fcn;
                    fig{1}.WindowKeyPressFcn = fcn;
                end
            end
                
            mcInstrumentHandler.params(params);
        end
        function fcn = globalWindowKeyPressFcn()
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            fcn = params.globalWindowKeyPressFcn;
        end
        
        % RESET DAQ
        function resetDAQ()
            instruments = mcInstrumentHandler.getInstruments();
            
            disp('Resetting DAQ devices:');
            
            for ii = 1:length(instruments)
                if strcmpi(instruments{ii}.config.kind.kind(1:2), 'ni')
                    disp(['    Closing ' instruments{ii}.config.name]);
                    instruments{ii}.close();
                end
            end
            
            daqreset();
            disp('Reset DAQ.');
        end
        
        % FIGURE
        function f = createFigure(obj, toolBarMode)     % Creates a figure that has the proper params.globalWindowKeyPressFcn (e.g. for arrow key control outside of mcUserInput).
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();

            if ischar(obj)
                str = obj;
            else
                str = class(obj);
            end
            
            f = figure('NumberTitle', 'off', 'Tag', str, 'Name', str, 'MenuBar', 'none', 'ToolBar', 'none', 'Visible', 'off');    % , 'ToolBar', 'figure');
            
            if isa(obj, 'mcSavableClass')
                
            end
            
%             if isfield(obj, 'config')
%                 if isfield(obj.config, 'gui')
%                     if isfield(obj.config.gui, 'position')
%                         f.Position = obj.config.gui.position;
%                     end
%                 end
%             end
            
            if strcmp(toolBarMode, 'saveopen')
                t = uitoolbar(f, 'tag', 'FigureToolBar');
                
                uipushtool(t, 'TooltipString', 'Open in New Window',  'ClickedCallback', @obj.loadNewGUI_Callback,    'CData', iconRead(fullfile(params.mcFolder, 'icons','file_open_new.png')));
                uipushtool(t, 'TooltipString', 'Open in This Window', 'ClickedCallback', @obj.loadGUI_Callback,       'CData', iconRead(fullfile(params.mcFolder, 'icons','file_open.png')));
                
%                 uipushtool(t, 'TooltipString', 'Save As', 'ClickedCallback', @obj.saveAsGUI_Callback, 'CData', iconRead(fullfile(params.mcFolder, 'icons','file_save_as.png')));
                uipushtool(t, 'TooltipString', 'Save',    'ClickedCallback', @obj.saveGUI_Callback,   'CData', iconRead(fullfile(params.mcFolder, 'icons','file_save.png')));
            end
            
            if ~isempty(params.globalWindowKeyPressFcn)
                f.WindowKeyPressFcn = params.globalWindowKeyPressFcn;
            end

            params.figures{length(params.figures)+1} = f;
            
            mcInstrumentHandler.params(params);
        end
    end
end




