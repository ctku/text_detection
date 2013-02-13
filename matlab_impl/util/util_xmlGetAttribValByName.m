function val = util_xmlGetAttribValByName(tree, name)

val = '';
no = size(tree.attributes,2);
for i=1:no
    if strcmp(tree.attributes(i).name, name)==1
        val = tree.attributes(i).value;
        i = no + 1; % leave loop
    end
end

end