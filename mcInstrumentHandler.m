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
        function tf = open()
            tf = true;
            
            params = mcInstrumentHandler.params();
            
            if ~isfield(params, 'open')
                disp('Opening mcInstrumentHandler');
                delete(instrfind)
%                 clear all
                close all
                if ~ismac
                    daqreset
                end
                
                params.open =                       true;
                params.instruments =                {};
                params.shouldEmulate =              false;
                params.saveDirManual =              '';
                params.saveDirBackground =          '';
                params.globalWindowKeyPressFcn =    [];
                params.figures =                    {};
                
                mcInstrumentHandler.params(params);                                 % Fill params with this so that we don't risk infinite recursion when we try to add the time axis.
                
                tf = false;                                                         % Return whether the mcInstrumentHandler was open...
                
                [~, params.hostname] =              system('hostname');
                
                params.hostname = params.hostname(1:end-1);
                
%                 for char = params.hostname
%                     disp(double(char));
%                 end
%                 
%                 params.hostname = strrep(params.hostname, '.', '_');    % Not sure if this is the best way to do this...
%                 params.hostname = strrep(params.hostname, '\n', '');
%                 params.hostname = strrep(params.hostname, '\r', '');
%                 params.hostname = strrep(params.hostname, '\0', '');
                
                params.instruments =                {mcAxis(mcAxis.timeConfig())};  % Initialize with only time (which is special)
                      % Temperary global variable that tells axes/inputs whether to be inEmulation or not. Will be replaced with a better system.
%                 [~, params.hostname] =              system('hostname');
                
                mcInstrumentHandler.params(params);
                
                folder = mcInstrumentHandler.getConfigFolder()
                if ~exist(folder, 'file')
                    mkdir(folder);
                end
                
                mcInstrumentHandler.loadParams();
            
                mkdir(params.saveDirManual);
                mkdir(params.saveDirBackground);
            end
        end
        
        function str = getConfigFolder()
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            str = ['configs' filesep params.hostname filesep];
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
        function str = timestamp(varin)
            if ischar(varin)
                folder = [getSaveFolder(0) varin filesep datestr(now,'yyyy_mm_dd')];
            elseif isnumeric(varin) || islogical(varin)
                folder = [getSaveFolder(varin) datestr(now,'yyyy_mm_dd')];
            else
                error('mcInstrumentHandler: timestamp varin not understood');
            end
            
            if ~exist(folder, 'folder')
                mkdir(folder);
            end
            
            str = [folder filesep datestr(now,'HH_MM_SS_FFF')];
        end
        
        
%         function tf = save(data)
%             mcInstrumentHandler.open();
%         end
%         function tf = saveBackground(data)
%             mcInstrumentHandler.open();
%         end
        
        function params = getParams()
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
        end
        function instruments = getInstruments()
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            instruments = params.instruments;
        end
        function [axes_, names, states] = getAxes()
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            
            axes_ =     {};     % Initialize empty lists.
            names =     {};
            states =    [];
            
            ii = 1;
            
            for instrument = params.instruments
                if isa(instrument{1}, 'mcAxis')                 % If an instrument is a axis...
                    axes_{ii} = instrument{1};                  % ...Then append its information.
                    names{ii} = instrument{1}.nameShort();
                    states(ii) = instrument{1}.getX();
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
                obj2.goto(obj2.getX());
            end
            
            mcInstrumentHandler.params(params);
        end 
        
%         function 
        
        function clearAll() % Usage not recommended.
            mcInstrumentHandler.open();
            params = mcInstrumentHandler.params();
            
            for instrument = params.instruments
                if isa(instrument{1}, 'mcAxis')% && isa(obj, 'mcAxis')) || (isa(instrument{1}, 'mcInput') && isa(obj, 'mcInput'))
                    instrument{1}.close();
                end
            end
            
            mcInstrumentHandler.params([]);
        end
        
%         function removeDeadFigures()
%             mcInstrumentHandler.open();
%             
%             params = mcInstrumentHandler.params();
%             
%             if ~isempty(params.figures)
%                 params.figures{cellfun(@(f)(~isvalid(f)), params.figures)} = [];
%             end
%             
%             mcInstrumentHandler.params(params);
%         end
        
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
        
        function f = createFigure(obj, toolBarMode)     % Creates a figure that has the proper params.globalWindowKeyPressFcn (e.g. for piezo control).
            mcInstrumentHandler.open();
