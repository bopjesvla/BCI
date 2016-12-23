function task = int2task (number)
  
  if number == 1
    task = 'jump'
  elseif number == 2
    task = 'slid'
  elseif number == 3
    task = 'spee'
  elseif number == 4
    task = 'rest'
  else
    printf('int2task.m: no matching task found for %c\n', number)
    task = 'rest'
  end
end
