function [SC, plottables]=state_colors(obj)


% Colors that the various states take when plotting

SC = struct( ...
  'dead_time',         [1 0.75 0.75],  ...
  'wait_for_cpoke1',   [125 196 192]/300, ...
  'wait_for_cpoke2',   [152 239 234]/255, ...
  'wait_for_spoke',    [217 255 235]/255, ...
  'sound1',            [157 136 196]/300, ...
  'sound2',            [200 172 250]/255, ...
  'inter_light_gap',   [226 176 138]/300, ...
  'inter_light_sound', [255 235   0]/255, ...
  'center_to_side_gap',[255 198 155]/255, ...
  'hit_state',         [128 255 128]/255, ...
  'left_reward',       [128 255 128]/255, ...
  'right_reward',      [128 255 128]/255, ...
  'iti',               [128 128 128]/255, ...
  'error_state',       [255   0   0]/255);


% Which states to plot, together with which event indices indicate an
% exit from that type of state
plottables = { ...
  'dead_time'          1:6 ;  ...
  'wait_for_cpoke1',   1:6 ; ...
  'sound1',            1:7 ; ...
  'inter_light_gap',   1:7 ; ...
  'inter_light_sound', 1:7 ; ...
  'wait_for_cpoke2',   1:6 ; ...
  'sound2',            1:7 ; ...
  'center_to_side_gap',1:7 ; ...
  'wait_for_spoke',    1:6 ; ...
  'hit_state',         1:7 ; ...
  'error_state',       1:7 ; ...
  'left_reward',       1:7 ; ...
  'right_reward',      1:7 ; ...
  'iti',               1:7 ; ...
  };