%             mcInstrumentHandler.removeDeadFigures();
            params = mcInstrumentHandler.params();
            
            
%             if ~isempty(params.figures)
%                 a = cellfun(@(x)(isvalid(x)), params.figures);
%                 if sum(a) > 1
% %                     a
% %                     b = strcmp(params.figures{a}.Name, title);
% %                 elseif sum(a) > 1
% %                     a
% %                     params.figures{a}
%                     b = cellfun(@(x)(strcmp(x.Name, title)), params.figures(a));
%                 else
%                     b = 0;
%                 end
%             else
%                 b = 0;
%             end
            
%             if sum(b) == 0
%                 
%             end

            if ischar(obj)
                str = obj;
            else
                str = class(obj);
            end
            
            f = figure('NumberTitle', 'off', 'Tag', str, 'Name', str, 'MenuBar', 'none', 'ToolBar', 'figure');
            
%             toolbar = findall(gcf, 'tag', 'FigureToolBar')
% %             
% %             tools = findall(toolbar)
%             set(toolbar.Children,'Visible','off');

%             disableList = { 'Plottools.PlottoolsOn',...
%                             'Plottools.PlottoolsOff',...
%                             'Annotation.InsertLegend',...
%                             'Annotation.InsertColorbar',...
%                             'DataManager.Linking',...
%                             'Exploration.Brushing',...
%                             'Exploration.DataCursor',...
%                             'Exploration.Rotate',...
%                             'Exploration.Pan',...
%                             'Exploration.ZoomOut',...
%                             'Exploration.ZoomIn',...
%                             'Standard.EditPlot',...
%                             'Standard.PrintFigure',...
%                             'Standard.SaveFigure',...
%                             'Standard.FileOpen',...
%                             'Standard.NewFigure'}
%                         
%             for str = disableList
%                 toolbarObj = findall(gcf, 'tag', str)
%                 if ~isempty(toolbarObj)
%                     str
%                     toolbarObj.Visible = 'off';
%                 end
%             end

%             graphObjs = findall(gcf);
%             
%             graphObjs(3)
% 
%             graphObjs(3).Visible = 'off';

            graphObjs = findall(gcf);
            
            set(graphObjs(3:end), 'Visible', 'off');

%             for graphObj = graphObjs(3:end)
%                 graphObj
%                 graphObj(1)
%                 graphObj(1).Visible = 'off';
%             end
            
            switch toolBarMode
                case 'saveopen'
                    display('here');
%                     toolbar2 = findall(toolbar, 'tag', 'FigureToolBar')
%                     toolbar2.Visible = 'on';
                    

                    saveButton = findall(gcf, 'tag', 'Standard.SaveFigure');
                    saveButton.TooltipString = ['Save ' class(obj)];
                    saveButton.ClickedCallback = @obj.saveGUI_Callback;
                    saveButton.Visible = 'on';

                    loadButton = findall(gcf, 'tag', 'Standard.FileOpen');
                    loadButton.TooltipString = ['Open ' class(obj)];
                    loadButton.ClickedCallback = @obj.loadGUI_Callback;
                    loadButton.Visible = 'on';
                case 'none'
                    % Nothing.
            end
            
%             toolbar = findall(tools, 'tag', 'FigureToolBar');
%             set(toolbar,'Visible','on');
%             
%             hToolbar = findall(gcf,'tag','FigureToolBar');
%             hPrintButton = findall(hToolbar,'tag','Standard.PrintFigure');
%             set(hPrintButton, 'ClickedCallback','printpreview(gcbf)', 'TooltipString','Print Preview');
  
%     'FigureToolBar'
%     'Plottools.PlottoolsOn'
%     'Plottools.PlottoolsOff'
%     'Annotation.InsertLegend'
%     'Annotation.InsertColorbar'
%     'DataManager.Linking'
%     'Exploration.Brushing'
%     'Exploration.DataCursor'
%     'Exploration.Rotate'
%     'Exploration.Pan'
%     'Exploration.ZoomOut'
%     'Exploration.ZoomIn'
%     'Standard.EditPlot'
%     'Standard.PrintFigure'
%     'Standard.SaveFigure'
%     'Standard.FileOpen'
%     'Standard.NewFigure'

            if ~isempty(params.globalWindowKeyPressFcn)
                f.WindowKeyPressFcn = params.globalWindowKeyPressFcn;
            end

            params.figures{length(params.figures)+1} = f;
            
            mcInstrumentHandler.params(params);
        end
    end
end




