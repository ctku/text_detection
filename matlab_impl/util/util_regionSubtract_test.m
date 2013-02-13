function [result] = util_regionSubtract_test

I = [1 1 1 1 1 1 1;
     1 1 1 1 1 1 1;
     1 2 2 2 2 2 1;
     1 2 2 2 2 2 1;
     1 2 2 2 2 2 1;
     1 2 2 2 2 2 1;
     1 2 2 2 2 2 1;
     1 2 2 2 2 2 1;
     1 1 1 1 1 1 1;
     1 1 1 1 1 1 1];
r_all.x = 2;
r_all.y = 3;
r_all.w = 5;
r_all.h = 6;

% test cases 1~9
for x=[1 3 5]
    for y=[1 4 8]
        r_inv.x = x;
        r_inv.y = y;
        r_inv.w = 3;
        r_inv.h = 3;
        r(x,y) = util_regionSubtract(r_all, r_inv);
    end
end
assert(r(1,1).x==2 && r(1,1).y==4 && r(1,1).w==5 && r(1,1).h==5 && ...
       r(1,4).x==4 && r(1,4).y==3 && r(1,4).w==3 && r(1,4).h==6 && ...
       r(1,8).x==2 && r(1,8).y==3 && r(1,8).w==5 && r(1,8).h==5 && ...
       r(3,1).x==2 && r(3,1).y==4 && r(3,1).w==5 && r(3,1).h==5 && ...
       r(3,4).x==2 && r(3,4).y==7 && r(3,4).w==5 && r(3,4).h==2 && ...
       r(3,8).x==2 && r(3,8).y==3 && r(3,8).w==5 && r(3,8).h==5 && ...
       r(5,1).x==2 && r(5,1).y==4 && r(5,1).w==5 && r(5,1).h==5 && ...
       r(5,4).x==2 && r(5,4).y==3 && r(5,4).w==3 && r(5,4).h==6 && ...
       r(5,8).x==2 && r(5,8).y==3 && r(5,8).w==5 && r(5,8).h==5);

% test cases 10,12
for x=[1 5]
    r_inv.x = x;
    r_inv.y = 1;
    r_inv.w = 3;
    r_inv.h = 10;
    r(x,1) = util_regionSubtract(r_all, r_inv);
end
assert(r(1,1).x==4 && r(1,1).y==3 && r(1,1).w==3 && r(1,1).h==6 && ...
       r(5,1).x==2 && r(5,1).y==3 && r(5,1).w==3 && r(5,1).h==6);
   
% test cases 11,13
for y=[1 7]
    r_inv.x = 1;
    r_inv.y = y;
    r_inv.w = 7;
    r_inv.h = 4;
    r(1,y) = util_regionSubtract(r_all, r_inv);
end
assert(r(1,1).x==2 && r(1,1).y==5 && r(1,1).w==5 && r(1,1).h==4 && ...
       r(1,7).x==2 && r(1,7).y==3 && r(1,7).w==5 && r(1,7).h==4);
   
% test cases 14
r_inv.x = 1;
r_inv.y = 4;
r_inv.w = 7;
r_inv.h = 3;
r(1,1) = util_regionSubtract(r_all, r_inv);
assert(r(1,1).x==2 && r(1,1).y==7 && r(1,1).w==5 && r(1,1).h==2);

% test cases 15
r_inv.x = 4;
r_inv.y = 1;
r_inv.w = 2;
r_inv.h = 10;
r(1,1) = util_regionSubtract(r_all, r_inv);
assert(r(1,1).x==2 && r(1,1).y==3 && r(1,1).w==2 && r(1,1).h==6);

% test cases 16
r_inv.x = 1;
r_inv.y = 1;
r_inv.w = 7;
r_inv.h = 10;
r(1,1) = util_regionSubtract(r_all, r_inv);
assert(r(1,1).x==0 && r(1,1).y==0 && r(1,1).w==0 && r(1,1).h==0);

% test no intersection
r_inv.x = 3;
r_inv.y = 9;
r_inv.w = 2;
r_inv.h = 3;
r(1,1) = util_regionSubtract(r_all, r_inv);
assert(r(1,1).x==2 && r(1,1).y==3 && r(1,1).w==5 && r(1,1).h==6);

result = 1

end
