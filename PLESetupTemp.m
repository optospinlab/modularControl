function PLESetupTemp()
%     load('C:\Users\Tomasz\Desktop\modularControl (testing)\manual\19_22_30_206 Counter vs Piezo X, Piezo Y.mat');
%     c = mcaPoints.promptBrightSpotConfig();

    
%     configPiezoX = mcaDAQ.piezoConfig();    configPiezoX.name = 'Piezo X'; configPiezoX.chn = 'ao0';
%     configPiezoY = mcaDAQ.piezoConfig();    configPiezoY.name = 'Piezo Y'; configPiezoY.chn = 'ao1';
% 
%     data = mcData(mcData.squareScanConfiguration(mcaDAQ(configPiezoX), mcaDAQ(configPiezoY), mciDAQ(mciDAQ.counterConfig), 20, 10, 300));
%     mcDataViewer(data, false);
% 
%     c = mcaPoints.brightSpotConfig(data.d);
%     
    c = mcaPoints.modifyAndPromptBrightSpotConfig();
    
    
%     c = mcaPoints.promptBrightSpotConfig();
%     c.shouldOptimize = mciDAQ.counterConfig;
%     c.additionalAxes = {mcaDAQ.piezoZConfig};
%     c.optNum = 2;

    a = mcaPoints(c);
    a.makePlot
    
    numScans =  10;
    
    e = mcePLE.customConfig(numScans);
    lenPLE =    240;
    
    c1 = mciDaughter.daughterConfig(a, 'prevOpt(end,1,3) + 25', [1 1], 'um');    c1.name = 'X Offset From Expected';
    c2 = mciDaughter.daughterConfig(a, 'prevOpt(end,2,3) + 25', [1 1], 'um');    c2.name = 'Y Offset From Expected';
    c3 = mciDaughter.daughterConfig(a, 'prevOpt(end,3,2) + 25', [1 1], 'um');    c3.name = 'Absolute Z';
    
    c4 = mciDaughter.daughterConfig(a, 'prev{1}', [c.optPix 1], 'cts');	c4.name = 'X Scan';
    c5 = mciDaughter.daughterConfig(a, 'prev{2}', [c.optPix 1], 'cts');  c5.name = 'Y Scan';
    c6 = mciDaughter.daughterConfig(a, 'prev{3}', [c.optPix 1], 'cts');  c6.name = 'Z Scan';
    
    i1 = mciDaughter(c1);
    i2 = mciDaughter(c2);
    i3 = mciDaughter(c3);
    
    i1b = mciDaughter(c4);
    i2b = mciDaughter(c5);
    i3b = mciDaughter(c6);
    
    I = mciPLE();
    
    i4 = mciDaughter(mciDaughter.daughterConfig(e, 'aPLE', [numScans max(I.config.kind.sizeInput)], 'cts'));
    i5 = mciDaughter(mciDaughter.daughterConfig(e, 'aSpec', [2 512], 'cts'));
    
    i6 = mciDaughter(mciDaughter.daughterConfig(e, 'aSpecPos',       [1 1], 'V'));
    i7 = mciDaughter(mciDaughter.daughterConfig(e, 'aSpecIntensity', [1 1], 'cts'));
    
    i8 = mciDaughter(mciDaughter.daughterConfig(e, 'aLineWid',   [1 1], 'V'));
    i9 = mciDaughter(mciDaughter.daughterConfig(e, 'aIntensity', [1 1], 'cts'));
    
    i10 = mciDaughter(mciDaughter.daughterConfig(e, 'aLineWidM',   [1 1], 'V'));
    i11 = mciDaughter(mciDaughter.daughterConfig(e, 'aIntensityM', [1 1], 'cts'));
    
    d.axes =    {a, mcAxis};
    d.scans =   {a.config.nums, 1:2};
    d.inputs =  {mciDAQ.counterConfig, i1, i2, i3, i1b, i2b, i3b, mcePLE(e), i4, i5, i6, i7, i8, i9, i10, i11};
    d.intTimes = NaN(size(d.inputs)); %, NaN, NaN, NaN];
    d.intTimes(1) = 5;
    
    mcDataViewer(mcData(d));
end

