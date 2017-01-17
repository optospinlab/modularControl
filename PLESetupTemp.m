function PLESetupTemp()
%     load('C:\Users\Tomasz\Desktop\modularControl (testing)\manual\19_22_30_206 Counter vs Piezo X, Piezo Y.mat');
%     c = mcaPoints.brightSpotConfig(data);
%     c.shouldOptimize = mciDAQ.counterConfig;
%     c.additionalAxes = {mcaDAQ.piezoZConfig};
    a = mcaDAQ; %mcAxis %mcaPoints();
    
    numScans =  15;
    
    e = mcePLE.customConfig(numScans);
    lenPLE =    240;
    
    c1 = mciDaughter.daughterConfig(a, 'prevOpt(1,3)', [1 1], 'um');    c1.name = 'X Offset';
    c2 = mciDaughter.daughterConfig(a, 'prevOpt(2,3)', [1 1], 'um');    c2.name = 'Y Offset';
    c3 = mciDaughter.daughterConfig(a, 'prevOpt(3,3)', [1 1], 'um');    c3.name = 'Z Offset';
    
    i1 = mciDaughter(c1);
    i2 = mciDaughter(c2);
    i3 = mciDaughter(c3);
    
    I = mciPLE();
    
    i4 = mciDaughter(mciDaughter.daughterConfig(e, 'aPLE', [max(I.config.kind.sizeInput) numScans], 'pixels'));
    i5 = mciDaughter(mciDaughter.daughterConfig(e, 'aSpec', [521 1], 'pixels'));
    
    i6 = mciDaughter(mciDaughter.daughterConfig(e, 'aSpecPos',       [1 1], 'V'));
    i7 = mciDaughter(mciDaughter.daughterConfig(e, 'aSpecIntensity', [1 1], 'cts'));
    
    i8 = mciDaughter(mciDaughter.daughterConfig(e, 'aLineWid',   [1 1], 'V'));
    i9 = mciDaughter(mciDaughter.daughterConfig(e, 'aIntensity', [1 1], 'cts'));
    
    i10 = mciDaughter(mciDaughter.daughterConfig(e, 'aLineWidM',   [1 1], 'V'));
    i11 = mciDaughter(mciDaughter.daughterConfig(e, 'aIntensityM', [1 1], 'cts'));

%     a.makePlot
%     saveas(gcf, 'Points.png');  % Temp!
    
    d.axes =    {a};
    d.scans =   {1:10}; %a.config.nums};
    d.inputs =  {mcePLE(e), i1, i2, i3, i4, i5, i6, i7, i8, i9, i10, i11};
    d.intTimes = NaN(size(d.inputs)); %, NaN, NaN, NaN];
    
    dv = mcDataViewer(mcData(d));
end

