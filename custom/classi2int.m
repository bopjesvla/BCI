%convert vector of string commands to vector of numerical commands matching commands in data
% 1 - rest
% 2 - jump
% 3 - slide
% 4 - spin
function class_nums = classi2int (class_strs)
  class_nums = zeros(size(class_strs,1),1);
  for i = 1:size(class_strs,1)
    class_num = task2int(class_strs(i,:));
    if class_num > 0 && class_num <= 4
      class_nums(i) = class_num;
    end 
  end
end
