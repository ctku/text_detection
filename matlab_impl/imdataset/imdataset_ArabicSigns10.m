function [param] = imdataset_ArabicSigns10(cmd1, cmd2, param)

switch cmd1
    case 'get_test_dataset'
        path = '../../../Dataset/ArabicSigns-1.0/data/';
        param = get_ArabicSigns10(path, param);
    otherwise
        warning('Unsupport cmd: %s',cmd1);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [param] = get_ArabicSigns10(path, param)

path_parsed = [path 'parsed.mat'];
if exist(path_parsed, 'file')
    load(path_parsed);
    param.no = no;
    param.fn_list = fn_list;
    param.att = att;
else
    no = numel(dir([path '*.jpg']));
    for i=1:no
        % for each .xml file
        fn_list{i} = [path 'ArabicSign-' sprintf('%05d',i) '.jpg']; 
        path_xml = [path 'ArabicSign-' sprintf('%05d',i) '.xml'];
        GEDI = util_GEDIxml2struct(path_xml);
        dlZone_no = size(GEDI.DL_DOCUMENT.DL_PAGE(1).DL_ZONE, 2);
        for z=1:dlZone_no
            dlZone = GEDI.DL_DOCUMENT.DL_PAGE(1).DL_ZONE(z);
            [x y w h] = util_polygonStr2xywh(dlZone.polygon);
            att{i,z}.x = x;
            att{i,z}.y = y;
            att{i,z}.w = w;
            att{i,z}.h = h;
            att{i,z}.tag = dlZone.contents;   % contents
            att{i,z}.lan = dlZone.language;   % language
            att{i,z}.off = 0;
            att{i,z}.rot = 0;
        end
    end
    save(path_parsed, 'no', 'fn_list', 'att');
    param.no = no;
    param.fn_list = fn_list;
    param.att = att;
end

end