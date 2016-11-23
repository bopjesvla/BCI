## Copyright (C) 2016 Kieran
## 
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*- 
## @deftypefn {Function File} {@var{retval} =} str_equals (@var{input1}, @var{input2})
##
## @seealso{}
## @end deftypefn

## Author: Kieran <kieran@IRIS>
## Created: 2016-11-22

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
  if class(str1) != class(str2)
    bool = false;
  elseif length(str1) != length(str2)
    bool = false;
  else
    for i = 1:length(str1)
      if str1(i) != str2(i)
        bool = false;
      endif
    endfor
  endif
    
endfunction
