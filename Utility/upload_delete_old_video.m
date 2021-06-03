function upload_delete_old_video

bpath  = 'X:\RATTER\Video';

map_bucket_drive;

vpath  = bSettings('get','VIDEO','video_path');
vfiles = file_recurser(vpath,'');

for i = 1:numel(vfiles)
    if isempty(vfiles(i).name); continue; end
    vfile = [vpath,vfiles(i).dir,filesep,vfiles(i).name];
    bfile = [bpath,vfiles(i).dir,filesep,vfiles(i).name];
    bdir  = [bpath,vfiles(i).dir];
    
    if ~exist(bfile,'file')
        
        if ~exist(bdir,'dir')
            try
                mkdir(bdir);
                disp(['Making directory ',bdir,'...']);
            catch
                disp(['Unable to make ',bdir]);
                continue;
            end
        end
    
        try
            copyfile(vfile,bfile,'f');
            disp(['Uploaded ',vfile]);
        catch
            disp(['Unable to upload ',vfile]);
            continue;
        end
    else
        bfiledata = dir(bfile);
        if bfiledata.bytes < vfiles(i).bytes
            
            try
                copyfile(vfile,bfile,'f');
                disp(['Replaced ',bfile]);
            catch
                disp(['Unable to replace ',bfile]);
                continue;
            end
        end
    end
    
    if now - datenum(vfiles(i).date,'dd-mmm-yyyy HH:MM:SS') > 14
        try
            delete(vfile);
            disp(['Deleted ',vfile]);
        catch
            disp(['Unable to delete ',vfile]);
            continue;
        end
    end
end

disp('COMPLETE');