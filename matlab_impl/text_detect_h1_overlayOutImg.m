function text_detect_h1_overlayOutImg()

    path = '../../_output_files/Output_img/aPICT0034 (ESSEX_SUMMER_INDATA_SCHOOL_ANALYSYS)/[0221_1659] aPICT0034.JPG_200x200_ER_candidate_img(63,1)/';
    path = '../../_output_files/Output_img/IMG_1291 (go_CREATE_SONY)/[0221_2014] IMG_1291.JPG_200x200_ER_candidate_img/';
    path = '../../_output_files/Output_img/';
    path = [path '[0222_1727] Pict0003.jpg_200x200_ER_candidate_img(65,0)=(10,11)(v)(CLUB con)/'];
    
    fns = dir([path 'ER*_0.png']);
    [H,W] = size(imread([path fns(1,1).name]));
    I_accum = false(H,W);
    for i=1:numel(fns)
        % in each folder
        I = logical(imread([path fns(i,1).name])); 
        I_accum = I | I_accum;
    end
    imshow(I_accum);

end