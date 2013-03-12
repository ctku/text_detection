
function out = proj_0306_MSRA()

% Project path init
PATH.FEATVEC_MAT = '../../_output_files/Feature_vectors/';
PATH.CLASSIFIER_MAT = '../../_output_files/Classifier/';
PATH.ADA_POST_MAT = '../../../../../LargeFiles/Adaboost_post/';
PATH.ADA_PRUNE_OUT_FOLDER = '../../../../../LargeFiles/Adaboost_prune_out/';
PATH.SVM_PRUNE_OUT_FOLDER = '../../../../../LargeFiles/Svm_prune_out/';
PATH.TRAINIMG_NONCHAR = '../../../../../LargeFiles/TrainImg_nonchar/';
PATH.TEST_FROM_PRUNED_ADA1 = '../../../../../LargeFiles/MSRATD500/[001] IMG_0059.JPG_400x400_ER_candidate_img_0_[0228_1555]/'; 
PATH.TEST_FROM_PRUNED_ADA2 = '../../../../../LargeFiles/MSRATD500/[004] IMG_0156.JPG_400x400_ER_candidate_img_0_[0228_1558]/';
PATH.TEST_FROM_PRUNED_ADA3 = '../../../../../LargeFiles/MSRATD500/[006] IMG_0172.JPG_400x400_ER_candidate_img_0_[0228_1111]/';
PATH.TEST_FROM_PRUNED_ADA4 = '../../../../../LargeFiles/MSRATD500/[012] IMG_0475.JPG_400x400_ER_candidate_img_0_[0228_1540]/';
PATH.TEST_FROM_PRUNED_ADA5 = '../../../../../LargeFiles/MSRATD500/[019] IMG_0507.JPG_400x400_ER_candidate_img_0_[0228_1526]/';
PATH.TEST_FROM_PRUNED_ADA6 = '../../../../../LargeFiles/MSRATD500/[034] IMG_0638.JPG_400x400_ER_candidate_img_0_[0228_1136]/';
PATH.TEST_FROM_PRUNED_ADA7 = '../../../../../LargeFiles/MSRATD500/[037] IMG_0667.JPG_400x400_ER_candidate_img_0_[0228_1140]/';


NAME.FEATVEC_MAT = '0311_test02_traditional_4_plus_3';
NAME.CLASSIFIER_MAT = 'svm_ova_w_non_0311_test02_traditional_4_plus_3';
NAME.TESTING_DATASET = 'MSRATD500';
NAME.TESTING_SIZE = '400x400';

FEAT.RESIZE = [128 128];
FEAT.SHAPECONTEXT = [80 12 5 1/8 2 0];
FEAT.RANDPROJBITS = 8;
FEAT.RANDPROJMATRIX = normrnd(0,1,FEAT.SHAPECONTEXT(2)*FEAT.SHAPECONTEXT(3),FEAT.RANDPROJBITS);

STAGE = [ ...
              %     <Char74K (chars)>
    '001';... % r1: collect & save feat vectors from dataset
              %     <MSRATD500 (nonchars)>
    '110';... % r1: random and save as .png
              % r2: collect feat vectors from .png
              % r3: save feat vectors
              %     <Training SVM>
    '010';... % r1: train one versus all(w/o non) classifier for each chars
              % r2: train one versus all(w/  non) classifier for each chars
              % r3: train char versus nonchar classifier
              %     <Testing SVM>
    '010'];   % r1: test by Char74K images 
              % r2: test by Pruned Ada .png

% extract char features
textdetect_a1_train_svm_Chars74K_all_vs_nonchars(PATH, NAME, FEAT, STAGE);



RULES.MIN_W_ABS = 3;
RULES.MIN_H_ABS = 3;
RULES.MIN_SIZE = 30;
RULES.MIN_W_REG2IMG_RATIO = 0.0019;
RULES.MAX_W_REG2IMG_RATIO = 0.4562;
RULES.MIN_H_REG2IMG_RATIO = 0.0100;
RULES.MAX_H_REG2IMG_RATIO = 0.7989;
RULES.PROB_MIN = 0.2;
RULES.DELTA_MIN = 0.1;
RULES.MIN_CONSEQ_ER_LEVEL = 2;
RULES.MAX_AREA_VARIATION = 0.05;
if 0
ds_eng = [];
ds_eng = imdataset('init', 'MSRATD500', ds_eng);
ds_eng = imdataset('get_test_dataset_deftxt_word', 'MSRATD500', ds_eng);
seq = [6 7 9 19 34 37 55 63 76 78 88 89 98 129 131 139 141 142 149 151 152 153 159 165 190];
order = 1;
useSVM = 2;

for i=seq(order:end)

    NAME.TESTING_IMG = util_changeFn(ds_eng.fn_list{i}, 'get_filename_and_extension', '');
    NAME.TESTING_IMG_IDX = i;
    ['[' num2str(i) ']' NAME.TESTING_IMG]

    text_detect_a4_classifyAdaPostp_optSVM_algo7(PATH, NAME, FEAT, RULES, useSVM);
    
