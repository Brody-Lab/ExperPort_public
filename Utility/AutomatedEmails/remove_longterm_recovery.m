function remove_longterm_recovery

try
    L = 28;
    
    %setpref('Internet','SMTP_Server','brodyfs2.princeton.edu');
    %setpref('Internet','E_mail',['RegistryMeister',datestr(now,'yymm'),'@Princeton.EDU']);
    set_email_sender
    
    file = ['C:\RegistryBackup\',datestr(now-L,'yyyymmdd'),'.mat'];

    [Rr,C] = bdata('select ratname, contact from ratinfo.rats where extant=1 and recovering=1');

    if exist(file,'file') ~= 0
        load(file); X = x;

        for i = 1:numel(Rr)
            j = find(strcmp(X.ratname,Rr{i})==1);

            if numel(j) ~= 1; continue; end

            if X.recovery(j) == 1
                %This rat was on recovery 4 weeks ago and still is.
                
                %Now let's check that he's been on recovery every day since
                continuousrecovery = 1;
                for d = 1:L
                    file = ['C:\RegistryBackup\',datestr(now-d,'yyyymmdd'),'.mat'];
                    try 
                        load(file); 
                        j = find(strcmp(x.ratname,Rr{i})==1);
                        if numel(j) ~= 1; continue; end
                        if x.recovery(j) == 0
                            %He wasn't on recovery on this day.
                            continuousrecovery = 0;
                            break
                        end
                    end
                end
                if continuousrecovery == 1

                    ratID = bdata(['select internalID from ratinfo.rats where ratname="',Rr{i},'"']);
                    if numel(ratID) == 1
                        mym(bdata,'update ratinfo.rats set recovering=0 where internalID="{S}"',ratID);


                        b = [0,find(C{i}==' ' | C{i}==','),numel(C{i})+1];
                        for k = 1:numel(b)-1
                            email=C{i}(b(k)+1:b(k+1)-1);
                            if numel(email) > 1

                                message = [Rr{i},' was determined to be on the recovery list ',...
                                          'for at least ',num2str(L/7),' weeks and has been removed via the ',...
                                          'automated script remove_longterm_recovery.m'];

                                disp(email);
                                disp(message);
                                disp(' ');

                                sendmail([email,'@princeton.edu'],[Rr{i},' Removed from Recovery'],message);
                            end
                        end
                    end
                end
            end
        end
    end
catch %#ok<CTCH>
    senderror_report;
end
