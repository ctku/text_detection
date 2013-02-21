function complete_map = text_detect_v2_checkProgress(type, folder_name, random_param)

% type = 0; % 0:non-char 1:char
% folder_name = '0128_test1_char_mat';
% folder_name = '0218_test1_nonc_mat';
addpath_for_me;

ds_eng = [];
ds_eng = imdataset('init', 'ICDAR2003RobustReading', ds_eng);
if type == 1
    ds_eng = imdataset('get_train_dataset_defxml_char', '', ds_eng);
    path = [ds_eng.path '_output_files/' folder_name '/'];
    nn = 'ch_0x0_r0';
else
    ran_no = random_param{1};
    ran_seed = random_param{2};
    ran_resize = random_param{3};
    ds_eng = imdataset('get_train_dataset_path', '', ds_eng);
    path = [ds_eng.path '_output_files/'];
    path = [path '[' ran_seed ']_random_' num2str(ran_no) '_nchar.mat'];
    load(path);
    path = [ds_eng.path '_output_files/' folder_name '/'];
    nn = ['nc_' num2str(ran_resize(1)) 'x' num2str(ran_resize(2)) '_r0'];
end

no_patch = 0;
max_region = 0;
for i=1:ds_eng.no
    if max_region < ds_eng.rect_region_no(i)
        max_region = ds_eng.rect_region_no(i);
    end
end

complete_map = 999999999*ones(ds_eng.no, max_region);
for i=1:ds_eng.no
    for r=1:ds_eng.rect_region_no(i)
        complete_map(i,r) = 0;
        fn = util_changeFn(ds_eng.fn_list{i}, 'get_filename_and_extension', '');
        fn = util_changeFn(fn, 'replace_extension', [nn '.' num2str(r) '.mat']);
        mat_ft = [path fn];
        if exist(mat_ft, 'file')
            complete_map(i,r) = 1;
        end
        no_patch = no_patch + 1;
    end
end

cpl = (sum(sum(complete_map==1))/no_patch)*100;
a = clock;
fprintf('\n[%02d/%02d %02d:%02d:%02d] complete %02.2f%%\n\n', ...
         a(2), a(3), a(4), a(5), round(a(6)), round(cpl*100)/100);
     
end