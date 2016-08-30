classdef mcVideo < mcInput
% mcVideo gets video with videoinput. It is a subclass of mcInput becaues it acts like an input. It does not start with mci
% because it is more than 'just an input'...
    
    properties
        f = [];         % Figure.
        a = [];         % Axes; video displayed here.
        v = [];         % videoinput object
        i = [];         % image object
        
        fb = [];        % Feedback vars
        
        pidArray = [];      % PIDs for the x, y, and z axes.
    end
    
    methods (Static)
        % Neccessary extra vars:
        %  - adaptor    string
        %  - format     string
        %  - fbAxes     cell array with {x,y,z}; [] for no feedback
        
        function config = defaultConfig()
            config = mciFunction.randConfig();
        end
        function config = blueConfig()
            config.name =               'Blue Video Input';

            config.kind.kind =          'videoinput';
            config.kind.name =          'Default Function Input';
            config.kind.extUnits =      'arb';                      % 'External' units.
            config.kind.normalize =     false;
            config.kind.sizeInput =     [NaN NaN];                  % Unknown until initiation
            
            config.adaptor =            'avtmatlabadaptor64_r2009b';
            config.format =             'F0M5_Mono8_640x480';
            config.fbAxes =             {mcaDAQ(mcaDAQ.piezoConfig()), mcaDAQ(mcaDAQ.piezoConfig()), mcaDAQ(mcaDAQ.piezoConfig())};
        end
    end
    
    methods
        function vid = mcVideo(varin)
            vid.f = mcInstrumentHandler.createFigure(vid, 'none');

            vid.f.Resize =      'off';
            vid.f.Position =    [100, 100, 1280, 960];
            vid.f.Visible =     'on';
%             f.MenuBar =     'none';
%             f.ToolBar =     'none';
            % Future: make resize fnc
            % Future: make close fnc

            vid.a = axes('Position', [0 0 1 1], 'XTick', 0, 'YTick', 0, 'LineWidth', 4, 'Box', 'on');

            vid.v = videoinput(vid.config.adaptor, 1, vid.config.format);

            vid.v.FramesPerTrigger = 1;
            vidRes = vid.v.VideoResolution;
            nBands = vid.v.NumberOfBands;
            vid.i = image(zeros(vidRes(2), vidRes(1), nBands), 'YData', [vidRes(2) 1]);
            preview(vid.v, vid.i);     % this appears on the axes we made.
            
            vid.config.kind.sizeInput = vidRes;
        end
        
        function image = getImage(vid)
            image = getsnapshot(vid.v);
        end
        
%         function focusFcn(vid, ~, event, ~)
%             % Future
%         end
%         function startFocus_Callback(vid, ~, ~)
%             vid.i.UpdatePreviewWindowFcn = @vid.focusFcn;
%         end
%         function stopFocus_Callback(vid, ~, ~)
%             vid.i.UpdatePreviewWindowFcn = [];
%         end
        
        function startFeedback_Callback(vid, ~, ~)
            % Srivatsa's code:
            vid.fb.frame_init = imadjust(vid.getImage());         % imadjust increases the contrast of the image by normalizing the data.
            vid.fb.points1 = detectSURFFeatures(vid.fb.frame_init, 'NumOctaves', 6, 'NumScaleLevels', 10,'MetricThreshold', 500);
            [vid.fb.features1, vid.fb.valid_points1] = extractFeatures(vid.fb.frame_init,  vid.fb.points1);
            
            vid.i.UpdatePreviewWindowFcn = @vid.feedbackFcn;
        end
        function stopFeedback_Callback(vid, ~, ~)
            vid.i.UpdatePreviewWindowFcn = [];
        end
        function feedbackFcn(vid, ~, event, ~)  % Third input is handle to image (special to this callback).
            frame = imadjust(event.Data);   % Normalize image (remove for performance?)
            
            % XY FEEDBACK
            points2 = detectSURFFeatures(frame, 'NumOctaves', 6, 'NumScaleLevels', 10,'MetricThreshold', 500);
            [features2, valid_points2] = extractFeatures(frame,  points2);

            indexPairs = matchFeatures(vid.fb.features1, features2);

            matchedPoints1 = vid.fb.valid_points1(indexPairs(:, 1), :);
            matchedPoints2 = valid_points2(indexPairs(:, 2), :);
            
            % Remove Outliers
            delta = (matchedPoints2.Location - matchedPoints1.Location);
            dist = sum(delta.*delta, 2); %sqrt(delta(:,1).*delta(:,1) + delta(:,2).*delta(:,2));

            mean_dist = mean(dist);
            stdev_dist = std(dist);
            
            % And filter the points such that only those within one standard deviation of the mean remain (change in the future?).
            filteredPoints = dist < mean_dist + stdev_dist & dist > mean_dist - stdev_dist;
            
            if ~empty(filteredPoints)                       % If there are points left after the filtering...
                offset = mean(delta(filteredPoints, :));
                
                x = pidArray(1).input(offset(1));           % Calculate the output of the pids (recommended um), based on the input offset...
                y = pidArray(2).input(offset(2));
                
                vid.config.fbAxes{1}.goto(x);               % ...and then send the axes to these values.
                vid.config.fbAxes{2}.goto(y);
                
                dx = x - vid.config.fbAxes{1}.getX();
                dy = y - vid.config.fbAxes{2}.getX();
                
                d2 = dx*dx + dy*dy;
                
                vid.a.Color = [1 - 1/(1 + 4*d2) 1/(1 + 4*d2) 0];       % Amount of red represents the deviation from the desired value.
                vid.a.LineWidth = 8 - 4/(1 + 4*d2);
            end
            
            % Z FEEDBACK
            contrast = getContrast(frame);
            
            if contrast < .9*targetContrast     % If the contrast is significantly less than 
                
            end
        end
    end
    
end

function contrast = getContrast(image)  % Returns a number proportional(?) to the contrast of the image
    i = gpuArray(image);    % Use GPU acceleration or not?
    
    contrast = sum(sum(imabsdiff(i, imfilter(i, fspecial('guassian')))));
end




