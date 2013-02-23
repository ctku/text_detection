% version 3.2
% feature : indexing post prob
function text_detect_a3_calAdaPostp(fd, fn, resize, classifier_fn_tag, rules)

close all;
addpath_for_me;
tic

% dataset initialization
ds_eng = [];
ds_eng = imdataset('init', 'ICDAR2003RobustReading', ds_eng);
ds_eng = imdataset('get_test_dataset_path', '', ds_eng);

% feature initialization
ft_ert = []; ft_bin = [];
ft_ert = imfeat('init', 'ertree', ft_ert);
ft_bin = imfeat('init', 'binary', ft_bin);

% extract ER tree feature 
I_path = [ds_eng.path fd fn];
I = imread(I_path);
ft_ert = imfeat('set_image', I, ft_ert);
ft_ert = imfeat('convert', '', ft_ert);
ft_ert = imfeat('resize', resize, ft_ert);

% load trained AdaBoostM1
load(['../../_output_files/Classifier/1stStage_ada_' classifier_fn_tag '.mat']); 
ft_ert.ft_pool = [0 0 0 0 0];
path = util_changeFn('','cd ..','');
path = util_changeFn(path,'cd ..','');
path = util_changeFn(path,'cd _mkdir','_output_files');
path = util_changeFn(path,'cd _mkdir','Parsed_mat');
for reverse = 0:1
    
    % if it's parsed, jump to next
    mat_ft = [path fn '_' num2str(resize(1)) 'x' num2str(resize(2)) '_reverse_' num2str(reverse) '.mat'];
    if exist(mat_ft, 'file')
        continue;
    end

    ft_ert = imfeat('extract_feature_raw_get_all_preproc', reverse, ft_ert);
    pmap = zeros(size(ft_ert.feat_raw.fmap))-1;
    for t = 1:255

        ft_struct = [];
        t
        for r = 1:ft_ert.feat_raw.size(t)
            ER = ft_ert.feat_raw.tree{t,r};
            if read_map(ER, pmap) ~= -1
                continue;
            end
            [postp, ft_struct, ft_ert] = get_post_prob_by_raw_ER([t,r], 0, rules, ft_struct, ft_ert, ft_bin, ada);
            pmap = write_map(ER, postp, pmap);

            idx = ER.par; 
            ER = ft_ert.feat_raw.tree{idx(1),idx(2)};
            while ~isequal(ER.par,[0,0])
                idx = ER.par;
                ER = ft_ert.feat_raw.tree{idx(1),idx(2)};
                if read_map(ER, pmap) ~= -1
                    continue;
                else
                    [postp, ft_struct, ft_ert] = get_post_prob_by_raw_ER(idx, 1, rules, ft_struct, ft_ert, ft_bin, ada);
                    pmap = write_map(ER, postp, pmap);
                end
            end
        end
    end
    save([path fn '_' num2str(resize(1)) 'x' num2str(resize(2)) '_reverse_' num2str(reverse) '.mat'],'pmap','ft_ert','-v7.3');
end
toc
end

function [val] = read_map(ER, map)

t = ER.raw(1);
fst = ER.raw(3);
val = map(fst,t);

end

function [map] = write_map(ER, val, map)

t = ER.raw(1);
fst = ER.raw(3);
num = ER.raw(2);
vec = fst:fst+num-1;
map(vec,t) = val;

end

function [postp, ft_struct, ft_ert] = get_post_prob_by_raw_ER(idx, use_inc, rules, ft_struct, ft_ert, ft_bin, ada)
%     profile on;
    idx
    if isequal(idx,[254,1])
    idx = idx;
    end
    % (1) get ER data
    ft_ert = imfeat('extract_feature_raw_get_one_cropped_data_and_dif', idx, ft_ert);
    ER = ft_ert.feat_raw.tree{idx(1), idx(2)};

    % (2) get posterior prob.
    if use_inc == 0
        % extract feature vector (by using initial computation scheme)
        [ft_outvec, ft_struct] = text_detect_sub_ftExtract_init(ER, ft_bin);
    else
        % extract feature vector (by using incrmental computation scheme)
        [ft_outvec, ft_struct] = text_detect_sub_ftExtract_incrementally(ER, ft_struct, ft_bin);
    end
    bb = ft_struct.ft_bb.feat_raw;
    if (bb.x_max-bb.x_min+1)/ft_ert.w >= rules.MIN_W_REG2IMG_RATIO && ...
       (bb.x_max-bb.x_min+1)/ft_ert.w <= rules.MAX_W_REG2IMG_RATIO && ...
       (bb.y_max-bb.y_min+1)/ft_ert.h >= rules.MIN_H_REG2IMG_RATIO && ...
       (bb.y_max-bb.y_min+1)/ft_ert.h <= rules.MAX_H_REG2IMG_RATIO && ...
       (bb.x_max-bb.x_min+1) >= rules.MIN_W_ABS && ...
       (bb.y_max-bb.y_min+1) >= rules.MIN_H_ABS && ...
       sum(sum(ER.data)) >= rules.MIN_SIZE

        % index the ft_outvec to speed up
        pool_index = ismember(ft_ert.ft_pool(:,1:4), ft_outvec(1:4), 'rows');
        if all(pool_index == 0)
            % calibrated AdaBoost as posterior probability
            [r_label, score] = predict(ada, ft_outvec(1:4));
            postp = 1./(1+exp(-2*max(score)));  
            % save it for future use
        	ft_ert.ft_pool = [ft_ert.ft_pool; [ft_outvec(1:4) postp]];
            ft_ert.feat_raw.tree{idx(1), idx(2)}.feat_vec = ft_outvec;
        else
            pool_index = find(pool_index == true);
            postp = ft_ert.ft_pool(pool_index, 5);
            ft_ert.ft_pool(1,5) = ft_ert.ft_pool(1,5) + 1;
            ft_ert.feat_raw.tree{idx(1), idx(2)}.feat_vec = -1*ones(1,7);
        end
    else
        % size is too small, ignore it.
        postp = 10^-5;
    end
%     profile viewer;
end