function [param] = imdataset_ICDAR2003RobustReading(cmd1, cmd2, param)

switch cmd1
    % sample dataset
    case 'get_sample_dataset_path'
        param.path = '../../../Dataset/ICDAR_Robust_Reading/SceneSample/';
    case 'get_sample_dataset_defxml_word'
        param.path = '../../../Dataset/ICDAR_Robust_Reading/SceneSample/';
        param = get_ICDAR2003RobustReading(param, 'defxml_word', '');
    % test dataset
    case 'get_test_dataset_path'
        param.path = '../../../Dataset/ICDAR_Robust_Reading/SceneTrialTest/';
    case 'get_test_dataset_defxml_word'
        param.path = '../../../Dataset/ICDAR_Robust_Reading/SceneTrialTest/';
        param = get_ICDAR2003RobustReading(param, 'defxml_word', '');
    % train dataset
    case 'get_train_dataset_path'
        param.path = '../../../Dataset/ICDAR_Robust_Reading/SceneTrialTrain/';
    case 'get_train_dataset_defxml_word'
        param.path = '../../../Dataset/ICDAR_Robust_Reading/SceneTrialTrain/';
        param = get_ICDAR2003RobustReading(param, 'defxml_word', '');
    case 'get_train_dataset_defxml_char'
        param.path = '../../../Dataset/ICDAR_Robust_Reading/SceneTrialTrain/';
        param = get_ICDAR2003RobustReading(param, 'defxml_char', '');
    case 'get_train_dataset_random_nonchar'
        param.path = '../../../Dataset/ICDAR_Robust_Reading/SceneTrialTrain/';
        param = get_ICDAR2003RobustReading(param, 'random_nonchar', cmd2);
    case 'get_train_dataset_GEDIxml_nonchar'
        param.path = '../../../Dataset/ICDAR_Robust_Reading/SceneTrialTrain/';
        param = get_ICDAR2003RobustReading(param, 'GEDIxml_nonchar', '');  
    otherwise
        warning('Unsupport cmd: %s',cmd1);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [param] = get_ICDAR2003RobustReading(param, type, cmd2)

switch type
    case 'defxml_word'
        param = parse_ICDAR2003RobustReading_from_defxml(param);
        param = construct_rect_from_parsed_ds_directly(param);
    case 'defxml_char'
        param = parse_ICDAR2003RobustReading_from_defxml(param);
        param = construct_rect_from_parsed_ds_bySplitOff(param);
    case 'random_nonchar'
        %param = parse_ICDAR2003RobustReading_by_random_surround(param, cmd2);
        param = parse_ICDAR2003RobustReading_by_random_subtract(param, cmd2);
        param = construct_rect_from_parsed_ds_directly(param);
    case 'GEDIxml_nonchar'
        param = parse_ICDAR2003RobustReading_from_GEDIxml(param);
        param = construct_rect_from_parsed_ds_directly(param);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [param] = parse_ICDAR2003RobustReading_from_defxml(param)

path_parsed = [param.path 'parsed.mat'];
if exist(path_parsed, 'file')
    load(path_parsed);
    param.no = no;
    param.fn_list = fn_list;
    param.res = res;
    param.att = att;
    param.att_region_no = att_region_no;
else
    path_xml = [param.path 'segmentation.xml'];
    tree = util_xml2struct(path_xml);
    no = (size(tree.children,2)-1)/2;
    for i=1:no
        fn_list{i} = [param.path tree.children(2*i).children(2).children.data];
        res(i).w = str2double(tree.children(2*i).children(4).attributes(1).value);
        res(i).h = str2double(tree.children(2*i).children(4).attributes(2).value);
        taggedRect_no = (size(tree.children(2*i).children(6).children,2)-1)/2;
        for r=1:taggedRect_no
            taggedRect = tree.children(2*i).children(6).children(2*r);
            att{i,r}.h = str2double(taggedRect.attributes(1).value);   % height
            att{i,r}.off = str2double(taggedRect.attributes(2).value); % offset
            att{i,r}.rot = str2double(taggedRect.attributes(3).value); % rotation
            att{i,r}.w = str2double(taggedRect.attributes(5).value);   % width
            att{i,r}.x = str2double(taggedRect.attributes(6).value);   % x
            att{i,r}.y = str2double(taggedRect.attributes(7).value);   % y
            att{i,r}.tag = taggedRect.children(2).children.data;       % tag
            att{i,r}.lan = 'ENGLISH';
            xOff_no = (size(taggedRect.children(4).children,2)-1)/2;
            for o=1:xOff_no
                xOff = taggedRect.children(4).children(2*o);
                att{i,r}.xoff(o) = str2double(xOff.children.data);     % x-offset of each char
            end
        end
        att_region_no(i) = taggedRect_no;
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

function [param] = parse_ICDAR2003RobustReading_from_GEDIxml(param, cmd2)

% still need to parse defxml first
param = parse_ICDAR2003RobustReading_from_defxml(param);

