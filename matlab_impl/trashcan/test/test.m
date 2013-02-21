addpath '../imdataset';
addpath '../imfeat';
addpath '../util';

img_path = 'IMG_2616.JPG';
if 1
    h = imshow(img_path);
    hp = impixelinfo;
    set(hp,'Position',[5 1 300 20]);
end

if 0
    I = rgb2gray(imread(img_path));
    ft_ert = [];
    ft_ert = imfeat('init', 'ertree', ft_ert);
    ft_ert = imfeat('set_image', I, ft_ert);
    ft_ert = imfeat('extract_feature_raw_get_all_preproc', '', ft_ert);
    save('ft_ert.mat','ft_ert');
else
    load('ft_ert.mat');
end
p = [111 444];
p_idx = uint32(p(2)*1280+p(1));
found = 0;
for t=1:256
    t
    for n=1:ft_ert.feat_raw.size(t)
    	fst = ft_ert.feat_raw.tree{t,n}.raw(3);
        num = ft_ert.feat_raw.tree{t,n}.raw(2);
        vec = ft_ert.feat_raw.pxls(fst:fst+num-1)+1; % correct start index as Matlab sense
        if sum(p_idx==vec)==1
            found = 1;
            break;
        end
    end
    if found==1
        break; 
    end
end

figure(2);
for i=1:no
    subplot(no,1,i);
    ft_ert = imfeat('extract_feature_raw_get_single_data_and_dif', [t,i], ft_ert);
    imshow(ft_ert.feat_raw.tree{t,i}.data);
end

