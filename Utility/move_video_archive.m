function move_video_archive(experimenter,ratname,direction,varargin)
%This is a one time function to move move video archive from archive_me to TigerData

map_tigerdata_drive
map_archiveme_drive

if nargin < 3; direction = 1; end
if nargin < 2; ratname = ''; end
if nargin < 1; experimenter = ''; end

if ~isempty(experimenter) && ~isempty(ratname)
    AMdir = ['Y:\RATTER\Video\',experimenter,'\',ratname];
    TDdir = ['Z:\physdata\RATTER\Video\',experimenter,'\',ratname];
elseif ~isempty(experimenter)
    AMdir = ['Y:\RATTER\Video\',experimenter];
    TDdir = ['Z:\physdata\RATTER\Video\',experimenter];
else
    AMdir = 'Y:\RATTER\Video\';
    TDdir = 'Z:\physdata\RATTER\Video\';
end

AMfiles = file_recurser(AMdir,{''});

total_files = numel(AMfiles);
filecount = 0;

if direction == 1; order = 1:numel(AMfiles);
else,              order = numel(AMfiles):-1:1;
end

for i = order
    if AMfiles(i).bytes > 0 && ~isempty(AMfiles(i).name) &&...
        ~isempty(AMfiles(i).date) %&& AMfiles(i).isdir == 0
        
        [pname,fname,ext] = fileparts(AMfiles(i).name);
        if strcmp(ext,'.lnk') || strcmp(ext,'.db'); continue; end
        if isempty(fname);     continue; end
        
        amfile = [AMdir, AMfiles(i).dir,filesep,AMfiles(i).name];
        tdfile = [TDdir,AMfiles(i).dir,filesep,AMfiles(i).name];
        
        disp(['Checking ',num2str(i),' of ',num2str(numel(AMfiles)),' ',amfile,'...']);
        
        %Does the file's directory exist on tigerdata? If not make it
        tdfile_dir = [TDdir,AMfiles(i).dir];
        if ~exist(tdfile_dir,'dir')
            try %#ok<TRYNC>
                disp(['Making Directory ',tdfile_dir,'...']);
                mkdir(tdfile_dir);
            end
        end
           
        %Let's see if the file is already on tigerdata
        if ~exist(tdfile,'file')
            %File is not on tigerdata so let's copy it over
            try %#ok<TRYNC>
                disp(['Copying ',amfile,' to TigerData...']);
                copyfile(amfile,tdfile,'f')
                filecount = filecount + 1;
            end
        end

        %Now let's confirm the file on tigerdata has the same hash as
        %the file on archive_me. If so let's delete the file on archive_me.

        disp(['Calculating ',tdfile,' hash...']);
        [td_hash,mssg] = DataHash(tdfile);
        amhashfile = [AMdir, AMfiles(i).dir,filesep,'File_DataHash.mat'];
        am_hash = [];
        if exist(amhashfile,'file')
            load(amhashfile)
            filepos = find(strcmp(local_datahash(:,1),AMfiles(i).name),1,'last');
            if ~isempty(filepos)
                am_hash = local_datahash{filepos,2};
            end
        end
        if isempty(am_hash)
            disp(['Calculating ',amfile,' hash...']);
            [am_hash,mssg] = DataHash(amfile);
        end
            
        if strcmp(am_hash,td_hash)
            %The hashes match, ok to delete archive_me file
            
            disp(['HASH MATCH. DELETING: ',amfile]);
            try
                eval(['!del ',amfile]);
            catch
                disp('delete failed');
            end 
        else
            disp('Hash did not match!')
            disp(['DELETING: ',tdfile]);
            eval(['!del ',tdfile]);
            disp(['Copying ',amfile,' to TigerData...']);
            copyfile(amfile,tdfile,'f')
            disp('Recalculating Hash')
            [am_hash,mssg] = DataHash(amfile);
            [td_hash,mssg] = DataHash(tdfile);
            if strcmp(am_hash,td_hash)
                disp('New hashes match')
                disp(['DELETING: ',amfile]);
                try
                    eval(['!del ',amfile]);
                catch
                    disp('delete failed');
                end 
            else
                disp(' ')
                disp('*******************')
                disp('HASHES DO NOT MATCH')
                disp('Not deleting anyfile')
                disp(amfile)
                disp('*******************')
                disp(' ')
            end
        end
    end
end

disp(' ');
disp('File Checking COMPLETE');
disp(' ');
disp([num2str(total_files),' files checked on Archive_Me']);
disp(' ');
disp([num2str(filecount),' files copied from Archive_Me to TigerData']);




            
            