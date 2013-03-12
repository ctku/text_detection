function complete_map = text_detect_h1_checkProgress(ds, type, folder_name, random_param)

% type:
%   1: output "word" region as small images
%   2: output "char" region as small images
%   3: output "non-char" region as small images

% dataset:
%   1: ICDAR2003RobustReading
%   2: MSRATD500

addpath_for_me;

ds_eng = [];
switch ds
    case 'ICDAR2003RobustReading'
        ds_eng = imdataset('init', 'ICDAR2003RobustReading', ds_eng);
        switch type
            case 2
                ds_eng = imdataset('get_train_dataset_defxml_char', '', ds_eng);
                path = [ds_eng.path '_output_files/' folder_name '/'];
                nn = 'ch_0x0_r0';
            case 3
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
    case 'MSRATD500'
        ds_eng = imdataset('init', 'MSRATD500', ds_eng);
        switch type
            case 3
                ds_eng = imdataset('get_train_dataset_path', '', ds_eng);
                path = util_changeFn(ds_eng.path, 'cd ..', '');
                path = util_changeFn(path, 'cd _mkdir', '_output_files');
                ran_no = random_param{1};
                ran_seed = random_param{2};
                ran_resize = random_param{3};
                path = [path '[' ran_seed ']_random_' num2str(ran_no) '_nchar.mat'];
                if exist(path, 'file')
                    load(path);
                else
                    ds_eng = imdataset('get_train_dataset_random_nonchar', ran_no, ds_eng);
                    save(path, 'ds_eng');
                end
                nn = ['nc_' num2str(ran_resize(1)) 'x' num2str(ran_resize(2)) '_r0'];
        end
end

no_patch = 0;
max_region = 0;
for i=1:ds_eng.no
    if max_region < ds_eng.rect_region_no(i)
        max_region = ds_eng.rect_region_no(i);
    end
end

path = util_changeFn(ds_eng.path, 'cd ..', '');
path = util_changeFn(path, 'cd _mkdir', '_output_files');
path = util_changeFn(path, 'cd _mkdir', folder_name);
complete_map = 999999999*ones(ds_eng.no, max_region);
for i=1:ds_eng.no
    for r=1:ds_eng.rect_region_no(i)
        complete_map(i,r) = 0;
        file = util_changeFn(ds_eng.fn_list{i}, 'get_filename_and_extension', '');
        mat_ft = [path '[' sprintf('%03d', i) '] ' file];
        mat_ft = util_changeFn(mat_ft, 'replace_extension', [nn '.' num2str(r) '.mat']);
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