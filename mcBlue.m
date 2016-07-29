function mcBlue()
    % Get video source

    % Send the image from the source to the imageAxes
%         axes(c.imageAxes);
    f = mcInstrumentHandler.createFigure('mcBlue');

    f.Resize =      'off';
    f.Position =    [100, 100, 1280, 960];
    f.Visible =     'on';
    f.MenuBar =     'none';
    f.ToolBar =     'none';
    % Make resize fnc

    a = axes('Position', [0 0 1 1]);

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
%     %UNTITLED Summary of this class goes here
%     %   Detailed explanation goes here
%     
%     properties
%     end
%     
%     methods
%     end
%     
% end