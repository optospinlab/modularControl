function autoPLESetupTemp()
    % Make the points config
    c = mcaPoints.promptBrightSpotConfig();     % Prompt the user with a uigetfile to get the data file.
    c.shouldOptimize = mciDAQ.counterConfig;    % Optimize at every point using this input
    c.additionalAxes = {mcaDAQ.piezoZConfig};   % Also optimize Z at every point, along with X and Y (which come by default)
    a = mcaPoints(c);
    a.makePlot                  % make a plot of the identified points
    saveas(gcf, 'Points.png');  % Temp!
    
    % Setup the data config
    d.axes = {mcAxis, a};
    d.scans = {1:20, a.config.nums};
                        % mciPLE.PLEConfig(xMin, xMax, upPixels, upTime, downTime)
    d.inputs = {mciPLE(   mciPLE.PLEConfig(0, 3, 240, 10, 1))};
    d.intTimes = NaN; 	% Don't care about integration time because this input has a set integration time
    
    % Make the dataViewer and aquire
    dv = mcDataViewer(mcData(d));
end




