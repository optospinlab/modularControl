function f = mcAxisListener(varin)
% mcAxisListener creates a GUI that regularly updates the position of any
% number of axes, specified by axes_.
%
%   f =  mcAxisListener()                   % Makes listener panel in new figure that listens to all registered axes.
%   f =  mcAxisListener(axes_)              % Makes listener panel in new figure that listens to the contents of axes_.
%   f1 = mcAxisListener(axes_, f1, pos)     % Makes listener panel in figure f1, with Position pos.

    fw = 300;               % Figure width
    fh = 500;               % Figure height

    pp = 5;                 % Panel padding
    pw = fw - 30;           % Panel width
    ph = 200;               % Panel height

    bh = 20;                % Button Height
            
    switch nargin
        case {0, 1}
            if nargin == 0
                warning('No axes provided to listen to... Listening to all of them.');
                [axes_, ~, ~] = mcInstrumentHandler.getAxes();
    %             error('Axes to listen to must be provided.');
            else
                axes_ = varin;
            end
            
            f = mcInstrumentHandler.createFigure('mcAxisListener');
            
            f.Resize =      'off';
            f.Visible =     'off';
            f.MenuBar =     'none';
            f.ToolBar =     'none';
            
            pos =           [0, 0, fw, fh];
        case 3
            axes_ =         varin{1};
            f =             varin{2};
            pos =           varin{3};
        otherwise
            error('mcAxisListener requires 1 or 3 arguments.');
    end
    
    l = length(axes_);
    
    if nargin <= 1
        pos(4) = bh*(l+1);
        f.Position =    pos;
    end
    
    bh = pos(4)/(l+1);
    
    p = uipanel('Parent', f, 'Position', pos);
    
    ii = 1;
    
    for axis_ = axes_
        uicontrol(  'Parent', p,...
                    'Style', 'text',...
                    'String', [axis_{1}.nameUnits() ': '],...
                    'Position', [pos(3)/4, pos(4) - (ii+.5)*bh, pos(3)/4, bh],...
                    'HorizontalAlignment', 'right');
        edit = uicontrol(   'Parent', p,...
                            'Style', 'edit',...
                            'String', num2str(axis_{1}.getX(), '%.02f'),...
                            'Position', [pos(3)/2, pos(4) - (ii+.5)*bh, pos(3)/4, bh]);
        edit.UserData = addlistener(axis_{1}, 'x', 'PostSet', @(s,e)(axisChanged_Callback(s, e, edit)));
        
        ii = ii + 1;
    end
    
    f.Visible =     'on';
end

function axisChanged_Callback(~, event, edit)
%     src
%     event
    edit.String = num2str(event.AffectedObject.getX(), '%.02f');
end




