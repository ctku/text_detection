function [param] = imfeat_binary(cmd1, cmd2, param)

switch cmd1
    case 'initialization'
        param.rd.mode = 'binary';
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
    case {'extract_feature_raw_shapecontext_all'}
        param.feat_raw = imfeat_shapecontext_algo(param.image, cmd1, cmd2);
    otherwise
        warning('Unsupport cmd: %s',cmd1);
end

end

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

if sum(sum(I,1)>0)==1 || sum(sum(I,2)>0)==1
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
MIN_SEG2ALL_RATIO = 0.001;

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [out] = imfeat_shapecontext_algo(I, cmd1, cmd2)

if isempty(cmd2)
    % default values
    nsamp = 50;
    nbins_theta = 12;
    nbins_r = 5;
    r_inner = 1/8;
    r_outer = 2;
    show_plot = 0;
else
    nsamp = cmd2(1);
    nbins_theta = cmd2(2);
    nbins_r = cmd2(3);
    r_inner = cmd2(4);
    r_outer = cmd2(5); 
    show_plot = cmd2(6);
end

I = padarray(I, [2 2]);
[x,y,t] = sc_bdry_extract(I);
nsamp1 = length(x);
if nsamp1>=nsamp
   [x,y,t] = sc_get_samples(x,y,t,nsamp);
else
   error('shape #1 doesn''t have enough samples')
end
Bsamp = [x y]';
Tsamp = zeros(1,nsamp);
mean_dist = [];
out_vec = zeros(1,nsamp);
[out, mean_dist] = sc_compute(Bsamp, Tsamp, mean_dist, nbins_theta, nbins_r, r_inner, r_outer, out_vec, show_plot);

end

function [x,y,t,c] = sc_bdry_extract(V)
% [x,y,t,c]=bdry_extract_3(V);
% compute (r,theta) histograms for points along boundary of single 
% region in binary image V 
if isequal(size(V),[64,7])
    V = V;
end
% extract a set of boundary points w/oriented tangents
%sig=1;
%Vg=gauss_sig(V,sig);
Vg=double(V); % if no smoothing is needed
c=contourc(Vg,[.5 .5]);
if isempty(c)
    B = bwboundaries(Vg,4,'noholes');
    c = B{1}';
end
[G1,G2]=gradient(Vg);

% need to deal with multiple contours (for objects with holes)
fz=c(1,:)~=0.5;
c(:,find(~fz))=NaN;
B=c(:,find(fz));

npts=size(B,2);
t=zeros(npts,1);
for n=1:npts
   x0=min(round(B(1,n)),size(Vg,2));
   y0=min(round(B(2,n)),size(Vg,1));
   t(n)=atan2(G2(y0,x0),G1(y0,x0))+pi/2;
end

x=B(1,:)';
y=B(2,:)';

end

function [xi,yi,ti] = sc_get_samples(x,y,t,nsamp)
% [xi,yi,ti]=get_samples_1(x,y,t,nsamp);
%
% uses Jitendra's sampling method

N=length(x);
k=3;
Nstart=min(k*nsamp,N);

ind0=randperm(N);
ind0=ind0(1:Nstart);

xi=x(ind0);
yi=y(ind0);
ti=t(ind0);
xi=xi(:);
yi=yi(:);
ti=ti(:);

d2=dist2([xi yi],[xi yi]);
d2=d2+diag(Inf*ones(Nstart,1));

s=1;
while s
   % find closest pair
   [a,b]=min(d2);
   [c,d]=min(a);
   I=b(d);
   J=d;
   % remove one of the points
   xi(J)=[];
   yi(J)=[];
   ti(J)=[];
   d2(:,J)=[];
   d2(J,:)=[];
   if size(d2,1)==nsamp
      s=0;
   end
end

end

function [BH,mean_dist] = sc_compute(Bsamp, Tsamp, mean_dist, nbins_theta, nbins_r, r_inner, r_outer, out_vec, show_plot)
% [BH,mean_dist]=sc_compute(Bsamp,Tsamp,mean_dist,nbins_theta,nbins_r,r_inner,r_outer,out_vec);
%
% compute (r,theta) histograms for points along boundary 
%
% Bsamp is 2 x nsamp (x and y coords.)
% Tsamp is 1 x nsamp (tangent theta)
% out_vec is 1 x nsamp (0 for inlier, 1 for outlier)
%
% mean_dist is the mean distance, used for length normalization
% if it is not supplied, then it is computed from the data
%
% outliers are not counted in the histograms, but they do get
% assigned a histogram
%

