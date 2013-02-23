function test
% f = figure('position', [100 200 200 200]);

% %Create an mwsamp control and 
% %register the Click event
% h = actxcontrol('mwsamp.mwsampctrl.2', ...
%     [0 0 20 200], f, ...
%     {'MouseDown' 'mymousedown'});
% h.eventlisteners
imshow(false(100,100));
[x,y] = ginput(4)



end

