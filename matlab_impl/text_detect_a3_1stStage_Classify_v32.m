% version 3.2
% feature : indexing post prob
function text_detect_a3_1stStage_Classify_v32()

close all;
addpath_for_me;
tic
% Input parameter
fd = 'ryoungt_13.08.2002'; fn = 'vPICT0025'; resize = [300 300];
fd = 'apanar_06.08.2002'; fn = 'IMG_1291'; resize = [600 600];

% 1st stage classifier parameters
rule_param.MIN_W_REG2IMG_RATIO = 0.0019;
rule_param.MAX_W_REG2IMG_RATIO = 0.4562;
rule_param.MIN_H_REG2IMG_RATIO = 0.0100;
rule_param.MAX_H_REG2IMG_RATIO = 0.7989;

% dataset initialization
ds_eng = [];
ds_eng = imdataset('init', 'ICDAR2003RobustReading', ds_eng);
ds_eng = imdataset('get_test_dataset_path', '', ds_eng);
ds_eng = imdataset('get_train_dataset_path', '', ds_eng);

% feature initialization
ft_ert = []; ft_bin = [];
ft_ert = imfeat('init', 'ertree', ft_ert);
ft_bin = imfeat('init', 'binary', ft_bin);

% extract ER tree feature 
I_path = [ds_eng.path fd '/' fn '.JPG'];
I = imread(I_path);
ft_ert = imfeat('set_image', I, ft_ert);
ft_ert = imfeat('convert', '', ft_ert);
ft_ert = imfeat('resize', resize, ft_ert);

% load trained AdaBoostM1
load('ada.mat'); 
ft_ert.ft_pool = [0 0 0 0 0];
path = util_changeFn('','cd ..','');
path = util_changeFn(path,'cd ..','');
path = util_changeFn(path,'cd _mkdir','_output_files');
for reverse = 0:1
    
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
            [postp, ft_struct, ft_ert] = get_post_prob_by_raw_ER([t,r], 0, rule_param, ft_struct, ft_ert, ft_bin, ada);
            pmap = write_map(ER, postp, pmap);

            idx = ER.par; 
            ER = ft_ert.feat_raw.tree{idx(1),idx(2)};
            while ~isequal(ER.par,[0,0])
                idx = ER.par;
                ER = ft_ert.feat_raw.tree{idx(1),idx(2)};
                if read_map(ER, pmap) ~= -1
                    continue;
                else
                    [postp, ft_struct, ft_ert] = get_post_prob_by_raw_ER(idx, 1, rule_param, ft_struct, ft_ert, ft_bin, ada);
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

function [postp, ft_struct, ft_ert] = get_post_prob_by_raw_ER(idx, use_inc, rule_param, ft_struct, ft_ert, ft_bin, ada)
%     profile on;
    idx
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
    if (bb.x_max-bb.x_min+1)/ft_ert.w >= rule_param.MIN_W_REG2IMG_RATIO && ...
       (bb.x_max-bb.x_min+1)/ft_ert.w <= rule_param.MAX_W_REG2IMG_RATIO && ...
       (bb.y_max-bb.y_min+1)/ft_ert.h >= rule_param.MIN_H_REG2IMG_RATIO && ...
       (bb.y_max-bb.y_min+1)/ft_ert.h <= rule_param.MAX_H_REG2IMG_RATIO
        % index the ft_outvec to speed up
        pool_index = ismember(ft_ert.ft_pool(:,1:4), ft_outvec, 'rows');
        if all(pool_index == 0)
            % calibrated AdaBoost as posterior probability
            [r_label, score] = predict(ada, ft_outvec);
            postp = 1./(1+exp(-2*max(score)));  
            % save it for future use
        	ft_ert.ft_pool = [ft_ert.ft_pool; [ft_outvec postp]];
        else
            pool_index = find(pool_index == true);
            postp = ft_ert.ft_pool(pool_index, 5);
            ft_ert.ft_pool(1,5) = ft_ert.ft_pool(1,5) + 1;
            ft_ert.ft_pool(1,5)
        end
    else
        % size is too small, ignore it.
        postp = 10^-5;
    end
%     profile viewer;
end