function [param] = imfeat(cmd1, cmd2, param)
    
param.prv.ret = 0;

switch cmd1
    case 'init'
        param.prv.feat_name = cmd2;
        param.prv.converted = 0;
        param = imfeat('initialization', cmd2, param);
    case 'set_image'
        param.image = cmd2;
        param.w = size(param.image, 2);
        param.h = size(param.image, 1);
    case 'convert'
        switch param.rd.mode
            case 'gray'
                if length(size(param.image))==3
                    param.image = rgb2gray(param.image);
                end
                param.prv.converted = 1;
            case 'rgb'
                % no need to convert
            otherwise
                warning('Unsupposrt color mode conversion: %s', param.rd.modes);
                param.prv.ret = -1;
        end
    case 'resize'
        if ~isequal(cmd2, [0,0])
            % resize and keep aspect ratio
            rt_w = cmd2(1) / param.w; 
            rt_h = cmd2(2) / param.h;
            % smaller ratio will ensure that the image fits in the view
            if rt_w <= rt_h
                param.w = round(param.w * rt_w);
                param.h = round(param.h * rt_w);
            else
                param.w = round(param.w * rt_h);
                param.h = round(param.h * rt_h);        
            end
            param.image = imresize(param.image, [param.h param.w]);
        end
    otherwise
        switch param.prv.feat_name
          % ===========(Start: added for each new feature ========
          % case 'xxx'
          %     param = imfeat_xxx(cmd1, cmd2, param);
          % ===========(End: added for each new feature ==========
        	case 'swt'
                param = imfeat_swt(cmd1, cmd2, param);
        	case 'mser'
                param = imfeat_mser(cmd1, cmd2, param);
        	case 'thmser'
                param = imfeat_thmser(cmd1, cmd2, param);
        	case 'ertree'
                param = imfeat_ertree(cmd1, cmd2, param);
        	case 'binary'
                param = imfeat_binary(cmd1, cmd2, param);
            otherwise
                warning('Please initialize the feature first!');
                param.prv.ret = -1;
        end
end
  
end
