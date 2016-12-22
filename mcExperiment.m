classdef mcExperiment < mcInput
% mcExperiment is a generalization of experimental procedures.
%
% Also see mcInput.

    properties
        f = [];     % figure
        t = [];     % uitable
        pcb = [];   % proceed checkbox
        % pb = [];  % proceed button
        
        objects = {};
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
            
            config.name = 'Template';                   % ** Change this to the UI name for this identity of mci<MyNewInput>.

            config.kind.kind =          'template';     % ** Change this to the programatic name that the program should use for this identity of mci<MyNewInput>.
            config.kind.name =          'Template';     % ** Change this to the technical name (e.g. name of device) for this identity of mci<MyNewInput>.
            config.kind.intUnits =      'units';        % ** Rename these to whatever units are used (e.g. counts).
            config.kind.shouldNormalize = false;        % (Not sure if this is functional.) If this variable is flagged, the measurement is subtracted from the previous and is divided by the time spent on a pixel. Not that this is done outside the measurement currently in mcData (individual calls to .measure() will not have this behavior currently)
            config.kind.sizeInput =    [1 1];           % ** The size (i.e. dimension) of the measurement. For a spectrum, this might be [512 1], a vector 512 pixels long. For a camera, this might be [1280 720]. Future: make NaN functional for dimensions of unknown length (e.g. a string of unknown length).
            
            step1config = mcaDAQ.defaultConfig();
            
            config.overview =   'Overview should be used to describe a mcExperiment.';
            config.inputs =     { NaN, NaN, NaN, NaN };     % Array containing the input for each step (can be set
            config.steps =      {   {'Step 1 Title', 'Step 1 tooltip', step1config};...
                                    {'Step 2 Title', 'Step 2 tooltip', step1config};...
                                    {'Step 3 Title', 'Step 3 tooltip', step1config};...
                                    {'Step 4 Title', 'Step 4 tooltip', step1config} };
%             config.steps =      { {'Mirror Down', 'This step moves the SPCM mirror down into spectrometer mode.', } };
            config.data =       { NaN, NaN, NaN, NaN };     % Array containing the result of each step (for use later)
            config.current =    1;                          % Current step
            config.autoProDef = true;                       % Default value for the autoproceed checkbox.
            config.dname = '';                              % Name of directory to save to.
        end
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
            
            numlines =      length(e.config.steps) + 1; % Number of steps + overview.
            p =             5;                          % Table padding\
            
%             mat2cell((0:numlines-1 < e.config.current)', ones(1, numlines), 1)
%             
%             [{'Overview'}; e.config.steps(:, 1)] 
%             
%             [{'View'}; cellfun(@(s)(s.class), e.config.steps(:, 3), 'UniformOutput', false)]
            
            w = 300;
            
            tdata = cell(numlines, 4);
            
            % Make the first line of the table - the overview of this mcExperiment.
            tdata{1, 1} = ' ';
            tdata{1, 2} = 'Overview';
            tdata{1, 3} = '<html><u style="color:blue">View</u></html>';
            
            % Make the lines which represent each step of this mcExperiment.
            for ii = 2:numlines
                c = e.config.steps{ii-1}{3};
                
                e.objects{ii-1} = eval([c.class '(c)']);
                
                tdata{ii, 1} = ii-1 < e.config.current;
                tdata{ii, 2} = e.config.steps{ii-1}{1};
                
                if strcmpi(c.class, 'mcData')
                    tdata{ii, 3} = '<html>mcData (<u style="color:blue">View</u>)</html>';
                else
                    tdata{ii, 3} = c.class;
                end
                
                if      ii-1 < e.config.current
                    tdata{ii, 4} = '<html><u style="color:blue">Redo</u></html>';
                elseif  ii-1 == e.config.current
                    tdata{ii, 4} = '<html><u style="color:blue">Waiting</u></html>';
                else
                    tdata{ii, 4} = '<html><u style="color:blue">Skip To Here</u></html>';
                end
            end
            
            % Future?: Make lines denoting the analytical result of the experiment.
            
            e.t = uitable(  'Position',     [p p w numlines*18+18],...
                            'RowName',      num2cell(0:numlines-1),...
                            'ColumnName',   {'Done?', 'Step Name' , 'Task', 'Interact'},...
                            'ColumnWidth',  {40, 'auto', 'auto'},...
                            'Data',         tdata,...
                            'CellSelectionCallback', @e.selectionCallback);
            
%             e.t = uitable(  'Position',     [p p w numlines*18+18],...
%                             'RowName',      num2cell(0:numlines-1),...
%                             'ColumnName',   {'Done?', 'Step Name' , 'Task', 'Interact'},...
%                             'ColumnWidth',  {40, 'auto', 'auto'},...
%                             'Data',         [mat2cell((0:numlines-1 < e.config.current)', ones(1, numlines), 1)...     
%                                             [{'Overview'}; e.config.steps(:, 1)]...
%                                             [{'<html><u style="color:blue">View</u></html>'}; cellfun(@(s)(['<html> ' s.class ' (<u style="color:blue">View</u>)</html>']), e.config.steps(:, 3), 'UniformOutput', false)]],....
%                             'CellSelectionCallback', @e.selectionCallback);

            bh = 20;
            bw = (w - 3*p)/2;
            
            % Auto-proceed check box.
            e.pcb = uicontrol('Style', 'check', 'Position', [p          numlines*18+18 + 2*p bw bh], 'String', 'Auto Proceed?', 'Value', e.config.autoProDef);
            
            % Proceed button.
            uicontrol('Style', 'push',  'Position', [2*p + bw   numlines*18+18 + 2*p bw bh], 'String', 'Proceed');
                        
            e.f.Position = [0 0 (w + 2*p) (numlines*18+18 + 3*p + bh)];
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
        
        function selectionCallback(e, ~, event)
            if ~isempty(event.Indices)
                % First, deselect the newly-selected cell.
                jscroll =   findjobj(e.t);
                h =         jscroll.getComponents;
                viewport =  h(1);
                a =         viewport.getComponents;
                jtable =    a(1);
                jtable.changeSelection(-1, -1, false, false);
                
                % Then do certain behavior depending upon the cell that was clicked.
                if all(event.Indices == [1 3])  % View Overview.
                    mcDialog('Overview for this mcExperiment:', 'Overview', e.config.overview);
                end
                
                if event.Indices(2) == 3 && event.Indices(1) > 1    % If we are in the 'Tasks' column and not on the overview
                    obj = e.objects{event.Indices(1)-1};
                    
                    if isa(obj, 'mcData')
                        mcDataViewer(obj);
                    end
                end
            end
        end
    end
end




