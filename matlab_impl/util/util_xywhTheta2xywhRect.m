function [x,y,w,h] = util_xywhTheta2xywhRect(x,y,w,h,theta,max_w,max_h)

% move centroid to origin
cx = x + w*0.5;
cy = y + h*0.5;

% form input matrix
A = [x     y;
     x+w-1 y;
     x+w-1 y+h-1;
     x     y+h-1]';
A(1,:) = A(1,:) - cx;
A(2,:) = A(2,:) - cy;

% form rotation matrix
R = [cos(theta) sin(theta);
    -sin(theta) cos(theta)];

% for rotated matrx
B = R*A;

% move centroid back to original place
B(1,:) = B(1,:) + cx;
B(2,:) = B(2,:) + cy;

% calculate output
min_x = max(floor(min(B(1,:))),1);
min_y = max(floor(min(B(2,:))),1);
max_x = min(ceil(max(B(1,:))),max_w);
max_y = min(ceil(max(B(2,:))),max_h);
x = min_x;
y = min_y;
w = max_x - min_x + 1;
h = max_y - min_y + 1;

end