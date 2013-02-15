function [param] = imfeat_ertree(cmd1, cmd2, param)

switch cmd1
    case 'initialization'
        param.rd.mode = 'gray';
    case {'extract_feature_raw_get_all_preproc', ...
          'extract_feature_raw_get_one_full_data_and_dif', ...
          'extract_feature_raw_get_one_cropped_data_and_dif', ...
          'extract_feature_raw_del_data_and_dif'}
        param.feat_raw = imfeat_ertree_algo(cmd1, cmd2, param);
    otherwise
        warning('Unsupport cmd: %s',cmd1);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [out] = imfeat_ertree_algo(cmd1, cmd2, param)

switch cmd1
    case 'extract_feature_raw_get_all_preproc'
        %profile on;
        out = imfeat_ertree_algo_get_all_preproc(param.image, cmd2);
        %profile viewer;
    case 'extract_feature_raw_get_one_full_data_and_dif'
        out = imfeat_ertree_algo_get_single(param.image, param.feat_raw, 'full', cmd2(1), cmd2(2));
    case 'extract_feature_raw_get_one_cropped_data_and_dif'
        out = imfeat_ertree_algo_get_single(param.image, param.feat_raw, 'cropped', cmd2(1), cmd2(2));
    case 'extract_feature_raw_del_data_and_dif'
        out = imfeat_ertree_algo_del_single(param.feat_raw, cmd2(1), cmd2(2));
end
        
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [out] = imfeat_ertree_algo_get_all_preproc(I, reverse)

img = I;
max_idx = double(max(max(img))) + 1;
img_rows = size(img,1);
img_cols = size(img,2);
pixels = img_rows*img_cols;

