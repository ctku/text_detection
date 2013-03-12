function text_detect_a4_classifyAdaPostp_optSVM_algo7(path, name, feat, rules, useSVM)

close all;
addpath_for_me;
tic

a = clock;
time_label = sprintf('[%02d%02d_%02d%02d]', a(2), a(3), a(4), a(5));
idx_label = sprintf('[%03d]', name.TESTING_IMG_IDX);

in_mat_path = [path.ADA_POST_MAT name.TESTING_DATASET '/' name.TESTING_SIZE '/'];
in_mat_file = [idx_label ' ' name.TESTING_IMG '_' name.TESTING_SIZE];

if useSVM == 1
    load([path.CLASSIFIER_MAT name.CLASSIFIER_MAT], 'svm');
    out_img_path = [path.SVM_PRUNE_OUT_FOLDER name.TESTING_DATASET '/' name.TESTING_SIZE '/'];
else
    out_img_path = [path.ADA_PRUNE_OUT_FOLDER name.TESTING_DATASET '/' name.TESTING_SIZE '/'];
end
chk_img_path = [out_img_path in_mat_file '_ER_candidate_img_' num2str(useSVM)];

if isempty(dir([chk_img_path '*']))
    out_img_path = util_changeFn(out_img_path, 'cd _mkdir', [in_mat_file '_ER_candidate_img_' num2str(useSVM) '_' time_label]);

    for reverse = 0:1

        load([in_mat_path in_mat_file '_reverse_' num2str(reverse) '.mat']); 

        % find index of ER cadidates to be char region
        % fill up -1 with previous postp
        for row = 1:size(pmap,1)
            postp = pmap(row,:);
            in_valley = 0;
            for col=2:length(postp)-1
                if postp(col)==-1
                    if postp(col-1)>=0 || in_valley
                        in_valley = 1;
                        postp(col) = postp(col-1);
                    end
                else
                    in_valley = 0;
                end
            end
        end
        % prune by prob relation
        for row = 1:size(pmap,1)
            postp = pmap(row,:);
            for col=2:length(postp)-1
                if postp(col) >= rules.PROB_MIN && ...
                   (postp(col)-postp(col-1)) > rules.DELTA_MIN && ...
                   (postp(col)-postp(col+1)) > rules.DELTA_MIN
                    [t,r] = row_col_2_cur_t_r(ft_ert, row, col);
                    % label is_done as 2 to indicate ER candidate
                    ft_ert.feat_raw.tree{t,r}.isdone = 2; 
                end
            end
        end
        % transform pmap to candidate map
        for t=1:255
            for r = 1:ft_ert.feat_raw.size(t)
                if ft_ert.feat_raw.tree{t,r}.isdone == 2
                    fst = ft_ert.feat_raw.tree{t,r}.raw(3);
                    num = ft_ert.feat_raw.tree{t,r}.raw(2);
                    vec = fst:fst+num-1;
                    pmap(vec,t) = ft_ert.feat_raw.tree{t,r}.raw(3);
                end
            end
        end
        % prune ERs belongs to the same seq by keeping last one
        for row = 1:size(pmap,1)
            postp = pmap(row,:);
            fst_idx = find(postp>=1, 1, 'first');
            if ~isempty(fst_idx)
                fst = postp(fst_idx);
                idx = find(postp==fst);
                if length(idx)==1
                    % assign it as real candidate
                    [t,r] = row_col_2_cur_t_r(ft_ert, row, idx);
                    ft_ert.feat_raw.tree{t,r}.isdone = 3;
                    continue; 
                end
                area_var = ones(1,length(postp));
                for i=1:length(idx)
                    if i==1
                        % when over two candidates exists, the 1st one tends to 
                        % have bad shape compared to later one
                        area_var(idx(i))=1;
                        continue;
                    end
                    if i==length(idx)
                        [cur_t,cur_r] = row_col_2_cur_t_r(ft_ert, row, idx(i));
                        [pre_t,pre_r] = row_col_2_cur_t_r(ft_ert, row, idx(i-1));
                        area_var(idx(i)) = (double(ft_ert.feat_raw.tree{cur_t,cur_r}.raw(2)) ...
                                           -double(ft_ert.feat_raw.tree{pre_t,pre_r}.raw(2))) ...
                                           /double(ft_ert.feat_raw.tree{cur_t,cur_r}.raw(2));
                        continue;
                    end
                    [cur_t,cur_r] = row_col_2_cur_t_r(ft_ert, row, idx(i));
                    [pre_t,pre_r] = row_col_2_cur_t_r(ft_ert, row, idx(i-1));
                    [nxt_t,nxt_r] = row_col_2_cur_t_r(ft_ert, row, idx(i+1));
                    area_var(idx(i)) = (double(ft_ert.feat_raw.tree{nxt_t,nxt_r}.raw(2)) ...
                                  -double(ft_ert.feat_raw.tree{pre_t,pre_r}.raw(2))) ...
                                  /double(ft_ert.feat_raw.tree{cur_t,cur_r}.raw(2));
                end
                [min_val, min_idx] = min(area_var);
                for i=idx
                    [t,r] = row_col_2_cur_t_r(ft_ert, row, i);
                    if i==min_idx || ...
                       ft_ert.feat_raw.tree{t,r}.isdone==3
                        % assign it as real candidate
                        ft_ert.feat_raw.tree{t,r}.isdone = 3;
                        continue;
                    else
                        % cancle its candidacy
                        ft_ert.feat_raw.tree{t,r}.isdone = 1;
                        fst = ft_ert.feat_raw.tree{t,r}.raw(3);
                        num = ft_ert.feat_raw.tree{t,r}.raw(2);
                        vec = fst:fst+num-1;
                        pmap(vec,t) = 0;
                    end
                end
            end
        end
        % save ER candidates as images
        c1 = 0; c2 = 0;
        for t=1:255
            for r = 1:ft_ert.feat_raw.size(t)
                if ft_ert.feat_raw.tree{t,r}.isdone == 3
                    % get ER data
                    fst = ft_ert.feat_raw.tree{t,r}.raw(3);
                    num = ft_ert.feat_raw.tree{t,r}.raw(2);
                    vec = ft_ert.feat_raw.pxls(fst:fst+num-1)+1; % correct start index as Matlab sense
                    TR_data = false(1, ft_ert.w*ft_ert.h);
                    TR_data(vec) = 1;
                    data = reshape(TR_data, ft_ert.w, ft_ert.h)'; % row-wised reshape
                    c1 = c1 + 1;

                    % do 2nd stage classification
                    if useSVM
                        if t==232 && r==59
                           t = t; 
                        end
                        if 0
                            feat_vec = ft_ert.feat_raw.tree{t,r}.feat_vec;
                        else
                            % crop to fit the boundary
                            ft_bin = []; 
                            ft_bin = imfeat('init', 'binary' ,ft_bin);
                            ft_bin = imfeat('set_image', ft_ert.feat_raw.tree{t,r}.data, ft_bin);
                            ft_bin = imfeat('extract_feature_raw_boundingbox_all', '', ft_bin);
                            I = ft_bin.image(ft_bin.feat_raw.y_min:ft_bin.feat_raw.y_max, ...
                                             ft_bin.feat_raw.x_min:ft_bin.feat_raw.x_max);
                            feat_vec = extract_features(I, feat);
                        end
                        isChar = svmclassify(svm, feat_vec);
                        if ~isnan(isChar) && isChar
                            % save ER as image
                            s = [out_img_path 'ER_(' num2str(t) ',' num2str(r) ')_reverse_' num2str(reverse) '.png'];
                            imwrite(data, s, 'png')
                            c2 = c2 + 1;
                        end
                    else
                        % save ER as image
                        s = [out_img_path 'ER_(' num2str(t) ',' num2str(r) ')_fst_(' num2str(fst) ')_reverse_' num2str(reverse) '.png'];
                        imwrite(data, s, 'png')
                        c2 = c2 + 1;
                    end
                end
            end
        end

        % save original image (for reference)
        total_ER_no = sum(ft_ert.feat_raw.size);
        s = [out_img_path '__[3]no_of_ER_(all,c1,c2)=(' num2str(total_ER_no) ',' num2str(c1) ',' num2str(c2) ')_reverse_' num2str(reverse) '.png'];
        if reverse == 0
            original_img = ft_ert.image;
        else
            original_img = 255 - ft_ert.image;
        end
        imwrite(original_img, s, 'png')

        % save accum image (for reference)
        if c2>0
            fns = dir([out_img_path 'ER*_' num2str(reverse) '.png']);
            [H,W] = size(imread([out_img_path fns(1,1).name]));
            I_accum = false(H,W);
            for i=1:numel(fns)
                I = logical(imread([out_img_path fns(i,1).name])); 
                I_accum = I | I_accum;
            end
            s = [out_img_path '__[1]accum_' num2str(c2) 'ERs_reverse_' num2str(reverse) '.png'];
            imwrite(I_accum, s, 'png');
        end

        % save normal MSER (for reference)
        if 0
        im = [];
        im = imfeat('init', 'mser', im);
        im = imfeat('set_image', original_img, im);
        im = imfeat('convert', '', im);
        mser_param = '';
        im = imfeat('extract_feature_raw', mser_param, im);
        set(figure, 'Position', [100, 100, im.w, im.h]);
        imagesc(im.image);
        axis off; hold on;
        pause(1);
        plot(im.feat_raw, 'showEllipses',false, 'showPixelList',true);
        [X, map] = frame2im(getframe(gca));
        s = [out_img_path '__[2]mser_image_reverse_' num2str(reverse) '.png'];
        imwrite(X, s, 'jpeg')
        hold off;
        close(gcf);
        end

    end
    toc
end

end

function [t,r] = row_col_2_cur_t_r(ft_ert, row, col)
    t = col;
    while ft_ert.feat_raw.fmap(row,t)==0
        t = t + 1;
    end
    r = ft_ert.feat_raw.fmap(row,t);
end

function [feat_vec] = extract_features(I, feat)
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
