function start_training_room_status

TrainingRoomStatusTimer = timerfind('Tag','TrainingRoomStatusTimer');

if isempty(TrainingRoomStatusTimer)
    TrainingRoomStatusTimer = timer;
    set(TrainingRoomStatusTimer,...
        'Period',       60,...
        'ExecutionMode','FixedRate',...
        'TasksToExecute',Inf,...
        'TimerFcn',     'training_room_status',...
        'Tag',          'TrainingRoomStatusTimer');
end

start(TrainingRoomStatusTimer);
    