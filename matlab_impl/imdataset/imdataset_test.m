function [result] = imdataset_test(dataset_name, func, cmd2)

result = 0;

switch dataset_name
    
    case 'MSRATD500'
        ds = [];
        ds = imdataset('init', 'MSRATD500', ds);
        ds = imdataset(func, cmd2, ds);
        for i=1:ds.no
            if (ds.att_region_no(i)>0)
                fprintf('%s\n',ds.fn_list{i});
            end
            for j=1:ds.att_region_no(i)
                fprintf('(x,y,w,h)=(%d,%d,%d,%d)\n',...
                    ds.att{i,j}.x, ...
                    ds.att{i,j}.y, ...
                    ds.att{i,j}.w, ...
                    ds.att{i,j}.h);
            end
        end
        result = 1; 
    
    case 'ICDAR2003'
        ds = [];
        ds = imdataset('init', 'ICDAR2003RobustReading', ds);
        ds = imdataset(func, cmd2, ds);
        for i=1:ds.no
            if (ds.att_region_no(i)>0)
                fprintf('%s\n',ds.fn_list{i});
            end
            for j=1:ds.att_region_no(i)
                fprintf('(x,y,w,h)=(%d,%d,%d,%d)\n',...
                    ds.att{i,j}.x, ...
                    ds.att{i,j}.y, ...
                    ds.att{i,j}.w, ...
                    ds.att{i,j}.h);
            end
        end
        result = 1;
           
    otherwise
        warning('Unsupported imfeat: %s', feat_name);
end

end