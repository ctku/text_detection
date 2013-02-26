function [param] = imdataset(cmd1, cmd2, param)

param.prv.ret = 0;

switch cmd1
    case 'init'
        param.prv.ds_name = cmd2;
    otherwise
        switch param.prv.ds_name
          % ===========(Start: added for each new dataset ========
          % case 'xxx'
          %     param = dataset_xxx(cmd1, cmd2, param);
          % ===========(End: added for each new dataset ==========
        	case 'ArabicSigns10'
                param = imdataset_ArabicSigns10(cmd1, cmd2, param);
        	case 'ICDAR2003RobustReading'
                param = imdataset_ICDAR2003RobustReading(cmd1, cmd2, param);
        	case 'Chars74K'
                param = imdataset_Chars74K(cmd1, cmd2, param);
        	case 'MSRATD500'
                param = imdataset_MSRATD500(cmd1, cmd2, param);
            otherwise
                warning('Please initialize the dataset first!');
                param.prv.ret = -1;
        end
end

end
