function [param] = imdataset_MSRATD500(cmd1, cmd2, param)

switch cmd1
    case 'get_train_dataset'
        path = '../../../Dataset/MSRA-TD500/train/';
        param = get_MSRATD500(path, param);
    case 'get_test_dataset'
        path = '../../../Dataset/MSRA-TD500/test/';
        param = get_MSRATD500(path, param);
    otherwise
        warning('Unsupport cmd: %s',cmd1);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [param] = get_MSRATD500(path, param)

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

end