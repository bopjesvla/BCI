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
## @deftypefn {Function File} {@var{retval} =} E_speed (@var{input1}, @var{input2})
##
## @seealso{}
## @end deftypefn

## Author: Kieran <kieran@IRIS>
## Created: 2016-11-22

function E = E_speed (task, class_input)
  load("commands.dat");
  load("speeds.dat");
  
  E = 0;
  if strcmp(task(1:4),"rest")
    E = middle;
  else
    T = task2int(task);
    C = classi2int(class_input);
    P_task = P_bayes(T,C);
    
    E = P_task * fast + (1-P_task) * slow;
  endif  
  
  
  
  

endfunction
