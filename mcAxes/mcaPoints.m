classdef (Sealed) mcaPoints < mcAxis          % ** Insert mca<MyNewAxis> name here...
% mcaPoints is an axis that traverses a series of points. There is no limit to the number of points nor the number of axes which
% define each point.
%
% For example, our series of (say, N) points could be defined in 3D piezo-space, where our three axes are piezoX, piezoY, piezoZ.
%
% This axis is similar to mcaGrid, with a critical difference:
%
% Also see mcAxis.

    properties
        axes_ = {};
    end

    methods (Static)    % The folllowing static configs are used to define the identity of axis objects. configs can also be loaded from .mat files
        %  - A
        
        function config = defaultConfig()               % Static config that should be used if no configuration is provided upon intialization.
            config = mcaPoints.customConfig();
        end
        function config = brightSpotConfig(d)
            config.class =              'mcaPoints';
            
            config.name =               ['Points Found in' d.name];
            
            config.src =                d;
            
            if isempty(d.inputs)
                error('mcaPoints(): Error checking in mcData should have caught this.');
            elseif length(d.inputs) > 1
                warning(['mcaPoints(): Expected a data structure with only one input. Found ' num2str(length(d.inputs)) ' inputs. We assume that the first input is the desired input']);
            end
            
            if length(d.axes) ~= 2
                error(['mcaPoints(): Expected a 2D data structure. Found ' num2str(length(d.axes)) ' dimensions.']);
            end
            
            s = wiener2(d.data, [3 3]);

            figure;

            r = regionprops(imclearborder(imregionalmax(s)) & s > quantile(s(:), .75), s, 'Centroid', 'MaxIntensity');

            c = cat(1, r.Centroid);

            [~, sorted] = sort(cat(1, r.MaxIntensity), 'descend');

            xind = c(sorted,1);
            yind = c(sorted,2);

            xvals = d.scans{1}(xind);
            yvals = d.scans{2}(yind);

            unitx = abs(d.scans{1}(2) - d.scans{1}(1));     % Make sure length is greater than 1?
            unity = abs(d.scans{2}(2) - d.scans{2}(1));

            nums = 1:length(xvals);

            for ii = nums
                taxi = abs(xind - xind(ii)) + abs(yind - yind(ii));
                halfsquarewid(ii) = ceil(min(taxi(taxi ~= 0))/4) + .5;
            end
            
            config.A =      0;
            config.axes =   d.axes;
            
            config.data = d;

            config.kind.kind =          'brightspot';
            config.kind.name =          'Bright spots found from 2D data';
            config.kind.intRange =      [1 length(xind)];
            config.kind.int2extConv =   @(x)(x);
            config.kind.ext2intConv =   @(x)(x);
            config.kind.intUnits =      'point';
            config.kind.extUnits =      'point';
            config.kind.base =          NaN;
            
            config.keyStep =            1;
            config.joyStep =            1;
        end
    end
    
    methods             % Initialization method (this is what is called to make an axis object).
        function a = mcaPoints(varin)
            a.extra = {'A', 'axes'};
            if nargin == 0
                a.construct(a.defaultConfig());
            else
                a.construct(varin);
            end
            config.num = length(config.axes);
            
            a = mcInstrumentHandler.register(a);
        end
    end
    
    % These methods overwrite the empty methods defined in mcAxis. These methods are used in the uncapitalized parent methods defined in mcAxis.
    methods
        % NAME ---------- The following functions define the names that the user should use for this axis.
        function str = NameShort(a)     % 'short' name, suitable for UIs/etc.
            str = [a.config.name ' (with ' num2str(config.num) ' axes)'];
        end
        function str = NameVerb(a)      % 'verbose' name, suitable to explain the identity to future users.
            str = [a.config.name ' ( ' ')'];
        end
        
        %EQ ------------- The function that should return true if the custom vars are the same (future: use a.extra for this?)
        function tf = Eq(~, ~)
            tf = false; % Don't care; two point axes cannot distrub each other (unlike, e.g. two DAQ axes with the same info).
        end
        
        % OPEN/CLOSE ---- The functions that define how the axis should init/deinitialize (these functions are not used in emulation mode).
        function Open(a)                % Do whatever neccessary to initialize the axis.
            for ii = 1:length(a.config.axes)
                a.config.axes{ii}.open();
            end
        end
        function Close(a)               % Do whatever neccessary to deinitialize the axis.
            for ii = 1:length(a.config.axes)
                a.config.axes{ii}.close();
            end
        end
        
        % READ ---------- Not neccessary
        
        % GOTO ---------- The 'meat' of the axis: the funtion that translates the user's intended movements to reality.
        function GotoEmulation(a, x)
            a.Goto(x);
        end
        function Goto(a, x)
            X = 1:max(a.config.kind.intRange) == x;
            
            Y = a.A * X';
            
            for ii = 1:length(a.axes_)
                a.axes_{ii}.goto(Y(ii));
            end
        end
    end
        
    methods
        % EXTRA --------- Any additional functionality this axis should have (remove if there is none).
        function makePlot(a)
            figure
            
            axes
            xlabel(
            
            imagesc(a.config.src.scans{1}, a.config.src.scans{2}, d);
            daspect([1 1 1])

            hold all;

            nums = 1:length(xvals);

            for ii = nums
                text(xvals(ii), yvals(ii), num2str(ii), 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center', 'color', 'red')

                taxi = abs(xind - xind(ii)) + abs(yind - yind(ii));

                halfsquarewid = ceil(min(taxi(taxi ~= 0))/4) + .5;

                plot(unitx * halfsquarewid * [1 1 -1 -1 1] + xvals(ii), unity * halfsquarewid * [1 -1 -1 1 1] + yvals(ii), 'red')
            end
        end
    end
end




