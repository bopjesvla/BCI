function command = bestCommand (class_inputs)
  load('commands.mat');
  all_commands = ['jump';'slid';'spee';'rest'];
  
  argmax = 1;
  max_spd = E_speed(all_commands(1,:), class_inputs);
  %disp(max_spd)
  for i = 2:size(all_commands,1)
    exp_spd = E_speed(all_commands(i,:), class_inputs);
    %disp(exp_spd)
    if exp_spd > max_spd
      max_spd = exp_spd;
      argmax = i;
    end
  end
  
  
  
  command = all_commands(argmax,:);
  
end
