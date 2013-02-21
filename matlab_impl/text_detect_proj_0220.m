
function out = text_detect_proj_0220(stage, cmd1)

PROJ_NAME = '20130218';

CHAR_REGION_FILENAME = 'ft_vector_7feat_20130217';

NON_CHAR_REGION_FOLDERNAME = '0218_test3_nonc_mat';
NON_CHAR_REGION_RANDOM_SEED = PROJ_NAME;
NON_CHAR_REGION_NO = 50;
NON_CHAR_REGION_RESIZE = [100,100];

TEST_IMG_FOLDER = '../../../Codes/_input_files';
TEST_IMG_FILENAME = 'IMG_1291';
TEST_IMG_RESIZE = [100,100];

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

addpath_for_me;
switch stage
    case 1
        % extract char features
        text_detect_a1_1stStage_ftExtract_Chars74K_char( ...
            CHAR_REGION_FILENAME);
    case 2
        % extract non-char features
        text_detect_a1_1stStage_ftExtract_ICDAR2003_general( ...
            0, 0, RULES, ...
            NON_CHAR_REGION_FOLDERNAME, ...
            {NON_CHAR_REGION_NO, ...
             NON_CHAR_REGION_RANDOM_SEED, ...
             NON_CHAR_REGION_RESIZE}, ...
            cmd1);
    case 3
        % check progress of stage 2
        out = text_detect_v2_checkProgress( ...
            0, ...
            NON_CHAR_REGION_FOLDERNAME, ...
            {NON_CHAR_REGION_NO, ...
             NON_CHAR_REGION_RANDOM_SEED, ...
             NON_CHAR_REGION_RESIZE});
    case 4
        % collect and train for 1st/2nd stage classifier
        text_detect_a2_1stStage_ftCol( ...
            CHAR_REGION_FILENAME, ...
            NON_CHAR_REGION_FOLDERNAME, ...
            NON_CHAR_REGION_RESIZE, ...
            PROJ_NAME);
    case 5
        % 1st stage classifier, and save postprob
        text_detect_a3_1stStage_Classify_v32( ...
            TEST_IMG_FOLDER, ...
            TEST_IMG_FILENAME, ...
            TEST_IMG_RESIZE, ...
            PROJ_NAME, ...
            RULES);
    case 6
        % prune by postprob
        text_detect_a3_1stStage_Classify_v41( ...
            TEST_IMG_FOLDER, ...
            TEST_IMG_FILENAME, ...
            TEST_IMG_RESIZE, ...
            PROJ_NAME, ...
            RULES);
    case 7
        % prune by postprob, and do 2nd stage classifier
        text_detect_a3_1stStage_Classify_v42( ...
            TEST_IMG_FOLDER, ...
            TEST_IMG_FILENAME, ...
            TEST_IMG_RESIZE, ...
            PROJ_NAME, ...
            RULES);
end


end