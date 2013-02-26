addpath_for_me;

ds_eng = [];
ds_eng = imdataset('init', 'ICDAR2003RobustReading', ds_eng);
ds_eng = imdataset('get_test_dataset_defxml_word', 'ICDAR2003RobustReading', ds_eng);
path = '../../_output_files/Output_img/Parsed_mat/';
resize = [400,400];
for i=1:ds_eng.no

    for reverse = 0:1
        fn = util_changeFn(ds_eng.fn_list{i}, 'get_filename_and_extension', '');
        % if it's parsed, jump to next
        oldname = [path fn '_' num2str(resize(1)) 'x' num2str(resize(2)) '_reverse_' num2str(reverse) '.mat'];
        sn = sprintf('%03d',i);
        newname = [path '[' sn '] ' fn '_' num2str(resize(1)) 'x' num2str(resize(2)) '_reverse_' num2str(reverse) '.mat'];
        if exist(oldname, 'file')
            movefile(oldname, newname)
%             java.io.File(oldname).renameTo(java.io.File(newname))
        end
    
    end
    
end