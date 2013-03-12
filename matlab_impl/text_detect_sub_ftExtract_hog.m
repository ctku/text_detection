function [ft_vector] = text_detect_sub_ftExtract_hog(data)

im = [];
im = imfeat('init', 'hog', im);
im = imfeat('set_image', data, im);
im = imfeat('resize_no_keep_ar', [32,32], im);
im = imfeat('extract_feature_raw', [4,4,9], im);

ft_vector = im.feat_raw;

end