% using fast algo implemented by c
[num, ER, pxl] = imfeat_ertree_get_ERs_c(uint8(img)', reverse);

% init TR & compute family relation map
fmap = zeros(pixels, max_idx);
N = zeros(1,256);
for i=0:num-1
    t = ER(3*i+1)+1; % ER pixel value + 1 = 1st index in TR
    n = ER(3*i+2);   % ER pixel num
    x = ER(3*i+3);   % ER pixel start index (in C sense: from 0)
    N(t) = N(t) + 1;
    fmap(x+1:x+n,t) = N(t);
    TR{t,N(t)}.data = -1;
    TR{t,N(t)}.data_l = -1;
    TR{t,N(t)}.data_t = -1;
    TR{t,N(t)}.data_r = -1;
    TR{t,N(t)}.data_b = -1;
    TR{t,N(t)}.dif = -1;
    TR{t,N(t)}.data_valid = 0;
    TR{t,N(t)}.dif_valid = 0;
    TR{t,N(t)}.isleaf = 1;
    TR{t,N(t)}.isdone = 0;
    TR{t,N(t)}.raw = [t, n, x+1]; % correct start index as Matlab sense
    TR{t,N(t)}.chd = [];
    TR{t,N(t)}.chd_no = 0;
    TR{t,N(t)}.postp = -1;
%     fst = x+1;
%     num = n;
%     vec = pxl(fst:fst+num-1)+1; % correct start index as Matlab sense
%     if sum(vec==(14*100+75))>0
%         t
%     end
end
if reverse==0
    t_last = max(max(img))+1;
else
    t_last = 256-min(min(img));
end
fmap(:,t_last) = 1;

% create last ER manually
TR{t_last,1}.par = [0,0]; % use zero parents to denote root node
TR{t_last,1}.data = true(img_rows, img_cols);
TR{t_last,1}.data_l = 1;
TR{t_last,1}.data_t = 1;
TR{t_last,1}.data_r = img_cols;
TR{t_last,1}.data_b = img_rows;
TR{t_last,1}.dif = false(img_rows, img_cols);
TR{t_last,1}.data_valid = 1;
TR{t_last,1}.dif_valid = 1;
TR{t_last,1}.isleaf = 0;
TR{t_last,1}.isdone = 0;
TR{t_last,1}.raw = [uint32(t_last), pixels, 1];
TR{t_last,1}.chd = [];
TR{t_last,1}.chd_no = 0;
TR{t_last,1}.postp = -1;
N(t_last) = 1;

% compute parent & isleaf
for t=1:t_last-1
    for n=1:N(t)
        col = t + 1;
        row = TR{t,n}.raw(3);
        while fmap(row,col)==0
            col = col + 1;
        end
        par = [double(col), fmap(row,col)];
        TR{t,n}.par = par;
        TR{par(1),par(2)}.isleaf = 0;
        TR{par(1),par(2)}.chd = [TR{par(1),par(2)}.chd; [t,n]];
        TR{par(1),par(2)}.chd_no = TR{par(1),par(2)}.chd_no + 1;
    end
end

out.size = N';
out.tree = TR;
out.pxls = pxl;
out.fmap = fmap;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [out] = imfeat_ertree_algo_get_single(I, feat_raw, type, t, n)

img = I;
img_rows = size(img,1);
img_cols = size(img,2);
pixels = img_rows*img_cols;
out = feat_raw;
pxl = feat_raw.pxls;

if out.tree{t,n}.data_valid == 0
    % compute data of cur ER
    fst = out.tree{t,n}.raw(3);
    num = out.tree{t,n}.raw(2);
    vec = pxl(fst:fst+num-1)+1; % correct start index as Matlab sense
    TR_data = false(1,pixels);
    TR_data(vec) = 1;
    data = reshape(TR_data, img_cols, img_rows)'; % row-wised reshape
    out.tree{t,n}.data = data;
    out.tree{t,n}.data_valid = 1;
end

par = out.tree{t,n}.par;
if ~isequal(par,[0 0])
    % compute data of par ER
    if out.tree{par(1),par(2)}.data_valid == 0
        fst = out.tree{par(1),par(2)}.raw(3);
        num = out.tree{par(1),par(2)}.raw(2);
        vec = pxl(fst:fst+num-1)+1; % correct start index as Matlab sense
        TR_data = false(1,pixels);
        TR_data(vec) = 1;
        out.tree{par(1),par(2)}.data = reshape(TR_data, img_cols, img_rows)'; % row-wised reshape
        out.tree{par(1),par(2)}.data_valid = 1;
    end
    % compute dif
    if out.tree{t,n}.dif_valid == 0
        dif = out.tree{par(1),par(2)}.data & ~out.tree{t,n}.data;
        out.tree{t,n}.dif_valid = 1;
        out.tree{t,n}.dif_size = double(out.tree{par(1),par(2)}.raw(2)) - double(out.tree{t,n}.raw(2));
        out.tree{t,n}.dif_par_ratio = double(out.tree{t,n}.dif_size) / double(out.tree{par(1),par(2)}.raw(2));
        % if necessary, crop dif & data only when computing dif
        if strcmp(type, 'cropped');
            % crop to a min rectangle containing all data
            [ll, tt, rr, bb] = imfeat_ertree_algo_crop_data(out.tree{par(1),par(2)}.data);
            out.tree{t,n}.dif = dif(tt:bb,ll:rr);
            out.tree{t,n}.data = out.tree{t,n}.data(tt:bb,ll:rr);
        else
            ll = 1;
            tt = 1;
            rr = img_cols;
            bb = img_rows;
            out.tree{t,n}.dif = dif;
        end
        out.tree{t,n}.data_l = ll;
        out.tree{t,n}.data_r = rr;
        out.tree{t,n}.data_t = tt;
        out.tree{t,n}.data_b = bb;
    end
end

end

function [l, t, r, b] = imfeat_ertree_algo_crop_data(data)
    [L, N] = bwlabel(data, 4);
    r = []; c = [];
    for i=1:N
        map = (i==L);
        r = [r find(max(map))];
        c = [c find(max(map'))];
    end
    l = min(r);
    r = max(r);
    t = min(c);
    b = max(c);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [out] = imfeat_ertree_algo_del_single(feat_raw, t, n)

out = feat_raw;
out.tree{t,n}.data = -1;
out.tree{t,n}.data_l = -1;
out.tree{t,n}.data_r = -1;
out.tree{t,n}.data_t = -1;
out.tree{t,n}.data_b = -1;
out.tree{t,n}.data_valid = 0;
out.tree{t,n}.dif = -1;
out.tree{t,n}.dif_valid = 0;


end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [out] = imfeat_ertree_algo_slow(img)

max_idx = double(max(max(img))) + 1;
pixels = size(img,1)*size(img,2);

% for t=1, we need to handle some corner case
mask{1} = (img==0);
accm{1} = mask{1};
[L{1}, N(1)] = bwlabel(accm{1}, 4);
for n=1:N(1)
    TR{1,n}.data = (L{1}==n);
    TR{1,n}.isleaf = 1; % initial value
    TR{1,n}.isdone = 0;
end

% for t=2:256
for t=2:max_idx
    mask{t} = (img==t-1);
    accm{t} = accm{t-1} | mask{t};
    [L{t}, N(t)] = bwlabel(accm{t}, 4);

    % assign data for t (current) level nodes
    for n=1:N(t)
        TR{t,n}.data = (L{t}==n);
        TR{t,n}.isleaf = 1; % initial value
        TR{t,n}.isdone = 0;
    end

    % assign parents for t-1 (previous) level nodes
    for n_pre=1:N(t-1)
        % check for each t (current) level nodes
        for n_now=1:N(t)
            if isequal(TR{t-1,n_pre}.data & TR{t,n_now}.data, TR{t-1,n_pre}.data)
                % TR{t,n_now} is TR{t-1,n_pre}'s parent
                TR{t-1,n_pre}.par = [t, n_now];
                % onece [t,n_now] is other's parent, it won't be leaf node
                TR{t,n_now}.isleaf = 0;
                % save difference binary map, which is the additional
                % 1's start appeared in parent
                TR{t-1,n_pre}.dif = TR{t,n_now}.data & ~TR{t-1,n_pre}.data;
                break; % leave inner loop
            end
            if n_now == N(t)
                error('cannot find its parent and children!');
            end
        end
    end
end

TR{t,1}.par = [0 0]; % use zero parents to denote root node
TR{t,1}.dif = false(size(img,1),size(img,2));
out.size = N';
out.tree = TR;

end


