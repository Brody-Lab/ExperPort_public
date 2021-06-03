function archive_old_video(auto_delete,no_upload,varargin)

if nargin < 1; auto_delete = 0; end
if nargin < 2; no_upload = 0; end

map_bucket_drive
map_archiveme_drive
map_archive_drive

Adir =  'Z:\brody\RATTER\Video';
%Adir =  'Z:\brody\ratter\Video';
AMdir = 'Y:\RATTER\Video';
Bdir  = 'X:\RATTER\Video';

Bfiles = file_recurser(Bdir,{''});

filestodelete_archiveme = cell(0);
filestodelete_bucket    = cell(0);

total_files = numel(Bfiles);
filecount = 0;

for i = 1:numel(Bfiles)
    if Bfiles(i).bytes > 0 && ~isempty(Bfiles(i).name) &&...
        ~isempty(Bfiles(i).date) &&...
        now - datenum(Bfiles(i).date,'dd-mmm-yyyy HH:MM:SS') > 365
        %This is an old video file that should be archived
        
        afile  = [Adir, Bfiles(i).dir,filesep,Bfiles(i).name];
        amfile = [AMdir,Bfiles(i).dir,filesep,Bfiles(i).name];
        bfile  = [Bdir, Bfiles(i).dir,filesep,Bfiles(i).name];
        
        disp(['Checking ',num2str(i),' of ',num2str(numel(Bfiles)),' ',bfile,'...']);
        
        %Does the file's directory exist on archive_me? If not make it
        amfile_dir = [AMdir,Bfiles(i).dir];
        if ~exist(amfile_dir,'dir')
            try %#ok<TRYNC>
                disp(['Making Directory ',amfile_dir,'...']);
                mkdir(amfile_dir);
            end
        end
        
        %Let's check if the file is already on archive
        if exist(afile,'file')
            tempa = dir(afile);
            if ~isempty(tempa) && tempa.bytes == Bfiles(i).bytes
                %The file on archive is the same size as the file on bucket.
                filestodelete_bucket{end+1} = bfile; %#ok<AGROW>
                
                if exist(amfile,'file')
                    %The file is also on archive_me
                    filestodelete_archiveme{end+1} = amfile; %#ok<AGROW>
                end
            end
                
        else    
            %Let's see if the file is already on archive_me
            if ~exist(amfile,'file') && no_upload == 0
                %File is not on archive_me so let's copy it over
                try %#ok<TRYNC>
                    disp(['Copying ',bfile,' to archive_me...']);
                    copyfile(bfile,amfile,'f')
                    filecount = filecount + 1;
                end
            end
        end
    end
end

disp(' ');
disp('File Checking COMPLETE');
disp(' ');
disp([num2str(total_files),' files checked on bucket']);
disp(' ');
disp([num2str(filecount),' files copied from bucket to archive_me']);
disp(' ');
disp([num2str(numel(filestodelete_bucket)),' files found on archive that can be deleted from bucket'])
disp(' ');
disp([num2str(numel(filestodelete_archiveme)),' files found on archive that can be deleted from archive_me'])


if auto_delete == 2
    return
end

if ~isempty(filestodelete_archiveme)
    
    if auto_delete == 0
        answer = questdlg('Do you want to delete files from archiveme that are stored on archive?','','Yes','No','No');
    else
        answer = 'Yes';
    end
    
    if strcmp(answer,'Yes')
        disp('Deleting files from archiveme...');
        for i = 1:numel(filestodelete_archiveme)
            disp(['DELETING: ',filestodelete_archiveme{i}]);
            try
                eval(['!del ',filestodelete_archiveme{i}]);
            catch
                disp('delete failed');
            end
        end
    end
end
    
if ~isempty(filestodelete_bucket)
    if auto_delete == 0
        answer = questdlg('Do you want to delete files from bucket that are stored on archive?','','Yes','No','No');
    else
        answer = 'Yes';
    end
    
    if strcmp(answer,'Yes')
        disp('Deleting files from bucket...');
        for i = 1:numel(filestodelete_bucket)
            disp(['DELETING: ',filestodelete_bucket{i}]);
            try
                eval(['!del ',filestodelete_bucket{i}]);
            catch
                disp('delete failed');
            end    
        end
    end
end    



            
            