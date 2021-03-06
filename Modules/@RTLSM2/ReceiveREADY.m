function [] = ReceiveREADY(sm, cmd)
  [lines] = FSMClient('readlines', sm.handle);
  [m,n] = size(lines);
  line = lines(1,1:n);
  if ~any(strcmp(cellstr(lines),'READY'))
  	error(sprintf('RTLinux FSM Server did not send READY during %s command.', cmd)); 
  end
end
