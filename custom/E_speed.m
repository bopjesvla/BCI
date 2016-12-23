function E = E_speed (task, class_input)
  load('commands.mat');
  load('speeds.mat');
  
  E = 0;
  T = task2int(task);
  C = class_input; %classi2int(class_input);
  P_task = P_bayes(T,C);
  if strcmp(task(1:4), 'rest')
    E = P_task * middle_fast + (1-P_task) * middle_slow;
  else
    E = P_task * fast + (1-P_task) * slow;
  end
  
  fprintf('%d: %d\n', T, E);
  
end
