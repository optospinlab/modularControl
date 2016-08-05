classdef mcDiamond
% mcDiamond is a class specifically for the diamond room. It starts up certain essential features and provides a GUI with useful
%   functions.
    
    properties
        pw = 300;
        ph = 500;
        
        f = [];
    end
    
    methods
        function dc = mcDiamond()
            mcBlue();
            mcUserInput(mcUserInput.diamondConfig());
%             mcAxisListener();
            
            mcAxis(mcAxis.polarizationConfig());
            
            configCounter = mcInput.counterConfig(); configCounter.name = 'Counter'; configCounter.chn = 'ctr2';
            
            mcInput(configCounter);
            mcInput(mcInput.spectrumConfig());
            
            
            dc.f = mcInstrumentHandler.createFigure(gui, 'saveopen');
            dc.f.Resize =      'off';
%             f.Visible =     'off';
%             f.MenuBar =     'none';
%             f.ToolBar =     'none';
            dc.f.Position = [100, 100, dc.pw, dc.ph];
        end
        
        function piezoScan_Callback(~,~)
            
        end
        
        function galvoScan_Callback(~,~)
            
        end
    end
end