end
end
% PROJ_NAME = '20130226';
% CHAR_REGION_FILENAME = 'ft_vector_7feat_20130217'; % no need to retraint
% DATASET_NAME = 'MSRATD500';
% NON_CHAR_REGION_FOLDERNAME = '0226_test1_nonc_mat';
% NON_CHAR_REGION_RANDOM_SEED = PROJ_NAME;
% NON_CHAR_REGION_NO = 50;
% NON_CHAR_REGION_RESIZE = [100,100];

% general rules
% RULES.MIN_W_ABS = 3;
% RULES.MIN_H_ABS = 3;
% RULES.MIN_SIZE = 30;
% RULES.MIN_W_REG2IMG_RATIO = 0.0019;
% RULES.MAX_W_REG2IMG_RATIO = 0.4562;
% RULES.MIN_H_REG2IMG_RATIO = 0.0100;
% RULES.MAX_H_REG2IMG_RATIO = 0.7989;
% RULES.PROB_MIN = 0.2;
% RULES.DELTA_MIN = 0.1;
% RULES.MIN_CONSEQ_ER_LEVEL = 2;
% RULES.MAX_AREA_VARIATION = 0.05;
% 
% ds_eng = [];
% ds_eng = imdataset('init', 'MSRATD500', ds_eng);
% ds_eng = imdataset('get_test_dataset_deftxt_word', 'MSRATD500', ds_eng);
% 
% if stage<=4
%     switch stage
%         case 1
%             % extract char features
%             textdetect_a1_train_svm_Chars74K( ...
%                 CHAR_REGION_FILENAME);
% %         case 2
% %             % extract non-char features
% %             text_detect_a1_ftExtract_MSRATD500_general( ...
% %                 0, 0, RULES, ...
% %                 NON_CHAR_REGION_FOLDERNAME, ...
% %                 {NON_CHAR_REGION_NO, ...
% %                  NON_CHAR_REGION_RANDOM_SEED, ...
% %                  NON_CHAR_REGION_RESIZE}, ...
% %                 order);
% %         case 3
% %             % check progress of stage 2
% %             out = text_detect_h1_checkProgress( ...
% %                 DATASET_NAME, 3, ...
% %                 NON_CHAR_REGION_FOLDERNAME, ...
% %                 {NON_CHAR_REGION_NO, ...
% %                  NON_CHAR_REGION_RANDOM_SEED, ...
% %                  NON_CHAR_REGION_RESIZE});
% %         case 4
% %             % collect and train for 1st/2nd stage classifier
% %             text_detect_a2_ftCol( ...
% %                 DATASET_NAME, ...
% %                 CHAR_REGION_FILENAME, ...
% %                 NON_CHAR_REGION_FOLDERNAME, ...
% %                 NON_CHAR_REGION_RESIZE, ...
% %                 PROJ_NAME);
%     end
% else
%     
% %     if order(1)=='F' && order(5)=='P'
% %         seq = max(round(ds_eng.no*str2double(order(2:4))/100),1):1:ds_eng.no;
% %     end
% %     if order(1)=='B' && order(5)=='P'
% %         seq = min(round(ds_eng.no*str2double(order(2:4))/100),ds_eng.no):-1:1;
% %     end
% %     if order(1)=='F' && order(5)=='N'
% %         seq = str2double(order(2:4)):1:ds_eng.no;
% %     end
% %     if order(1)=='B' && order(5)=='N'
% %         seq = str2double(order(2:4)):-1:1;
% %     end
%     seq = [6 7 9 19 34 37 55 63 76 78 88 89 98 129 131 139 141 142 149 151 152 153 159 165 190];
%     seq = [1 4 12 26 41 71];
%     seq = [100 111 114 124 125 132 187];
%     for i=seq(order:end)
% 
%         TEST_IMG_FOLDER = util_changeFn(ds_eng.fn_list{i}, 'remove_filename_and_extension', '');
%         TEST_IMG_FILENAME = util_changeFn(ds_eng.fn_list{i}, 'get_filename_and_extension', '');
%         TEST_IMG_RESIZE = [400,400];
%         ['[' num2str(i) ']' TEST_IMG_FILENAME]
% 
%         switch stage
%             case 5
%                 % 1st stage classifier, and save postprob
%                 text_detect_a3_calAdaPostp( ...
%                     DATASET_NAME, ...
%                     TEST_IMG_FOLDER, ...
%                     TEST_IMG_FILENAME, i, ...
%                     TEST_IMG_RESIZE, ...
%                     PROJ_NAME, ...
%                     RULES);
%             case 55
%                 % save resized image
%                 im = [];
%                 I = imread(ds_eng.fn_list{i});
%                 im = imfeat('init', 'binary', im);
%                 im = imfeat('set_image', I, im);
%                 im = imfeat('resize', TEST_IMG_RESIZE, im);
%                 path = '../../../../KCD_NoSync/temp1/';
%                 imwrite(im.image, [path '[' num2str(i) '] ' TEST_IMG_FILENAME], 'jpg');
%             case 67
%                 % prune by (1)Adaboost postprob, and (2) SVM(optional) - Algo7
%                 text_detect_a4_classifyAdaPostp_optSVM_algo7( ...
%                     DATASET_NAME, ...
%                     TEST_IMG_FILENAME, i, ...
%                     TEST_IMG_RESIZE, ...
%                     PROJ_NAME, ...
%                     RULES, ...
%                     cmd1);
%         end
%     end
% end



end