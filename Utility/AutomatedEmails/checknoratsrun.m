function checknoratsrun(slots,waterslots,ratrig,varargin)

try 
    
    if nargin < 3
        ratrig = bSettings('get','RIGS','ratrig');
        if isnan(ratrig); ratrig = 1; end
    end
    
    [RR,CT]    = bdata(['select ratname, contact from ratinfo.rats where extant=1 and israt=',num2str(ratrig)]);
    
    if ratrig == 1; allrignums = 1:38;
    else            allrignums = 401:404;
    end
    
    [RN,RG,TS] = bdata(['select ratname, rig, timeslot from ratinfo.schedule where date="',datestr(now,29),'"']);
    remrat = [];
    for i = 1:numel(RG)
        if sum(allrignums == RG(i)) == 0
            remrat(end+1) = i;
        end
    end
    RN(remrat) = [];
    RG(remrat) = [];
    TS(remrat) = [];
    
    
    RS         = bdata(['select ratname from sessions where sessiondate="',datestr(now,29),'"']);
    remrat = [];
    for i = 1:numel(RS)
        if sum(strcmp(RR,RS{i})) == 0
            remrat(end+1) = i;
        end
    end
    RS(remrat) = [];
    
    
    RW         = bdata(['select rat from ratinfo.water where date="',datestr(now,'yyyy-mm-dd'),'"']);
    remrat = [];
    for i = 1:numel(RW)
        if sum(strcmp(RR,RW{i})) == 0
            remrat(end+1) = i;
        end
    end
    RW(remrat) = [];
    
    
    [EX,EM,LM,OT,MT,AT,SA] = bdata('select experimenter, email, lab_manager, tech_overnight, tech_morning, tech_afternoon, subscribe_all from ratinfo.contacts where is_alumni=0');
    
    WaterList = WM_rat_water_list(0,0,'all',datestr(now,'yyyy-mm-dd'),1,ratrig);
    for i=1:numel(WaterList)
        WaterList{i} = unique(WaterList{i}); 
        WaterList{i}(strcmp(WaterList{i},'')) = [];
    end   
    
    set_email_sender
    
    if nargin < 1; slots = 1:9; end
    if nargin < 2; waterslots = 1:9; end 
    urg = unique(RG);      
    
    E = cell(0);
    EW = cell(0);
    output = []; %#ok<NASGU>

    aratdidrun = 0;
    for slot = slots
        for rig = urg'
            rn = RN{RG == rig & TS == slot};
            if strcmp(rn,''); continue; end
            
            if sum(strcmp(RS,rn)) > 0; aratdidrun = 1; 
            else                       E{end+1} = rn; %#ok<AGROW>
            end            
        end
    end

    aratwaswatered = 0;
    for slot = waterslots
        for r = 1:numel(WaterList{slot})
            
            if sum(strcmp(RW,WaterList{slot}{r})) > 0; aratwaswatered = 1; 
            else                                       EW{end+1} = WaterList{slot}{r}; %#ok<AGROW>
            end            
        end
    end
    
    EW = unique(EW);
    E  = unique(E);
    
    email = cell(0);
    message = cell(0);
    textalert = 0;
    
    if ratrig == 1;
        species = 'rats';
        capspecies = 'Rats';
        singlespecies = 'Rat';
    else
        species = 'mice';
        capspecies = 'Mice';
        singlespecies = 'Mouse';
    end
    if aratdidrun == 0 && ~isempty(E)
        message{end+1} = ['No ',species,' appeared to run today in sessions ',num2str(slots)];
    end
    if aratwaswatered == 0 && ~isempty(EW)
        message{end+1} = ['No ',species,' appeared to be watered in sessions ',num2str(waterslots)];
        textalert = 1;
    else
        if ~isempty(message)
            message{end+1} = ['But sessions ',num2str(waterslots),' did get watered.'];
            message{end+1} = 'So everything is probably okay. Just being thorough.';
        end
    end
    if textalert == 1 && ~isempty(message)
        message{end+1} = 'Please contact the appropriate tech and make sure someone';
        message{end+1} = ['gives the ',species,' their 1 hour of free water.'];
    end
    
    if ~isempty(message)    
        message{end+1} = ' ';
        message{end+1} = 'Thanks,';
        message{end+1} = 'The Schedule Meister';
        message{end+1} = '  ';                                                             
        message{end+1} = '  ';                                                             
        message{end+1} = 'This email was generated by the Brody Lab Automated Email System.';
        IP = get_network_info;
        message{end+1} = ' ';
        if ischar(IP); message{end+1} = ['Email generated by ',IP];
        else           message{end+1} = 'Email generated by an unknown computer!!!';
        end
        
        message{end+1} = 'ratter\ExperPort\Utility\AutomatedEmails\checknoratsrun.m';
        
        for e = 1:length(E)
            temp = strcmp(RR,E{e});
            if sum(temp) == 1
                ct = CT{temp};
                em = parse_emails(ct);
            
                for t = 1:length(em)
                    email{end+1} = [em{t},'@princeton.edu']; %#ok<AGROW>
                end
            end
        end
        
        if sum(SA) + sum(LM) > 0
            temp = EM(SA==1 | LM==1);
            email(end+1:end+length(temp)) = temp;
        end
        
        if ratrig == 1
            if any(slots <= 3) 
                temp = EM(OT==1);
                email(end+1:end+length(temp)) = temp;
            end
            if any(slots >= 4 & slots <= 6) 
                temp = EM(MT==1);
                email(end+1:end+length(temp)) = temp;
            end
            if any(slots <= 9) 
                temp = EM(AT==1);
                email(end+1:end+length(temp)) = temp;
            end
        end
        email = unique(email);
         
        for e = 1:length(email)
            ex = EX{strcmp(EM,email{e})};
            try %#ok<TRYNC>
                eval(['output.',ex,' = message;']);
            end
        end
        
        message = remove_duplicate_lines(message);
        sendmail(email,['No ',capspecies,' Ran Today'],message);    
        
        if textalert == 1
            RECIP = EX(logical(LM));
            if ratrig == 1

                shift = [];
                if any(slots == 1) || any(slots == 2) || any(slots == 3); shift(end+1) = 1; end
                if any(slots == 4) || any(slots == 5) || any(slots == 6); shift(end+1) = 2; end
                if any(slots == 7) || any(slots == 8) || any(slots == 9); shift(end+1) = 3; end

                for i = 1:numel(shift)
                    temp = text_tech_schedule_change(datestr(now,'yyyy-mm-dd'),shift(i));
                    RECIP(end+1:end+numel(temp)) = temp;
                end
            else
                if isempty(RECIP); RECIP = cell(0); end
                for i = 1:numel(email)
                    temp = find(strcmp(EM,email{i})==1,1,'first');
                    if ~isempty(temp)
                        RECIP{end+1} = EX{temp};
                    end
                end
            end
                
            RECIP = unique(RECIP);
            
            for i = 1:numel(RECIP)
                if strcmp(RECIP{i},'Carlos'); continue; end
                send_text_message(['No ',species,' watered sessions ',num2str(waterslots)],[singlespecies,' Water Alert'],RECIP{i}); 
            end
        end
    end
    
    LTR = 'abcdefghijklmnopqrstuvwxyz';
    for ltr = 1:26
        file = ['C:\Automated Emails\Schedule\NoRun\',yearmonthday,LTR(ltr),'_NoRatsRan_Email.mat'];
        if ~exist(file,'file'); save(file,'output'); break; end    
    end

catch %#ok<CTCH>
    senderror_report;
end





