function [out] = util_cropBinImg(I)

% crop to fit the boundary
ft_bin = []; 
ft_bin = imfeat('init', 'binary' ,ft_bin);
ft_bin = imfeat('set_image', I, ft_bin);
ft_bin = imfeat('extract_feature_raw_boundingbox_all', '', ft_bin);
out = I(ft_bin.feat_raw.y_min:ft_bin.feat_raw.y_max, ...
        ft_bin.feat_raw.x_min:ft_bin.feat_raw.x_max);
            
end