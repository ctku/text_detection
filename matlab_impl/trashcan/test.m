function test

fv = [1 1; 2 1; 1 -1; 2 -1];
lb = [0  ;   0;    1;    1];
svm{1} = svmtrain(fv, lb, 'SHOWPLOT',true);
ft_vector = [2 0.5];
result = svmclassify(svm{1}, ft_vector,'SHOWPLOT',true);

svm{2} = svmtrain(fv, lb, 'SHOWPLOT',true);
ft_vector = [2 0.5];
result = svmclassify(svm{2}, ft_vector,'SHOWPLOT',true);

end

