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
## @deftypefn {Function File} {@var{retval} =} task2int (@var{input1}, @var{input2})
##
## @seealso{}
## @end deftypefn

## Author: Kieran <kieran@IRIS>
## Created: 2016-11-22

%convert string of task to int of task, as defined by:
% 1 - rest
% 2 - jump
% 3 - slide
% 4 - spin
function task_int = task2int (task_str)
  task_int = 1;
  if str_equals(task_str,"rest")
    task_int = 1;
  elseif str_equals(task_str, "jump")
    task_int = 2;
  elseif str_equals(task_str, "slid")
    task_int = 3;
  elseif str_equals(task_str, "spin")
    task_int = 4;
  else
    printf("task2int.m: no matching task found for string: \"%s\"\n", task_str);
    %error("fuck this shit");
  endif
endfunction
