% sm = ForceTrialComplete(sm) Sets the Trial Complete flag to 1

function [sm] = ForceTrialComplete(sm)
     DoSimpleCmd(sm, 'FORCE TRIAL COMPLETE');
     return;

