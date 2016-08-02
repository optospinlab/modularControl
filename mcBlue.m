function mcBlue()
% mcBlue is a temperary function to get blue input.
% Status: see the commented classdef (below) for future plans. Possibly also make a generic class for video input (a subclass of
%   mcInput?

    f = mcInstrumentHandler.createFigure('mcBlue');

    f.Resize =      'off';
    f.Position =    [100, 100, 1280, 960];
    f.Visible =     'on';
    f.MenuBar =     'none';
    f.ToolBar =     'none';
    % Future: make resize fnc

    axes('Position', [0 0 1 1]);

    f.UserData = videoinput('avtmatlabadaptor64_r2009b', 1, 'F0M5_Mono8_640x480');
%         src = getselectedsource(c.vid);

    f.UserData.FramesPerTrigger = 1;
    vidRes = f.UserData.VideoResolution;
    nBands = f.UserData.NumberOfBands;
    hImage = image(zeros(vidRes(2), vidRes(1), nBands), 'YData', [vidRes(2) 1]);
    preview(f.UserData, hImage);
    videoEnabled = 1;

%         axes(c.track_Axes);
%         frame = getsnapshot(c.vid);
%         imshow(frame);
    %Testing image 
    %frame = flipdim(rgb2gray(imread('C:\Users\Tomasz\Desktop\DiamondControl\test_image.png')),1);

end
    
% classdef mcBlue
% % mcBlue
%     
%     properties
%         f = [];     % Figure; video info stored in UserData.
%         l = [];     % Listener for blue feedback.
%     end
%     
%     methods
%         function blue = mcBlue()
%             
%         end
%         
%         function getImage(blue)
%             
%         end
%         
%         function lockFeedback(blue)
%             
%         end
%         
%         function stopFeedback(blue)
%             
%         end
%     end
%     
% end




