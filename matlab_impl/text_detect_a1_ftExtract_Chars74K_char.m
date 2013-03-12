function text_detect_a1_ftExtract_Chars74K_char(output_fn)

bad_idx = [9:12, ...
           105:108, ...
           189:192, ...
           213:216, ...
           253:256, ...
           293:296, ...
           401:404, ...
           481:483, ...
           501:504, ...
           689:692, ...
           729:736, ...
           777:780, ...
           805:808, ...
           873:880, ...
           933:936, ...
           993:996];
addpath_for_me;
tic
% dataset initialization
ds_eng = [];
ds_eng = imdataset('init', 'Chars74K', ds_eng);
ds_eng = imdataset('get_eng_font_dataset', '', ds_eng);

% feature initialization
ft_ert = []; ft_bin = [];
ft_ert = imfeat('init', 'ertree' ,ft_ert);
ft_bin = imfeat('init', 'binary' ,ft_bin);

p = 0;
for i=1:ds_eng.no
    i
    % for each training image
    fn = util_changeFn(ds_eng.fn_list{i}, 'get_filename_and_extension', '');
    if sum(str2double(fn(8:12))==bad_idx)>0 %ex:img001-00001.png
        continue;
    end
    img = imread(ds_eng.fn_list{i});

    % (1) extract ER tree feature
    fprintf('Training img (%d/%d) of %s ...\n', i, ds_eng.no, ds_eng.fn_list{i});
    ft_ert = imfeat('set_image', img, ft_ert);
    ft_ert = imfeat('extract_feature_raw_get_all_preproc', 0, ft_ert);
    
    % (2) select ER having the largest area as representative
    max_pix_no = 0;
    max_ER_idx = [0,0];
    for t=1:254
        for tt=1:ft_ert.feat_raw.size(t)
            if ft_ert.feat_raw.tree{t,tt}.raw(2) > max_pix_no
                max_pix_no = ft_ert.feat_raw.tree{t,tt}.raw(2);
                max_ER_idx = [t,tt];
            end
        end
    end
    ft_ert = imfeat('extract_feature_raw_get_one_cropped_data_and_dif', max_ER_idx, ft_ert);
    ER = ft_ert.feat_raw.tree{max_ER_idx(1),max_ER_idx(2)};
    
    % (3) extract feature vector (by using initial computation scheme)
    [ft_outvec, ft_struct] = text_detect_sub_ftExtract_init(ER, ft_bin);
    p = p + 1;
    ft_vector(p, :) = ft_outvec;
end
toc
save([ds_eng.path '_output_files/' output_fn '.mat'], 'ft_vector');

end