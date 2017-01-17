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
                                { 'edit',   'Number!:  '        0,          'Enter a number!',                          [01 234 1]},...
                                { 'edit',   'Number!:  '        0,          'Enter a number!',                          [01 234 0]},...
                                { 'edit',   'Number!:  '        0,          'Enter a number!',                          [-Inf Inf]},...
                                { 'edit',   'Number!:  '        0,          'Enter a number!',                          [0 0]},...
                                { 'push',   'Push this button', 'hello',    'Push to activate a generic config' },...
                                { 'edit',   'Number!:  '        0,          'Enter another number!' } };
        end
    end
    
    methods
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

