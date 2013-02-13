function text_detect_a3_1stStage_Classify_v4()

close all;
addpath_for_me;
tic
% Input parameter
% fd = 'ryoungt_05.08.2002'; fn = 'qPICT0011'; resize = [200 200];
fd = 'apanar_06.08.2002'; fn = 'IMG_1291'; resize = [0 0];

% 1st stage classifier parameters
rule_param.PROB_MIN = 0.2;
rule_param.DELTA_MIN = 0.1;

a = clock;
time_label = sprintf('[%02d%02d_%02d%02d]', a(2), a(3), a(4), a(5));
path = util_changeFn('','cd _mkdir','_output_files');
string_fr = [fn '_' num2str(resize(1)) 'x' num2str(resize(2))];
in_path = path;
out_path = util_changeFn(path,'cd _mkdir',[string_fr '_ER_candidate_img_' time_label]);
    
for reverse = 0:1

    load([in_path string_fr '_reverse_' num2str(reverse) '.mat']); 
    
    % find index of ER cadidates to be char region
    idx = [];
    for row = 1:size(pmap,1)
        postp = pmap(row,:);
        for col=2:length(postp)-1
            if postp(col) >= rule_param.PROB_MIN && ...
               (postp(col)-postp(col-1)) > rule_param.DELTA_MIN && ...
               (postp(col)-postp(col+1)) > rule_param.DELTA_MIN
                idx(imap_t(row,col),imap_r(row,col)) = 1;
            end
        end
    end

    % save ER candidates as images
    p = 0;
    for row=1:size(idx,1)
        for col=1:size(idx,2)
            if idx(row,col)==0
                continue;
            end

            % get ER data
            fst = ft_ert.feat_raw.tree{row,col}.raw(3);
            num = ft_ert.feat_raw.tree{row,col}.raw(2);
            vec = ft_ert.feat_raw.pxls(fst:fst+num-1)+1; % correct start index as Matlab sense
            TR_data = false(1, ft_ert.w*ft_ert.h);
            TR_data(vec) = 1;
            data = reshape(TR_data, ft_ert.w, ft_ert.h)'; % row-wised reshape

            % save ER as image
            s = [out_path 'ER_(' num2str(row) ',' num2str(col) ')_reverse_' num2str(reverse) '.jpg'];
            imwrite(data, s, 'jpeg')
            p = p + 1;
        end
    end
    % save original image (for reference)
    s = [out_path '__[1]original_image_reverse_' num2str(reverse) '.jpg'];
    if reverse == 0
        original_img = ft_ert.image;
    else
        original_img = 255 - ft_ert.image;
    end
    imwrite(original_img, s, 'jpeg')

    % save normal MSER (for reference)
    im = [];
    im = imfeat('init', 'mser', im);
    im = imfeat('set_image', original_img, im);
    im = imfeat('convert', '', im);
    mser_param = '';
    im = imfeat('extract_feature_raw', mser_param, im);
    set(figure, 'Position', [100, 100, im.w, im.h]);
    imagesc(im.image);
    axis off; hold on;
    pause(1);
    plot(im.feat_raw, 'showEllipses',false, 'showPixelList',true);
    [X, map] = frame2im(getframe(gca));
    s = [out_path '__[2]mser_image_reverse_' num2str(reverse) '.jpg'];
    imwrite(X, s, 'jpeg')
    hold off;
    close(gcf);
    
    % save selected vs total ER info (for reference)
    total_ER_no = sum(ft_ert.feat_raw.size);
    s = [out_path '__[3]no_of_ER_(slected,total)=(' num2str(p) ',' num2str(total_ER_no) ')_reverse_' num2str(reverse) '.jpg'];
    imwrite(data, s, 'jpeg')
end
toc
end
