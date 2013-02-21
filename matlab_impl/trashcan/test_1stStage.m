addpath_for_me;
clear;

PROB_MIN = 0.2;
DELTA_MIN = 0.1;
LEN_MIN = 2;

% testing data preparation
fmap=...
[1 1 1 1 1;
 0 2 2 1 1;
 0 3 3 1 1;
 2 4 3 1 1;
 3 4 3 1 1;
 0 5 4 2 1;
 0 6 5 2 1;
 0 7 6 3 1];
prob=...
[0.5 0.6 0.9 0.2 0.2; %Z
 0   0.9 0.9 0.2 0.2; %A
 0   0.9 0.3 0.2 0.2; %N
 0   0.4 0.3 0.2 0.2; %U
 0.9 0.4 0.3 0.2 0.2; %-
 0   0.5 0.9 0.7 0.2; %S
 0   0.5 0.9 0.7 0.2; %S
 0   0.1 0.1 0.1 0.2];%-
goals=...
[0 0 1 0 0;
 0 1 1 0 0;
 0 1 0 0 0;
 0 0 0 0 0;
 1 0 0 0 0;
 0 0 1 0 0;
 0 0 1 0 0;
 0 0 0 0 0];
N=max(fmap);
for t=1:5
    for n=1:N(t)
        TR{t,n}.par = [];
        TR{t,n}.chd = [];
        TR{t,n}.chd_no = 0;
    end
end
TR{1,1}.raw = [1 1 1];
TR{1,2}.raw = [1 1 4];
TR{1,3}.raw = [1 1 5];
TR{2,1}.raw = [2 1 1];
TR{2,2}.raw = [2 1 2];
TR{2,3}.raw = [2 1 3];
TR{2,4}.raw = [2 2 4];
TR{2,5}.raw = [2 1 6];
TR{2,6}.raw = [2 1 7];
TR{2,7}.raw = [2 1 8];
TR{3,1}.raw = [3 1 1];
TR{3,2}.raw = [3 1 2];
TR{3,3}.raw = [3 3 3];
TR{3,4}.raw = [3 1 6];
TR{3,5}.raw = [3 1 7];
TR{3,6}.raw = [3 1 8];
TR{4,1}.raw = [4 5 1];
TR{4,2}.raw = [4 2 6];
TR{4,3}.raw = [4 1 8];
TR{5,1}.raw = [5 8 1];


for t=1:4
    for n=1:N(t)
        col = t + 1;
        row = TR{t,n}.raw(3);
        while fmap(row,col)==0
            col = col + 1;
        end
        par = [double(col), fmap(row,col)];
        TR{t,n}.par = par;
        TR{par(1),par(2)}.chd = [TR{par(1),par(2)}.chd; t n];
        TR{par(1),par(2)}.chd_no = TR{par(1),par(2)}.chd_no + 1;
    end
end

chk = zeros(8,5);
% find first non empty ER
init_t = 1;
init_r = 1;
while isequal(TR{init_t,init_r},[])
    init_t = init_t + 1;
end

cmap = zeros(8,5); % checked map (mark as 1 if prob is obtained)
pmap = zeros(8,5); % probability map
qmap = zeros(8,5); % qualify map
for r = 1:8
    for t = 1:5
        if fmap(r,t)==0 || cmap(r,t)~=0
            continue;
        end
        ER = TR{t,fmap(r,t)};
        % (1) get posterior prob. 
        %     mark current ER as checked (with 1)
        pmap(ER.raw(3):ER.raw(3)+ER.raw(2)-1,t) = prob(r,t);
        cmap(ER.raw(3):ER.raw(3)+ER.raw(2)-1,t) = 1;
        % (2) check if it's like a char
        if t>=2
            if pmap(r,t)>PROB_MIN
                if (pmap(r,t)-pmap(r,t-1))>DELTA_MIN
                    % it's like a char. Mark qualify map as 1
                    qmap(ER.raw(3):ER.raw(3)+ER.raw(2)-1,t) = 1;%qmap(ER.raw(3):ER.raw(3)+ER.raw(2)-1,t-1) + 1;
                end
            else
                % it's not like a char, implying so are parents
                % mark parents ER as skipped (with 2) till root
                for c=t+1:5
                    ER = TR{c,fmap(r,c)};
                    cmap(ER.raw(3):ER.raw(3)+ER.raw(2)-1,c) = 2;
                    pmap(ER.raw(3):ER.raw(3)+ER.raw(2)-1,c) = 10^(-5);
                end
                break; % leave (for t=init_t:5)
            end
        end
    end
end

qmap-goals



