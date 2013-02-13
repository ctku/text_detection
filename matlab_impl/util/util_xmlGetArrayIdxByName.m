function idx = util_xmlGetArrayIdxByName(tree, name)

idx = 0;
no = size(tree,2);
for i=1:no
    if strcmp(tree(i).name, name)==1
        idx = i;
        i = no + 1; % leave loop
    end
end

end