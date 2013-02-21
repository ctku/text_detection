tic
a=ones(100,100);
b=2*ones(100,100);
for i=1:100
    c = a.*b;
%     c = bsxfun(@times,a,b);
end
toc