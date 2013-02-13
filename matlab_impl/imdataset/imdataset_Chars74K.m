function [param] = imdataset_Chars74K(cmd1, cmd2, param)

switch cmd1
    % English font dataset
    case 'get_eng_font_dataset_path'
        param.path = '../../Dataset/Chars74K/English/Fnt/';
    case 'get_eng_font_dataset'
        param.path = '../../Dataset/Chars74K/English/Fnt/';
        param = get_Chars74K(param);
    % English handwriting dataset
    case 'get_eng_handwriting_dataset_path'
        param.path = '../../Dataset/Chars74K/English/Hnd/Img/';
    % English good image dataset  
    case 'get_eng_goodimg_dataset_path'
        param.path = '../../Dataset/Chars74K/English/Img/GoodImg/Bmp/';
    % English bad image dataset  
    case 'get_eng_badimg_dataset_path'
        param.path = '../../Dataset/Chars74K/English/Img/BadImg/Bmp/';
    otherwise
        warning('Unsupport cmd: %s',cmd1);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [param] = get_Chars74K(param)

param = parse_Chars74K(param);
param = construct_rect_from_parsed_ds_directly(param);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [param] = parse_Chars74K(param)

path = param.path;
path_parsed = [path 'parsed.mat'];
if exist(path_parsed, 'file')
    load(path_parsed);
    param.no = no;
    param.fn_list = fn_list;
    param.res = res;
    param.att = att;
    param.att_region_no = att_region_no;
else
    no = 0;
    fds = dir(path);
    for i=1:numel(fds)
        % in each folder
        if strcmp(fds(i,1).name,'.') || strcmp(fds(i,1).name,'..') || ...
           fds(i,1).isdir == 0
            continue;
        end
        fns = dir([path fds(i,1).name '/*.png']);
        for ii=1:numel(fns)
            fd_name = fds(i,1).name;
            if ~(strcmp(fd_name(1:6),'Sample') && ...
                 str2double(fd_name(7:9)) <= 62 && ...
                 fds(i,1).isdir == 0)
                continue;
            end
            % for each .png file
            no = no + 1;
            % assign fn_list
            fn_list{no} = [path fd_name '/' fns(ii,1).name];
            % assign res
            imgInfo = imfinfo(fn_list{no});
            res(no).w = imgInfo.Width;
            res(no).h = imgInfo.Height;
            % assign att
            fd_id = str2num(fd_name(7:9));
            if fd_id <= 10 % 0-9
                att{no,1}.tag = char(48+fd_id-1);
            elseif fd_id <= 36 % A-Z
                att{no,1}.tag = char(65+fd_id-11);
            elseif fd_id <= 62 % a-z
            	att{no,1}.tag = char(97+fd_id-37);
            end
            att{no,1}.x = 1;
            att{no,1}.y = 1;
            att{no,1}.w = res(no).w;
            att{no,1}.h = res(no).h;
            att{no,1}.lan = 'ENGLISH';
            % assign att_region_no
            att_region_no(no) = 1;
        end
       
    end
    save(path_parsed, 'no', 'fn_list', 'res', 'att', 'att_region_no');
    param.no = no;
    param.fn_list = fn_list;
    param.res = res;
    param.att = att;
    param.att_region_no = att_region_no;
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [param] = construct_rect_from_parsed_ds_directly(param)

path = param.path;
path_constructed = [path 'constructed.mat'];
if exist(path_constructed, 'file')
    load(path_constructed);
    param.rect = rect;
    param.rect_region_no = rect_region_no;
else
    for i=1:param.no
        for r=1:param.att_region_no(i)
            attr = param.att{i,r};
            param.rect{i,r}.h = attr.h;
            param.rect{i,r}.w = attr.w;
            % Matlab index start from 1 not zero or minus
            param.rect{i,r}.x = max(attr.x, 1);
            param.rect{i,r}.y = max(attr.y, 1);
        end
    end
    param.rect_region_no = param.att_region_no;
    rect = param.rect;
    rect_region_no = param.rect_region_no;
    save(path_constructed, 'rect', 'rect_region_no');
end

end



