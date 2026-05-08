function [missing,difsize,filecount] = check_archiveme_phys_files(auto_delete,varargin)

%This function will check if files that were placed in
%archive_me\RATTER\PhysData\Raw...
%now exist on archive.  If so, the user is given them option to delete the
%files from archive_me and bucket.
%
%The user selects a folder in archive_me\RATTER\PhysData\Raw
%all files in that folder (and subfolders) are indexed and checked to exist
%on archive.  If a file is not found on archive the full path is added to
%the output variable missing.  If a file is found on archive but the size
%of the file on archive does not equal the size of the file on archive_me
%the full path is added the the output variable difsize.  
%
%If files from archive_me files are found on archive, the user is given the
%option at the end to delete them from archive_me and from bucket.  To
%avoid being asked the question and have to click Yes, set the input
%variable auto_delete to 1.
%
%Optional Inputs:
%   auto_delete     Set to 1 to automatically delete files from archive_me
%                   and bucket that are found on archive. Setting no input
%                   this defaults to 0 and the user is asked if they want
%                   to delete files
%
%Outputs:
%   missing         full path of files on archive_me that are not on
%                   archive
%   
%   difsize         full path of files on archive_me that are on archive
%                   but the size of the files do not agree
%
%   filecount       the total number of files found in the folder selected
%                   by the user including subfolders
%
%Written by Chuck 2020

if nargin == 0; auto_delete = 0; end

map_bucket_drive;
map_archiveme_drive;
map_archive_drive;

Adir =  'Z:\RATTER\PhysData\Raw\';
AMdir = 'Y:\RATTER\PhysData\Raw\';
Bdir  = 'X:\RATTER\PhysData\Raw\';

cd(Bdir);
p = uigetdir;
subdir = p(numel(AMdir)+1:end);

Bfiles = file_recurser(p,{''});

missing = cell(0);
difsize = cell(0);
filestodelete_archiveme = cell(0);
filestodelete_bucket    = cell(0);

total_files = numel(Bfiles);
filecount = 0;
for i=1:total_files
    if ~isempty(Bfiles(i).name)
        filecount = filecount+1;
        disp(['Checking ',num2str(i),' of ',num2str(total_files)]);
        if exist([AMdir,subdir,Bfiles(i).dir,'\',Bfiles(i).name],'file')
            disp(['Duplicate: ',p,Bfiles(i).dir,'\',Bfiles(i).name]);
            
            temp = dir([AMdir,subdir,Bfiles(i).dir,'\',Bfiles(i).name]);
            if temp.bytes == Bfiles(i).bytes
                filestodelete_bucket{end+1} = [Bdir,subdir,Bfiles(i).dir,'\',Bfiles(i).name];
            end
        end
    end
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
    
    
    
