function textdetect_a1_train_svm_Chars74K_all_vs_nonchars(path, name, feat, stage_vec)

addpath_for_me;
close all;

test_idx = 9;
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

%%
% Stage 1:  collect feature vectors - 74K (chars)
stage1 = bin2dec(stage_vec(1,:));
if stage1>0
    tic   
    % dataset initialization
    ds = [];
    ds = imdataset('init', 'Chars74K', ds);
    ds = imdataset('get_eng_font_dataset', '', ds);
    
    p = 0;
    cur_fld = 1;
    save_file = 0;
    for i=1:ds.no

        % for each training image
        fn = util_changeFn(ds.fn_list{i}, 'get_filename_and_extension', '');
        if sum(str2double(fn(8:12))==desired_idx)==0 || ... %ex:img001-00001.png
           0%exist([path.FEATVEC_MAT name.FEATVEC_MAT sprintf('%03d',cur_fld) '.mat'], 'file')
            continue;
        elseif str2double(fn(8:12))==desired_idx(end)
            save_file = 1;
        end

        % extract feature
        p = p + 1;
        [ft_vector(p, :) no] = extract_feature_Chars74K(ds, i, feat, path);

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

%%
% Stage 2:  collect feature vectors - MSRATD500 (nonchars)
stage2 = bin2dec(stage_vec(2,:));
if stage2>0
    tic
   
    % extract training non char patches and save as .png files
    if bitand(stage2,bin2dec('001'))>0
        ds = [];
        ds = imdataset('init', 'MSRATD500', ds);
        ds = imdataset('get_train_dataset_random_nonchar', 5000, ds);
        p = 0;
        for i=1:ds.no
            if ds.rect_region_no(i) == 0
                continue;
            end
            extract_training_nonchar_patches_MSRATD500(ds, i, path);
        end
    end
    
    % feature extraction from .png files
    if bitand(stage2,bin2dec('010'))>0
        ft_vector = [];
        fns = dir([path.TRAINIMG_NONCHAR '*.png']);
        for i=1:numel(fns)
            % extract feature vector
            I = imread([path.TRAINIMG_NONCHAR fns(i,1).name]);
            ft_vector = [ft_vector; extract_features(I, feat)];
            if mod(i,50)==0
                i 
            end
        end
    end
    
    % save feature vector as .mat file
    if bitand(stage2,bin2dec('100'))>0
        mat_path = [path.FEATVEC_MAT name.FEATVEC_MAT '_nonc.mat'];
        save(mat_path, 'ft_vector');
        fprintf('Save %s \n', mat_path);
    end
    
    toc
end

%%
% Stage 3: (1) Train one versus all(w/o non) classifier for each chars
stage3 = bin2dec(stage_vec(3,:));
if bitand(stage3,bin2dec('001'))>0
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

% Stage 3: (2) Train one versus all(w/ non) classifier for each chars
stage3 = bin2dec(stage_vec(3,:));
if bitand(stage3,bin2dec('010'))>0
    tic

    for i=1:62
        mat_path = [path.FEATVEC_MAT name.FEATVEC_MAT sprintf('%03d',i) '.mat'];
        load(mat_path);
        fv_char{i} = ft_vector;
    end
    mat_path = [path.FEATVEC_MAT name.FEATVEC_MAT '_nonc.mat'];
    load(mat_path);
    fv_nonc = ft_vector;
    
    for i=1:62
        i
        fv = []; lb = [];
        no_used_samples = 33;
        for j=1:62
            fv_j = fv_char{j};
            if j==i
                fv = [fv; fv_j];
                lb = [lb; true(size(fv_j,1),1)];
                n_pos = size(fv_j,1);
            else
                fv = [fv; fv_j(1:no_used_samples,:)];
                lb = [lb; false(no_used_samples,1)];
            end
        end
        fv = [fv; fv_nonc];
        lb = [lb; false(size(fv_nonc,1),1)];
        n_neg_char = size(fv,1) - n_pos;
        n_neg_nonc = size(fv_nonc,1);
        fprintf('Training svm classifier %d...\n', i);
        fprintf('pos samples n=%d\n', n_pos);
        fprintf('neg samples n=%d+%d\n', n_neg_char, n_neg_nonc);
        fprintf('feature dimension d=%d\n', size(fv,2));
        svm{i} = svmtrain(fv, lb, 'kernel_function', 'rbf');
    end
    save([path.CLASSIFIER_MAT name.CLASSIFIER_MAT '.mat'], 'svm');
    toc
end

% Stage 3: (3) Train char versus nonchar classifier
if bitand(stage3,bin2dec('100'))>0
    tic
    fv = []; lb = [];
    no_used_samples = 33;
    for i=1:62
        mat_path = [path.FEATVEC_MAT name.FEATVEC_MAT sprintf('%03d',i) '.mat'];
        load(mat_path);
        fv = [fv; ft_vector(1:no_used_samples,:)];% take 1st k samples
    end
    n_char = size(fv,1);
    
    mat_path = [path.FEATVEC_MAT name.FEATVEC_MAT '_nonc.mat'];
    load(mat_path);
    fv = [fv; ft_vector];
    n_nonc = size(ft_vector,1);
    
    lb = true(size(fv,1),1);
    lb(end-n_nonc+1:end) = false;
    fprintf('Training svm classifier...\n');
    fprintf('pos samples n=%d\n', n_char);
    fprintf('neg samples n=%d\n', n_nonc);
    fprintf('feature dimension d=%d\n', size(fv,2));
    svm = svmtrain(fv, lb, 'kernel_function', 'rbf');

    save([path.CLASSIFIER_MAT name.CLASSIFIER_MAT '.mat'], 'svm');
    toc
end

