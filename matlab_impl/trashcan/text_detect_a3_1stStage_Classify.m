function text_detect_a3_1stStage_Classify()

close all;
addpath_for_me;
% 1st stage classifier parameters
PROB_MIN = 0.2;
DELTA_MIN = 0.1;
rsize = [0, 0];

% dataset initialization
ds_eng = [];
ds_eng = imdataset('init', 'ICDAR2003RobustReading', ds_eng);
ds_eng = imdataset('get_test_dataset_defxml_word', '', ds_eng);
    
% feature initialization
ft_ert = []; ft_bin = [];
ft_ert = imfeat('init', 'ertree' ,ft_ert);
ft_bin = imfeat('init', 'binary' ,ft_bin);

% extract ER tree feature 
I_path = util_changeFn(ds_eng.path, 'cd ', 'ryoungt_05.08.2002');
I_path = [I_path 'PICT0014.JPG'];
I = imread(I_path);
ft_ert = imfeat('set_image', I, ft_ert);
ft_ert = imfeat('convert', '', ft_ert);
ft_ert = imfeat('resize', rsize, ft_ert);
ft_ert = imfeat('extract_feature_raw_get_all_preproc', 1, ft_ert);

if 0
	load('r_crt.mat');
else
    % extract features for each ER in the tree from non-empty node
    r = ft_ert.feat_raw;
    [p, n] = get_initial_seed_algo(ft_ert);
    ER_idx = [p, n];
    % (0) get data and dif of ER
    ft_ert = imfeat('extract_feature_raw_get_single_data_and_dif', ER_idx, ft_ert);
    r = ft_ert.feat_raw;
    ER = r.tree{ER_idx(1), ER_idx(2)};
    
    % (1) extract initial raw features
    ft_bin = imfeat('set_image', ER.data, ft_bin);
    ft1 = imfeat('extract_feature_raw_boundingbox_all', '', ft_bin);
    ft2 = imfeat('extract_feature_raw_size_all', '', ft_bin);
    ft3 = imfeat('extract_feature_raw_perimeter_all', '', ft_bin);
    ft4 = imfeat('extract_feature_raw_eulerno_all', '', ft_bin);
    ft5 = imfeat('extract_feature_raw_hzcrossing_all', '', ft_bin);

    % (2) compute desired features
    % aspect ratio
    ft_ar = (ft1.feat_raw.x_max - ft1.feat_raw.x_min + 1) / ...
            (ft1.feat_raw.y_max - ft1.feat_raw.y_min + 1);  
    % compactness
    ft_cp = sqrt(ft2.feat_raw) / ft3.feat_raw;
    % number of holes
    ft_hl = 1 - ft4.feat_raw;
    % median of horizontal crossing
    h = size(ER.data,1);
    median_idx = round(h * [1/6 3/6 5/6]);
    ft_hz = median(ft5.feat_raw(median_idx));

    % (3) collect predict result
    % load trained AdaBoostM1
    load('ada.mat'); 
    [r_label(p), score] = predict(ada, [ft_ar, ft_cp, ft_hl, ft_hz]);
    r_score(p) = max(score);

    % (4) compute ER sequences with including relation incrementally
    while true
        p
        % (0) pre-checking
        % if root node is reach, end while loop
        if ER.par(1)==0 && ER.par(2)==0
            r.tree{ER_idx(1),ER_idx(2)}.isdone = 1;
            break;
        end
        % no need to process if it is processed
        if ER.isdone
            % switch to next ER
            r.tree{ER_idx(1),ER_idx(2)}.isdone = 1;
            ER_idx = ER.par;
            ER = r.tree{ER_idx(1), ER_idx(2)};
            continue;
        end
        
        % (1) get data and dif of ER
        ft_ert = imfeat('extract_feature_raw_get_single_data_and_dif', ER_idx, ft_ert);
        r = ft_ert.feat_raw;
        ER = r.tree{ER_idx(1), ER_idx(2)};
                        
        % (1) preparation for raw feature incremental computation
        f_cum_bb = ft1.feat_raw; % 1
        f_cum_sz = ft2.feat_raw; % 1
        f_cum_pr = ft3.feat_raw; % 1
        f_cum_eu = ft4.feat_raw; % 1
        f_cum_hz = ft5.feat_raw; % h of ER
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
        median_idx = round(h * [1/6 3/6 5/6]);
        ft_hz = median(ft5.feat_raw(median_idx));

        % (4) collect features
        p = p + 1;
        [r_label(p), score] = predict(ada, [ft_ar, ft_cp, ft_hl, ft_hz]);
        r_score(p) = max(score);

        % (6) delete data and dif of ER (release memory)
        ft_ert = imfeat('extract_feature_raw_del_single_data_and_dif', ER_idx, ft_ert);
        r = ft_ert.feat_raw;
        
        % (5) switch to next ER
        r.tree{ER_idx(1),ER_idx(2)}.isdone = 1;
        ER_idx = ER.par;
        ER = r.tree{ER_idx(1), ER_idx(2)};
    end % end while true

    % Calibrated AdaBoost as posterior probability
    r_crt = 1./(1+exp(-2*r_score));
    
    save('r_crt.mat', 'r_score', 'r_crt', 'r_label');
