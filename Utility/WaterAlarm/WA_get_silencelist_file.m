function handles = WA_get_silencelist_file(handles)

x = dir(handles.SilenceListPath);
pname = cell(0);
for i = 1:numel(x)
    if x(i).isdir == 1 && numel(x(i).name) == 6 
        pname{end+1} = x(i).name;
    end
end
pname = unique(pname');
pname = pname{end};

x = dir([handles.SilenceListPath,pname]);

fname = cell(0);
for i = 1:numel(x)
    if x(i).isdir == 0
        fname{end+1} = x(i).name;
    end
end

if ~isempty(fname)
    sfname = unique(fname');
    handles.SilenceListFile = [handles.SilenceListPath,pname,filesep,sfname{end}];
else
    handles.SilenceListFile = '';
end