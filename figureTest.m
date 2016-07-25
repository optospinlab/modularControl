function figureTest()
    global params

    params.f = figure()
    
    menu = uicontextmenu;
    params.ctsMenu = uimenu(menu, 'Label', ' Value: ~~.~~ --');
    params.pixMenu = uimenu(menu, 'Label', ' Pixel: [ ~~.~~ --, ~~.~~ -- ]');
    params.posMenu = uimenu(menu, 'Label', ' Position: [ ~~.~~ --, ~~.~~ -- ]');
    mgoto = uimenu(menu, 'Label', 'Goto');
    mgpix = uimenu(mgoto, 'Label', 'Selected Pixel',    'Callback',@d);
    mgexa = uimenu(mgoto, 'Label', 'Selected Position', 'Callback',@b);
    mnorm = uimenu(menu, 'Label', 'Normalization');
    mnmin = uimenu(mnorm, 'Label', 'Set as Minimum', 'Callback',@d);
    mnmax = uimenu(mnorm, 'Label', 'Set as Maximum',  'Callback',@b);
    
    params.a = axes('Parent', params.f, 'DataAspectRatioMode', 'manual','BoxStyle','full','Box','on') %, 'Xgrid', 'on', 'Ygrid', 'on'
    
    x = 1:100;
    y = 1:100;
    
    lx = length(x);
    ly = length(y);
    
%     params.a.DataAspectRatio = [lx ly 1];
    params.a.DataAspectRatio = [1 1 1];
%     params.a.PlotBoxAspectRatio = [lx ly 1];
    
    m = rand(ly, lx);
    m(1:50, 1:50) = NaN;
    
    c = repmat(m, 1, 1, 3);
    
    c(:,:,2) = rand(ly, lx);
    c(:,:,3) = rand(ly, lx);
    
    params.i = image(params.a, x, y, c, 'alphadata', ~isnan(m), 'ButtonDownFcn', @figureClickCallback, 'UIContextMenu', menu)
    params.a.XLim = [min(x), max(x)]; 
    params.a.YLim = [min(y), max(y)];
    
    params.a.YDir = 'normal';


    daspect(params.a, [1 1 1]);
    
    hold(params.a,'on')
    params.s = scatter(params.a, [0 0], [0 0], 40, [1 0 0; 0 1 0], 'PickableParts', 'none', 'Linewidth', 2);
    hold(params.a,'off')
    
    params.a.YDir = 'normal';
end

function figureClickCallback(src, event)
    global params
    
    if src == params.i && event.Button == 3
        x = event.IntersectionPoint(1);
        y = event.IntersectionPoint(2);

        xlist = (params.i.XData - x) .* (params.i.XData - x);
        ylist = (params.i.YData - y) .* (params.i.YData - y);

        xi = min(find(xlist == min(xlist)));
        yi = min(find(ylist == min(ylist)));

        params.s.XData = [x params.i.XData(xi)];
        params.s.YData = [y params.i.XData(yi)];

        val = params.i.CData(yi, xi);
        
        if isnan(val)
            params.ctsMenu.Label = ' Value: ----- cts/sec';
        else
            params.ctsMenu.Label = [' Value: ' num2str(val, 4) ' cts/sec'];
        end
        params.posMenu.Label = [' Position: [ ' num2str(x, 4) ' mV, ' num2str(y, 4) ' mV ]'];
        params.pixMenu.Label = [' Pixel: [ ' num2str(params.i.XData(xi), 4) ' mV, ' num2str(params.i.YData(yi), 4) ' mV ]'];
    end
end

function b(src, event)
    'b'
end

function d(src, event)
    'd'
end




