function text_detect_v3_visualizeByDrawRegionInImg(type, folder_name, cmd2)

% type:
%   2: show "char" rectangles in images
%   1: show "word" rectangles in images
%   0: show "non-char" rectangles in images

addpath_for_me;

% dataset initialization
ds_eng = [];
ds_eng = imdataset('init', 'ICDAR2003RobustReading', ds_eng);
switch type
    case 0
        ds_eng = imdataset('get_train_dataset_random_nonchar', cmd2, ds_eng);
    case 1
        ds_eng = imdataset('get_train_dataset_defxml_word', '', ds_eng);
    case 2
        ds_eng = imdataset('get_train_dataset_defxml_char', '', ds_eng);
end

for i=1:ds_eng.no
    % prepare for output image path
    path = util_changeFn(ds_eng.fn_list{i}, 'cd .._with_filename', '');
    path = util_changeFn(path, 'cd _mkdir_with_filename', '_output_files');
    path = util_changeFn(path, 'cd _mkdir_with_filename', folder_name);
    
    % trick of drawing rectangle
    % (1) show image on figure
    set(figure, 'Position', [100, 100, ds_eng.res(i).w, ds_eng.res(i).h]);
    imagesc(imread(ds_eng.fn_list{i}));
    axis off; hold on;
    % (2) draw rectangle on it
    for r=1:ds_eng.rect_region_no(i)
        rect = ds_eng.rect{i,r};
        rectangle('position',int32([rect.x rect.y rect.w rect.h]), 'EdgeColor','yellow', 'linewidth',3);
        rectangle('position',int32([rect.x rect.y rect.w rect.h]), 'EdgeColor','black', 'linewidth',1);
    end
    % (3) read figure buffer and save to jpg
    [X, map] = frame2im(getframe(gca));
    close(gcf);
    imwrite(X, path, 'jpeg')
    %break; % open for debugging
end

end