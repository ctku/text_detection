
function out = proj_0226_MSRA(stage, cmd1, order)

PROJ_NAME = '20130226';

CHAR_REGION_FILENAME = 'ft_vector_7feat_20130217'; % no need to retrain

DATASET_NAME = 'MSRATD500';

NON_CHAR_REGION_FOLDERNAME = '0226_test1_nonc_mat';
NON_CHAR_REGION_RANDOM_SEED = PROJ_NAME;
NON_CHAR_REGION_NO = 50;
NON_CHAR_REGION_RESIZE = [100,100];

% general rules
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

addpath_for_me;

ds_eng = [];
ds_eng = imdataset('init', 'MSRATD500', ds_eng);
ds_eng = imdataset('get_test_dataset_deftxt_word', 'MSRATD500', ds_eng);

if stage<=4
    switch stage
        case 1
            % extract char features
            text_detect_a1_ftExtract_Chars74K_char( ...
                CHAR_REGION_FILENAME);
        case 2
            % extract non-char features
            text_detect_a1_ftExtract_MSRATD500_general( ...
                0, 0, RULES, ...
                NON_CHAR_REGION_FOLDERNAME, ...
                {NON_CHAR_REGION_NO, ...
                 NON_CHAR_REGION_RANDOM_SEED, ...
                 NON_CHAR_REGION_RESIZE}, ...
                order);
        case 3
            % check progress of stage 2
            out = text_detect_h1_checkProgress( ...
                DATASET_NAME, 3, ...
                NON_CHAR_REGION_FOLDERNAME, ...
                {NON_CHAR_REGION_NO, ...
                 NON_CHAR_REGION_RANDOM_SEED, ...
                 NON_CHAR_REGION_RESIZE});
        case 4
            % collect and train for 1st/2nd stage classifier
            text_detect_a2_ftCol( ...
                DATASET_NAME, ...
                CHAR_REGION_FILENAME, ...
                NON_CHAR_REGION_FOLDERNAME, ...
                NON_CHAR_REGION_RESIZE, ...
                PROJ_NAME);
    end
else
    
%     if order(1)=='F' && order(5)=='P'
%         seq = max(round(ds_eng.no*str2double(order(2:4))/100),1):1:ds_eng.no;
%     end
%     if order(1)=='B' && order(5)=='P'
%         seq = min(round(ds_eng.no*str2double(order(2:4))/100),ds_eng.no):-1:1;
%     end
%     if order(1)=='F' && order(5)=='N'
%         seq = str2double(order(2:4)):1:ds_eng.no;
%     end
%     if order(1)=='B' && order(5)=='N'
%         seq = str2double(order(2:4)):-1:1;
%     end
    seq = [6 7 9 19 34 37 55 63 76 78 88 89 98 129 131 139 141 142 149 151 152 153 159 165 190];
    seq = [1 4 12 26 41 71];
    seq = [100 111 114 124 125 132 187];
    for i=seq(order:end)

        TEST_IMG_FOLDER = util_changeFn(ds_eng.fn_list{i}, 'remove_filename_and_extension', '');
        TEST_IMG_FILENAME = util_changeFn(ds_eng.fn_list{i}, 'get_filename_and_extension', '');
        TEST_IMG_RESIZE = [400,400];
        ['[' num2str(i) ']' TEST_IMG_FILENAME]

        switch stage
            case 5
                % 1st stage classifier, and save postprob
                text_detect_a3_calAdaPostp( ...
                    DATASET_NAME, ...
                    TEST_IMG_FOLDER, ...
                    TEST_IMG_FILENAME, i, ...
                    TEST_IMG_RESIZE, ...
                    PROJ_NAME, ...
                    RULES);
            case 55
                % save resized image
                im = [];
                I = imread(ds_eng.fn_list{i});
                im = imfeat('init', 'binary', im);
                im = imfeat('set_image', I, im);
                im = imfeat('resize', TEST_IMG_RESIZE, im);
                path = '../../../../KCD_NoSync/temp1/';
                imwrite(im.image, [path '[' num2str(i) '] ' TEST_IMG_FILENAME], 'jpg');
            case 66
                % prune by (1)Adaboost postprob, and (2) SVM(optional) - Algo6
                text_detect_a4_classifyAdaPostp_optSVM_algo6( ...
                    TEST_IMG_FOLDER, ...
                    TEST_IMG_FILENAME, i, ...
                    TEST_IMG_RESIZE, ...
                    PROJ_NAME, ...
                    RULES, ...
                    cmd1);
            case 67
                % prune by (1)Adaboost postprob, and (2) SVM(optional) - Algo7
                text_detect_a4_classifyAdaPostp_optSVM_algo7( ...
                    DATASET_NAME, ...
                    TEST_IMG_FILENAME, i, ...
                    TEST_IMG_RESIZE, ...
                    PROJ_NAME, ...
                    RULES, ...
                    cmd1);
        end
    end
end



end