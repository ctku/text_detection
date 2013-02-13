function text_detect_a3_1stStage_Classify_v2()

close all;
addpath_for_me;
% 1st stage classifier parameters
PROB_MIN = 0.2;
DELTA_MIN = 0.1;
MIN_BB_AREA = 9;
rsize = [500, 500];

% dataset initialization
ds_eng = [];
ds_eng = imdataset('init', 'ICDAR2003RobustReading', ds_eng);
ds_eng = imdataset('get_test_dataset_defxml_word', '', ds_eng);
    
% feature initialization
ft_ert = []; ft_bin = [];
ft_ert = imfeat('init', 'ertree', ft_ert);
ft_bin = imfeat('init', 'binary', ft_bin);

% extract ER tree feature 
% I_path = [ds_eng.path 'ryoungt_05.08.2002/wPICT0013.jpg'];
% I_path = [ds_eng.path 'ryoungt_05.08.2002/Pict0021.jpg'];
% I_path = [ds_eng.path 'ryoungt_05.08.2002/PICT0014.JPG'];
% I_path = [ds_eng.path 'ryoungt_05.08.2002/bPICT0010.JPG'];
% reverse = 0; I_path = 'test/patches/flats.jpg'; 
% I_path = 'test/patches/bmc_po_75_no25.jpg';
load_testPatches;ds_eng.no = 12;ds_eng.fn_list = fn_list_testPatches;

for i=1:1%:ds_eng.no
    I_path = ds_eng.fn_list{i};
    I = imread(I_path);
    ft_ert = imfeat('set_image', I, ft_ert);
    ft_ert = imfeat('convert', '', ft_ert);
    ft_ert = imfeat('resize', rsize, ft_ert);
    f = figure(i);
    subplot(2,5,1); imshow(ft_ert.image);
    subplot(2,5,2); imshow(255-ft_ert.image);
%     subplot(2,5,3); imshow(255-ft_ert.image);
    
    % MSER
%     im = [];
%     im = imfeat('init', 'mser', im);
%     im = imfeat('set_image', ft_ert.image, im);
%     im = imfeat('convert', '', im);
%     mser_param = '';
%     im = imfeat('extract_feature_raw', mser_param, im);
%     % Show MSER
%     subplot(2,3,3); imshow(im.image); hold on;
%     plot(im.feat_raw, 'showEllipses',false, 'showPixelList',true); hold off;
    
    for reverse=0%:1
        ft_ert = imfeat('extract_feature_raw_get_all_preproc', reverse, ft_ert);
        % fill up gap
        fmap = ft_ert.feat_raw.fmap;
        if 0
        fmap(find(fmap>0))=1;
        for t=1:254
            for n=1:ft_ert.feat_raw.size(t)
                if ~isequal(ft_ert.feat_raw.tree{t,n}.par,[0,0])
                    col = t + 1;
                    row = ft_ert.feat_raw.tree{t,n}.raw(3);
                    num = ft_ert.feat_raw.tree{t,n}.raw(2);
                    while fmap(row,col)==0
                        fmap(row:row+num-1,col) = 1;
                        col = col + 1;
                    end
                end
            end
        end
        end
%         subplot(2,5,5+reverse);
        imshow(imresize(rot90(fmap),[244,750]));
        hp = impixelinfo;
        set(hp,'Position',[5 1 300 20]);
        
        h = actxcontrol('mwsamp.mwsampctrl.2', ...
            [0 0 200 200], gcf, ...
            {'MouseDown' 'mymousedown'});
        h.eventlisteners
%         imshow(rot90(fmap));
    end
%     fn = util_changeFn(ds_eng.fn_list{i}, 'get_filename_and_extension', '');
%     h=figure;
%     save(fn,h,'jpg');
    
end



