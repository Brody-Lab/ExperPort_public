% [double time] = GetTrialStartTime(sm)    
%                Gets the time the current trial started
function [time] = GetTrialStartTime(sm)
  time = str2double(DoQueryCmd(sm, 'GET TRIAL START TIME'));
  return;
