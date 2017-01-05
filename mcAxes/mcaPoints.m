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
        additionalAxes = {};
        shouldOptimize = [];
        
        prevOpt = [];
        rollingMeanDiff = [];
    end

    methods (Static)    % The folllowing static configs are used to define the identity of axis objects. configs can also be loaded from .mat files
        %  - A
        
        function config = defaultConfig()               % Static config that should be used if no configuration is provided upon intialization.
            config = mcaPoints.blankConfig();
        end
        function config = blankConfig()
            config.class =              'mcaPoints';
            
            config.A =      [];
            config.axes =   {};
            
            config.name =               'Blank mcaPoints';

            config.kind.kind =          'brightspot';
            config.kind.name =          'Bright spots found from 2D data';
            config.kind.intRange =      [];
            config.kind.int2extConv =   @(x)(x);
            config.kind.ext2intConv =   @(x)(x);
            config.kind.intUnits =      'point';
            config.kind.extUnits =      'point';
            config.kind.base =          NaN;
            
            config.keyStep =            1;
            config.joyStep =            1;
        end
        function config = brightSpotConfig(d)
            config.class =              'mcaPoints';
            
            config.name =               ['Points Found in ' d.name];
            
            config.src =                d;
            
            if isempty(d.inputs)
                error('mcaPoints(): Error checking in mcData should have caught this.');
            elseif length(d.inputs) > 1
                warning(['mcaPoints(): Expected a data structure with only one input. Found ' num2str(length(d.inputs)) ' inputs. We assume that the first input is the desired input']);
            end
            
            if length(d.axes) ~= 2
                error(['mcaPoints(): Expected a 2D data structure. Found ' num2str(length(d.axes)) ' dimensions.']);
            end
            
            s = wiener2(d.data{1}, [3 3]);

%             figure;
            bw = imdilate(imclearborder(imregionalmax(s)) & s > quantile(s(:), .9), strel('diamond',1));
            % Don't hardcode quantile!!!
            
            %             figure; imagesc(bw);
            r = regionprops(bw, s, 'WeightedCentroid', 'MaxIntensity');

            c = cat(1, r.WeightedCentroid);

            [~, sorted] = sort(cat(1, r.MaxIntensity), 'descend');

            xind = round(c(sorted,1));
            yind = round(c(sorted,2));

            xvals = d.scans{1}(xind);
            yvals = d.scans{2}(yind);

            unitx = abs(d.scans{1}(2) - d.scans{1}(1));     % Make sure length is greater than 1?
            unity = abs(d.scans{2}(2) - d.scans{2}(1));

            config.nums = 1:length(xvals);
            
            halfsquarewid = zeros(size(xvals));

            for ii = config.nums
                taxi = abs(xind - xind(ii)) + abs(yind - yind(ii));
                halfsquarewid(ii) = ceil(min(taxi(taxi ~= 0))/4) + 1.5;
            end
            
            limit = .75;    % Don't hardcode!!!
            
            config.A =      [xvals; yvals; min(halfsquarewid*unitx, limit); min(halfsquarewid*unity, limit)];
            
            config.axes =   d.axes(2:-1:1);
            