%%
% Stage 4: (1) Test if it works
% result = false(62,62);
stage4 = bin2dec(stage_vec(4,:));
if bitand(stage4,bin2dec('001'))>0
    tic
    load([path.CLASSIFIER_MAT name.CLASSIFIER_MAT '.mat']);

    % dataset initialization
    ds = [];
    ds = imdataset('init', 'Chars74K', ds);
    ds = imdataset('get_eng_font_dataset', '', ds);
    
    % extract 62*1=62 HOG feature vectors
    p = 0;
    ft_vector = [];
    for i=1:ds.no
        fn = util_changeFn(ds.fn_list{i}, 'get_filename_and_extension', '');
        if sum(str2double(fn(8:12))==test_idx)==0
            continue;
        end
        % extract feature vectors
        p = p + 1;
        ft_vector(p, :) = extract_feature_Chars74K(ds, i, feat, path);
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

%%
% Stage 4: (2)Test if it works
% result = false(62,62);
if bitand(stage4,bin2dec('010'))>0
    tic
    load([path.CLASSIFIER_MAT name.CLASSIFIER_MAT '.mat']);

    % dataset initialization
%     ds = [];
%     ds = imdataset('init', 'Chars74K', ds);
%     ds = imdataset('get_eng_font_dataset', '', ds);
    

    ft_vector = [];
    fns = dir([path.TEST_FROM_PRUNED_ADA1 'ER*.png']);
    for i=1:numel(fns)
        % extract feature vector
        ft_vector = extract_features(I, feat);
        score = 0;
        imshow(I);
        r = [];
        for k=1:62
            r = [r; svmclassify(svm{k}, ft_vector)];
            score = sum(r);
%             if r==1
%                 k
%             end
        end
        score
        score=score;
%         ft_vector = [ft_vector; extract_features(I, feat)];
%         if mod(i,50)==0
%             i 
%         end
    end

    % extract 62*1=62 HOG feature vectors
    p = 0;
    ft_vector = [];
    for i=1:ds.no
        fn = util_changeFn(ds.fn_list{i}, 'get_filename_and_extension', '');
        if sum(str2double(fn(8:12))==test_idx)==0
            continue;
        end
        % extract feature vectors
        p = p + 1;
        ft_vector(p, :) = extract_feature_Chars74K(ds, i, feat, path);
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

%%
function extract_training_nonchar_patches_MSRATD500(ds, idx, path)

    img1 = rgb2gray(imread(ds.fn_list{idx}));
    for n=1:ds.rect_region_no(idx)
        r = ds.rect{idx,n};
        img2 = img1(r.y:r.y+r.h-1,r.x:r.x+r.w-1);
        img3 = imadjust(img2,stretchlim(img2),[]);
        if sum(sum(img3<=127)) > sum(sum(img3>=128))
            img4 = img3>=128;
        else
            img4 = img3<=127;
        end
        [L, N] = bwlabel(img4, 4);
        s = 1;
        min_w_h = 20;
        found = 0;
        while s<20000
            x = min(ceil(rand(1)*r.w), r.w);
            y = min(ceil(rand(1)*r.h), r.h);
            I = (L==L(y,x));
            if sum(I(1,:))+sum(I(end,:))+sum(I(:,1))+sum(I(:,end))<4
                % crop to fit the boundary
                ft_bin = []; 
                ft_bin = imfeat('init', 'binary' ,ft_bin);
                ft_bin = imfeat('set_image', I, ft_bin);
                ft_bin = imfeat('extract_feature_raw_boundingbox_all', '', ft_bin);
                I = ft_bin.image(ft_bin.feat_raw.y_min:ft_bin.feat_raw.y_max, ...
                                 ft_bin.feat_raw.x_min:ft_bin.feat_raw.x_max);
                if size(I,1)>=min_w_h && size(I,2)>=min_w_h
                    % found! use I, and leave while loop
                    found = 1;
                    break;
                end
            end
            s = s + 1;
        end
        if found==1
            s = [path.TRAINIMG_NONCHAR util_changeFn(ds.fn_list{idx}, 'get_filename_and_extension', '')];
            s = util_changeFn(s, 'insert_after_filename', ['_n' num2str(n)]);
            s = util_changeFn(s, 'replace_extension', 'png');
            imwrite(I, s, 'png');
            fprintf('[%d] region %d: found (%dx%d)\n',idx,n,size(I,1),size(I,2));
        else
            fprintf('[%d] region %d: not found!\n',idx,n);
        end
    end
    
end

%%
function [feat_vec, no_feat_vec] = extract_feature_Chars74K(ds, idx, feat, path)

    % (1) extract ER tree feature
    img = imread(ds.fn_list{idx});
    ft_ert = []; 
    ft_ert = imfeat('init', 'ertree' ,ft_ert);
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

    % extract feature vector 
    feat_vec = extract_features(ER.data, feat);
    no_feat_vec = 1;

end

%%
function [feat_vec] = extract_features(I, feat)

    I = util_cropBinImg(I);
    I = util_resizeBinImg(I, 'fit_with_keeping_ar_and_zero_padding', [48,64]);

    %feat_vec = extract_feature_shapecontext(I, feat);
    feat_vec = extract_feature_traditional_4_plus_3(I, feat);
end

function [feat_vec] = extract_feature_traditional_4_plus_3(I, feat)
    % (1) extract initial raw features
    ft_bin = [];
    ft_bin = imfeat('init', 'binary' ,ft_bin);
    ft_bin = imfeat('set_image', I, ft_bin);
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

    feat_vec = [ft_ar, ft_cp, ft_hl, ft_hz, ft_ho, ft_ch, ft_rf];
    
end

function [feat_vec] = extract_feature_shapecontext(I, feat)

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
