function [param] = imfeat_mser(cmd1, cmd2, param)

switch cmd1
    case 'initialization'
        param.rd.mode = 'gray';
    case 'set_color_mode'
        param.rd.mode = cmd2; 
    case 'extract_feature_raw'
        param.feat_raw = imfeat_mser_algo(param.image, cmd2);
    otherwise
        warning('Unsupport cmd: %s',cmd1);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [out] = imfeat_mser_algo(I, param)

if size(param) == 0
    out = detectMSERFeatures(I);
else
    out = detectMSERFeatures(I,...
        'ThresholdDelta', param(1),...
        'RegionAreaRange', param(2:3),...
        'MaxAreaVariation', param(4));
end

end