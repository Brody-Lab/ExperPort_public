

newstartup;

datadir = bSettings('get','GENERAL','Main_Data_Directory');
datadir = [datadir,filesep,'Data'];
cd(datadir);

E = dir(pwd);
for i = 1:numel(E)
    if strcmp(E(i).name,'.') || strcmp(E(i).name,'..') || E(i).isdir==0 || strcmp(E(i).name,'CVS')
        continue; 
    end
    
    R = dir([datadir,filesep,E(i).name]);
    for j = 1:numel(R)
        if strcmp(R(j).name,'.') || strcmp(R(j).name,'..') || R(j).isdir==0 || strcmp(R(j).name,'CVS')
            continue; 
        end
        
        F = dir([datadir,filesep,E(i).name,filesep,R(j).name]);
        for k = 1:numel(F)
            if strcmp(F(k).name,'.') || strcmp(F(k).name,'..') || F(k).isdir==0 || strcmp(F(k).name,'CVS')
                continue; 
            end
        
            disp([datadir,filesep,E(i).name,filesep,R(j).name,filesep,F(k).name]);
            
            if ~isempty(strfind(F(k).name,'ASV'))
                foundfile = 0;
                for m = 1:numel(F)
                    if F(m).isdir == 0 && ~isempty(strfind(F(m).name,F(k).name(1:end-4)))
                        foundfile = 1;
                    end
                end
                
                if foundfile == 0
                    datafile = recover_ASV_solodata('file_path',[datadir,filesep,E(i).name,filesep,R(j).name,filesep,F(k).name],...
                        'cvs_commit',1,'delete_ASV',0);

                    commit_datafile_session(datafile);
                    return;
                end
            end
        end
    end
end
disp('COMPLETE');

return;

datafile = recover_ASV_solodata('cvs_commit',1,'delete_ASV',0);
newstartup;
commit_datafile_session(datafile);
