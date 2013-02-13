function text_detect_v4_calcMinRegion2FullsizeRatio(type)

% type:
%   2: for "word" patches
%   1: for "char" patches
%   0: for "non-char" patches

addpath_for_me;

% dataset initialization
ds_eng = [];
ds_eng = imdataset('init', 'ICDAR2003RobustReading', ds_eng);
switch type
    case 2
        ds_eng = imdataset('get_train_dataset_defxml_word', '', ds_eng);
    case 1
        ds_eng = imdataset('get_train_dataset_defxml_char', '', ds_eng);
    case 0
        ds_eng = imdataset('get_train_dataset_random_nonchar', 500, ds_eng);
end

wr = []; 
hr = [];
for i=1:ds_eng.no
    for ii=1:ds_eng.rect_region_no(i) 
        wr = [wr; double(ds_eng.rect{i,ii}.w)/double(ds_eng.res(i).w)];
        hr = [hr; double(ds_eng.rect{i,ii}.h)/double(ds_eng.res(i).h)];
    end
end
[min(wr) max(wr)]
[min(hr) max(hr)]

end