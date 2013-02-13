function [ft_vector, ft_struct] = text_detect_sub_ftExtract_incrementally(ER, ft_struct, ft_bin)

% (1) preparation for raw feature incremental computation
f_cum_bb = ft_struct.ft_bb.feat_raw; % 1
f_cum_sz = ft_struct.ft_sz.feat_raw; % 1
f_cum_pr = ft_struct.ft_pr.feat_raw; % 1
f_cum_eu = ft_struct.ft_eu.feat_raw; % 1
f_cum_hz = ft_struct.ft_hz.feat_raw; % h of ER
I_new = ER.dif;
I_cum = ER.data;
h = size(ER.data, 1);
ft_bin = imfeat('set_image', I_new, ft_bin);

% (2) compute raw features incrementally
% bounding box
ex1 = f_cum_bb;
ft1 = imfeat('compute_feature_raw_boundingbox_incrementally', ex1, ft_bin);
% size
ex2 = f_cum_sz;
ft2 = imfeat('compute_feature_raw_size_incrementally', ex2, ft_bin);
% perimeter
ex3{1} = I_cum;
ex3{2} = f_cum_pr;
ft3 = imfeat('compute_feature_raw_perimeter_incrementally', ex3, ft_bin);
% euler no
ex4{1} = I_cum;
ex4{2} = f_cum_eu;
ft4 = imfeat('compute_feature_raw_eulerno_incrementally', ex4, ft_bin);
% horizontal crossing
ex5{1} = I_cum;
ex5{2} = f_cum_hz;
ft5 = imfeat('compute_feature_raw_hzcrossing_incrementally', ex5, ft_bin);

% (3) compute desired features
% aspect ratio
ft_ar = (ft1.feat_raw.x_max - ft1.feat_raw.x_min + 1) / ...
        (ft1.feat_raw.y_max - ft1.feat_raw.y_min + 1);  
% compactness
ft_cp = sqrt(ft2.feat_raw) / ft3.feat_raw;
% number of holes
ft_hl = 1 - ft4.feat_raw;
% median of horizontal crossing
h = ft1.feat_raw.y_max - ft1.feat_raw.y_min + 1;
if h>=3
    median_idx = (ft1.feat_raw.y_min-1)*ones(1,3) + round(h * [1/6 3/6 5/6]);
else
    median_idx = [1 1 1];
end
ft_hz = median(ft5.feat_raw(median_idx));

% (4) pack output
ft_vector = [ft_ar, ft_cp, ft_hl, ft_hz];
ft_struct.ft_bb = ft1;
ft_struct.ft_sz = ft2;
ft_struct.ft_pr = ft3;
ft_struct.ft_eu = ft4;
ft_struct.ft_hz = ft5;

end