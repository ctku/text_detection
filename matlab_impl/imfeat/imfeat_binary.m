function [param] = imfeat_binary(cmd1, cmd2, param)

switch cmd1
    case 'initialization'
        param.rd.mode = 'binary';
%     case 'compute_feature_raw_aspectratio_incrementally'
%         param.feat_raw = imfeat_aspectratio_algo(param.image, cmd1, cmd2);
%     case 'compute_feature_raw_compactness_incrementally'
%         param.feat_raw = imfeat_compactness_algo(param.image, cmd1, cmd2);
%     case {'extract_feature_raw_numofhole_all', ...
%           'extract_feature_raw_numofhole_givenchkpt'}
%         param.feat_raw = imfeat_numofhole_algo(param.image, cmd1, cmd2);
    case {'extract_feature_raw_size_all', ...
          'extract_feature_raw_size_givenchkpt', ...
          'compute_feature_raw_size_incrementally'}
        param.feat_raw = imfeat_size_algo(param.image, cmd1, cmd2);
    case {'extract_feature_raw_boundingbox_all', ...
          'extract_feature_raw_boundingbox_givenchkpt', ...
          'compute_feature_raw_boundingbox_incrementally'}
        param.feat_raw = imfeat_boundingbox_algo(param.image, cmd1, cmd2);
    case {'extract_feature_raw_perimeter_all', ...
          'extract_feature_raw_perimeter_givenchkpt', ...
          'compute_feature_raw_perimeter_incrementally'}
        param.feat_raw = imfeat_perimeter_algo(param.image, cmd1, cmd2);
    case {'extract_feature_raw_eulerno_all', ...
          'extract_feature_raw_eulerno_givenchkpt', ...
          'compute_feature_raw_eulerno_incrementally'}
        param.feat_raw = imfeat_eulerno_algo(param.image, cmd1, cmd2);
    case {'extract_feature_raw_hzcrossing_all', ...
          'extract_feature_raw_hzcrossing_givenchkpt', ...
          'extract_feature_raw_hzcrossing_slicemedian', ...
          'compute_feature_raw_hzcrossing_incrementally'}
        param.feat_raw = imfeat_hzcrossing_algo(param.image, cmd1, cmd2);
    case {'extract_feature_raw_convexhull_all'}
        param.feat_raw = imfeat_convexhull_algo(param.image, cmd1, cmd2);
    case {'extract_feature_raw_holesize_all'}
        param.feat_raw = imfeat_holesize_algo(param.image, cmd1, cmd2);
    case {'extract_feature_raw_reflectpointno_all'}
        param.feat_raw = imfeat_reflectpointno_algo(param.image, cmd1, cmd2);
    otherwise
        warning('Unsupport cmd: %s',cmd1);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ok
% function [out] = imfeat_aspectratio_algo(I, cmd1, cmd2)
% 
% switch cmd1
%     case 'compute_feature_raw_aspectratio_incrementally'
%         box = imfeat_boundingbox_algo ...
%               (I, 'compute_feature_raw_boundingbox_incrementally', cmd2{1});
%     otherwise
%         warning('Unsupport cmd: %s',cmd1);
% end
% w = box.x_max - box.x_min + 1;
% h = box.y_max - box.y_min + 1;
% out = w/h;
% 
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%....
% function [out] = imfeat_compactness_algo(I, cmd1, cmd2)
% 
% switch cmd1
%     case 'compute_feature_raw_compactness_incrementally'
%         a = imfeat_size_algo ...
%               (I, 'compute_feature_raw_size_incrementally', cmd2);
%         p = imfeat_perimeter_algo ...
%               (I, 'compute_feature_raw_perimeter_incrementally', cmd2);
%     otherwise
%         warning('Unsupport cmd: %s',cmd1);
% end
% out = sqrt(a)/p;
% 
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% function [out] = imfeat_numofhole_algo(I, cmd1, cmd2)
% 
% switch cmd1
%     case 'extract_feature_raw_numofhole_all'
%         [L, N] = bwlabel(I, 4);
%         if N == 1
%             e = imfeat_eulerno_algo ...
%                   (I, 'extract_feature_raw_eulerno_all', cmd2);
%         else
%             warning('cmd %d support single connected component only',cmd1);
%         end
%     case 'extract_feature_raw_numofhole_givenchkpt'
%         e = imfeat_eulerno_algo ...
%               (I, 'extract_feature_raw_eulerno_givenchkpt', cmd2);
%     otherwise
%         warning('Unsupport cmd: %s',cmd1);
% end
% out = 1-e;
% 
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [out] = imfeat_size_algo(I, cmd1, cmd2)

