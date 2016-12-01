%convert string of task to int of task, as defined by (first 4 letters):
% 1 - jump
% 2 - slide
% 3 - speed
% 4 - rest
function task_int = task2int (task_str)
  task_int = 1;
  if str_equals(task_str,'jump')
    task_int = 1;
  elseif str_equals(task_str, 'slid')
    task_int = 2;
  elseif str_equals(task_str, 'spee')
    task_int = 3;
  elseif str_equals(task_str, 'rest')
    task_int = 4;
  else
    printf('task2int.m: no matching task found for string: \');
    %error('fuck this shit');
  end
end
