bestCommand([4;4;4;4])

%P_bayes('rest', ['rest';'rest';'rest';'rest';'rest';'rest';'rest';'rest';'rest'])
%E_speed('slide', ['rest';'rest';'jump';'rest';'rest';'rest';'jump'])
%bestCommand([4;4;4;4])
%t = tic;
%a = [1 1;1 2;1 3;2 4;2 5;2 6;]

%while size(a,1)>0 && a(1,1)==1
%  a = a(2:size(a),:)
%end

%a(end+1,:) = [toc(t) 7]

%a(:,2)