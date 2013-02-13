function idx = util_xmlGetArrayIdxByChilName(tree, name)

idx = 0;
no = size(tree.children,2);
for i=1:no
    if strcmp(tree.children(i).name, name)==1
        idx = i;
        i = no + 1; % leave loop
    end
end

end