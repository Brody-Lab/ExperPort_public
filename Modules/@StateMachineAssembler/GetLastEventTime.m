% [double time] = GetLastEventTime(sm)    
%                Gets the time, in seconds, of the last event as recorded
%                by the bpod
function [time] = GetLastEventTime(sm)
  time = str2double(DoQueryCmd(sm, 'GET LAST EVENT TIME'));
  return;
