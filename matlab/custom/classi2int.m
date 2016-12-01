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
## @deftypefn {Function File} {@var{retval} =} classi2int (@var{input1}, @var{input2})
##
## @seealso{}
## @end deftypefn

## Author: Kieran <kieran@IRIS>
## Created: 2016-11-22

%convert vector of string commands to vector of numerical commands matching commands in data
% 1 - rest
% 2 - jump
% 3 - slide
% 4 - spin
function class_nums = classi2int (class_strs)
  class_nums = [];
  for i = 1:size(class_strs,1)
    class_num = task2int(class_strs(i,:));
    if class_num > 0 && class_num <= 4
      class_nums(i) = class_num;
    endif    
  endfor
  
  
  
endfunction
