function [result] = imfeat_test(feat_name)

result = 0;
im = [];

switch feat_name
    case 'swt'
        % Stroke With Transform (SWT)
        I = imread('..\..\Dataset\ArabicSigns-1.0\jpg\ArabicSign-00001.jpg');
        im = imfeat('init', 'swt', im);
        im = imfeat('set_image', I, im);
        im = imfeat('convert', '', im);
        im = imfeat('resize', [300,300], im);
        im = imfeat('extract_feature_mask', '', im);
        result = 1;
        
    case 'mser'
        % Maximally Stable Extremal Region (MSER)
        I = imread('..\..\Dataset\ArabicSigns-1.0\jpg\ArabicSign-00001.jpg');
        im = imfeat('init', 'mser', im);
        im = imfeat('set_image', I, im);
        im = imfeat('convert', '', im);
        a = 6;
        im = imfeat('resize', [a a], im);
        % imwrite(t.image,'test_img\test_mser2.jpg','jpg')
        % (ThresholdDelta, RegionAreaRange,MaxAreaVariation)
        if 1
        mser_param = [10,...
                      [1 a*a-1],...
                      1];
        else
        mser_param = '';
        end
        im = imfeat('extract_feature_raw', mser_param, im);
        % Show MSER
        imshow(im.image); hold on;
        plot(im.feat_raw, 'showEllipses',false, 'showPixelList',true);
        im.feat_raw.Count
        result = 1;
        
    case 'thmser'
        % THresholded Maximally Stable Extremal Region (THMSER)
        I = [1 2 3; 
             1 2 3; 
             4 5 6];
        im = imfeat('init', 'thmser', im);
        im = imfeat('set_image', I, im);
        r = imfeat('extract_feature_mask', 3, im);
        assert(sum(sum(r.feat_mask == [0 0 1; 0 0 1; 0 0 0]))==9)
        result = 1;

     case 'ertree'
        % Extremal Region TREE (ERTREE)
        % example 1 (reverse = 0)
        I = [3 4 2 2;
             4 4 2 2;
             2 2 3 3];
        im = imfeat('init', 'ertree', im);
        im = imfeat('set_image', I, im);
        im = imfeat('extract_feature_raw_get_all_preproc', 0, im);
        r = im.feat_raw.tree;
        s = im.feat_raw.size;
        for t = 1:size(r,1)
            for n = 1:s(t)
                im = imfeat('extract_feature_raw_get_one_full_data_and_dif', [t, n], im);
            end
        end
        r = im.feat_raw.tree;
        assert(isequal(r{3,1}.data, [0 0 0 0; 0 0 0 0; 1 1 0 0]) && ...
               isequal(r{3,1}.dif,  [0 0 1 1; 0 0 1 1; 0 0 1 1]) && ...
               isequal(r{3,2}.data, [0 0 1 1; 0 0 1 1; 0 0 0 0]) && ...
               isequal(r{3,2}.dif , [0 0 0 0; 0 0 0 0; 1 1 1 1]) && ...
               isequal(r{4,1}.data, [1 0 0 0; 0 0 0 0; 0 0 0 0]) && ...
               isequal(r{4,1}.dif , [0 1 1 1; 1 1 1 1; 1 1 1 1]) && ...
               isequal(r{4,2}.data, [0 0 1 1; 0 0 1 1; 1 1 1 1]) && ...
               isequal(r{4,2}.dif , [1 1 0 0; 1 1 0 0; 0 0 0 0]) && ...
               isequal(r{5,1}.data, [1 1 1 1; 1 1 1 1; 1 1 1 1]) && ...
               isequal(r{5,1}.dif , [0 0 0 0; 0 0 0 0; 0 0 0 0]) && ...
               isequal(r{3,1}.par, [4,2]) && isequal(r{3,1}.chd, []) && r{3,1}.chd_no==0 && ...
               isequal(r{3,2}.par, [4,2]) && isequal(r{3,2}.chd, []) && r{3,2}.chd_no==0 && ...
               isequal(r{4,1}.par, [5,1]) && isequal(r{4,1}.chd, []) && r{4,1}.chd_no==0 && ...
               isequal(r{4,2}.par, [5,1]) && isequal(r{4,2}.chd, [3,1;3,2]) && r{4,2}.chd_no==2 && ...
               isequal(r{5,1}.par, [0,0]) && isequal(r{5,1}.chd, [4,1;4,2]) && r{5,1}.chd_no==2 && ...
               r{3,1}.isleaf==1 && r{3,2}.isleaf==1 && ...
               r{4,1}.isleaf==1 && r{4,2}.isleaf==0 && ...
               r{5,1}.isleaf==0);
        for t = 1:size(r,1)
            for n = 1:s(t)
                im = imfeat('extract_feature_raw_del_data_and_dif', [t, n], im);
            end
        end
        r = im.feat_raw.tree;
        assert(isequal(r{3,1}.data,-1) && ...
               isequal(r{3,1}.dif, -1) && ...
               isequal(r{3,2}.data,-1) && ...
               isequal(r{3,2}.dif, -1) && ...
               isequal(r{4,1}.data,-1) && ...
               isequal(r{4,1}.dif, -1) && ...
               isequal(r{4,2}.data,-1) && ...
               isequal(r{4,2}.dif, -1) && ...
               isequal(r{5,1}.data,-1) && ...
               isequal(r{5,1}.dif, -1) && ...
               isequal(r{3,1}.par, [4,2]) && ...
               isequal(r{3,2}.par, [4,2]) && ...
               isequal(r{4,1}.par, [5,1]) && ...
               isequal(r{4,2}.par, [5,1]) && ...
               isequal(r{5,1}.par, [0,0]) && ...
               r{3,1}.isleaf==1 && r{3,2}.isleaf==1 && ...
               r{4,1}.isleaf==1 && r{4,2}.isleaf==0 && ...
               r{5,1}.isleaf==0);
           
        % example 2 (reverse=1)
        I = [3 4 2 2;
             4 4 2 2;
             2 2 3 3];
        im = imfeat('init', 'ertree', im);
        im = imfeat('set_image', I, im);
        im = imfeat('extract_feature_raw_get_all_preproc', 1, im);
        r = im.feat_raw.tree;
        s = im.feat_raw.size;
        for t = 1:size(r,1)
            for n = 1:s(t)
                im = imfeat('extract_feature_raw_get_one_cropped_data_and_dif', [t, n], im);
            end
        end
        r = im.feat_raw.tree;
        assert(isequal(r{252,1}.data, [0 1; 1 1]) && ...
               isequal(r{252,1}.dif,  [1 0; 0 0]) && ...
               isequal(r{253,1}.data, [1 1 0 0; 1 1 0 0; 0 0 0 0]) && ...
               isequal(r{253,1}.dif , [0 0 1 1; 0 0 1 1; 1 1 1 1]) && ...
               isequal(r{253,2}.data, [0 0 0 0; 0 0 0 0; 0 0 1 1]) && ...
               isequal(r{253,2}.dif , [1 1 1 1; 1 1 1 1; 1 1 0 0]) && ...
               isequal(r{254,1}.data, [1 1 1 1; 1 1 1 1; 1 1 1 1]) && ...
               isequal(r{254,1}.dif , [0 0 0 0; 0 0 0 0; 0 0 0 0]) && ...
               isequal(r{252,1}.par, [253,1]) && ...
               isequal(r{253,1}.par, [254,1]) && ...
               isequal(r{253,2}.par, [254,1]) && ...
               isequal(r{254,1}.par, [0,0]) && ...
               r{252,1}.isleaf==1 && ...
               r{253,1}.isleaf==0 && r{253,2}.isleaf==1 && ...
               r{254,1}.isleaf==0);
           
        result = 1;
        
	case 'binary'
        im = imfeat('init', 'binary', im);
        
        % aspect ratio (w/h) - incremental