end

% plot posterior probability before/after calibration
figure(1);
subplot(3,1,1); plot(r_score);
subplot(3,1,2); plot(r_crt);
subplot(3,1,3); plot(r_label);

% find index of ER cadidates to be char region
idx = [];
for i=2:length(r_crt)
	if r_crt(i)>=PROB_MIN && (r_crt(i)-r_crt(i-1))>DELTA_MIN
        idx = [idx i];
    end
end

% plot each candidate ERs
if 1
    figure(2);
    for i=1:length(idx)
        subplot(1,length(idx),i);

        if i==1
    %         ER_idx = [idx(i), 1];
            [p, n] = get_initial_seed_algo(ft_ert);
            ER_idx = [p, n];
        else
            t = idx(i-1);
            while t < idx(i) 
                ER = ft_ert.feat_raw.tree{ER_idx(1), ER_idx(2)};
                ER_idx = ER.par;
                t = t + 1;
            end
        end

        ft_ert = imfeat('extract_feature_raw_get_single_data_and_dif', ER_idx, ft_ert);
        ER = ft_ert.feat_raw.tree{ER_idx(1), ER_idx(2)};
        imshow(ER.data);
        title(['idx: ' num2str(ER_idx(1)) ',' num2str(ER_idx(2))]);
    end

    figure(3);
    imshow(I);
    hp = impixelinfo;
    set(hp,'Position',[5 1 300 20]);
else

    figure(2);
    % [p, n] = get_initial_seed_algo(ft_ert);
    ER_idx = [45, 4];
    Num = 20;
    t = 1;
    while t <= Num
        subplot(4,Num/4,t);
        ER = ft_ert.feat_raw.tree{ER_idx(1), ER_idx(2)};
        ER_idx = ER.par;
        ft_ert = imfeat('extract_feature_raw_get_single_data_and_dif', ER_idx, ft_ert);
        ER = ft_ert.feat_raw.tree{ER_idx(1), ER_idx(2)};
        imshow(ER.data);
        title(['idx: ' num2str(ER_idx(1)) ',' num2str(ER_idx(2))]);
        t = t + 1;
    end

end

end

function [t,n] = get_initial_seed_algo(ft_ert)

p = [111 444];
p_idx = uint32(p(2)*1280+p(1));
found = 0;
for t=1:256
    for n=1:ft_ert.feat_raw.size(t)
    	fst = ft_ert.feat_raw.tree{t,n}.raw(3);
        num = ft_ert.feat_raw.tree{t,n}.raw(2);
        vec = ft_ert.feat_raw.pxls(fst:fst+num-1)+1; % correct start index as Matlab sense
        if sum(p_idx==vec)==1
            found = 1;
            break;
        end
    end
    if found==1
        break; 
    end
end

end

