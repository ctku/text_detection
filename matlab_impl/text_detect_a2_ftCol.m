function text_detect_a2_1stStage_ftCol(ch_file_name, nc_folder_name, nc_size, out_fn_tag)

addpath_for_me;
ds_char = [];
ds_nonc = [];

% collect trained 'char' features
ds_char = imdataset('init', 'Chars74K', ds_char);
ds_char = imdataset('get_eng_font_dataset', '', ds_char);
path_saved_mat = [ds_char.path '_output_files/' ch_file_name '.mat'];
load(path_saved_mat, 'ft_vector');
fv_char = ft_vector;
no_char = size(fv_char, 1);

% collect trained 'non-char' features
ds_nonc = imdataset('init', 'ICDAR2003RobustReading', ds_nonc);
ds_nonc = imdataset('get_train_dataset_defxml_char', '', ds_nonc);
fv_nonc = zeros(10000*2000,7);
no_nonc = 0;
for i=1:4:ds_nonc.no
    i
    fn = util_changeFn(ds_nonc.fn_list{i}, 'cd .._with_filename', '');
    fn = util_changeFn(fn, 'cd _with_filename', '_output_files');
    fn = util_changeFn(fn, 'cd _with_filename', nc_folder_name);
    for ii=1:1
        ii
        path_saved_mat = util_changeFn(fn, 'replace_extension', ...
                         ['nc_' num2str(nc_size(1)) 'x' num2str(nc_size(2)) '_r0.' num2str(ii) '.mat']);
        if exist(path_saved_mat, 'file')
            % collect it
            ft_vector = [];
            load(path_saved_mat);
            fv_nonc(no_nonc+1:no_nonc+size(ft_vector,1),:) = ft_vector(:,1:7);
            no_nonc = no_nonc + size(ft_vector,1);
        else
            % leave "for ii=1:200"
            break;
        end
    end
end

fprintf('%d char patches (%d feature vectors) are used.\n', no_char, no_char);
fprintf('%d nonc patches (%d feature vectors) are used.\n', no_nonc, no_nonc);
fv = [fv_char; fv_nonc(1:no_nonc,:)];
lb = [ones(size(fv_char,1),1); zeros(no_nonc,1)];

% train 1st stage classifier (by AdaBoostM1)
t_ada = tic;
ada = fitensemble(fv(:,1:4), lb, 'AdaBoostM1', 100, 'tree');
toc(t_ada);
save(['../../_output_files/Classifier/1stStage_ada_' out_fn_tag '.mat'], 'ada');

% train 1st stage classifier (by SVM)
t_svm = tic;
svm = svmtrain(fv, lb, 'kernel_function', 'rbf');
toc(t_svm);
save(['../../_output_files/Classifier/2ndStage_svm_' out_fn_tag '.mat'], 'svm');


end