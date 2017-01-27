function PLESetupTemp3()
    c = mcaPoints.modifyAndPromptBrightSpotConfig();
    a = mcaPoints(c);
    a.makePlot
    
    c1 = mciDaughter.daughterConfig(a, 'prevOpt(end,1,3) + 25', [1 1], 'um');    c1.name = 'X Offset From Expected';
    c2 = mciDaughter.daughterConfig(a, 'prevOpt(end,2,3) + 25', [1 1], 'um');    c2.name = 'Y Offset From Expected';
    c3 = mciDaughter.daughterConfig(a, 'prevOpt(end,3,2) + 25', [1 1], 'um');    c3.name = 'Absolute Z';
    
    c4 = mciDaughter.daughterConfig(a, 'prev{1}', [c.optPix 1], 'cts');	 c4.name = 'X Scan';
    c5 = mciDaughter.daughterConfig(a, 'prev{2}', [c.optPix 1], 'cts');  c5.name = 'Y Scan';
    c6 = mciDaughter.daughterConfig(a, 'prev{3}', [c.optPix 1], 'cts');  c6.name = 'Z Scan';
    
    i1 = mciDaughter(c1);
    i2 = mciDaughter(c2);
    i3 = mciDaughter(c3);
    
    i1b = mciDaughter(c4);
    i2b = mciDaughter(c5);
    i3b = mciDaughter(c6);
    
    d.axes =    {a, mcAxis};
    d.scans =   {1:length(a.config.nums), 1:20};
    d.inputs =  {mciDAQ.counterConfig, i1, i2, i3, i1b, i2b, i3b};
    d.intTimes = NaN(size(d.inputs)); %, NaN, NaN, NaN];
    d.intTimes(1) = 10;
    
    mcDataViewer(mcData(d));
end




