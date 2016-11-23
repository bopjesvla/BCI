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
## @deftypefn {Function File} {@var{retval} =} int2task (@var{input1}, @var{input2})
##
## @seealso{}
## @end deftypefn

## Author: Kieran <kieran@IRIS>
## Created: 2016-11-22

function task = int2task (number)
  
  if number == 1
    task = 'rest'
  elseif number == 2
    task = 'jump'
  elseif number == 3
    task = 'slide'
  elseif number == 4
    task = 'spin'
  else
    printf("int2task.m: no matching task found for %c\n", number)
    task = 'rest'
  endif
endfunction
