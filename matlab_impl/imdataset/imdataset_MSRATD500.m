function [param] = imdataset_MSRATD500(cmd1, cmd2, param)

switch cmd1
    % test dataset
    case 'get_test_dataset_path'
        param.path = '../../../Dataset/MSRA-TD500/test/';
    case 'get_test_dataset_deftxt_word'
        param.path = '../../../Dataset/MSRA-TD500/test/';
        param = get_MSRATD500(param, 'deftxt_word', '');
    % train dataset
    case 'get_train_dataset_path'
        param.path = '../../../Dataset/MSRA-TD500/train/';
    case 'get_train_dataset_deftxt_word'
        param.path = '../../../Dataset/MSRA-TD500/train/';
        param = get_MSRATD500(param, 'deftxt_word', '');
    case 'get_train_dataset_random_nonchar'
        param.path = '../../../Dataset/MSRA-TD500/train/';
        param = get_MSRATD500(param, 'random_nonchar', cmd2);
    otherwise
        warning('Unsupport cmd: %s',cmd1);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [param] = get_MSRATD500(param, type, cmd2)

switch type
    case 'deftxt_word'
        param = parse_MSRATD500_from_deftxt(param);
        param = construct_rect_from_parsed_ds_directly(param);
    case 'random_nonchar'
        param = parse_MSRATD500_by_random_subtract(param, cmd2);
        param = construct_rect_from_parsed_ds_directly(param);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [param] = parse_MSRATD500_from_deftxt(param)

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
    fds = dir([path '*.JPG']);
    for i=1:numel(fds)
        % for each .jpg file
        no = no + 1;
        % assign fn_list
        fn_list{no} = [path fds(i,1).name];
        % assign res
        imgInfo = imfinfo(fn_list{no});
        res(no).w = imgInfo.Width;
        res(no).h = imgInfo.Height;
        
        gt_file = util_changeFn(fn_list{no}, 'replace_extension', 'gt');
        fid = fopen(gt_file);
        A = fscanf(fid, '%g %g', [7 inf])';
        % assign att_region_no
        att_region_no(no) = size(A,1);
        for r=1:att_region_no(no)
            [x,y,w,h] = util_xywhTheta2xywhRect(...
                        A(r,3), A(r,4), A(r,5), A(r,6), A(r,7), ...
                        res(no).w, res(no).h);
            % assign att
            att{no,r}.x = x;
            att{no,r}.y = y;
            att{no,r}.w = w;
            att{no,r}.h = h;
            %att{no,r}.lan = 'ENGLISH';
        end
        fclose(fid);
    end
    save(path_parsed, 'no', 'fn_list', 'res', 'att', 'att_region_no');
    param.no = no;
    param.fn_list = fn_list;
    param.res = res;
    param.att = att;
    param.att_region_no = att_region_no;
end

path_parsed = [path 'parsed_regions.txt'];
if 1%~exist(path_parsed, 'file')
    % 250
    % xx1.jpg 2
    % x y w h
    % x y w h
    % xx2.jpg 1
    % ...
    fid = fopen(path_parsed,'w');
    fprintf(fid, '%d\n', no);
    for i=1:no
        fprintf(fid, '%s\t%d\n', fn_list{i}, att_region_no(i));
        for r=1:att_region_no(i)
            fprintf(fid, '%d\t%d\t%d\t%d\n', att{i,r}.x, att{i,r}.y, att{i,r}.w, att{i,r}.h);
        end
    end
    fclose(fid);
end

path_parsed = [path 'parsed_filenames.txt'];
if ~exist(path_parsed, 'file')
    % xxx.jpg
    % xxx.jpg
    % ...
    fid = fopen(path_parsed,'w');
    fprintf(fid, '%d\n', no);
    for i=1:no
        fprintf(fid, '%s\n', fn_list{i});
    end
    fclose(fid);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [param] = parse_MSRATD500_by_random_subtract(param, cmd2)

% some parameter setting
MAX_TRIALS = 1000;                % max trials in an image
MIN_REGION_W = 30;                % min allowed randomized region width
MIN_REGION_H = 30;                % min allowed randomized region height
MAX_REGION_TO_IMAGE_RATIO = 0.25; % max region to image ratio 0~100%

% still need to parse defxml first
param = parse_MSRATD500_from_deftxt(param);

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
        % subtract regions that have been randomed
        if att_region_no(idx)>0
            for r=1:att_region_no(idx)
                rect = util_regionSubtract(rect, att{idx,r});
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