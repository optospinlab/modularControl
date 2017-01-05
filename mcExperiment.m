classdef mcExperiment < mcInput
% mcExperiment is a generalization of experimental procedures.
%
% Also see mcInput.

    properties
        f = [];     % figure
        
        proceeding = false;     % Whether or not we should proceed to the next step in the experiment.
        
        num = 0;                % The step that we are currently on.
        
        objects = {};           % Cell array to store the objects that result from the mcAxis/mcInput/mcData configs in e.config.
        
        % Cell array to hold the UIControl elements.
        doneboxes = {};
        proceedboxes = {};
        names = {};
        push1 = {};
        push2 = {};
        
        fname = [];
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
            
            config.name = 'Example Experiment';

            config.kind.kind =          'example';
            config.kind.name =          'Example Experiment';
            config.kind.intUnits =      'units';        % Change!
            config.kind.shouldNormalize = false;
            config.kind.sizeInput =    [1 1];           % Change!
            
            step1config = mcaDAQ.defaultConfig();
            step2config = mcData.defaultConfiguration();
            
            config.overview =   'Overview should be used to describe a mcExperiment.';
            config.steps =      {   {'Goto',            step1config,    0,  'Example goto step.'};...
                                    {'mcData',          step2config,    2,  'Example scan step.'};...
                                    {'Pause (5 sec)',   'pause',        5,  'Example pause step (for five seconds.'};...
                                    {'mcData w\ load',  step2config,    2,  'Example scan step (with loading option).'} };
            config.current =    1;                          % Current step
            config.autoProDef = true;                       % Default value for the autoproceed checkbox.
            config.dname = '';                              % Name of directory to save to. Implement!
            
            % runtime generated:
            %   - config.classes
        end
    end
    
    methods             % Initialization method (this is what is called to make an input object).
        function e = mcExperiment(varin)
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
    

    % These methods overwrite the empty methods defined in mcInput. These methods are used in the uncapitalized parent methods defined in mcInput.
    methods
        function str = NameShort(e)     % 'short' name, suitable for UIs/etc.
            str = [e.config.name];
        end
        function str = NameVerb(I)      % 'verbose' name, suitable to explain the identity to future users.
            str = [e.config.name ' (mcExperiment with overview: ' I.config.overview ')'];  % ** Change these to your custom vars.
        end
        
        %EQ ------------- The function that should return true if the custom vars are the same (future: use i.extra for this?)
        function tf = Eq(I, b)          % Compares two mcExperiments
            tf = strcmp(I.config.name, b.config.name);                 % Don't care.
        end

        % OPEN/CLOSE ---- Opens/closes the GUI for the experiment.
        function Open(e)
            if ~isfield(e.config, 'current')
                e.config.current = 1;
            end
            if ~isfield(e.config, 'autoProDef')
                e.config.autoProDef = true;
            end
            
            e.f = mcInstrumentHandler.createFigure(e, 'none');      % Create a figure for this experiment with no toolbars.
            e.f.Name = ['mcExperiment - ' e.config.name];
            e.f.CloseRequestFcn = @e.crf;
            
            e.num = length(e.config.steps);
            
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
                        'TooltipString', sprintf('Buttons to interact with each step:\n\n + Aquire/Goto/etc starts the step\n + Redo returns to the step'),...
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
            uicontrol(  'Parent', e.f,...
                        'Style', 'push',...
                        'Position', [t2, p + (e.num)*bh, bw, bh],...
                        'String', 'View',...
                        'Callback', @(~,~)(mcDialog('Read the overview to learn more about the experiment.', 'Overview', e.config.overview)));
            
            e.objects =         cell(1, e.num);
            e.doneboxes =       cell(1, e.num);
            e.names =           cell(1, e.num);
            e.push1 =           cell(1, e.num);
            e.push2 =           cell(1, e.num);
            e.proceedboxes =    cell(1, e.num);
            
            e.config.classes =  cell(1, e.num);
            
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
                                                'TooltipString', e.config.steps{ii}{4});
                e.push1{ii} =       uicontrol(  'Parent', e.f,...
                                                'Style', 'push',...
                                                'Position', [t2, p + (e.num-ii)*bh, (bw-p)/2, bh],...
                                                'String', 'View',...
                                                'Callback', {@e.push1_Callback, ii});
                e.push2{ii} =       uicontrol(  'Parent', e.f,...
                                                'Style', 'push',...
                                                'Position', [t3, p + (e.num-ii)*bh, (bw-p)/2, bh],...
                                                'String', 'Redo',...
                                                'Callback', {@e.push2_Callback, ii});
                e.proceedboxes{ii}= uicontrol(  'Parent', e.f,...
                                                'Style', 'check',...
                                                'Value', e.config.autoProDef || strcmpi(e.config.classes{ii}(1:3), 'pau'),...
                                                'HorizontalAlign', 'left',...
                                                'Position', [t4, p + (e.num-ii)*bh, cw, bh],...
                                                'Callback', @e.proceedCheck_Callback);
                                            
                if isstruct(e.config.steps{ii}{2})
                    if isfield(e.config.steps{ii}{2}, 'class')
                        e.config.classes{ii} = e.config.steps{ii}{2}.class;
                    else
                        error(['mcData(): Axis config for ' e.config.steps{ii}{2}.name ' given without class.']);
                    end
                elseif ischar(e.config.steps{ii}{2})
                    e.config.classes{ii} = e.config.steps{ii}{2};
                    
                    switch lower(e.config.classes{ii}(1:2))
                        case 'mc'
                            error('mcExperiment.Open(): String-type step should not be allowed to impersonate an mcClass');
                    end
                else
                    error(['mcExperiment.Open(): Type ' class(e.config.steps{ii}{2}) ' not understood.']);
                end
                
                switch lower(e.config.classes{ii}(1:3)) % Change, in case the first three letters aren't enough?
                    case 'mca'  % mcAxis
                        c = e.config.steps{ii}{2};
                        e.objects{ii} = eval([c.class '(c)']);  % Make an mcAxis (subclass) object based on that config.
                    case 'mci'  % mcInput
                        data = mcData(mcData.singleConfiguration(e.config.steps{ii}{2}, e.config.steps{ii}{3}));
                        data.r.scanMode = -1;                               % Make sure this is paused at start...
                        data.d.name = [e.name ' - ' data.d.name];
                            
                        e.objects{ii} = mcDataViewer(data, false, false);
                        e.objects{ii}.isPersistant = true;
                    case 'mcd'  % mcData
                        if strcmpi(e.config.classes{ii}, 'mcData')
                            data = mcData(e.config.steps{ii}{2});
                            data.r.scanMode = -1;                               % Make sure this is paused at start...
                            data.d.name = [e.name ' - ' data.d.name];
                            
                            e.objects{ii} = mcDataViewer(data, false, false);   % ...and don't initially show the gui.
                            e.objects{ii}.isPersistant = true;
                        else
                            warning('mcExperiment.Open(): Class starting with mcd not understood');
                        end
                    case 'pau'  % pause
                        % Do nothing.
                end
            end
            
            pause(.05);     % Why is this there again?
            
            e.f.Position = [0 0 (w) ((e.num+2)*bh + 2*p)];
            
            e.refreshStep();
            e.f.Visible = 'on';
        end
        function Close(e)
            % Save!
            
            figure(e.f);
            closereq
        end
        
        % MEASURE ------- The 'meat' of the input: the funtion that actually does the measurement and 'inputs' the data. Ignore integration time (with ~) if there should not be one.
        function data = Measure(e, ~)
            while e.config.current <= e.num
                e.proceeding = e.proceedboxes{e.config.current}.Value;
                e.refreshStep();
                
                waitfor(e, 'proceeding', true);
                e.refreshStep();
                
                switch lower(e.config.classes{e.config.current}(1:3))
                    case {'mcd', 'mci'}
                        e.objects{e.config.current}.df.Visible = 'on';  % Make the data figue visible,
                        figure(e.f);    % But resore focus to the mcExperiment panel, so that we can tell whether the data figure should be closed (don't close if the data figure is selected).
                        
                        e.objects{e.config.current}.data.r.scanMode = 0;    % Take a new scan (future: check for half-finished).
                        
%                         while e.objects{e.config.current}.data.r.scanMode ~= 2
                        e.objects{e.config.current}.acquire();
                        
%                         mode1 = e.objects{e.config.current}.data.r.scanMode
                        
                        waitfor(e.objects{e.config.current}.data.r, 'scanMode');
                        
%                         mode2 = e.objects{e.config.current}.data.r.scanMode
                        
                        drawnow
                        pause(.1);  % Remove?
                        
%                         if e.objects{e.config.current}.data.r.scanMode ~= 2
%                             e.config.current = e.config.current - 1;
                        if ~(gcf == e.objects{e.config.current}.cf || gcf == e.objects{e.config.current}.df)
                            e.objects{e.config.current}.cf.Visible = 'off';
                            e.objects{e.config.current}.cfToggle.State = 'off';
                            
                            e.objects{e.config.current}.df.Visible = 'off';
                        end
                    case 'mca'
                        if ischar(e.config.steps{e.config.current}{3})
                            if strcmpi(e.config.steps{e.config.current}{3}(end-1:end), '()')
                                a = e.objects{e.config.current};    %#ok
                                eval(['a.', e.config.steps{e.config.current}{3}]);
                            else
                                warning(['Not sure what to make of the input from step ' num2str(e.config.current)]);
                            end
                        elseif isnumeric(e.config.steps{e.config.current}{3})
                            e.objects{e.config.current}.goto(e.config.steps{e.config.current}{3});
                        else
                            warning(['Not sure what to make of the input from step ' num2str(e.config.current)]);
                        end
                    case 'pau'
                        pause(e.config.steps{e.config.current}{3});
                end
                
                e.Step();
                e.config.current = e.config.current + 1;
            end
            
            e.refreshStep();
            
            data = e.Analysis();
        end
    end
    
    % Saving
    methods
        function save(e, name)
            for ii = 1:length(e.objects)
                if isa(e.objects{ii}, 'mcData')
                    e.objects.save([mcInstrumentHandler.getSaveFolder(1) filesep fname filsep name]);
                end
            end
        end
    end
    
    % Fill-in methods
    methods
        function Step(e)    % Proceed with the iith step of the experiment e. Overwrite this in mce subclasses.
            disp(['Step ' num2str(e.config.current) ' -> ' num2str(e.config.current + 1)]);
%             switch ii
%                 case 0
%                     % Do something at the end of step 0.
%                 case 1
%                     % Do something at the end of step 1.
%                 %...
%             end
        end
        
        function data = Analysis(~)
            data = NaN;
        end
    end
    
    methods
        function crf(e, ~, ~)   % Close request function
            if ~isvalid(e)
                closereq
            end
        end
        
        function push1_Callback(e, ~, ~, ii)
            if ii == e.config.current && ( strcmpi(e.config.classes{ii}(1:3), 'mci') || strcmpi(e.config.classes{ii}(1:3), 'mcd') )
                e.objects{e.config.current}.scanButton_Callback(0,0);
%                 mode3 = e.objects{e.config.current}.data.r.scanMode
%                 e.proceeding = (e.objects{e.config.current}.data.r.scanMode == 2);
            else
                if ii < e.config.current
                    e.config.current = ii;
                end

                e.proceeding = true;
            end
            e.refreshStep();
        end
        function push2_Callback(e, ~, ~, ii)
            e.objects{ii}.df.Visible = 'on';
        end
        function proceedCheck_Callback(e, src, ~)
            if e.config.current <= e.num
                e.proceeding = (src == e.proceedboxes{e.config.current} && e.proceedboxes{e.config.current}.Value);
            end
        end
        
        function refreshStep(e)
            for ii = 1:e.num
                if      ii < e.config.current
                    e.doneboxes{ii}.Value = 1;
                    e.doneboxes{ii}.BackgroundColor = [0.9400 0.9400 0.9400];
                    
                    switch lower(e.config.classes{ii}(1:3))
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
                    
                    switch lower(e.config.classes{ii}(1:3))
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
                    
                    switch lower(e.config.classes{ii}(1:3))
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
%                         e.push2{ii}.Enable = 'on';    % Enable eventually...
                    end
                end
            end
        end
    end
end




