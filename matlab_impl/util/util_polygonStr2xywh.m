function [x,y,w,h] = util_polygonStr2xywh(polygon)

% polygon = '(352,909);(929,909);(928,958);(816,968);(352,970)';
remain = polygon;
p = [];
while true
    [polygon, remain] = strtok(remain, '();');
    if isempty(polygon),  break;  end
    p = [p; str2double(regexp(polygon, ',', 'split'))];
end

maxp = max(p);
minp = min(p);
x = minp(1);
y = minp(2);
w = maxp(1) - x;
h = maxp(2) - y;

end