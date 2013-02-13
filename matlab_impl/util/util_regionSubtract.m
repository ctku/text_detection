function [r_out] = util_regionSubtract(r_all, r_inv)

% all region
x1 = r_all.x;
x2 = r_all.x + r_all.w - 1;
y1 = r_all.y;
y2 = r_all.y + r_all.h - 1;
% invalid region
x1i = r_inv.x;
x2i = r_inv.x + r_inv.w - 1;
y1i = r_inv.y;
y2i = r_inv.y + r_inv.h - 1;
% create checking patterns
i_at_l = (x1i<=x1);
i_at_t = (y1i<=y1);
i_at_r = (x2i>=x2);
i_at_b = (y2i>=y2);
no_intersection = (x2i<x1) || (x2<x1i) || (y2i<y1) || (y2<y1i);
chk_pattern = [i_at_l, i_at_t, i_at_r, i_at_b];

% 1st index => region of 1:left 2:top 3:right 4:bottom
% 2nd index => rect coordinate of 1:left 2:top 3:right 4:bottom 5:size
a = zeros(4,5); 
no_output = 0;

% handle case by case
if no_intersection
    r_out = r_all;
else
    if isequal(chk_pattern,[1 1 0 0])
        a(3,1:4) = [x2i+1, y1   , x2   , y2   ];
        a(4,1:4) = [x1   , y2i+1, x2   , y2   ];
    elseif isequal(chk_pattern,[0 1 0 0])
        a(1,1:4) = [x1   , y1   , x1i-1, y2   ];
        a(3,1:4) = [x2i+1, y1   , x2   , y2   ];
        a(4,1:4) = [x1   , y2i+1, x2   , y2   ];
    elseif isequal(chk_pattern,[0 1 1 0])
        a(1,1:4) = [x1   , y1   , x1i-1, y2   ];
        a(4,1:4) = [x1   , y2i+1, x2   , y2   ];
    elseif isequal(chk_pattern,[0 0 1 0])
        a(1,1:4) = [x1   , y1   , x1i-1, y2   ];
        a(2,1:4) = [x1   , y1   , x2   , y1i-1];
        a(4,1:4) = [x1   , y2i+1, x2   , y2   ];
    elseif isequal(chk_pattern,[0 0 1 1])
        a(1,1:4) = [x1   , y1   , x1i-1, y2   ];
        a(2,1:4) = [x1   , y1   , x2   , y1i-1];
    elseif isequal(chk_pattern,[0 0 0 1])
        a(1,1:4) = [x1   , y1   , x1i-1, y2   ];
        a(2,1:4) = [x1   , y1   , x2   , y1i-1];
        a(3,1:4) = [x2i+1, y1   , x2   , y2   ];
    elseif isequal(chk_pattern,[1 0 0 1])
        a(2,1:4) = [x1   , y1   , x2   , y1i-1];
        a(3,1:4) = [x2i+1, y1   , x2   , y2   ];
    elseif isequal(chk_pattern,[1 0 0 0])
        a(2,1:4) = [x1   , y1   , x2   , y1i-1];
        a(3,1:4) = [x2i+1, y1   , x2   , y2   ];
        a(4,1:4) = [x1   , y2i+1, x2   , y2   ];
    elseif isequal(chk_pattern,[0 0 0 0])
        a(1,1:4) = [x1   , y1   , x1i-1, y2   ];
        a(2,1:4) = [x1   , y1   , x2   , y1i-1];
        a(3,1:4) = [x2i+1, y1   , x2   , y2   ];
        a(4,1:4) = [x1   , y2i+1, x2   , y2   ];
    elseif isequal(chk_pattern,[1 1 0 1])
        a(3,1:4) = [x2i+1, y1   , x2   , y2   ];
    elseif isequal(chk_pattern,[1 1 1 0])
        a(4,1:4) = [x1   , y2i+1, x2   , y2   ];
    elseif isequal(chk_pattern,[0 1 1 1])
        a(1,1:4) = [x1   , y1   , x1i-1, y2   ];
    elseif isequal(chk_pattern,[1 0 1 1])
        a(2,1:4) = [x1   , y1   , x2   , y1i-1];
    elseif isequal(chk_pattern,[1 0 1 0])
        a(2,1:4) = [x1   , y1   , x2   , y1i-1];
        a(4,1:4) = [x1   , y2i+1, x2   , y2   ];
    elseif isequal(chk_pattern,[0 1 0 1])
        a(1,1:4) = [x1   , y1   , x1i-1, y2   ];
        a(3,1:4) = [x2i+1, y1   , x2   , y2   ];
    elseif isequal(chk_pattern,[1 1 1 1])
        % no region left
        no_output = 1;
    else
        assert(1==0);
    end

    % calc size
    w = a(:,3) - a(:,1) + 1;
    h = a(:,4) - a(:,2) + 1;
    a(:,5) = w.*h;
    [val idx] = max(a(:,5));

    % calc output region
    if (no_output==0)
        r_out.x = a(idx,1);
        r_out.y = a(idx,2);
        r_out.w = a(idx,3) - a(idx,1) + 1;
        r_out.h = a(idx,4) - a(idx,2) + 1;
    else
        r_out.x = 0;
        r_out.y = 0;
        r_out.w = 0;
        r_out.h = 0;
    end
end

end
