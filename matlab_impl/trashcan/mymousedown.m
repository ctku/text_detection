function mymousedown(varargin)

x = double(varargin{5});
y = double(varargin{6})
fprintf('Single click on (x,y)=(%d,%d)\n', x, y);
% disp('The X position is: ')
% double(varargin{5})
% disp('The Y position is: ')
% double(varargin{6})
figure(4);
plot(x,y);

end