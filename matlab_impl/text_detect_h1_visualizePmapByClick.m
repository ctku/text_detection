


load('../../_output_files/Output_img/Parsed_mat/[003] aPICT0036.JPG_200x200_reverse_0.mat'); 

% fill up -1 with previous postp
for row = 1:size(pmap,1)
    postp = pmap(row,:);
    in_valley = 0;
    for col=2:length(postp)-1
        if postp(col)==-1
            if postp(col-1)>=0 || in_valley
                in_valley = 1;
                postp(col) = postp(col-1);
            end
        else
            in_valley = 0;
        end
    end
    pmap(row,:) = postp;
end

figure(1);contour(pmap);figure(gcf);
while(1)
    figure(1);
    [col,row] = ginput(2);
    if col(1)==col(2) && row(1)==row(2)
       col = col; 
    end
    col = ceil(col(1));
    row = ceil(row(1));
    r = ft_ert.feat_raw.fmap(row,col);
    t = col;
    if r>0
        fst = ft_ert.feat_raw.tree{t,r}.raw(3);
        num = ft_ert.feat_raw.tree{t,r}.raw(2);
        vec = ft_ert.feat_raw.pxls(fst:fst+num-1)+1; % correct start index as Matlab sense
        TR_data = false(1, ft_ert.w*ft_ert.h);
        TR_data(vec) = 1;
        data = reshape(TR_data, ft_ert.w, ft_ert.h)'; % row-wised reshape
        figure(2); imshow(data); title(['ER=(' num2str(t) ',' num2str(r) ') fst=(' num2str(fst) ')']); pause(1);
    else
        figure(2); imshow(false(ft_ert.h,ft_ert.w)); title('No ER is found'); pause(1);
    end
end