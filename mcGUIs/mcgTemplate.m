classdef mcgTemplate < mcGUI
    % Template to explain how to make a custom mcGUI (unfinished).
    
    properties
    end
    
    methods (Static)
        function config = defaultConfig()
            config = mcgTemplate.exampleConfig();
        end
        function config = exampleConfig()
            % ** Make the appropriate cell array table of values (each line corresponding to a uicontrol line).
            %                     Style     String              Variable    TooltipString                               Optional: Limit [min max round] (only for edit)
            config.controls = { { 'title',  'Title:  ',         NaN,        'This section is an example section' },...
                                { 'edit',   'Number!:  '        0,          'Enter an integer between 1 and 42!',           [1 42 1]},...
                                { 'edit',   'Number!:  '        0,          'Enter a number between 1 and 42!',             [1 42 0]},...
                                { 'edit',   'Number!:  '        0,          'Enter any real number!',                       [-Inf Inf]},...
                                { 'edit',   'Number!:  '        0,          'Only zero is allowed!',                          [0 0]},...
                                { 'push',   'Push this button', 'hello',    'Push to activate a generic config' },...
                                { 'edit',   'Number!:  '        0,          'Enter anthing!' } };
        end
    end
    
    methods
        function gui = mcgTemplate(varin)               % Change this 
            switch nargin
                case 0
                    gui.load();                             % Attempt to load a previous config from configs/computername/classname/config.mat
                    
                    if isempty(gui.config)                  % If the file did not exist or the loading failed...
                        gui.config = gui.defaultConfig();   % ...then use the defaultConfig() as a backup.
                    end
                case 1
                    gui.config = varin;
            end
            
            gui.buildGUI();
        end
        
        function Callbacks(gui, ~, ~, cbName)
            switch cbName
                case 'hello'                    % ** Add behavior as desired.
                    disp('Hello World!');       % **
                otherwise
                    if ischar(cbName)
                        disp([class(gui) '.Callbacks(s, e, cbName): No callback of name ' cbName]);
                    else
                        disp([class(gui) '.Callbacks(s, e, cbName): Did not understand cbName; not a string.']);
                    end
            end
        end
    end
end