nsamp=size(Bsamp,2);
in_vec=out_vec==0;

% compute r,theta arrays
r_array=real(sqrt(dist2(Bsamp',Bsamp'))); % real is needed to
                                          % prevent bug in Unix version
theta_array_abs=atan2(Bsamp(2,:)'*ones(1,nsamp)-ones(nsamp,1)*Bsamp(2,:),Bsamp(1,:)'*ones(1,nsamp)-ones(nsamp,1)*Bsamp(1,:))';
theta_array=theta_array_abs-Tsamp'*ones(1,nsamp);

% create joint (r,theta) histogram by binning r_array and
% theta_array

% normalize distance by mean, ignoring outliers
if isempty(mean_dist)
   tmp=r_array(in_vec,:);
   tmp=tmp(:,in_vec);
   mean_dist=mean(tmp(:));
end
r_array_n=r_array/mean_dist;

% use a log. scale for binning the distances
r_bin_edges=logspace(log10(r_inner),log10(r_outer),5);
r_array_q=zeros(nsamp,nsamp);
for m=1:nbins_r
   r_array_q=r_array_q+(r_array_n<r_bin_edges(m));
end
fz=r_array_q>0; % flag all points inside outer boundary

% put all angles in [0,2pi) range
theta_array_2 = rem(rem(theta_array,2*pi)+2*pi,2*pi);
% quantize to a fixed set of angles (bin edges lie on 0,(2*pi)/k,...2*pi
theta_array_q = 1+floor(theta_array_2/(2*pi/nbins_theta));

nbins=nbins_theta*nbins_r;
BH=zeros(nsamp,nbins);
for n=1:nsamp
   fzn=fz(n,:)&in_vec;
   Sn=sparse(theta_array_q(n,fzn),r_array_q(n,fzn),1,nbins_theta,nbins_r);
   BH(n,:)=Sn(:)';

   if show_plot == 1
    h = figure(1);  
    axs = subplot(2,1,1);  
    axis equal;  
    point = [Bsamp(1,n) Bsamp(2,n)];  
    sc_DrawPolar(Bsamp,point,r_inner*mean_dist,r_outer*mean_dist,nbins_theta,nbins_r);  
    % draw 2d histogram  
    subplot(2,1,2);  
    axis equal;  
    hold on;  

    temp = flipud(full(Sn)');  
    imagesc(temp);colormap(gray);  
    axis image;  
    xlabel('{/theta}');  
    ylabel('log(r)');  
    for i=1:size(temp,2)  
        for j=1:size(temp,1)  
            if temp(j,i)  
                text(i,j,sprintf('%d',temp(j,i)),'Color','r');  
            end  
        end  
    end  
    hold off;  
    %
    pause;  
    close(h);
   end
   
end

end

function out = dist2(x, c)

[ndata, dimx] = size(x);
[ncentres, dimc] = size(c);
if dimx ~= dimc
	error('Data dimension does not match dimension of centres')
end
out = (ones(ncentres, 1) * sum((x.^2)', 1))' + ...
  		ones(ndata, 1) * sum((c.^2)',1) - ...
  		2.*(x*(c'));
    
end

function sc_DrawPolar(samp,point,r_min,r_max,nbins_theta,nbins_r)
%SCDRAWPOLAR draw a polar on the center point
%   point           - the center point
%   r_min           - min radius
%   r_max           - max radius
%   nbins_theta     - theta divide
%   nbins_r         - r divide
%   fig_handle      - draw the diagram on which figure
gca;
hold on;

plot(samp(1,:)',samp(2,:)','r.');
plot(point(1),point(2),'ko');

r_bin_edges=logspace(log10(r_min),log10(r_max),nbins_r);

% draw circles
th = 0 : pi / 50 : 2 * pi;
xunit = cos(th);
yunit = sin(th);
for i=1:length(r_bin_edges)
    line(xunit * r_bin_edges(i) + point(1), ...
                    yunit * r_bin_edges(i) + point(2), ...
        'LineStyle', ':', 'Color', 'k', 'LineWidth', 1);
end

% draw spokes
th = (1:nbins_theta) * 2*pi / nbins_theta;
cs = [cos(th);zeros(1,size(th,2))];
sn = [sin(th);zeros(1,size(th,2))];
line(r_max*cs + point(1), r_max*sn + point(2),'LineStyle', ':', ...
    'Color', 'k', 'LineWidth', 1);

axis equal;
axis off;
hold off;

end







