classdef mcSavableClass < handle
% mcSavableClass is the parent class for objects (mostly figures) that have
%   configs which are savable and should be recoverable in the future (e.g.
%   after restart).
%
% Status: Mostly finished. Needs commenting.
    
    properties
        config = [];
    end
    
    methods
        function makeClassFolder(obj)
            folder = [mcInstrumentHandler.getConfigFolder() class(obj)];
            if ~exist(folder, 'file')
                mkdir([mcInstrumentHandler.getConfigFolder() class(obj)]);
            end
        end
        
        function save(varin)
            switch nargin
                case 1
                    obj = varin;
                    if isfield(obj.config, 'src')
                        fname = obj.config.src;
                    else
                        if ismethod(obj, 'name')
                            fname = [mcInstrumentHandler.getConfigFolder() class(obj) filesep obj.name() '.mat'];
                        else
                            fname = [mcInstrumentHandler.getConfigFolder() class(obj) filesep 'config.mat'];
                        end
                    end
                case 2
                    obj = varin{1};
                    fname = [mcInstrumentHandler.getConfigFolder() class(obj) filesep varin{2}];
            end

            config = obj.config;

            save(fname, 'config');
        end
%         function save(obj, fname)
%             obj.makeClassFolder();
%             config = obj.config;
% %             if exist(fname, 'file')
% %                 save(fname, 'config');
% %             elseif exist([mcInstrumentHandler.getConfigFolder() class(obj) filesep fname], 'file')
%                 save([mcInstrumentHandler.getConfigFolder() class(obj) filesep fname], 'config');
% %             else
% %                 warning([class(obj) ': filename not understood.']);
% %             end
%         end
        function saveGUI_Callback(obj, ~, ~)        % Customize this if neccessary in the daughter class (e.g. saving a .png or a folder of data)
            obj.makeClassFolder();
            [FileName, PathName] = uiputfile('*.mat', 'Save Config As', [mcInstrumentHandler.getConfigFolder() class(obj) filesep 'config.mat']);
            if FileName ~= 0
                config = obj.config;
                save([PathName FileName], 'config');
            end
        end
        
        function interpretConfig(obj, config)
            if ischar(config)
                obj.load(config);
            elseif isstruct(config)
                obj.config = config;
            end
        end
        
        function load(obj, fname)
            fname2 = [mcInstrumentHandler.getConfigFolder() class(obj) filesep fname];
            if exist(fname2, 'file')
                config2 = load(fname2);
                obj.config = config2.config;
                obj.config.src = fname2;
            else
                warning([class(obj) ': The file given to load does not exist.']);
            end
        end
        function loadGUI_Callback(obj, ~, ~)
            obj.makeClassFolder();
            [FileName, PathName] = uigetfile('*.mat', 'Load Config', [mcInstrumentHandler.getConfigFolder() class(obj)]);
            if FileName ~= 0
                config2 = load([PathName FileName]);
                obj.config = config2.config;
                obj.config.src = [PathName FileName];
            end
        end
    end
end