%         % prepare new info
%         I_new = [1 1 0 0;
%                  1 0 0 0;
%                  0 0 0 1;
%                  0 0 1 1];
%         im = imfeat('set_image', I_new, im);
%         % prepare extra info
%         f_cum.x_min = 2;
%         f_cum.x_max = 3;
%         f_cum.y_min = 2;
%         f_cum.y_max = 3;
%         extra{1} = f_cum;
%         r1 = imfeat('compute_feature_raw_aspectratio_incrementally', extra, im);
%         assert(r1.feat_raw==1)
        
        % compactness (sqrt(a)/p) - incremental
        % prepare new info
%         I_new = [1 1 0 0;
%                  1 0 0 0;
%                  0 0 0 1;
%                  0 0 1 1];
%         im = imfeat('set_image', I_new, im);
%         % prepare extra info
%         I_cum = [0 0 0 0;
%                  0 1 1 0;
%                  0 1 1 0;
%                  0 0 0 0];
%         f_cum = 4;
%         extra{1} = I_cum;
%         extra{2} = f_cum;
%         r1 = imfeat('compute_feature_raw_compactness_incrementally', extra, im);
%         assert(r1.feat_raw==sqrt(10)/16)
        
        % number of holes (1-e)
%         I = [0 0 0 0 0;
%              1 1 1 1 0;
%              1 0 1 0 0;
%              1 1 1 1 0];
%         im = imfeat('set_image', I, im);
%         r1 = imfeat('extract_feature_raw_numofhole_all', '', im);
%         r2 = imfeat('extract_feature_raw_numofhole_givenchkpt', [2 2], im);
%         assert(r1.feat_raw==1 && r2.feat_raw==1)
        
        % size
        I_new = [0 0 0 0 0;
                 1 1 0 0 0;
                 0 1 1 0 0;
                 0 0 0 1 1];
        im = imfeat('set_image', I_new, im);
        r1 = imfeat('extract_feature_raw_size_all', '', im);
        r2 = imfeat('extract_feature_raw_size_givenchkpt', [3 3], im);
        assert(r1.feat_raw==6 && r2.feat_raw==4);
        
        % size (incrmentally)
        f_cum = 4;
        I_new = [0 0 0 0 0;
                 1 1 0 0 0;
                 0 1 1 0 0;
                 0 0 0 1 1];
        im = imfeat('set_image', I_new, im);
        extra = f_cum;
        r1 = imfeat('compute_feature_raw_size_incrementally', extra, im);
        assert(r1.feat_raw==10);
        
        % bounding box
        I_new = [0 0 0 0 0;
                 1 1 0 0 0;
                 0 1 1 0 0;
                 0 0 0 1 1];
        im = imfeat('set_image', I_new, im);
        r1 = imfeat('extract_feature_raw_boundingbox_all', '', im);
        r2 = imfeat('extract_feature_raw_boundingbox_givenchkpt', [3 3], im);
        assert(r1.feat_raw.x_min==1 && r1.feat_raw.x_max==5 && ...
               r1.feat_raw.y_min==2 && r1.feat_raw.y_max==4 && ...
               r2.feat_raw.x_min==1 && r2.feat_raw.x_max==3 && ...
               r2.feat_raw.y_min==2 && r2.feat_raw.y_max==3);
               
        % bounding box (incrmentally)
        f_cum = [];
        f_cum.x_min = 2;
        f_cum.x_max = 3;
        f_cum.y_min = 2;
        f_cum.y_max = 2;
        I_new = [1 1 0 0;
                 0 0 0 0;
                 0 0 1 1];
        im = imfeat('set_image', I_new, im);
        extra = f_cum;
        r1 = imfeat('compute_feature_raw_boundingbox_incrementally', extra, im);
        assert(r1.feat_raw.x_min==1 && r1.feat_raw.x_max==4 && ...
               r1.feat_raw.y_min==1 && r1.feat_raw.y_max==3);

        % perimeter
        I_new = [0 0 1 0 0 0;
                 0 1 1 0 0 0;
                 0 1 1 0 0 0;
                 0 1 0 0 0 1];
        im = imfeat('set_image', uint8(I_new), im);
        r1 = imfeat('extract_feature_raw_perimeter_all', '', im);   
        r2 = imfeat('extract_feature_raw_perimeter_givenchkpt', [2 3], im);
        r3 = imfeat('extract_feature_raw_perimeter_givenchkpt', [4 6], im);
        assert(r1.feat_raw==16 && r2.feat_raw==12 && r3.feat_raw==4);
        
        % perimeter (incrmentally)
        f_cum = 16;
        I_cum = [0 0 1 0 0 0;
                 0 1 1 0 0 0;
                 0 1 1 0 0 0;
                 0 1 0 0 0 1];
        I_new = [0 1 0 0 0 1;
                 0 0 0 0 1 1;
                 1 0 0 1 1 1;
                 0 0 0 0 0 0];
        im = imfeat('set_image', uint8(I_new), im);
        extra = [];
        extra{1} = uint8(I_cum);
        extra{2} = f_cum;
        r1 = imfeat('compute_feature_raw_perimeter_incrementally', extra, im);
        assert(r1.feat_raw==26);    
        
        % euler no
        I_new = [1 0 1 1 1;
                 0 0 1 0 1;
                 0 1 1 1 1];
        im = imfeat('set_image', I_new, im);
        r1 = imfeat('extract_feature_raw_eulerno_all', '', im);
        r2 = imfeat('extract_feature_raw_eulerno_givenchkpt', [1 1], im);
        r3 = imfeat('extract_feature_raw_eulerno_givenchkpt', [2 3], im);
        assert(r1.feat_raw==(2-1) && r2.feat_raw==(1-0) && r3.feat_raw==(1-1));

        % euler no (incrmentally)
        f_cum = 1;
        I_cum = [0 0 0 1 1;
                 0 0 1 0 1;
                 0 1 1 1 1];
        I_new = [1 1 1 0 0;
                 1 0 0 0 0;
                 1 1 0 0 0];
        im = imfeat('set_image', uint8(I_new), im);
        extra = [];
        extra{1} = uint8(I_cum);
        extra{2} = f_cum;
        r1 = imfeat('compute_feature_raw_eulerno_incrementally', extra, im);
        assert(r1.feat_raw==-1);
        
        % horizontal crossing
        I_new = [0 0 0 0 0 1 1;
                 0 1 1 0 1 1 1;
                 0 1 1 0 1 0 1;
                 0 0 0 0 0 0 1];
        im = imfeat('set_image', uint8(I_new), im);
        r1 = imfeat('extract_feature_raw_hzcrossing_all', '', im);
        r2 = imfeat('extract_feature_raw_hzcrossing_givenchkpt', [2 2], im);
        r3 = imfeat('extract_feature_raw_hzcrossing_givenchkpt', [4 7], im);
        I_new = [0 0 0 0 0 0 0 0;
                 1 0 0 0 0 0 0 1;
                 1 0 0 0 0 0 0 1;
                 0 1 0 1 1 0 1 0;
                 0 1 0 1 1 0 1 0
                 0 0 1 0 0 1 0 0
                 0 0 1 0 0 1 0 0];
        im = imfeat('set_image', uint8(I_new), im);
        r4 = imfeat('extract_feature_raw_hzcrossing_slicemedian', [1/6 3/6 5/6], im);
        assert(sum(r1.feat_raw==[2 4 6 2])==4 && ...
               sum(r2.feat_raw==[0 2 2 0])==4 && ...
               sum(r3.feat_raw==[2 2 4 2])==4 && ...
               r4.feat_raw==median([4,6,4]));
        
        % horizontal crossing (incrmentally)
        f_cum =   [2,2]; 
	    %        ~ ~ ~ ~
        %        ^
        f_off = 1;
        I_cum = [0 0 0 0 0 0;
                 0 0 1 1 0 0;
                 0 0 1 1 0 0;
                 0 0 0 0 0 0];
        I_new = [1 0 0 0 0 1;
                 1 0 0 0 0 0;
                 1 0 0 0 0 0;
                 1 1 1 0 0 0];
        im = imfeat('set_image', uint8(I_new), im);
        extra = [];
        extra{1} = uint8(I_cum);
        extra{2} = f_cum;
        extra{3} = f_off;
        r1 = imfeat('compute_feature_raw_hzcrossing_incrementally', extra, im);
        assert(isequal(r1.feat_raw,[4 4 4 2]));

        % convex hull
        I = [0 0 1 0 0;
             0 0 1 0 0;
             1 1 1 1 1];
        im = imfeat('set_image', uint8(I), im);
        r = imfeat('extract_feature_raw_convexhull_all', '', im);
        assert(r.feat_raw==4);
        I = [1 0 1 0 1;
             0 0 1 0 0;
             1 1 1 1 1];
        im = imfeat('set_image', uint8(I), im);
        r = imfeat('extract_feature_raw_convexhull_all', '', im);
        assert(r.feat_raw==8);
        
        result = 1;
           
    otherwise
        warning('Unsupported imfeat: %s', feat_name);
end

end