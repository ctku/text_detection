function text_detect_h1_visualizeByCropRegionAsSmallImg(dataset, type, folder_name)

% type:
%   1: output "word" region as small images
%   2: output "char" region as small images
%   3: output "non-char" region as small images

% dataset:
%   1: ICDAR2003RobustReading
%   2: MSRATD500

addpath_for_me;

% dataset initialization
ds_eng = [];
switch dataset
    case 'ICDAR2003RobustReading'
        ds_eng = imdataset('init', 'ICDAR2003RobustReading', ds_eng);
        switch type
            case 1
                ds_eng = imdataset('get_train_dataset_defxml_word', '', ds_eng);
            case 2
                ds_eng = imdataset('get_train_dataset_defxml_char', '', ds_eng);
        end
    case 'MSRATD500'
        ds_eng = imdataset('init', 'MSRATD500', ds_eng);
        switch type
            case 1
                ds_eng = imdataset('get_train_dataset_deftxt_word', '', ds_eng);
            case 3
                ds_eng = imdataset('get_train_dataset_path', '', ds_eng);
                path = util_changeFn(ds_eng.path, 'cd ..', '');
                path = util_changeFn(path, 'cd _mkdir', '_output_files');
                ran_no = 50;
                ran_seed = '20130226';
                path = [path '[' ran_seed ']_random_' num2str(ran_no) '_nchar.mat'];
                if exist(path, 'file')
                    load(path);
                else
                    ds_eng = imdataset('get_train_dataset_random_nonchar', ran_no, ds_eng);
                    save(path, 'ds_eng');
                end
        end
end

for i=1:ds_eng.no
    % prepare for output image path
    file = util_changeFn(ds_eng.fn_list{i}, 'get_filename_and_extension', '');
    path = util_changeFn(ds_eng.fn_list{i}, 'remove_filename_and_extension', '');
    path = util_changeFn(path, 'cd ..', '');
    path = util_changeFn(path, 'cd _mkdir', '_output_files');
    path = util_changeFn(path, 'cd _mkdir', folder_name);
    path = [path '[' sprintf('%03d', i) '] ' file];
    for ii=1:ds_eng.rect_region_no(i)
        x1 = ds_eng.rect{i,ii}.x;
        x2 = ds_eng.rect{i,ii}.x + ds_eng.rect{i,ii}.w - 1;
        y1 = ds_eng.rect{i,ii}.y;
        y2 = ds_eng.rect{i,ii}.y + ds_eng.rect{i,ii}.h - 1;
        img = imread(ds_eng.fn_list{i});
        I = img(y1:y2,x1:x2,:);
        out_path = util_changeFn(path, 'replace_extension', [num2str(ii) '.jpg']);
        imwrite(I, out_path, 'jpeg')
    end
    
end

end