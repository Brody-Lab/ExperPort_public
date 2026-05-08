function archive_old_video_wrapper

while 1
    
    starttime = now;
    disp('******************************************');
    disp(['Run Started: ',datestr(starttime,'yyyy-mm-dd HH:MM:SS')]);
    disp('******************************************');
    disp(' ');
    
    archive_old_video(1);
    
    disp(' ');
    disp('******************************************');
    disp('COMPLETE');
    disp('******************************************');
    disp(' ');
    
    rundur = (now - starttime) * 24;
    if rundur < 4
        pausedur = ceil((4 - rundur) * 3600);
        disp(['Pausing for ',num2str(pausedur),'s']);
        disp(['Next run will start at: ',datestr(now + (pausedur/(3600*24)),'yyyy-mm-dd HH:MM:SS')]);
        pause(pausedur);
    end
end