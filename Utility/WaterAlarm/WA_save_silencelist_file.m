function handles = WA_save_silencelist_file(handles)


pname = [handles.SilenceListPath,datestr(now,'yymmdd'),filesep];
if ~exist(pname,'dir')
    mkdir(pname);
end

handles.SilenceListFile = [pname,'SilenceList_',datestr(now,'HH_MM_SS'),'.mat'];

silence_list = handles.SilenceList;

save(handles.SilenceListFile,'silence_list')