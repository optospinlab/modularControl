function PLESetupTemp2()
    % Setup the data config
    d.axes = {mcAxis};  % This is the time axis
    d.scans = {1:20};   % Scan for 20 time points
    
                        % mciPLE.PLEConfig(xMin, xMax, upPixels, upTime (s), downTime (s))
    d.inputs = {mciPLE(   mciPLE.PLEConfig(0, 3, 240, 10, 1))};
    d.intTimes = NaN; 	% Don't care about integration time because this input has a set integration time
    data.flags.circTime = true;     % make it scan forever
    
    % Make the dataViewer and aquire
    dv = mcDataViewer(mcData(d));
end




