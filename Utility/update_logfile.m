function update_logfile(file,str)

%This function is useb by Bpod code to write an entry into the runrats log
%when an issue is encountered

time = datestr(now,'yymmdd HH:MM:SS');
str = [time,'  Bpod Issue: ',str,char(10)];

f = fopen(file,'a+t');
fseek(f,0,'eof');
fprintf(f,str,'char');
fclose(f);