function bool = str_equals (str1, str2)
  
  
  %str1 should contain the string "rest"
  %printf("Computer, how do you spell \"rest\"?\n")
  %disp(str1)
  
  %for i=1:length(str1)
  %  printf("%c.", str1(i));
  %endfor
  %printf("\n");
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  %error("FUCK THIS SHIT!");
  
  
  
  
  
  bool = true;
  if class(str1) ~= class(str2)
    bool = false;
  elseif length(str1) ~= length(str2)
    bool = false;
  else
    for i = 1:length(str1)
      if str1(i) ~= str2(i)
        bool = false;
      end
    end
  end
    
end
