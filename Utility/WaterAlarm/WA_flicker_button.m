function WA_flicker_button

h = findall(0,'Tag','Run_Toggle');
if get(h,'value') == 1
    clr = get(h,'backgroundcolor');
    str = get(h,'string');
    strend = str(end-2:end);
    newstr = str;
    if     strcmp(strend,'ing'); newstr = [str,'   '];
    elseif strcmp(strend,'   '); newstr = [str(1:end-3),'.  '];
    elseif strcmp(strend,'.  '); newstr = [str(1:end-3),'.. '];
    elseif strcmp(strend,'.. '); newstr = [str(1:end-3),'...'];
    elseif strcmp(strend,'...'); newstr = [str(1:end-3),'   '];
    end
        
        
    if all(clr == [0,1,0])
        set(h,'backgroundcolor',[0.3,1,1],'string',newstr);
    else
        set(h,'backgroundcolor',[  0,1,0],'string',newstr);
    end
end


