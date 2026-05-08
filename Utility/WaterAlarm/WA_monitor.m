function WA_monitor

WaterAlarm_check_running_timer = timer;
set(WaterAlarm_check_running_timer,'Period',60*15,'ExecutionMode','FixedRate','TasksToExecute',Inf,...
    'BusyMode','drop','TimerFcn','WA_startup','StartDelay',60);
start(WaterAlarm_check_running_timer)