%         no_ER = sum(ft_ert.feat_raw.size);
%         fmap = ft_ert.feat_raw.fmap;
%         cmap = zeros(no_ER,255); % checked map (mark as 1 if prob is obtained)
%         pmap = zeros(no_ER,255); % probability map
%         qmap = zeros(no_ER,255); % qualify map
%         smap = zeros(no_ER,255); % score map
%         MAX_DPR_RATIO = 0.1;
%         MIN_AREA_SIZE = 30;%ft_ert.w*ft_ert.h/10000;
%         MAX_AREA_SIZE = ft_ert.w*ft_ert.h/4;
%         ERs = [];

% for r = 1:no_ER
%     for t = 1:255
%         if fmap(r,t)==0 || cmap(r,t)~=0
%             continue;
%         end
%         ER_idx = [t fmap(r,t)];
%         ER = ft_ert.feat_raw.tree{t,fmap(r,t)};
%         ER_par_idx = ER.par;
%         ER_par = ft_ert.feat_raw.tree{ER_par_idx(1),ER_par_idx(2)};
%         if ER_par.chl_no == 1
%             score = score + (ER_par_idx(1) - E
%             
%         end
%         add_score = ER
%     end
% end


% for t=1:254
%     for n=1:ft_ert.feat_raw.size(t)
%         ER = ft_ert.feat_raw.tree{t,n};
%         if ER.chd_no <= 2
%             continue;
% %         elseif ER.chd_no == 1
% %             chd_idx = ER.chd;
% %             ER_chd = ft_ert.feat_raw.tree{chd_idx(1),chd_idx(2)};
% %             dif_size = double(ER.raw(2)) - double(ER_chd.raw(2));
% %             dif_par_ratio = double(dif_size) / double(ER.raw(2));  
% %             if dif_par_ratio < MAX_DPR_RATIO && ...
% %                ER_chd.raw(2) > MIN_AREA_SIZE && ...
% %                ER_chd.raw(2) < MAX_AREA_SIZE
% %                 ft_ert = imfeat('extract_feature_raw_get_single_data_and_dif', [chd_idx(1),chd_idx(2)], ft_ert);
% %                 ERs = [ERs ft_ert.feat_raw.tree{chd_idx(1),chd_idx(2)}];
% %             end
%         else
%             for i=1:ER.chd_no
%                 chd_idx = ER.chd(i,1:2);
%                 ER_chd = ft_ert.feat_raw.tree{chd_idx(1),chd_idx(2)};
%                 if ER_chd.raw(2) > MIN_AREA_SIZE && ...
%                    ER_chd.raw(2) < MAX_AREA_SIZE
%                     ft_ert = imfeat('extract_feature_raw_get_single_data_and_dif', [chd_idx(1),chd_idx(2)], ft_ert);
%                     ft_ert.feat_raw.tree{chd_idx(1),chd_idx(2)}.idx = chd_idx;
%                     ERs = [ERs ft_ert.feat_raw.tree{chd_idx(1),chd_idx(2)}];
%                 end
%             end
%         end
% 
%     end
% end
% figure(2);
% for i=1:ceil(length(ERs)/10)
%     i
%     for r=1:10
%         if (i-1)*10+r>length(ERs)
%             break;
%         end
%         subplot(size(ERs,2)/10,10,(i-1)*10+r);
%         imshow(ERs((i-1)*9+r).data);
%         idx = ERs((i-1)*9+r).idx;
%         title([num2str(idx(1)) ',' num2str(idx(2))]);
%     end
% end


% search diff_par_ratio < MAX_DPR_RATIO

% ERs = [];
% p = 0;
% img_all = false(size(ft_ert.image));
% for t=1:255
%     for r=1:ft_ert.feat_raw.size(t)
%         if isequal(ft_ert.feat_raw.tree{t,r}.par,[0,0])
%             break;
%         end
%         ft_ert = imfeat('extract_feature_raw_get_single_data_and_dif', [t,r], ft_ert);
%         if ft_ert.feat_raw.tree{t,r}.dif_par_ratio < MAX_DPR_RATIO && ...
%            ft_ert.feat_raw.tree{t,r}.raw(2) > MIN_AREA_SIZE && ...
%            ft_ert.feat_raw.tree{t,r}.raw(2) < MAX_AREA_SIZE
%             ft_ert.feat_raw.tree{t,r}.isdone = 2;
%             img_all = img_all | ft_ert.feat_raw.tree{t,r}.data;
%         end
%     end
% end

% imshow(img_all);
% for t=1:20
%     for r=1:ft_ert.feat_raw.size(t)
%         subplot(1,ft_ert.feat_raw.size(t),r);
%         ft_ert = imfeat('extract_feature_raw_get_single_data_and_dif', [t,r], ft_ert);
%         ER = ft_ert.feat_raw.tree{t, r};
%         imshow(ER.data);
%         title(['ER:' num2str(t) ',' num2str(r)]);
%         xlabel(['NX:' num2str(ER.par(1)) ',' num2str(ER.par(2))]);
%     end
% end

% for t=72:80
%     figure(t);
%     for r=1:ft_ert.feat_raw.size(t)
%         subplot(1,ft_ert.feat_raw.size(t),r);
%         ft_ert = imfeat('extract_feature_raw_get_single_data_and_dif', [t,r], ft_ert);
%         ER = ft_ert.feat_raw.tree{t, r};
%         imshow(ER.data);
%         title(['ER:' num2str(t) ',' num2str(r)]);
%         xlabel(['NX:' num2str(ER.par(1)) ',' num2str(ER.par(2))]);
%     end
% end



% load trained AdaBoostM1
% load('ada.mat'); 

% for r = 1%:no_ER
%     is_first = 1;
%     for t = 1:255
%         if fmap(r,t)==0 || cmap(r,t)~=0
%             continue;
%         end
%         ER_idx = [t fmap(r,t)];
%         ft_ert = imfeat('extract_feature_raw_get_single_data_and_dif', ER_idx, ft_ert);
%         ER = ft_ert.feat_raw.tree{ER_idx(1), ER_idx(2)};
%         
%         % (1) get posterior prob.
%         if is_first
%             % extract feature vector (by using initial computation scheme)
%             [ft_outvec, ft_struct] = text_detect_sub_ftExtract_init(ER, ft_bin);
%             is_first = 0;
%         else
%             % extract feature vector (by using incrmental computation scheme)
%             [ft_outvec, ft_struct] = text_detect_sub_ftExtract_incrementally(ER, ft_struct, ft_bin);
%         end
%         bb = ft_struct.ft_bb.feat_raw;
%         if (bb.x_max-bb.x_min+1)*(bb.y_max-bb.y_min+1) <= MIN_BB_AREA
%             % size is too small, ignore it.
%             post_prob = 0;
%         else
%             % calibrated AdaBoost as posterior probability
%             [r_label, score] = predict(ada, ft_outvec);
%             post_prob = 1./(1+exp(-2*max(score)));
%         end
%         
%         pmap(ER.raw(3):ER.raw(3)+ER.raw(2)-1,t) = post_prob;
%         % mark current ER as checked (with 1)
%         cmap(ER.raw(3):ER.raw(3)+ER.raw(2)-1,t) = 1;
%         
%         % (2) check if it's like a char
%         if t>=2
%             if pmap(r,t)>PROB_MIN
%                 if (pmap(r,t)-pmap(r,t-1))>DELTA_MIN
%                     % it's like a char. Mark qualify map as 1
%                     qmap(ER.raw(3):ER.raw(3)+ER.raw(2)-1,t) = 1;%qmap(ER.raw(3):ER.raw(3)+ER.raw(2)-1,t-1) + 1;
%                 end
%             else
%                 % it's not like a char, implying so are parents
%                 % mark parents ER as skipped (with 2) till root
% %                 for c=t+1:255
% %                     if fmap(r,c)==0 || cmap(r,c)~=0
% %                         continue;
% %                     end
% %                     c
% %                     ER = ft_ert.feat_raw.tree{c,fmap(r,c)};
% %                     cmap(ER.raw(3):ER.raw(3)+ER.raw(2)-1,c) = 2;
% %                     pmap(ER.raw(3):ER.raw(3)+ER.raw(2)-1,c) = 10^(-5);
% %                 end
% %                 break; % leave (for t=init_t:5)
%             end
%         end
%     end
% end

