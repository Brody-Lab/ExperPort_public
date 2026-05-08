% [double time] = GetLastEventTimeMatlab(sm)    
%                Gets the time, in seconds, of the last event as recorded
%                by matlab now
function [time] = GetLastEventTimeMatlab(sm)
  time = str2double(DoQueryCmd(sm, 'GET LAST EVENT TIME MATLAB'));
  return;
