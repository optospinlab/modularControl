function mcDiamond
    % Starts the neccessary features of the diamond microscope.
    
    % Open some GUIs:
    
    mcVideo();
%     disp('  Opened the blue camera...')
    
    input = mcUserInput(mcUserInput.diamondConfig());
%     disp('  Opened mcUserInput mcAxes...')
    
    input.openListener();
%     disp('  Opened mcUserInput listeners...')
    
    mcgDiamond();
%     disp('  Opened mcgDiamond...')
    
%     disp('  Opening mcUserInput waypoints...')  % This is needed to connect the trigger of the joystick to the mcWaypoints feature.
%     input.openWaypoints();

    % Additionally, open these instruments:
    mcaManual(mcaManual.polarizationConfig());

    configCounter = mciDAQ.counterConfig(); configCounter.name = 'Counter'; configCounter.chn = 'ctr2';
    mciDAQ(configCounter);

    mciSpectrum();
%     disp('  Opened additional mcInstruments...')
end




