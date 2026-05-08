function archive_old_video(auto_delete,no_upload,time_to_kill,direction,varargin)

%update 2026-03-27 we will no longer be moving video from cup to archive_me
%and then to archive. Archive has not existed for over a year and
%archive_me is full. Therefore videos after 1 year on cup will be moved to
%TigerData

if nargin < 1; auto_delete = 0; end
if nargin < 2; no_upload = 0; end
if nargin < 3; time_to_kill = Inf; end %how long to run function in minutes
if nargin < 4; direction = 1; end

start_time = now;

map_bucket_drive
map_tigerdata_drive

TDdir =  'Z:\physdata\RATTER\Video';
Bdir  = 'X:\RATTER\Video';

Bfiles = file_recurser(Bdir,{''});

filestodelete_bucket    = cell(0);

total_files = numel(Bfiles);
filecount = 0;

if direction == 1; order = 1:numel(Bfiles);
else,              order = numel(Bfiles):-1:1;
end

for i = order
    
    if (now - start_time) * 24 * 60 > time_to_kill; return; end
    
    if Bfiles(i).bytes > 0 && ~isempty(Bfiles(i).name) &&...
        ~isempty(Bfiles(i).date) &&...
        now - datenum(Bfiles(i).date,'dd-mmm-yyyy HH:MM:SS') > 300
        %This is an old video file that should be archived
        
        [pname,fname,ext] = fileparts(Bfiles(i).name); %#ok<ASGLU>
        if ~strcmp(ext,'.mp4'); continue; end
        
        tdfile = [TDdir,Bfiles(i).dir,filesep,Bfiles(i).name];
        bfile  = [Bdir, Bfiles(i).dir,filesep,Bfiles(i).name];
        
        disp(['Checking ',num2str(i),' of ',num2str(numel(Bfiles)),' ',bfile,'...']);
        
        %Does the file's directory exist on tigerdata? If not make it
        tdfile_dir = [TDdir,Bfiles(i).dir];
        if ~exist(tdfile_dir,'dir')
            try %#ok<TRYNC>
                disp(['Making Directory ',tdfile_dir,'...']);
                mkdir(tdfile_dir);
            end
        end

        %Let's see if the file is already on tigerdata
        if ~exist(tdfile,'file') && no_upload == 0
            %File is not on tigerdata so let's copy it over
            disp(['Copying ',bfile,' to TigerData...']);
            try
                copyfile(bfile,tdfile,'f')
                filecount = filecount + 1;
            catch
                disp('ERROR: Unable to copy file...');
                continue;
            end
        end
        
        if (now - start_time) * 24 * 60 > time_to_kill; return; end

        %Now let's confirm the file on tigerdata has the same hash as
        %the file on cup. If so let's delete the file on cup.

        disp(['Calculating ',tdfile,' hash...']);
        try
            [td_hash,mssg] = DataHash(tdfile); %#ok<ASGLU>
        catch
            disp('ERROR: unable to compute hash...')
            continue;
        end
        bhashfile = [Bdir, Bfiles(i).dir,filesep,'File_DataHash.mat'];
        b_hash = [];
        if exist(bhashfile,'file')
            load(bhashfile) %#ok<LOAD>
            filepos = find(strcmp(local_datahash(:,1),Bfiles(i).name),1,'last'); %#ok<USENS>
            if ~isempty(filepos)
                b_hash = local_datahash{filepos,2};
            end
        end
        if isempty(b_hash)
            disp(['Calculating ',bfile,' hash...']);
            try
                [b_hash,mssg] = DataHash(bfile); %#ok<ASGLU>
            catch
                disp('ERROR: unable to compute hash...');
                continue;
            end
        end

        if strcmp(b_hash,td_hash)
            %The hashes match, ok to delete cup file
            if auto_delete == 1
                disp(['HASH MATCH. DELETING: ',bfile]);
                try
                    eval(['!del ',bfile]);
                catch
                    disp('delete failed');
                end 
            else
                filestodelete_bucket{end+1} = bfile; %#ok<AGROW>
            end
        else
            disp('Hash did not match!')
            disp(['DELETING: ',tdfile]);
            try
                eval(['!del ',tdfile]);

                if (now - start_time) * 24 * 60 > time_to_kill; return; end

                disp(['Copying ',bfile,' to TigerData...']);
                copyfile(bfile,tdfile,'f')

                if (now - start_time) * 24 * 60 > time_to_kill; return; end

                disp('Recalculating Hash')
                [b_hash,mssg]  = DataHash(bfile); %#ok<ASGLU>
                [td_hash,mssg] = DataHash(tdfile); %#ok<ASGLU>
                if strcmp(b_hash,td_hash)
                    disp('New hashes match')
                    if auto_delete == 1
                        disp(['DELETING: ',bfile]);
                        try
                            eval(['!del ',bfile]);
                        catch
                            disp('delete failed');
                        end 
                    else
                        filestodelete_bucket{end+1} = bfile; %#ok<AGROW>
                    end
                else
                    disp(' ')
                    disp('*******************')
                    disp('HASHES DO NOT MATCH')
                    disp('Not deleting anyfile')
                    disp(bfile)
                    disp('*******************')
                    disp(' ')
                end
            catch
                disp('ERROR: unable to redo file...')
            end
        end
    end
end

disp(' ');
disp('File Checking COMPLETE');
disp(' ');
disp([num2str(total_files),' files checked on Cup']);
disp(' ');
disp([num2str(filecount),' files copied from Cup to TigerData']);
disp(' ');
disp([num2str(numel(filestodelete_bucket)),' files found on TigerData that can be deleted from Cup'])

if auto_delete == 2
    return
end

% if ~isempty(filestodelete_archiveme)
%     
%     if auto_delete == 0
%         answer = questdlg('Do you want to delete files from archiveme that are stored on archive?','','Yes','No','No');
%     else
%         answer = 'Yes';
%     end
%     
%     if strcmp(answer,'Yes')
%         disp('Deleting files from archiveme...');
%         for i = 1:numel(filestodelete_archiveme)
%             disp(['DELETING: ',filestodelete_archiveme{i}]);
%             try
%                 eval(['!del ',filestodelete_archiveme{i}]);
%             catch
%                 disp('delete failed');
%             end
%         end
%     end
% end
    
if ~isempty(filestodelete_bucket)
    if auto_delete == 0
        answer = questdlg('Do you want to delete files from Cup that are stored on TigerData?','','Yes','No','No');
    else
        answer = 'Yes';
    end
    
    if strcmp(answer,'Yes')
        disp('Deleting files from Cup...');
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



            
            