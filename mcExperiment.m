classdef mcExperiment < mcInput
% mcExperiment is a generalization of experimental procedures.
%
% Also see mcInput.

    properties
        f = [];     % figure
        t = [];     % uitable
        pcb = [];   % proceed checkbox
        % pb = [];  % proceed button
        
        proceeding = false;
        
        num = 0;
        
        objects = {};
        doneboxes = {};
        proceedboxes = {};
        names = {};
        push1 = {};
        push2 = {};
    end

    methods (Static)
        % Neccessary extra vars:
        %  - steps
        %  - results
        
        function config = defaultConfig()               % Static config that should be used if no configuration is provided upon intialization.
            config = mcExperiment.customConfig();
        end
        function config = customConfig()
            config.class = 'mcExperiment';
            
            config.name = 'Template';

            config.kind.kind =          'template';     % ** Change this to the programatic name that the program should use for this identity of mci<MyNewInput>.
            config.kind.name =          'Template';     % ** Change this to the technical name (e.g. name of device) for this identity of mci<MyNewInput>.
            config.kind.intUnits =      'units';        % ** Rename these to whatever units are used (e.g. counts).
            config.kind.shouldNormalize = false;        % (Not sure if this is functional.) If this variable is flagged, the measurement is subtracted from the previous and is divided by the time spent on a pixel. Not that this is done outside the measurement currently in mcData (individual calls to .measure() will not have this behavior currently)
            config.kind.sizeInput =    [1 1];           % ** The size (i.e. dimension) of the measurement. For a spectrum, this might be [512 1], a vector 512 pixels long. For a camera, this might be [1280 720]. Future: make NaN functional for dimensions of unknown length (e.g. a string of unknown length).
            
            step1config = mcaDAQ.defaultConfig();
            step2config = mcData.defaultConfiguration();
            
            config.overview =   'Overview should be used to describe a mcExperiment.';
            config.inputs =     { NaN, NaN, 5, NaN };   % Array containing the input for each step (can be set
            config.steps =      {   {'Goto',            'Example goto step.',                        step1config};...
                                    {'mcData',          'Example scan step.',                        step2config};...
                                    {'Pause (5 sec)',   'Example pause step (for five seconds.',     'pause'};...
                                    {'mcData w\ load',  'Example scan step (with loading option).',  step2config} };
%             config.steps =      { {'Mirror Down', 'This step moves the SPCM mirror down into spectrometer mode.', } };
            config.data =       { NaN, NaN, NaN, NaN };     % Array containing the result of each step (for use later)
            config.current =    1;                          % Current step
            config.autoProDef = true;                       % Default value for the autoproceed checkbox.
            config.dname = '';                              % Name of directory to save to.
            
            % runtime generated:
            %   - config.class
        end
%         function config = addStep(config, name, tooltip, data, enableLoad)
%             config.steps{end+1} =   {name, tooltip, data, enableLoad};
%             config.inputs{end+1} =  NaN;
%             config.data{end+1} =    NaN;
%         end
    end
    
    methods             % Initialization method (this is what is called to make an input object).
        function e = mcExperiment(varin)
            e.extra = {'overview', 'inputs', 'steps', 'results'};
            if nargin == 0
                e.construct(e.defaultConfig());
            else
                e.construct(varin);
            end
            e.inEmulation = false;  % Never emulate.
            e = mcInstrumentHandler.register(e);
        end
    end
    

    % These methods overwrite the empty methods defined in mcInput. These methods are used in the uncapitalized parent methods defined in mcInput.
    methods
        function str = NameShort(e)     % 'short' name, suitable for UIs/etc.
            str = [e.config.name];
        end
        function str = NameVerb(I)      % 'verbose' name, suitable to explain the identity to future users.
            str = [e.config.name ' (mcExperiment with overview: ' I.config.overview ')'];  % ** Change these to your custom vars.
        end
        
        %EQ ------------- The function that should return true if the custom vars are the same (future: use i.extra for this?)
        function tf = Eq(~, ~)          % Compares two mcExperiments
            tf = false;                 % Don't care.
        end

        % OPEN/CLOSE ---- Opens/closes the GUI for the experiment.
        function Open(e)
            e.f = mcInstrumentHandler.createFigure(e, 'none');      % Create a figure for this experiment with no toolbars.
            
            e.f.Name = ['mcExperiment - ' e.config.name];
            
            e.num = length(e.config.steps);
            
            if e.num ~= length(e.config.inputs)
                error('mcExperiment.Open(): Expected the same number of inputs as steps');
            end
            if e.num ~= length(e.config.data)
                error('mcExperiment.Open(): Expected the same number of outputs as steps');
            end
            
            numlines =      e.num + 1; % Number of steps + overview.
%             p =             5;                          % Table padding
            
%             mat2cell((0:numlines-1 < e.config.current)', ones(1, numlines), 1)
%             
%             [{'Overview'}; e.config.steps(:, 1)] 
%             
%             [{'View'}; cellfun(@(s)(s.class), e.config.steps(:, 3), 'UniformOutput', false)]
            
            w = 300;
            bh = 18;
            cw = 20;
            p = 5;
            bw = (w - 5*p - 2*cw)/2;
            
            t0 = p;
            t1 = t0 + cw + p;
            t2 = t1 + bw + p;
            t3 = t2 + (bw-p)/2 + p;
            t4 = t2 + bw + p;
            
%             uicontrol('Style', 'text', 'HorizontalAlign', 'center', 'String', 'Done',   'Position', [t0, p + (e.num+2)*bh, cw, bh]);
            uicontrol(  'Parent', e.f,...
                        'Style', 'text',...
                        'FontWeight', 'bold',...
                        'HorizontalAlign', 'left',...
                        'String', 'Name',...
                        'TooltipString', 'The name of each step',...
                        'Position', [t1, p + (e.num+1)*bh, bw, bh]);
            uicontrol(  'Parent', e.f,...
                        'Style', 'text',...
                        'FontWeight', 'bold',...
                        'HorizontalAlign', 'left',...
                        'String', 'Command',...
                        'TooltipString', sprintf('Buttons to interact with each step:\n\n + Aquire starts the step\n + Redo returns to the step'),...
                        'Position', [t2, p + (e.num+1)*bh, bw, bh]);
            uicontrol(  'Parent', e.f,...
                        'Style', 'text',...
                        'FontWeight', 'bold',...
                        'HorizontalAlign', 'center',...
                        'String', 'Auto',...
                        'TooltipString', 'Whether or not the step should proceed automatically',...
                        'Position', [t4, p + (e.num+1)*bh, cw+5, bh]);
                    
                    
            uicontrol(  'Parent', e.f,...
                        'Style', 'text',...
                        'HorizontalAlign', 'left',...
                        'Position', [t1, p + (e.num)*bh, bw, bh],...
                        'String', 'Overview',...
                        'TooltipString', 'Read the overview to learn more about the experiment.');
            
            e.objects =         cell(1, e.num);
            e.doneboxes =       cell(1, e.num);
            e.names =           cell(1, e.num);
            e.push1 =           cell(1, e.num);
            e.push2 =           cell(1, e.num);
            e.proceedboxes =    cell(1, e.num);
            
            e.config.class =    cell(1, e.num);
            
            for ii = 1:e.num
                e.doneboxes{ii} =   uicontrol(  'Parent', e.f,...
                                                'Style', 'check',...
                                                'Value', 1,...
                                                'HorizontalAlign', 'left',...
                                                'Position', [t0, p + (e.num-ii)*bh, cw, bh],...
                                                'Enable', 'Inactive');
                e.names{ii} =       uicontrol(  'Parent', e.f,...
                                                'Style', 'text',...
                                                'HorizontalAlign', 'left',...
                                                'Position', [t1, p + (e.num-ii)*bh, bw, bh],...
                                                'String', e.config.steps{ii}{1},...
                                                'TooltipString', e.config.steps{ii}{2});
                e.push1{ii} =       uicontrol(  'Parent', e.f,...
                                                'Style', 'push',...
                                                'Position', [t2, p + (e.num-ii)*bh, (bw-p)/2, bh],...
                                                'String', 'View');
                e.push2{ii} =       uicontrol(  'Parent', e.f,...
                                                'Style', 'push',...
                                                'Position', [t3, p + (e.num-ii)*bh, (bw-p)/2, bh],...
                                                'String', 'Redo');
                e.proceedboxes{ii}= uicontrol(  'Parent', e.f,...
                                                'Style', 'check',...
                                                'Value', 1,...
                                                'HorizontalAlign', 'left',...
                                                'Position', [t4, p + (e.num-ii)*bh, cw, bh]);
                                            
                if isstruct(e.config.steps{ii}{3})
                    if isfield(e.config.steps{ii}{3}, 'class')
                        e.config.class{ii} = e.config.steps{ii}{3}.class;
                    else
                        error(['mcData(): Axis config for ' e.config.steps{ii}{3}.name ' given without class.']);
                    end
                elseif ischar(e.config.steps{ii}{3})
                    e.config.class{ii} = e.config.steps{ii}{3};
                    
                    switch lower(e.config.class{ii}(1:2))
                        case 'mc'
                            error('mcExperiment.Open(): String-type step should not be allowed to impersonate an mcClass');
                    end
                else
                    error(['mcExperiment.Open(): Type ' class(e.config.steps{ii}{3}) ' not understood.']);
                end
                
                switch lower(e.config.class{ii}(1:3)) % Change, in case the first three letters aren't enough?
                    case 'mca'  % mcAxis
                        c = e.config.steps{ii}{3};
                        e.objects{ii} = eval([c.class '(c)']);  % Make an mcAxis (subclass) object based on that config.
                    case 'mci'  % mcInput
                        e.objects{ii} = mcDataViewer(mcData(mcData.singleConfiguration(e.config.steps{ii}{3})), false, false);
                    case 'mcd'  % mcData
                        if strcmpi(e.config.class{ii}, 'mcData')
                            data = mcData(e.config.steps{ii}{3});
                            data.r.scanMode = -1;                               % Make sure this is paused at start...
                            e.objects{ii} = mcDataViewer(data, false, false);   % ...and don't initially show the gui.
                        else
                            warning('mcExperiment.Open(): Class starting with mcd not understood');
                        end
                    case 'pau'  % pause
                        % Do nothing.
                end
            end
            
            pause(.05);
            
%             tdata = cell(numlines, 4);
%             
%             % Make the first line of the table - the overview of this mcExperiment.
%             tdata{1, 1} = ' ';
%             tdata{1, 2} = 'Overview';
%             tdata{1, 3} = '<html><u style="color:blue">View</u></html>';
%             
%             % Make the lines which represent each step of this mcExperiment.
%             for ii = 2:numlines
%                 c = e.config.steps{ii-1}{3};
%                 
%                 e.objects{ii-1} = eval([c.class '(c)']);
%                 
%                 tdata{ii, 1} = ii-1 < e.config.current;
%                 tdata{ii, 2} = e.config.steps{ii-1}{1};
%                 
%                 if strcmpi(c.class, 'mcData')
%                     tdata{ii, 3} = '<html>mcData (<u style="color:blue">View</u>)</html>';
%                 else
%                     tdata{ii, 3} = c.class;
%                 end
%                 
%                 if      ii-1 < e.config.current
%                     tdata{ii, 4} = '<html><u style="color:blue">Redo</u></html>';
%                 elseif  ii-1 == e.config.current
%                     tdata{ii, 4} = '<html><u style="color:blue">Waiting</u></html>';
%                 else
%                     tdata{ii, 4} = '<html><u style="color:blue">Skip To Here</u></html>';
%                 end
%             end
%             
%             % Future?: Make lines denoting the analytical result of the experiment.
%             
%             e.t = uitable(  'Position',     [p p w numlines*18+18],...
%                             'RowName',      num2cell(0:numlines-1),...
%                             'ColumnName',   {'Done?', 'Step Name' , 'Task', 'Interact'},...
%                             'ColumnWidth',  {40, 'auto', 'auto'},...
%                             'Data',         tdata,...
%                             'CellSelectionCallback', @e.selectionCallback);
            
%             e.t = uitable(  'Position',     [p p w numlines*18+18],...
%                             'RowName',      num2cell(0:numlines-1),...
%                             'ColumnName',   {'Done?', 'Step Name' , 'Task', 'Interact'},...
%                             'ColumnWidth',  {40, 'auto', 'auto'},...
%                             'Data',         [mat2cell((0:numlines-1 < e.config.current)', ones(1, numlines), 1)...     
%                                             [{'Overview'}; e.config.steps(:, 1)]...
%                                             [{'<html><u style="color:blue">View</u></html>'}; cellfun(@(s)(['<html> ' s.class ' (<u style="color:blue">View</u>)</html>']), e.config.steps(:, 3), 'UniformOutput', false)]],....
%                             'CellSelectionCallback', @e.selectionCallback);

            
            % Auto-proceed check box.
            e.pcb = uicontrol('Parent', e.f, 'Style', 'check', 'Position', [t0          numlines*18+18 + 2*p bw bh], 'String', 'Auto Proceed?', 'Value', e.config.autoProDef);
            
            % Proceed button.
            uicontrol('Parent', e.f, 'Style', 'push',  'Position', [t2   numlines*18+18 + 2*p bw bh], 'String', 'Proceed');
                        
            e.f.Position = [0 0 (w) (numlines*18+18 + 3*p + bh)];
            
            e.refreshStep()
            e.f.Visible = 'on';
        end
        function Close(e)
            % Save!
            
            delete(e.f);
        end
        
        % MEASURE ------- The 'meat' of the input: the funtion that actually does the measurement and 'inputs' the data. Ignore integration time (with ~) if there should not be one.
        function data = Measure(e, ~)
            
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
        
        function refreshStep(e)
            for ii = 1:e.num
                if      ii < e.config.current
                    e.doneboxes{ii}.Value = 1;
                    e.doneboxes{ii}.BackgroundColor = [0.9400 0.9400 0.9400];
                    
                    switch lower(e.config.class{ii}(1:3))
                        case {'mcd', 'mci'}
                            e.push2{ii}.String = 'View';
                            e.push2{ii}.Enable = 'on';
                        otherwise
                            e.push2{ii}.Visible = 'off';
                    end
                    
                    e.push1{ii}.String = 'Redo';
                    e.push1{ii}.Enable = 'on';
                elseif  ii == e.config.current && e.proceeding
                    e.doneboxes{ii}.Value = 1;
                    e.doneboxes{ii}.BackgroundColor = [0 0.9400 0];
%                     e.names{ii}.BackgroundColor = [0 0.9400 0];
                    
                    switch lower(e.config.class{ii}(1:3))
                        case {'mcd', 'mci'}
                            e.push2{ii}.String = 'View';
                            e.push2{ii}.Enable = 'on';
                            e.push1{ii}.String = 'Pause';
                            e.push1{ii}.Enable = 'on';
                        case 'mca'
                            e.push1{ii}.String = 'Goto';
                            e.push1{ii}.Enable = 'off';
                            e.push2{ii}.Visible = 'off';
                        case 'pau'
                            e.push1{ii}.String = 'Pause';
                            e.push1{ii}.Enable = 'off';
                            e.push2{ii}.Visible = 'off';
                        otherwise
                            e.push1{ii}.Visible = 'off';
                            e.push2{ii}.Visible = 'off';
                    end
                    
                elseif  ii >= e.config.current
                    e.doneboxes{ii}.Value = 0;
                    e.doneboxes{ii}.BackgroundColor = [0.9400 0.9400 0.9400];
                    
                    if ii == e.config.current
                        e.doneboxes{ii}.BackgroundColor = [0 0.9400 0];
%                         e.names{ii}.BackgroundColor = [0 0.9400 0];
                    end
                    
                    switch lower(e.config.class{ii}(1:3))
                        case {'mcd', 'mci'}
                            e.push1{ii}.String = 'Acquire';
                            e.push1{ii}.Enable = 'off';
                            e.push2{ii}.String = 'Load';
                            e.push2{ii}.Enable = 'off';
                        case 'mca'
                            e.push1{ii}.String = 'Goto';
                            e.push1{ii}.Enable = 'off';
                            e.push2{ii}.Visible = 'off';
                        case 'pau'
                            e.push1{ii}.String = 'Pause';
                            e.push1{ii}.Enable = 'off';
                            e.push2{ii}.Visible = 'off';
                        otherwise
                            e.push1{ii}.Visible = 'off';
                            e.push2{ii}.Visible = 'off';
                    end
                    
                    
                    if ii == e.config.current
                        e.push1{ii}.Enable = 'on';
                        e.push2{ii}.Enable = 'on';
                    end
                end
            end
        end
        
%         function selectionCallback(e, ~, event)
%             if ~isempty(event.Indices)
%                 % First, deselect the newly-selected cell.
%                 jscroll =   findjobj(e.t);
%                 h =         jscroll.getComponents;
%                 viewport =  h(1);
%                 a =         viewport.getComponents;
%                 jtable =    a(1);
%                 jtable.changeSelection(-1, -1, false, false);
%                 
%                 % Then do certain behavior depending upon the cell that was clicked.
%                 if all(event.Indices == [1 3])  % View Overview.
%                     mcDialog('Overview for this mcExperiment:', 'Overview', e.config.overview);
%                 end
%                 
%                 if event.Indices(2) == 3 && event.Indices(1) > 1    % If we are in the 'Tasks' column and not on the overview
%                     obj = e.objects{event.Indices(1)-1};
%                     
%                     if isa(obj, 'mcData')
%                         mcDataViewer(obj);
%                     end
%                 end
%             end
%         end
    end
end