switch cmd1
    case 'extract_feature_raw_size_all'
    	out = sum(sum(I));
    case 'extract_feature_raw_size_givenchkpt'
        % row: row of checked point
        % col: column of checked point
        row = cmd2(1); 
        col = cmd2(2);
        if I(row,col)==0
            out = 0;
        else
            [L, N] = bwlabel(I, 4);
            out = sum(sum(L(row,col)==L));
        end
    case 'compute_feature_raw_size_incrementally'
        new = I;
        cum = cmd2;
        out = sum(sum(new)) + cum;
    otherwise
        warning('Unsupport cmd: %s',cmd1);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [out] = imfeat_boundingbox_algo(I, cmd1, cmd2)

switch cmd1
    case 'extract_feature_raw_boundingbox_all'
        [L, N] = bwlabel(I, 4);
        r = []; c = [];
        for i=1:N
            map = (i==L);
            r = [r find(max(map))];
            c = [c find(max(map'))];
        end
        out.x_min = min(r);
        out.x_max = max(r);
        out.y_min = min(c);
        out.y_max = max(c);
    case 'extract_feature_raw_boundingbox_givenchkpt'
        % row: row of checked point
        % col: column of checked point
        row = cmd2(1); 
        col = cmd2(2);
        if I(row,col)==0
            out = 0;
        else
            [L, N] = bwlabel(I, 4);
            map = (L(row,col)==L);
            r = find(max(map));
            c = find(max(map'));
            out.x_min = min(r);
            out.x_max = max(r);
            out.y_min = min(c);
            out.y_max = max(c);
        end
    case 'compute_feature_raw_boundingbox_incrementally'
        new = I;    % new pixels
        cum = cmd2; % accumulated feature vector
        if sum(sum(I))>0
            r = find(max(new));
            c = find(max(new'));
            out.x_min = min(min(r), cum.x_min);
            out.x_max = max(max(r), cum.x_max);
            out.y_min = min(min(c), cum.y_min);
            out.y_max = max(max(c), cum.y_max);
        else
            out = cum;
        end
    otherwise
        warning('Unsupport cmd: %s',cmd1);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [out] = imfeat_perimeter_algo(I, cmd1, cmd2)

switch cmd1
    case 'extract_feature_raw_perimeter_all'
        % calc using change algo
        cum = zeros(size(I,1), size(I,2));
        out = imfeat_perimeter_change_algo(I, cum);
    case 'extract_feature_raw_perimeter_givenchkpt'
        % row: row of checked point
        % col: column of checked point
        row = cmd2(1); 
        col = cmd2(2);
        if I(row,col)==0
            out = 0;
        else
            % find target area 'map'
            [L, N] = bwlabel(I, 4);
            map = (L(row,col)==L);
            % calc using change algo
            cum = zeros(size(I,1), size(I,2));
            out = imfeat_perimeter_change_algo(map, cum);
        end
    case 'compute_feature_raw_perimeter_incrementally'
        new = I;       % new pixels
        cum = cmd2{1}; % accumulated pixels
        per = cmd2{2}; % accumulated perimeter
        out = per + imfeat_perimeter_change_algo(new, cum);
    otherwise
        warning('Unsupport cmd: %s',cmd1);
end

end

function [out] = imfeat_perimeter_change_algo(new, cum)

% new: newly-added binary map
% cum: accumulated binary map
if 1
    out = imfeat_binary_get_perimeter_c(new', cum');
    out = double(out);
else
    % calc perimeter difference for each new pixel
    p = 0;
    cum = padarray(cum, [1 1]);    % enlarge 1 pxl to avoid bondary checking
    new = padarray(new, [1 1]);    % enlarge 1 pxl to avoid bondary checking
    for h = find(sum(new'==1))     % non-zero rows
        for w = find(new(h,:)==1)  % non-zero element
            % for each new pixel p
            p = p + 1;
            % (1) calc num of adjacent edge q with accumulated map
            q = 0;
            if cum(h-1, w)==1; q = q + 1; end
            if cum(h, w-1)==1; q = q + 1; end
            if cum(h, w+1)==1; q = q + 1; end
            if cum(h+1, w)==1; q = q + 1; end
            % (2) calc edge no change: psi(p) = 4 - 2{q:qAp^C(q)<=C(p)}
            psi(p) = 4 - 2*q;
            % (3) add each new pixel into cum for next loop
            cum(h,w) = 1;
        end
    end

    % accumulate perimeter change
    phi = 0;
    for i = 1:p
        phi = phi + psi(i);
    end
    out = phi;
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [out] = imfeat_eulerno_algo(I, cmd1, cmd2)

switch cmd1
    case 'extract_feature_raw_eulerno_all'
        % calc using change algo
        cum = zeros(size(I,1), size(I,2));
        out = imfeat_eulerno_change_algo(I, cum);
    case 'extract_feature_raw_eulerno_givenchkpt'
        % row: row of checked point
        % col: column of checked point
        row = cmd2(1); 
        col = cmd2(2);
        if I(row,col)==0
            out = 0;
        else
            % find target area 'map'
            [L, N] = bwlabel(I, 4);
            map = (L(row,col)==L);
            % calc using change algo
            cum = zeros(size(I,1), size(I,2));
            out = imfeat_eulerno_change_algo(map, cum);
        end
    case 'compute_feature_raw_eulerno_incrementally'
        new = I;       % new pixels
        cum = cmd2{1}; % accumulated pixels
        eul = cmd2{2}; % accumulated euler no
        out = eul + imfeat_eulerno_change_algo(new, cum);
    otherwise
        warning('Unsupport cmd: %s',cmd1);
end

end

function [out] = imfeat_eulerno_change_algo(new, cum)

% new: newly-added binary map
% cum: accumulated binary map
if 1
    out = imfeat_binary_get_eulerno_c(new', cum');
    out = double(out);
else    
    Q1 = {[1 0; 0 0], [0 1; 0 0], [0 0; 0 1], [0 0; 1 0]}; % quads with 1 one
    Q3 = {[0 1; 1 1], [1 0; 1 1], [1 1; 1 0], [1 1; 0 1]}; % quads with 3 ones
    Qd = {[0 1; 1 0], [1 0; 0 1]};                         % quads with diagnal ones
    N_Q1 = 4;
    N_Q3 = 4;
    N_Qd = 2;

    % calc Euler no difference for each new pixel
    p = 0;
    [H W] = size(cum);
    % enlarge 1 pxl to avoid bondary checking
    cum = [zeros(1,W+2); [zeros(H,1) cum zeros(H,1)]; zeros(1,W+2)];
    new = [zeros(1,W+2); [zeros(H,1) new zeros(H,1)]; zeros(1,W+2)];
    com = cum;
    h_idx = find(sum(new'==1));
    for h = h_idx      % non-zero rows
        w_idx = find(new(h,:)==1);
        for w = w_idx  % non-zero element
            % for each new pixel p
            p = p + 1;
            % (1) add each new pixel into com for later used in step 2
            com(h,w) = 1;
            % (2) match 3 kinds of 2x2 quads (Q1,Q3,Qd) with com(newly-combined) 
            %     and cum(previously-accumulated) seperately centered at p(h,w).
            %     So subindex y goes from -1 to 0, x from -1 to 0.
            %     if mached with com: score q plus 1.
            %     if mached with cum: score q minus 1.
            q1 = 0; q3 = 0; qd = 0;
            for y = -1:0
                for x = -1:0
                    sum_com = com(h+y,w+x) + com(h+y,w+x+1) + com(h+y+1,w+x) + com(h+y+1,w+x+1);
                    sum_cum = cum(h+y,w+x) + cum(h+y,w+x+1) + cum(h+y+1,w+x) + cum(h+y+1,w+x+1);
                    if sum_com==1; q1 = q1 + 1; end;
                    if sum_cum==1; q1 = q1 - 1; end;
                    if sum_com==3; q3 = q3 + 1; end;
                    if sum_cum==3; q3 = q3 - 1; end;
                    if (com(h+y,  w+x)==1 && com(h+y,  w+x+1)==0 && ...
                        com(h+y+1,w+x)==0 && com(h+y+1,w+x+1)==1) || ...
                       (com(h+y,  w+x)==0 && com(h+y,  w+x+1)==1 && ...
                        com(h+y+1,w+x)==1 && com(h+y+1,w+x+1)==0)
                        qd = qd + 1;
                    end
                    if (cum(h+y,  w+x)==1 && cum(h+y,  w+x+1)==0 && ...
                        cum(h+y+1,w+x)==0 && cum(h+y+1,w+x+1)==1) || ...
                       (cum(h+y,  w+x)==0 && cum(h+y,  w+x+1)==1 && ...
                        cum(h+y+1,w+x)==1 && cum(h+y+1,w+x+1)==0)
                        qd = qd - 1;
                    end     
                end
            end 
            % (3) cal Euler no change: psi(p) = 1/4 * (q1 - q3 + 2*qd)
            psi(p) = (q1 - q3 + 2*qd) / 4;
            % (4) add each new pixel into cum for next loop
            cum(h,w) = 1;
        end
    end
    
    % update Euler no change
    phi = 0;
    for i = 1:p
        phi = phi + psi(i);
    end
    out = phi;
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [out] = imfeat_hzcrossing_algo(I, cmd1, cmd2)

switch cmd1
    case 'extract_feature_raw_hzcrossing_all'
        % calc using change algo
        cum = zeros(size(I,1), size(I,2));
        out = imfeat_hzcrossing_change_algo(I, cum);
    case 'extract_feature_raw_hzcrossing_givenchkpt'
        % row: row of checked point
        % col: column of checked point
        row = cmd2(1); 
        col = cmd2(2);
        if I(row,col)==0
            out = 0;
        else
            % find target area 'map'
            [L, N] = bwlabel(I, 4);
            map = (L(row,col)==L);
            % calc using change algo
            cum = zeros(size(I,1), size(I,2));
            out = imfeat_hzcrossing_change_algo(map, cum);
        end
    case 'extract_feature_raw_hzcrossing_slicemedian'
        slice_no = length(cmd2);
        assert(slice_no > 0);
        if 0;
            h1 = find(sum(I'==1),1,'first');    % 1st non-zero row
            h2 = find(sum(I'==1),1,'last');     % last non-zeros row
        else
            h1 = 1;
            h2 = size(I,1);
        end
        h = h2 - h1 + 1;
        r = [];
        for i=1:slice_no
            assert(cmd2(i)<=1);
            % calc using change algo
            cum = zeros(size(I,1), size(I,2));
            % create a slice of image
            mask = cum;
            mask(round(h*cmd2(i)+h1-1),:) = 1;
            new = I & mask;
            r = [r sum(imfeat_hzcrossing_change_algo(new, cum))];
        end
        out = median(r);
    case 'compute_feature_raw_hzcrossing_incrementally'
        new = I;       % new pixels
        cum = cmd2{1}; % accumulated pixels
        hzc = cmd2{2}; % accumulated hzcrossing vector
        off = cmd2{3}; % offset between hzc & (new or cum)
        hzc_cum = zeros(1,size(I,1));
        hzc_cum(off+1:off+size(hzc,2)) = hzc;
        hzc_dif = imfeat_hzcrossing_change_algo(new, cum);
        out = hzc_cum + hzc_dif;
    otherwise
        warning('Unsupport cmd: %s',cmd1);
end

end

function [out] = imfeat_hzcrossing_change_algo(new, cum)

% new: newly-added binary map
% cum: accumulated binary map
if 1
    out = imfeat_binary_get_hzcrossing_c(new', cum');
    out = double(out);
else
    % calc hzcrossing vector difference for each new pixel
    p = 0;
    out = 0;
    % enlarge 1 pxl to avoid bondary checking
    [H W] = size(cum);
    cum = [zeros(1,W+2); [zeros(H,1) cum zeros(H,1)]; zeros(1,W+2)];
    new = [zeros(1,W+2); [zeros(H,1) new zeros(H,1)]; zeros(1,W+2)];
    for h = find(sum(new'==1))     % non-zero rows
        for w = find(new(h,:)==1)  % non-zero element
            % for each new pixel p
            p = p + 1;
            % (1) calc change by check adjacent pxl in accumulated map
            q = zeros(1, H);
            if (cum(h, w-1)==0 && cum(h, w+1)==0) q(h-1) = q(h-1) + 2; end % -1 is due to 1 pxl enlarge
            if (cum(h, w-1)==1 && cum(h, w+1)==1) q(h-1) = q(h-1) - 2; end % -1 is due to 1 pxl enlarge
            out = out + q;
            % (2) add each new pixel into cum for next loop
            cum(h,w) = 1;
        end
    end
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [out] = imfeat_convexhull_algo(I, cmd1, cmd2)

if sum(sum(I,1)>0)==1 || sum(sum(I,2)>0)
    out = sum(sum(I));
else
    p = 1;
    for h = 1:size(I,1)
       k = find(I(h,:)==1);
       n = length(k);
       x(p:p+n-1) = k;
       y(p:p+n-1) = h;
       p = p + n;
    end
    vi = convhull(x, y);
    out = polyarea(x(vi), y(vi));
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [out] = imfeat_holesize_algo(I, cmd1, cmd2)

[H,W] = size(I);
B = logical(I);

% fill up from edge of left side
i = 1;
while ~isempty(i)
    i = find(B(:,1)==0,1,'first');
    if ~isempty(i)
        B = imfill(B, [i,1], 4);
    end
end

% fill up from edge of right side
i = 1;
while ~isempty(i)
    i = find(B(:,W)==0,1,'first');
    if ~isempty(i)
        B = imfill(B, [i,W], 4);
    end
end

% fill up from edge of top side
i = 1;
while ~isempty(i)
    i = find(B(1,:)==0,1,'first');
    if ~isempty(i)
        B = imfill(B, [1,i], 4);
    end
end

% fill up from edge of bottom side
i = 1;
while ~isempty(i)
    i = find(B(H,:)==0,1,'first');
    if ~isempty(i)
        B = imfill(B, [H,i], 4);
    end
end

% rest unfilled pixels are holes
out = sum(sum(~B));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [out] = imfeat_reflectpointno_algo(I, cmd1, cmd2)

% minimum segment/perimeter ratio that will take into account
MIN_SEG2ALL_RATIO = 0.08;

B = logical(I);
[B, L] = bwboundaries(B,4,'noholes');

if size(B{1},1) >=9
    points = [B{1};B{1}(2:3,:)];   % it orders clockwisely
    no_points = size(points,1);
    seg_turn = false(1,no_points); % record segment turn label (0:RL,1:LR)
    seg_len = zeros(1,no_points);  % record segment length
    MIN_L = max(3, ceil(no_points*MIN_SEG2ALL_RATIO));
    l2r = 0;
    r2l = 0;
    s = 0; l = 0;
    pre_l = next_locates_at(points(1,:), points(2,:));
    pre_nonN_d = 'R'; % initial guess
    for i=2:no_points-1
        [cur_d, pre_l] = get_turn_direction(pre_l, points(i,:), points(i+1,:));
        if cur_d~='N'
            seq = [pre_nonN_d, cur_d];
            if seq(1)=='R' && seq(2)=='L'
                pre_nonN_d = cur_d;
                s = s + 1;
                seg_len(s) = l;
                l = 0;
            elseif seq(1)=='L' && seq(2)=='R'
                pre_nonN_d = cur_d;
                s = s + 1;
                seg_turn(s) = true;
                seg_len(s) = l;
                l = 0;
            end
        end
        l = l + 1;
    end
    
    % only keep segments longer than MIN_L to cal no of transition
    valid_idx = seg_len>0;
    seg_turn = seg_turn(valid_idx);
    seg_len = seg_len(valid_idx);
    valid_turn = seg_turn(seg_len>=MIN_L);
    out = 0;
    for i=1:length(valid_turn)-1
        if valid_turn(i)+valid_turn(i+1)==1
            out = out + 1;
        end
    end
    % normally, it is expected to be even
    out = ceil(out/2)*2;
else
    out = 0;
end

end

function [out] = imfeat_reflectpointno_algo_old(I, cmd1, cmd2)

B = logical(I);
[B, L] = bwboundaries(B,4,'noholes');

if size(B{1},1) >=9
    points = [B{1};B{1}(2:3,:)];
    no_points = size(points,1);
    l2r = 0;
    r2l = 0;
    pre_l = next_locates_at(points(1,:), points(2,:));
    pre_nonN_d = 'R'; % we will conpensate it if this guess is wrong
    for i=2:no_points-1
        [cur_d, pre_l] = get_turn_direction(pre_l, points(i,:), points(i+1,:));
        if cur_d~='N'
            switch [pre_nonN_d, cur_d]
                case 'RL'
                    pre_nonN_d = cur_d;
                    r2l = r2l + 1;
                case 'LR'
                    pre_nonN_d = cur_d;
                    l2r = l2r + 1;
            end
        end
    end
    out = l2r + r2l;
    % since it must be even, the extra one cause it as odd is from initial
    % wrong guess 'R', so subtract 1 if it's odd here.
    out = out - mod(out,2);
else
    out = 0;
end

end

function [d, nxt_loc] = get_turn_direction(cur_loc, cur_xy, nxt_xy)

    nxt_loc = next_locates_at(cur_xy, nxt_xy);
    loc_pattern = [cur_loc, nxt_loc];
    switch loc_pattern
        case {'BR','RT','TL','LB'}
            d = 'L'; % turn left
        case {'LT','BL','RB','TR'}
            d = 'R'; % turn right
        otherwise
            d = 'N'; % no turn
    end
    
end

function loc = next_locates_at(cur_xy, nxt_xy)

    if nxt_xy(1)==cur_xy(1)
        if nxt_xy(2)<cur_xy(2)
            loc = 'L';
        else
            loc = 'R';
        end
    elseif nxt_xy(2)==cur_xy(2)
        if nxt_xy(1)<cur_xy(1)
            loc = 'T';
        else
            loc = 'B';
        end
    end
    
end
