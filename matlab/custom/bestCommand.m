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
## @deftypefn {Function File} {@var{retval} =} bestCommand (@var{input1}, @var{input2})
##
## @seealso{}
## @end deftypefn

## Author: Kieran <kieran@IRIS>
## Created: 2016-11-22

function command = bestCommand (class_inputs)
  load('commands.dat');
  all_commands = ['rest';'jump';'slid';'spin'];
  
  
  %[_, argmax] = max( E_speed(all_commands, class_inputs));
  
  argmax = 1;
  max_spd = E_speed(all_commands(1,:), class_inputs);
  printf("rest: %d\n", max_spd);
  for i = 2:size(all_commands,1)
    exp_spd = E_speed(all_commands(i,:), class_inputs);
    printf("%s: %d\n", all_commands(i,:), exp_spd);
    if exp_spd > max_spd
      max_spd = exp_spd;
      argmax = i;
    endif
  endfor
  
  
  
  command = all_commands(argmax,:);
  
endfunction
