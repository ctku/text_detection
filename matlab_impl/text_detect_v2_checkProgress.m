
type = 0; % 0:non-char 1:char
ch_folder_name = '0128_test1_char_mat';
nc_folder_name = '0218_test1_nonc_mat';
addpath_for_me;

ds_eng = [];
ds_eng = imdataset('init', 'ICDAR2003RobustReading', ds_eng);
if type == 1
    ds_eng = imdataset('get_train_dataset_defxml_char', '', ds_eng);
    path = [ds_eng.path '_output_files/' ch_folder_name '/'];
    nn = 'ch_0x0_r0';
else
    ds_eng = imdataset('get_train_dataset_path', '', ds_eng);
    path = [ds_eng.path '_output_files/'];
    path = [path '[20130218]_random_2000_nchar.mat'];
    load(path);
    path = [ds_eng.path '_output_files/' nc_folder_name '/'];
    nn = 'nc_100x100_r0';
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