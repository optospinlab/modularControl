function mcBrynn()
    % Open some GUIs:
    mcVideo(mcVideo.brynnConfig());
    
    input = mcUserInput(mcUserInput.brynnConfig());
    input.openListener();        
    input.openWaypoints();
    
    mcgBrynn();

    % Additionally, open these instruments:
    mcaManual(mcaManual.polarizationConfig());
end




