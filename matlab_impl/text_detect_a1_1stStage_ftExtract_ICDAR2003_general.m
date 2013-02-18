function text_detect_a1_1stStage_ftExtract_ICDAR2003_general(type, reverse, folder_name, random_cmd, order)

%  Input - type (int): 0: extract features of "non-char" patches
%                      1: extract features of "char" patches
%                      2: extract features of "word" patches (not used)
%        - reverse (int): 0: keep image gray level unchanged
%                            (assume text is brighter than background)
%                         1: reverse image gray level as "255-I"
%                            (assume text is darker than background)
%        - folder_name (string): output folder name, will be created at
%                                $databasepath\_output_files\folder_name
%        - random_cmd (1x2 cells): used for random non-char method
%                       {1} (int): number of patches need to be randomed
%                       {2} (string): sequence id
%        - order (string): used when several computers runing on the same dataset
%                FxxxP: means running forward from xxx percent of images
%                BxxxP: means running backward from xxx percent of images
%                FxxxN: means running forward from xxx-th image
%                BxxxN: means running backward from xxx-th image
%                          
if (type~=0 && type~=1) || ...
   (reverse~=0 && reverse~=1)
    error('Error input');
end

addpath_for_me;
open_profile = 0;

% dataset initialization
ds_eng = [];
ds_eng = imdataset('init', 'ICDAR2003RobustReading', ds_eng);
switch type
    case 0
        ds_eng = imdataset('get_train_dataset_path', '', ds_eng);
        path = util_changeFn(ds_eng.path, 'cd _mkdir', '_output_files');
        random_no = random_cmd{1};
        random_id = random_cmd{2};
        path = [path '[' random_id ']_random_' num2str(random_no) '_nchar.mat'];
        if exist(path, 'file')
            load(path);
        else
            ds_eng = imdataset('get_train_dataset_random_nonchar', random_no, ds_eng);
            save(path, 'ds_eng');
        end
        rsize = [100 100];
        nn = ['nc_100x100_r' num2str(reverse)];
    case 1
        ds_eng = imdataset('get_train_dataset_defxml_char', '', ds_eng);
        rsize = [0 0];
        nn = ['ch_0x0_r' num2str(reverse)];
    case 2
        ds_eng = imdataset('get_train_dataset_defxml_word', '', ds_eng);
        rsize = [0 0];
        nn = ['ch_0x0_r' num2str(reverse)];
end

% feature initialization
ft_ert = []; ft_bin = [];
ft_ert = imfeat('init', 'ertree' ,ft_ert);
ft_bin = imfeat('init', 'binary' ,ft_bin);

% training part
if order(1)=='F' && order(5)=='P'
	train_seq = max(round(ds_eng.no*str2double(order(2:4))/100),1):1:ds_eng.no;
end
if order(1)=='B' && order(5)=='P'
    train_seq = min(round(ds_eng.no*str2double(order(2:4))/100),ds_eng.no):-1:1;
end
if order(1)=='F' && order(5)=='N'
    train_seq = str2double(order(2:4)):1:ds_eng.no;
end
if order(1)=='B' && order(5)=='N'
    train_seq = str2double(order(2:4)):-1:1;
end
for i=train_seq
    path = util_changeFn(ds_eng.fn_list{i}, 'cd .._with_filename', '');
    path = util_changeFn(path, 'cd _mkdir_with_filename', '_output_files');
    path = util_changeFn(path, 'cd _mkdir_with_filename', folder_name);
    
    % for each test image
    img = imread(ds_eng.fn_list{i});
    
    for ii=1:ds_eng.rect_region_no(i)
        % for each rect region
        
        % if it's trained, jump to next
        mat_ft = util_changeFn(path, 'replace_extension', [nn '.' num2str(ii) '.mat']);
        if exist(mat_ft, 'file')
            continue;
        end
        
        % (0) start extraction
        p = 0;
        ft_vector = [];
        fprintf('Training "%s" region (%d/%d) from \n %s (%d/%d) ...\n', ...
                nn, ii, ds_eng.rect_region_no(i), ds_eng.fn_list{i}, i, ds_eng.no);
        
        % (1) extract image patch
        x1 = ds_eng.rect{i,ii}.x;
        x2 = ds_eng.rect{i,ii}.x + ds_eng.rect{i,ii}.w - 1;
        y1 = ds_eng.rect{i,ii}.y;
        y2 = ds_eng.rect{i,ii}.y + ds_eng.rect{i,ii}.h - 1;
        I = img(y1:y2,x1:x2,:);
        
        % (2) resize to fit in ex:(200,60) keeping ar
        ft_ert = imfeat('set_image', I, ft_ert);
        ft_ert = imfeat('convert', '', ft_ert);
        ft_ert = imfeat('resize', rsize, ft_ert);
        
        % (3) extract ER tree feature
        mat_er = util_changeFn(mat_ft, 'replace_extension', ['ert_r' num2str(reverse) '.mat']);
        mat_er = util_changeFn(mat_er, 'cd .._with_filename', '');
        mat_er = util_changeFn(mat_er, 'cd _with_filename', 'ert_mat_files');
        ft_ert = imfeat('extract_feature_raw_get_all_preproc', reverse, ft_ert);
        
        % (4) extract features for each ER in the tree
        r_tic = tic;
        r = ft_ert.feat_raw;
        for t=1:size(r.size,1)
            if (open_profile==1); profile on; end
            t
            % for each threshold index t
            for tt=1:r.size(t)
                
                % for each ER region index tt
                ER_idx = [t,tt];
                ER = r.tree{ER_idx(1), ER_idx(2)};
                if ~ER.isdone
                    
                    % (1) get data and dif of ER
                    ft_ert = imfeat('extract_feature_raw_get_one_cropped_data_and_dif', ER_idx, ft_ert);
                    r = ft_ert.feat_raw;
                    ER = r.tree{ER_idx(1), ER_idx(2)};
                    
                    % (2) extract feature vector (by using initial computation scheme)
                    [ft_outvec, ft_struct] = text_detect_sub_ftExtract_init(ER, ft_bin);
                    p = p + 1;
                    ft_vector(p, :) = ft_outvec;
                    
                    % (4) compute ER sequences with including relation incrementally
                    while true
                        % (1) pre-checking
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

                        % (2) get data and dif of ER
                        ft_ert = imfeat('extract_feature_raw_get_one_cropped_data_and_dif', ER_idx, ft_ert);
                        r = ft_ert.feat_raw;
                        ER = r.tree{ER_idx(1), ER_idx(2)};
                        
                        % (3) extract feature vector (by using incrmental computation scheme)
                        [ft_outvec, ft_struct] = text_detect_sub_ftExtract_incrementally(ER, ft_struct, ft_bin);
                        p = p + 1;
                        ft_vector(p,:) = ft_outvec;
                        
                        % (4) delete data and dif of ER (release memory)
                        %ft_ert = imfeat('extract_feature_raw_del_data_and_dif', ER_idx, ft_ert);
                        r = ft_ert.feat_raw;
                        
                        % (5) switch to next ER
                        r.tree{ER_idx(1),ER_idx(2)}.isdone = 1;
                        ER_idx = ER.par;
                        ER = r.tree{ER_idx(1), ER_idx(2)};
                    end % end while true
                end % end ~ER.isdone
            end % end for tt
            if (open_profile==1); profile viewer; end
        end % end for t
    toc(r_tic);
    save(mat_ft, 'ft_vector');
    fprintf('%s saved\n', mat_ft);
    end %end for each rect region
end % end for each image

end