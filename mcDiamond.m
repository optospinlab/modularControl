function mcDiamond
    % Starts the neccessary features of the diamond microscope.
    
    % Open some GUIs:
    
    disp('  Opening the blue camera...')
    mcVideo();
    
    disp('  Opening mcUserInput mcAxes...')
    input = mcUserInput(mcUserInput.diamondConfig());
    
    disp('  Opening mcUserInput listeners...')
    input.openListener();
    
    disp('  Opening mcgDiamond...')
    mcgDiamond();
    
%     disp('  Opening mcUserInput waypoints...')  % This is needed to connect the trigger of the joystick to the mcWaypoints feature.
%     input.openWaypoints();

    % Additionally, open these instruments:
    disp('  Opening additional mcInstruments...')
    mcaManual(mcaManual.polarizationConfig());

    configCounter = mciDAQ.counterConfig(); configCounter.name = 'Counter'; configCounter.chn = 'ctr2';
    mciDAQ(configCounter);

    mciSpectrum();
end




