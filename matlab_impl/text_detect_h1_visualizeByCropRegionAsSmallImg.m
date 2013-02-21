function text_detect_v3_visualizeByCropRegionAsSmallImg(type, folder_name)

% type:
%   2: output "char" region as small images
%   1: output "word" region as small images

addpath_for_me;

% dataset initialization
ds_eng = [];
ds_eng = imdataset('init', 'ICDAR2003RobustReading', ds_eng);
switch type
    case 1
        ds_eng = imdataset('get_train_dataset_defxml_word', '', ds_eng);
    case 2
        ds_eng = imdataset('get_train_dataset_defxml_char', '', ds_eng);
end

for i=1:ds_eng.no
    % prepare for output image path
    path = util_changeFn(ds_eng.fn_list{i}, 'cd .._with_filename', '');
    path = util_changeFn(path, 'cd _mkdir_with_filename', '_output_files');
    path = util_changeFn(path, 'cd _mkdir_with_filename', folder_name);
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