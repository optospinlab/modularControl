function PLESetupTemp()
    load('C:\Users\Tomasz\Desktop\modularControl (testing)\manual\19_22_30_206 Counter vs Piezo X, Piezo Y.mat');
    c = mcaPoints.brightSpotConfig(data);
    c.shouldOptimize = mciDAQ.counterConfig;
    c.additionalAxes = {mcaDAQ.piezoZConfig};
    a = mcaPoints(c);
    
%     c1 = mciDaughter.daughterConfig(a, 'prevOpt(1,3)', [3 3], 'um');
%     c2 = mciDaughter.daughterConfig(a, 'prevOpt(2,3)', [3 3], 'um');
%     c3 = mciDaughter.daughterConfig(a, 'prevOpt(3,3)', [3 3], 'um');
%     i1 = mciDaughter(c1);
%     i2 = mciDaughter(c2);
%     i3 = mciDaughter(c3);
    
    a.makePlot
    saveas(gcf, 'Points.png');  % Temp!
    
    d.axes = {mcAxis, a};
    d.scans = {1:20, a.config.nums};
    d.inputs = {mciPLE}; %, i1, i2, i3};
    d.intTimes = [NaN]; %, NaN, NaN, NaN];
    
    dv = mcDataViewer(mcData(d));
end

