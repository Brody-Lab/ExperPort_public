function check_video_hash_wrapper

while 1
    disp('******************************************');
    disp(['Run Started: ',datestr(now,'yyyy-mm-dd HH:MM:SS')]);
    disp('******************************************');
    disp(' ');
    
    check_video_hash;
    
    disp(' ');
    disp('******************************************');
    disp('COMPLETE');
    disp('******************************************');
    disp(' ');
end