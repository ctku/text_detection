function test
f = figure('position', [100 200 200 200]);
%Create an mwsamp control and 
%register the Click event
h = actxcontrol('mwsamp.mwsampctrl.2', ...
    [0 0 200 200], f, ...
    {'MouseDown' 'mymousedown'});
h.eventlisteners
end

