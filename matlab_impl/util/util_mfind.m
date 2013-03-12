function [I B] = util_mfind(M, X)

% find a row or a column?
if(size(X,2) == 1);
    % boolean indexes
    B = ismember(M', X', 'rows')';
else
    % boolean indexes
    B = ismember(M, X, 'rows');
end

% row/column indexes
I = find(B == true);