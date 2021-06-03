function [SC, plottables]=state_colors(obj)

% Colors that the various states take when plotting
SC = struct( ...
  'wait_for_cpoke',  [1 0.75 0.75],   ...  
  'rand_valve_delay', [0 0.1 0.95],   ...
  'valid_samp_time', [0.8 0.1 0.95],   ... 
  'hold_cpoke',      [0.8 0.1 0.95],   ... 
  'wait_for_apoke',  [0.5 0.7 0.7],    ...
  'left_reward',     [0.5 0.9 0.5],    ...
  'right_reward',    [0.5 0.9 0.5],    ...
  'drink_time',      [0.5 0.9 0.5],    ...
  'left_dirdel',     [0.5 0.9 0.5],    ...  
  'right_dirdel',    [0.5 0.9 0.5],    ...
  'timeout',         [0.6 0.12 0.12],  ...
  'iti',             [0.7 0.7 0.7],    ...
  'dead_time',       'w',    ...
  'state35',         [0.3 0.3 0.3],    ...
  'extra_iti',       [0.9 0 0], ...
  'hit_state',       [0.5 0.9 0.5]);


% Which states to plot, together with which event indices indicate an
% exit from that type of state
plottables = { ...
  'dead_time'          1:7   ; ...
  'wait_for_cpoke'     1:6   ; ...
  'rand_valve_delay'    1:7  ; ...
  'valid_samp_time'    1:7   ; ...
  'hold_cpoke'          1:7   ; ...
  'wait_for_apoke'     1:6   ; ...
  'left_reward'        1:7   ; ...
  'left_dirdel'        1:7   ; ...
  'right_dirdel'       1:7   ; ...
  'right_reward'       1:7   ; ...
  'drink_time'         1:7   ; ...
  'timeout'            1:7   ; ...
  'extra_iti'          1:7   ; ...
  'iti'                1:7   ; ...
  'hit_state'          1:7   ; ...
             };

