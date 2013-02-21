function text_detect_v4_calcMeanRegionSize(type)

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

ws = [];
hs = [];
for i=1:ds_eng.no
    for ii=1:ds_eng.rect_region_no(i) 
        ws = [ws; ds_eng.rect{i,ii}.w];
        hs = [hs; ds_eng.rect{i,ii}.h];
    end
end
mean(ws)
mean(hs)

end