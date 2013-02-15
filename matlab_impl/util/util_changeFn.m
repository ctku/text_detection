function [fn_out] = util_changeFn(fn_in, pos, patt)

fn_len = length(fn_in);
pt_len = length(patt);
fn_out = fn_in;
last_dot = max(strfind(fn_in,'.'));
switch pos
    % operate related with filename
    case 'insert_after_filename'
        dot_and_ext = fn_in(last_dot:fn_len);
        dae_len = length(dot_and_ext);
        fn_out(last_dot:last_dot+pt_len-1) = patt;
        fn_out(last_dot+pt_len:last_dot++pt_len+dae_len-1) = dot_and_ext;
    case 'replace_extension'
        fn_out(last_dot+1:last_dot+pt_len) = patt;
    case 'get_filename_and_extension'
        last_slash = max(strfind(fn_in,'/'));
        fn_out = '';
        fn_out(1:fn_len-last_slash) = fn_in(last_slash+1:end);
    case 'remove_filename_and_extension'
        last_slash = max(strfind(fn_in,'/'));
        fn_out = '';
        fn_out(1:last_slash) = fn_in(1:last_slash);
    case 'replace_filename_and_extension'
        path = util_changeFn(fn_in, 'remove_filename_and_extension', '');
        fn_out = [path patt];
    % operate path with filename
    case 'cd .._with_filename'
        fn = util_changeFn(fn_in, 'get_filename_and_extension', '');
        path = util_changeFn(fn_in, 'remove_filename_and_extension', '');
        path = util_changeFn(path, 'cd ..', '');
        fn_out = [path fn];
    case 'cd _with_filename'
        last_slash = max(strfind(fn_in,'/'));
        fn_and_ext = fn_in(last_slash+1:fn_len);
        fae_len = length(fn_and_ext);
        fn_out(last_slash+1:last_slash+pt_len+1) = [patt '/'];
        fn_out(last_slash+pt_len+2:last_slash++pt_len+fae_len+1) = fn_and_ext;
    case 'cd _mkdir_with_filename'
        last_slash = max(strfind(fn_in,'/'));
        fn_and_ext = fn_in(last_slash+1:fn_len);
        fae_len = length(fn_and_ext);
        check = [fn_out(1:last_slash) patt];
        if ~exist(check, 'dir')
            mkdir(check);
        end
        fn_out(last_slash+1:last_slash+pt_len+1) = [patt '/'];
        fn_out(last_slash+pt_len+2:last_slash++pt_len+fae_len+1) = fn_and_ext;
    % operate path without filename
    case 'cd ..'
        if isempty(fn_in)
           fn_in = strrep([pwd '\'], '\', '/');
        end
        last_slash = max(strfind(fn_in,'/'));
        last_2nd_slash = max(strfind(fn_in(1:last_slash-1),'/'));
        fn_out = '';
        fn_out(1:last_2nd_slash) = fn_in(1:last_2nd_slash);
    case 'cd '
        fn_out(fn_len+1:fn_len+pt_len+1) = [patt '/'];
    case 'cd _mkdir'
        check = [fn_in patt];
        if ~exist(check, 'dir')
            mkdir(check);
        end
        fn_out(fn_len+1:fn_len+pt_len+1) = [patt '/'];
    otherwise
        warning('Unsupported position: %s',pos);
end

end