function [param] = imfeat_thmser(cmd1, cmd2, param)

switch cmd1
    case 'initialization'
        param.rd.mode = 'gray';
    case 'extract_feature_mask'
        param.feat_mask = imfeat_thmser_algo(param.image, cmd2);
    otherwise
        warning('Unsupport cmd: %s',cmd1);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [out] = imfeat_thmser_algo(I, T)

out = (I==T);

end