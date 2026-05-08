function WA_startup

h = findall(0,'Name','WaterAlarm');

if isempty(h)
    %WaterAlarm is not running, start it
    WaterAlarm;
else
    %WaterAlarm is running
    h = findall(0,'Tag','Run_Toggle');
    if get(h,'value') == 0
        %WaterAlarm is paused, unpause it
        t = timerfindall('TimerFcn','WaterAlarm(''Update'')');
        if strcmp(get(t,'running'),'off')
            set(h,'string','Running','backgroundcolor',[0,1,0],'value',1);
            start(t);
        end
    end
end