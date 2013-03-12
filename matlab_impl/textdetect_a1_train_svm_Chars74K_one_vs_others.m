function textdetect_a1_train_svm_Chars74K_one_vs_others(path, name, feat, stage_vec)

addpath_for_me;
close all;

test_idx = 1;
desired_idx = [1,2,5,6,13,14,17,18,21,22,...
               25,26,29,30,33,34,37,38,41,42,...
               45,46,49,50,53,54,57,58,61,62,...
               65,66,69,70,73,74,77,78,81,82,...
               85,86,89,89,101,102,109,110,113,114];
% desired_idx = [1,2,5,6,13,14,17,18,21,22];
% desired_idx = [1];
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
all_ones = true(1,1000);
all_ones(bad_idx) = 0;
desired_idx = 1:1000;
desired_idx = desired_idx(all_ones & all_ones);

 
% Stage 1: collect feature vectors
if stage_vec(1)==1
    tic   
    % dataset initialization
    ds_eng = [];
    ds_eng = imdataset('init', 'Chars74K', ds_eng);
    ds_eng = imdataset('get_eng_font_dataset', '', ds_eng);

    % feature initialization
    ft_ert = []; ft_hog = [];
    ft_ert = imfeat('init', 'ertree' ,ft_ert);
    ft_hog = imfeat('init', 'hog' ,ft_hog);
    
    p = 0;
    cur_fld = 1;
    save_file = 0;
    for i=1:ds_eng.no

        % for each training image
        fn = util_changeFn(ds_eng.fn_list{i}, 'get_filename_and_extension', '');
        if sum(str2double(fn(8:12))==desired_idx)==0 || ... %ex:img001-00001.png
           0%exist([path.FEATVEC_MAT name.FEATVEC_MAT sprintf('%03d',cur_fld) '.mat'], 'file')
            continue;
        elseif str2double(fn(8:12))==desired_idx(end)
            save_file = 1;
        end
        
        if cur_fld==19
           cur_fld = cur_fld; 
        end
        % extract feature
        p = p + 1;
        ft_vector(p, :) = extract_feature_Chars74K(ds_eng.fn_list{i}, feat);

        % save feature vector when switch folder
        if save_file == 1
            mat_path = [path.FEATVEC_MAT name.FEATVEC_MAT sprintf('%03d',cur_fld) '.mat'];
            save(mat_path, 'ft_vector');
            fprintf('Save %s \n', mat_path);
            cur_fld = cur_fld + 1;
            p = 0;
            ft_vector = [];
            save_file = 0;
        end    
    end
    toc
end

% Stage 2: Train one versus all classifier for each chars
if stage_vec(2)==1
    tic
    fv = []; lb = [];
    for i=1:62
        mat_path = [path.FEATVEC_MAT name.FEATVEC_MAT sprintf('%03d',i) '.mat'];
        load(mat_path);
        fv = [fv; ft_vector];
        no_fv_per_class = size(ft_vector,1);
    end
    for i=1:62
        i
        lb = false(size(fv,1),1);
        lb((i-1)*no_fv_per_class+1:i*no_fv_per_class) = true;
        svm{i} = svmtrain(fv, lb, 'kernel_function', 'rbf');
    end
    save([path.CLASSIFIER_MAT name.CLASSIFIER_MAT '.mat'], 'svm');
    toc
end

% Stage 3: Test if it works
% result = false(62,62);
if stage_vec(3)==1
    tic
    load([path.CLASSIFIER_MAT name.CLASSIFIER_MAT '.mat']);

    % dataset initialization
    ds_eng = [];
    ds_eng = imdataset('init', 'Chars74K', ds_eng);
    ds_eng = imdataset('get_eng_font_dataset', '', ds_eng);
    
    % extract 62*1=62 HOG feature vectors
    p = 0;
    ft_vector = [];
    for i=1:ds_eng.no
        fn = util_changeFn(ds_eng.fn_list{i}, 'get_filename_and_extension', '');
        if sum(str2double(fn(8:12))==test_idx)==0
            continue;
        end
        % extract HOG feature
        p = p + 1;
        ft_vector(p, :) = extract_feature_Chars74K(ds_eng.fn_list{i}, feat);
    end
    
    % test for each char classifier
    result = false(62,62);
    for i=1:62
        result(:,i) = svmclassify(svm{i}, ft_vector);
    end
    
    % accuracy
    correct_no = 0;
    for i=1:62
        if result(i,i)==1 %&& sum(result(:,i))==1
            correct_no = correct_no + 1;
        end
    end
    acu = correct_no / 62
    toc
end

end

function feat_vec = extract_feature_Chars74K(path, feat)

    % feature initialization
    ft_ert = []; ft_bin = [];
    ft_ert = imfeat('init', 'ertree' ,ft_ert);
    ft_bin = imfeat('init', 'binary' ,ft_bin);
    
    % (1) extract ER tree feature
    img = imread(path);
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

    ft_bin = imfeat('set_image', ER.data, ft_bin);
    ft_bin = imfeat('extract_feature_raw_boundingbox_all', '', ft_bin);
    I = ft_bin.image(ft_bin.feat_raw.y_min:ft_bin.feat_raw.y_max, ...
                     ft_bin.feat_raw.x_min:ft_bin.feat_raw.x_max);
    
    % (3) extract feature vector (by using initial computation scheme)
    im = []; 
    im = imfeat('init', 'binary' ,im);
    im = imfeat('set_image', I, im);
    im = imfeat('resize', feat.RESIZE, im);
    %s = ['..\..\..\..\..\LargeFiles\a\' util_changeFn(path, 'get_filename_and_extension', '')];
    %imwrite(im.image, s, 'jpeg')
    im = imfeat('extract_feature_raw_shapecontext_all', feat.SHAPECONTEXT, im);
    
    if 1
        projimg = (im.feat_raw * feat.RANDPROJMATRIX) > 0;
        feat_vec = hist(bin2dec(num2str(projimg))',0:(2^feat.RANDPROJBITS-1));
    else
        feat_vec = im.feat_raw';
        feat_vec = feat_vec(:);
    end

end