no = length(param.fn_list);
for i=1:no
    % for each .xml file
    path_xml = util_changeFn(param.fn_list{i}, 'replace_extension', 'xml');
    GEDI = util_GEDIxml2struct(path_xml);
    dlZone_no = size(GEDI.DL_DOCUMENT.DL_PAGE(1).DL_ZONE, 2);
    for z=1:dlZone_no
        dlZone = GEDI.DL_DOCUMENT.DL_PAGE(1).DL_ZONE(z);
        param.att{i,z}.x = str2double(dlZone.col);
        param.att{i,z}.y = str2double(dlZone.row);
        param.att{i,z}.w = str2double(dlZone.width);
        param.att{i,z}.h = str2double(dlZone.height);
    end
    param.rect_region_no(i) = dlZone_no;
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [param] = parse_ICDAR2003RobustReading_by_random_surround(param, cmd2)

path_parsed = [param.path 'random_nonchar_' num2str(cmd2) '.mat'];
if exist(path_parsed, 'file')
    load(path_parsed);
else
    % some parameter setting
    MAX_TRIALS_IN_AN_IMAGE = 5; % max trials in an image
    MIN_REGION_W = 30;          % min allowed randomized region width
    MIN_REGION_H = 30;          % min allowed randomized region height

    % still need to parse defxml first
    param = parse_ICDAR2003RobustReading_from_defxml(param);

    % initialize variables
    no = cmd2;
    att = [];
    att_region_no = zeros(1,param.no);

    % random pickup regions
    for i=1:no
        while true % guarantee a successful random region for each i
            % (1) random an image
            idx = ceil(rand(1)*param.no);
            % (2) determin valid region for randomization
            if param.att_region_no(idx)==0
                % no text region exists in ground truth
                % choose all image as the valid region
                valid_w = param.res(idx).w;
                valid_h = param.res(idx).h;
                valid_x = 1;
                valid_y = 1;
            else
                % some text regions exist in ground truth
                % init with opposite value
                r_x1 = param.res(idx).w; r_x2 = 0;
                r_y1 = param.res(idx).h; r_y2 = 0;
                % avoid the center union region of all text regions 
                for j=1:param.att_region_no(idx)
                    r_x1 = min(r_x1, max(param.att{idx,j}.x, 1));
                    r_x2 = max(r_x2, max(param.att{idx,j}.x, 1) + param.att{idx,j}.w - 1);
                    r_y1 = min(r_y1, max(param.att{idx,j}.y, 1));
                    r_y2 = max(r_y2, max(param.att{idx,j}.y, 1) + param.att{idx,j}.h - 1);
                end
                space = [];
                % left available space
                space{1}.x = 1;
                space{1}.y = 1;
                space{1}.w = r_x1 - 1;
                space{1}.h = param.res(idx).h;
                space{1}.s = space{1}.w * space{1}.h;
                % top available space
                space{2}.x = 1;
                space{2}.y = 1;
                space{2}.w = param.res(idx).w;
                space{2}.h = r_y1 - 1;
                space{2}.s = space{2}.w * space{2}.h;
                % right available space
                space{3}.x = r_x2 + 1;
                space{3}.y = 1;
                space{3}.w = param.res(idx).w - r_x2 + 1;
                space{3}.h = param.res(idx).h;
                space{3}.s = space{3}.w * space{3}.h;
                % bottom available space
                space{4}.x = 1;
                space{4}.y = r_y2 + 1;
                space{4}.w = param.res(idx).w;
                space{4}.h = param.res(idx).h - r_y2 + 1;
                space{4}.s = space{4}.w * space{4}.h;
                % random one region as the valid region
                s_idx = ceil(rand(1)*4);
                valid_w = space{s_idx}.w; 
                valid_h = space{s_idx}.h;
                valid_x = space{s_idx}.x;
                valid_y = space{s_idx}.y;
            end
            % (3) try at most MAX_TRIALS_IN_AN_IMAGE times to random a region in an image 
            trial = 1;
            while trial <= MAX_TRIALS_IN_AN_IMAGE
                % randomize a region
                x = ceil(rand(1,2)*valid_w); 
                y = ceil(rand(1,2)*valid_h);
                x1 = min(x); x2 = max(x);
                y1 = min(y); y2 = max(y); 
                w = x2-x1+1;
                h = y2-y1+1;
                % crop w,h to keep a randomed aspect ratio
                % random an aspect ratio w:h from 1:2~2:1
                ar = (1+rand(1))/(1+rand(1));
                if w*ar > h
                    % h is not enough, truncate w
                    w = round(h/ar);
                else
                    % h is too large, truncate h
                    h = round(w*ar);
                end
                % check if bad case happened
                if w<MIN_REGION_W || h<MIN_REGION_H
                    trial = trial + 1;
                    continue;
                else
                    % pass checking. Create region info
                    att_region_no(idx) = att_region_no(idx) + 1;
                    r = att_region_no(idx);
                    att{idx,r}.x = valid_x + x1 - 1;  % x
                    att{idx,r}.y = valid_y + y1 - 1;  % y
                    att{idx,r}.w = w;                 % width
                    att{idx,r}.h = h;                 % height
                    att{idx,r}.off = 0;               % offset
                    att{idx,r}.rot = 0;               % rotation
                    att{idx,r}.tag = '';              % tag
                    att{idx,r}.lan = 'NONTEXT';
                    fprintf('trial:%d (x,y,w,h)=(%d,%d,%d,%d)\n',trial,att{idx,r}.x,att{idx,r}.y,att{idx,r}.w,att{idx,r}.h);
                    trial = 0; % means a successful random region is created
                    break; % leave "while trial<=..."
                end
            end
            % (4) leave "while true" if a successful random region is created
            if trial==0
                break;
            end
        end
    end
    param.att = att;
    param.att_region_no = att_region_no;
    save(path_parsed, 'param');
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [param] = parse_ICDAR2003RobustReading_by_random_subtract(param, cmd2)

