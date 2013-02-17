function [ft_vector, ft_struct] = text_detect_sub_ftExtract_init(ER, ft_bin)

% (1) extract initial raw features
ft_bin = imfeat('set_image', ER.data, ft_bin);
ft1 = imfeat('extract_feature_raw_boundingbox_all', '', ft_bin);    % 1st stage
ft2 = imfeat('extract_feature_raw_size_all', '', ft_bin);           % 1st stage
ft3 = imfeat('extract_feature_raw_perimeter_all', '', ft_bin);      % 1st stage
ft4 = imfeat('extract_feature_raw_eulerno_all', '', ft_bin);        % 1st stage
ft5 = imfeat('extract_feature_raw_hzcrossing_all', '', ft_bin);     % 1st stage
ft6 = imfeat('extract_feature_raw_holesize_all', '', ft_bin);       % 2nd stage
ft7 = imfeat('extract_feature_raw_convexhull_all', '', ft_bin);     % 2nd stage
ft8 = imfeat('extract_feature_raw_reflectpointno_all', '', ft_bin); % 2nd stage

% (2) compute desired features
% aspect ratio (1st)
ft_ar = (ft1.feat_raw.x_max - ft1.feat_raw.x_min + 1) / ...
        (ft1.feat_raw.y_max - ft1.feat_raw.y_min + 1);  
% compactness (1st)
ft_cp = sqrt(ft2.feat_raw) / ft3.feat_raw;
% number of holes (1st)
ft_hl = 1 - ft4.feat_raw;
% median of horizontal crossing (1st)
h = ft1.feat_raw.y_max - ft1.feat_raw.y_min + 1;
if h>=3
    median_idx = (ft1.feat_raw.y_min-1)*ones(1,3) + round(h * [1/6 3/6 5/6]);
else
    median_idx = [1 1 1];
end
ft_hz = median(ft5.feat_raw(median_idx));
% hole area ratio (2nd)
ft_ho = ft6.feat_raw / ft2.feat_raw;
% convex hull ratio (2nd)
ft_ch = ft7.feat_raw / ft2.feat_raw;
% no of outer boundary reflection point (2nd)
ft_rf = ft8.feat_raw;

% (3) pack output structure for incremental method
ft_struct.ft_bb = ft1;
ft_struct.ft_sz = ft2;
ft_struct.ft_pr = ft3;
ft_struct.ft_eu = ft4;
ft_struct.ft_hz = ft5;
ft_struct.ft_hz_pre_data_t = ER.data_t;

ft_vector = [ft_ar, ft_cp, ft_hl, ft_hz, ft_ho, ft_ch, ft_rf];

end