%             a1 = d.axes{1}
%             a2 = d.axes{2}
            
            config.data = d;

            config.kind.kind =          'brightspot';
            config.kind.name =          'Bright spots found from 2D data';
            config.kind.intRange =      num2cell(1:length(xind));
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
            if nargin == 0
                a.construct(a.defaultConfig());
            else
                a.construct(varin);
            end
            
            a.extra = {'A', 'axes'};
            
            for ii = 1:length(a.config.axes)
                c = a.config.axes{ii};
                a.axes_{ii} = eval([c.class '(c)']);
            end
            
            if ~isfield(a.config, 'shouldOptimize')
                a.config.shouldOptimize = [];
            else
                c = a.config.shouldOptimize;
                a.shouldOptimize = eval([c.class '(c)']);
            end
            if ~isfield(a.config, 'additionalAxes')
                a.config.additionalAxes = {};
                a.additionalAxes = {};
            else
                for ii = 1:length(a.config.additionalAxes)
                    c = a.config.additionalAxes{ii};
                    a.additionalAxes{ii} = eval([c.class '(c)']);
                end
            end
            
            a.rollingMeanDiff =  NaN(2, 10);
            
            a = mcInstrumentHandler.register(a);
        end
    end
    
    % These methods overwrite the empty methods defined in mcAxis. These methods are used in the uncapitalized parent methods defined in mcAxis.
    methods
        % NAME ---------- The following functions define the names that the user should use for this axis.
        function str = NameShort(a)     % 'short' name, suitable for UIs/etc.
            str = [a.config.name ' (' num2str(length(a.config.axes)) ' axes)'];
        end
        function str = NameVerb(a)      % 'verbose' name, suitable to explain the identity to future users.
            str = [a.config.name ' ( ' ')'];
        end
        
        %EQ ------------- The function that should return true if the custom vars are the same (future: use a.extra for this?)
        function tf = Eq(a, b)
            tf = strcmpi(a.config.name, b.config.name);
        end
        
        % OPEN/CLOSE ---- The functions that define how the axis should init/deinitialize (these functions are not used in emulation mode).
        function Open(a)                % Do whatever neccessary to initialize the axis.
            for ii = 1:length(a.config.axes)
                a.axes_{ii}.open();
            end
        end
        function Close(a)               % Do whatever neccessary to deinitialize the axis.
            for ii = 1:length(a.config.axes)
                a.axes_{ii}.close();
            end
        end
        
        % READ ---------- Not neccessary
        
        % GOTO ---------- The 'meat' of the axis: the funtion that translates the user's intended movements to reality.
        function GotoEmulation(a, x)
            a.Goto(x);
        end
        function Goto(a, x)
            a.x = x;
            a.xt = a.x;
            
            X = a.config.nums == x;
            
            Y = a.config.A * X';
            
            n = length(a.axes_);
            
            if ~isempty(a.config.shouldOptimize)
                m = mean(a.rollingMeanDiff, 2);
                
                y = Y;
                
                if ~isnan(m)
                    Y(1:n) = Y(1:n) + m;
                end
            end
            
            for ii = 1:length(a.axes_)
                a.axes_{ii}.goto(Y(ii));
            end
            
            if ~isempty(a.config.shouldOptimize)
                for ii = 1:n
                    a.prevOpt(x, ii, 1) = y(ii);
                    
                    d = mcData(mcData.optimizeConfiguration(a.axes_{ii},...
                                                            a.shouldOptimize,...
                                                            Y(length(a.axes_) + ii),...
                                                            200,... % Should not be hardcoded!
                                                            5));    % Should not be hardcoded!
                    disp(['Beginning Optimization of ' a.axes_{ii}.name '...']);
                    d.aquire();
                    disp('...Finished.');
                    
                    a.prevOpt(x, ii, 2) = a.axes_{ii}.getX();
                    a.prevOpt(x, ii, 3) = a.prevOpt(x, ii, 2) - a.prevOpt(x, ii, 1);
                    
                    a.rollingMeanDiff(ii, 1) = a.prevOpt(x, ii, 3);
                end
                
                for jj = 1:length(a.additionalAxes)
                    ii = ii + 1;
                    
                    a.prevOpt(x, ii, 1) = a.additionalAxes{jj}.getX();
                    
                    d = mcData(mcData.optimizeConfiguration(a.additionalAxes{jj},...
                                                            a.shouldOptimize,...
                                                            5,...   % Should not be hardcoded!
                                                            200,... % Should not be hardcoded!
                                                            5));    % Should not be hardcoded!
                                                        
                    disp(['Beginning Optimization of ' a.additionalAxes{jj}.name '...']);
                    d.aquire();
                    disp('...Finished.');
                    
                    a.prevOpt(x, ii, 2) = a.additionalAxes{jj}.getX();
                    a.prevOpt(x, ii, 3) = a.prevOpt(x, ii, 2) - a.prevOpt(x, ii, 1);
                end
                
                p = a.prevOpt;
                
                save('temp.mat', 'p');
                
%                 a.prevOpt = 0;
                
                a.rollingMeanDiff = circshift(a.rollingMeanDiff, [0 1]);
            end
        end
    end
        
    methods
        % EXTRA --------- Any additional functionality this axis should have (remove if there is none).
        function makePlot(a)
            a.open();
            
            figure;
            
            ax = axes;
            
            xlabel(a.axes_{1}.nameUnits());
            ylabel(a.axes_{2}.nameUnits());
            
            imagesc(a.config.src.scans{1}, a.config.src.scans{2}, a.config.src.data{1});
            
            ax.YDir = 'normal';
            
            daspect([1 1 1]);

            hold all;
                    
            s = size(a.config.A);
            shouldPlotBox = s(1) == 4;

            for ii = a.config.nums
                text(   a.config.A(1,ii), a.config.A(2,ii), num2str(ii),...
                        'VerticalAlignment', 'middle',...
                        'HorizontalAlignment', 'center',...
                        'color', 'red');
                
                if shouldPlotBox
                    plot(   a.config.A(3,ii) * [1 1 -1 -1 1] + a.config.A(1,ii),...
                            a.config.A(4,ii) * [1 -1 -1 1 1] + a.config.A(2,ii),...
                            'red');
                end
            end
        end
    end
end




