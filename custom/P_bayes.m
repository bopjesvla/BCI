function P = P_bayes (T, C)

  %load essential data structures
  load('commands.mat');
  load('bias.mat'); %bias is the a-priori probability of the user thinking of a particular task
  load('c_perf.mat');
  
  %target task in numerical form
  %T = task2int(task)
  %set of recorded classifications in numerical form
  %C = classi2int(class_input)
  
  P = ( bias(T) * prod(C_perf(C,T)) ) / ...
      (   ...
        bias(rest) * prod(C_perf(C,rest)) + ...
        bias(jump) * prod(C_perf(C,jump)) + ...
        bias(slid) * prod(C_perf(C,slid)) + ...
        bias(spee) * prod(C_perf(C,spee)) ...
      );
  
end