% some parameter setting
MAX_TRIALS = 1000;                % max trials in an image
MIN_REGION_W = 30;                % min allowed randomized region width
MIN_REGION_H = 30;                % min allowed randomized region height
MAX_REGION_TO_IMAGE_RATIO = 0.25; % max region to image ratio 0~100%

% still need to parse defxml first
param = parse_ICDAR2003RobustReading_from_defxml(param);

% initialize variables
no = cmd2;
att = [];
att_region_no = zeros(1,param.no);

% random pickup regions
for i=1:no
    trial = 0;
    while true % guarantee a successful random region for each i
        % (1) random an image
        idx = ceil(rand(1)*param.no);

        % randomize a region
        x = ceil(rand(1,2)*param.res(idx).w); 
        y = ceil(rand(1,2)*param.res(idx).h);
        x1 = min(x); x2 = max(x);
        y1 = min(y); y2 = max(y); 
        rect.x = x1;
        rect.y = y1;
        rect.w = x2-x1+1;
        rect.h = y2-y1+1;

        % if some text regions exist in ground truth, subtract those regions
        if param.att_region_no(idx)>0
            for r=1:param.att_region_no(idx)
                rect = util_regionSubtract(rect, param.att{idx,r});
            end
        end

        % check if bad case happened
        if rect.w<MIN_REGION_W || rect.h<MIN_REGION_H ||...
           ((rect.w*rect.h)/(param.res(idx).w*param.res(idx).h))>MAX_REGION_TO_IMAGE_RATIO
            trial = trial + 1;
            if (trial==MAX_TRIALS)
                error('cannot random a reasonable regions over MAX_TRIALS times');
            end
            continue;
        else
            % pass checking. Create region info
            att_region_no(idx) = att_region_no(idx) + 1;
            r = att_region_no(idx);
            att{idx,r}.x = rect.x;      % x
            att{idx,r}.y = rect.y;      % y
            att{idx,r}.w = rect.w;      % width
            att{idx,r}.h = rect.h;      % height
            att{idx,r}.off = 0;         % offset
            att{idx,r}.rot = 0;         % rotation
            att{idx,r}.tag = '';        % tag
            att{idx,r}.lan = 'NONTEXT';
            fprintf('trial:%d (x,y,w,h)=(%d,%d,%d,%d)\n',trial,att{idx,r}.x,att{idx,r}.y,att{idx,r}.w,att{idx,r}.h);
            % leave "while true"
            break; 
        end
    end
end
param.att = att;
param.att_region_no = att_region_no;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [param] = construct_rect_from_parsed_ds_directly(param)

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

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [param] = construct_rect_from_parsed_ds_bySplitOff(param)

for i=1:param.no
    c = 0;
    for r=1:param.att_region_no(i)
        attr = param.att{i,r};
        tag_len = length(attr.tag);
        for t=1:tag_len
            c = c + 1;
            if t==1
                param.rect{i,c}.x = attr.x;
                if tag_len == 1
                    param.rect{i,c}.w = attr.w;
                else
                    param.rect{i,c}.w = attr.xoff(1);
                end
            elseif t==tag_len
                param.rect{i,c}.x = attr.x + attr.xoff(t-1);
                param.rect{i,c}.w = attr.w - attr.xoff(t-1) + 1;
            else
                param.rect{i,c}.x = attr.x + attr.xoff(t-1);
                param.rect{i,c}.w = attr.xoff(t) - attr.xoff(t-1) + 1;
            end
            param.rect{i,c}.y = attr.y;
            param.rect{i,c}.h = attr.h;
            % Matlab index start from 1 not zero or minus
            param.rect{i,c}.x = max(param.rect{i,c}.x, 1);
            param.rect{i,c}.y = max(param.rect{i,c}.y, 1);
        end
    end
    param.rect_region_no(i) = c;
end

end


