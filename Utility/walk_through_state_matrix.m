function FullStatePath = walk_through_state_matrix(AllEvents,SM,bpod_rule,output_condensed_path)


TimerStartOffset = SM.TimerStartOffset;
TimerEndOffset   = SM.TimerEndOffset;
CounterOffset    = SM.CounterOffset;
ConditionOffset  = SM.ConditionOffset;
JumpOffset       = SM.JumpOffset;

InputMatrix      = SM.InputMatrix;
TimerStartMatrix = SM.GlobalTimerStartMatrix;
TimerEndMatrix   = SM.GlobalTimerEndMatrix;
CounterMatrix    = SM.GlobalCounterMatrix;
ConditionMatrix  = SM.ConditionMatrix;
StateTimerMatrix = SM.StateTimerMatrix;


CurrentStateCode = 1;
FullStatePath = [];
LastStateTransBlock = 0;
CondensedStatePath = 1;
for i = 1:size(AllEvents,1)
    ThisEvent = AllEvents(i,1);
    TransBlock = AllEvents(i,2);

    FullStatePath(i) = CurrentStateCode; %#ok<AGROW>
    
    if ThisEvent < TimerStartOffset
        NewStateCode = InputMatrix(     CurrentStateCode, ThisEvent);
    elseif ThisEvent < TimerEndOffset
        NewStateCode = TimerStartMatrix(CurrentStateCode, ThisEvent-(TimerStartOffset-1));
    elseif ThisEvent < CounterOffset
        NewStateCode = TimerEndMatrix(  CurrentStateCode, ThisEvent-(TimerEndOffset-1));
    elseif ThisEvent < ConditionOffset
        NewStateCode = CounterMatrix(   CurrentStateCode, ThisEvent-(CounterOffset-1));
    elseif ThisEvent < JumpOffset
        NewStateCode = ConditionMatrix( CurrentStateCode, ThisEvent-(ConditionOffset-1));
    elseif ThisEvent == 165
        NewStateCode = StateTimerMatrix(CurrentStateCode);
    elseif ThisEvent ~= 255
        display(['Unknown Event #',num2str(i),' is ',num2str(ThisEvent)]);
    end
    if NewStateCode ~= CurrentStateCode 
        if (LastStateTransBlock < TransBlock && bpod_rule == 1) || bpod_rule == 0
            CurrentStateCode = NewStateCode;
            LastStateTransBlock = TransBlock;
            CondensedStatePath(end+1) = NewStateCode; %#ok<AGROW>
        else
            disp(['Event #',num2str(i),' is ',num2str(ThisEvent),...
                  ' and would have made state transition ',num2str(CurrentStateCode+38),...
                  ' to ',num2str(NewStateCode+38)])
        end
    end
end

if output_condensed_path == 1
    FullStatePath = CondensedStatePath - 1;
else
    FullStatePath = FullStatePath + 38;
end 