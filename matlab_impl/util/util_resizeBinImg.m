function [out] = util_resizeBinImg(I, way, resize)

switch way
    case 'fit_with_keeping_ar'
        out = fit_with_keeping_ar(I, resize);
    case 'fit_with_keeping_ar_and_zero_padding'
        out = fit_with_keeping_ar(I, resize);
        [h,w] = size(out);
        W = resize(1);
        H = resize(2);
        if W~=w
            pad_x = ceil((W-w)/2);
            out = padarray(out, [0 pad_x]);
        elseif H~=h
            pad_y = ceil((H-h)/2);
            out = padarray(out, [pad_y 0]);
        end
        out = out(1:H,1:W);
end
            
end

function [out] = fit_with_keeping_ar(I, resize)

[H,W] = size(I);

% resize and keep aspect ratio
rt_w = resize(1) / W; 
rt_h = resize(2) / H;
% smaller ratio will ensure that the image fits in the view
if rt_w <= rt_h
    W = round(W * rt_w);
    H = round(H * rt_w);
else
    W = round(W * rt_h);
    H = round(H * rt_h);        
end
out = imresize(I, [H W]);

end