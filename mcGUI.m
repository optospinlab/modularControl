classdef mcGUI < mcSavableClass

    
    properties
%         config = [];            % Defined in mcSavableClass. All static variables (e.g. valid range) go in config.
        controls = {};
        f = [];
        
        updated = 0;
        
        pw = 300;
        ph = 700; % Make variable...
    end
    
    methods (Static)
        function config = defaultConfig()
            config = mcGUI.exampleConfig();
        end
        function config = exampleConfig()
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
        function gui = mcGUI(varin)
            switch nargin
                case 0
                    gui.config = gui.defaultConfig();
                case 1
                    gui.config = varin;
            end
            
            gui.buildGUI();
        end
        
        function buildGUI(gui)
            gui.f = mcInstrumentHandler.createFigure(gui, 'saveopen');
            gui.f.Resize =      'off';
            gui.f.Position = [100, 100, gui.pw, gui.ph];
            
            bh = 20;    % Button height
            ii = 1.5;   % Initial button
            m = .1;     % Margin
            w = 1 - 2*m;
            
            M = gui.pw*m;
            W = gui.pw*w;
            
            
            prevControl = '';
            
            jj = 1;
            
            for control_ = gui.config.controls
                control = control_{1};
                switch control{1}
                    case 'title'
                        if ~isempty(prevControl)
                            ii = ii + 1;            % Add a space after the last line.
                        end
                        
                        uicontrol(  'Parent', gui.f,...
                                    'Style', 'text',... 
                                    'String', control{2},... 
                                    'TooltipString', control{4},... 
                                    'HorizontalAlignment', 'left',...
                                    'FontWeight', 'bold',...
                                    'Position', [M, gui.ph - ii*bh, W, bh]);     
                        ii = ii + 1;
                    case 'text'
                        if strcmpi(prevControl, 'title')
                            ii = ii + .25;
                        end
                        if strcmpi(prevControl, 'push')
                            ii = ii + 1;
                        end
                        
                        uicontrol(                      'Parent', gui.f,...  
                                                        'Style', 'text',... 
                                                        'String', control{2},... 
                                                        'TooltipString', control{4},... 
                                                        'HorizontalAlignment', 'left',...
                                                        'Position', [M, gui.ph - ii*bh, W, bh]);
                                                    
                        gui.controls{jj} =   uicontrol( 'Parent', gui.f,...
                                                        'Style', 'edit',... 
                                                        'String', control{3},...
                                                        'Position', [M, gui.ph - (ii+1)*bh, W, bh]);    
                                   
                        ii = ii + 2;
                    case 'edit'
                        if strcmpi(prevControl, 'title')
                            ii = ii + .25;
                        end
                        if strcmpi(prevControl, 'push')
                            ii = ii + 1;
                        end
                        
                        uicontrol(                      'Parent', gui.f,...  
                                                        'Style', 'text',... 
                                                        'String', control{2},... 
                                                        'TooltipString', control{4},... 
                                                        'HorizontalAlignment', 'right',...
                                                        'Position', [M, gui.ph - ii*bh, W/2, bh]);
                                                    
                        gui.controls{jj} =   uicontrol( 'Parent', gui.f,...
                                                        'Style', 'edit',... 
                                                        'String', control{3},...
                                                        'Value', control{3},...     % Also store number as value (used if string change is undesirable).
                                                        'Position', [M + W/2, gui.ph - ii*bh, W/2, bh]);     
                                     
                        if length(control) > 4
                            gui.controls{jj}.TooltipString =    gui.getLimitString(control{5});
                            gui.controls{jj}.Callback =         {@gui.limit control{5}};
                        else
                            gui.controls{jj}.TooltipString =    gui.getLimitString([]);
                            gui.controls{jj}.Callback =         @gui.update;
                        end  
                            
                        jj = jj + 1;
                        ii = ii + 1;
                    case 'push'
                        if ~strcmpi(prevControl, 'push')
                            ii = ii + .25;
                        end
                        
                        uicontrol(  'Parent', gui.f,...  
                                    'Style', 'push',... 
                                    'String', control{2},... 
                                    'TooltipString', control{4},... 
                                    'Position', [M, gui.ph - ii*bh, W, bh],... 
                                    'Callback', {@gui.Callbacks, control{3}});                      
                        ii = ii + 1;
                end
                
                prevControl = control{1};
            end
            
            gui.f.Visible = 'on';
        end
        
        function limit(gui, src, ~, lim)
            val = str2double(src.String);       % Try to interpret the edit string as a double.
            
            if isnan(val)                       % If we don't understand.. (e.g. '1+1' was input), try to eval() it.
                try
                    val = eval(src.String);     % This would be an example of an exploit, if this was supposed to be a secure application. The user should never be able to execute his own code.
                catch
                    val = src.Value;            % If we still don't understand, revert to the previous value.
                end
            end
            
            % Next, preform our checks on our value.
            if length(lim) == 1 && lim  % If we only should round...
                val = round(val);
            elseif length(lim) > 1      % If we have min/max bounds...
                if val > lim(2)
                    val = lim(2);
                end
                
                if val < lim(1)
                    val = lim(1);
                end
                
                % Note that this will cause val = lim(1) if lim(1) > lim(2) instead of the expected lim(1) < lim(2)
                
                if length(lim) > 2 && lim(3)
                    val = round(val);
                end
            end
            
            src.String =    val;
            src.Value =     val;
            
            gui.update();
        end
        function str = getLimitString(~, lim)
            str = 'No requirements.';
            
            if length(lim) == 1
                if lim
                    str = 'Must be an integer.';
                end
            elseif length(lim) > 1
                str = ['Bounded between ' num2str(lim(1)) ' and ' num2str(lim(2)) '.'];
                
                if length(lim) > 2 && lim(3)
                    str = [str ' Must be an integer.'];
                end
            end
        end
        function update(gui)
            gui.updated = gui.updated + 1;
        end
        
%         function val = getEditValue(gui, jj)  % Gets the value of the jj'th edit (change this eventually to look for the edit corresponding to a string? After all, this makes editing difficult)
%             val = gui.controls{jj}.Value;
%         end
    end
    
    methods
        function Callbacks(gui, ~, ~, cbName)
            switch cbName
                case 'quit'
                    delete(gui);
                case 'hello'
                    disp('Hello World!');
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




