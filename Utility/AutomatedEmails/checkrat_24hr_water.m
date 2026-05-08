function output = checkrat_24hr_water(threshold1,threshold2,ratrig,doemail,varargin)

try 
    if nargin < 1; threshold1 = 23; end
    if nargin < 2; threshold2 = 24; end
    if nargin < 3
        ratrig = bSettings('get','RIGS','ratrig');
        if isnan(ratrig); ratrig = 1; end
    end
    if nargin < 4; doemail = 1; end
    
    [RR,RC]   = bdata(['select ratname, contact from ratinfo.rats where extant=1 and israt=',num2str(ratrig)]);
    
    [WRY,WEY]     = bdata(['select rat, stoptime from ratinfo.water where date="',           datestr(now-1,'yyyy-mm-dd'),'"']);
    [WRT,WST,WET] = bdata(['select rat, starttime, stoptime from ratinfo.water where date="',datestr(now,  'yyyy-mm-dd'),'"']);
    
    [SRY,SEY] = bdata(['select ratname, endtime   from sessions     where sessiondate="',datestr(now-1,'yyyy-mm-dd'),'"']);
    [SRT,SST] = bdata(['select ratname, starttime from sess_started where sessiondate="',datestr(now,  'yyyy-mm-dd'),'"']);
    
    [DRT,DET] = bdata(['select ratname, endtime   from sessions     where sessiondate="',datestr(now,  'yyyy-mm-dd'),'"']);
    
    
    WEYN = [];
    for i = 1:numel(WEY)
        WEYN(i) = datenum([datestr(now-1,'yyyy-mm-dd'),' ',WEY{i}],'yyyy-mm-dd HH:MM:SS'); %#ok<AGROW>
    end
    
    WETN = [];
    for i = 1:numel(WET)
        WETN(i) = datenum([datestr(now,  'yyyy-mm-dd'),' ',WET{i}],'yyyy-mm-dd HH:MM:SS'); %#ok<AGROW>
    end
    
    SEYN = [];
    for i = 1:numel(SEY)
        SEYN(i) = datenum([datestr(now-1,'yyyy-mm-dd'),' ',SEY{i}],'yyyy-mm-dd HH:MM:SS'); %#ok<AGROW>
    end
    
    SSTN = [];
    for i = 1:numel(SST)
        SSTN(i) = datenum([datestr(now,  'yyyy-mm-dd'),' ',SST{i}],'yyyy-mm-dd HH:MM:SS'); %#ok<AGROW>
    end
    
    DETN = [];
    for i = 1:numel(DET)
        DETN(i) = datenum([datestr(now,  'yyyy-mm-dd'),' ',DET{i}],'yyyy-mm-dd HH:MM:SS'); %#ok<AGROW>
    end
    
    last_access_water = zeros(numel(RR),6);
    %column 1 when did yesterday's water end
    %column 2 when did today's water end
    %column 3 when did training end yesterday
    %column 4 when did training start today
    %column 5 when did training end today
    %column 6 now if the rat currently has access to water
    
    for i = 1:numel(RR)
        
        p = find(strcmp(WRY,RR{i})==1);
        if ~isempty(p)
            last_access_water(i,1) = max(WEYN(p));
        else
            last_access_water(i,1) = nan;
        end
        
        p = find(strcmp(WRT,RR{i})==1);
        if ~isempty(p)
            last_access_water(i,2) = max(WETN(p));
        else
            last_access_water(i,2) = nan;
        end
        
        p = find(strcmp(SRY,RR{i})==1);
        if ~isempty(p)
            last_access_water(i,3) = max(SEYN(p));
        else
            last_access_water(i,3) = nan;
        end
        
        p = find(strcmp(SRT,RR{i})==1);
        if ~isempty(p)
            last_access_water(i,4) = max(SSTN(p));
        else
            last_access_water(i,4) = nan;
        end
        
        p = find(strcmp(DRT,RR{i})==1);
        if ~isempty(p)
            last_access_water(i,5) = max(DETN(p));
        else
            last_access_water(i,5) = nan;
        end
        
        p = find(strcmp(WRT,RR{i})==1);
        found_active_water = 0;
        if ~isempty(p) 
            for j = 1:numel(p)
                if strcmp(WST{p(j)},WET{p(j)})
                    last_access_water(i,6) = now;
                    found_active_water = 1;
                end
            end
        end
        if found_active_water == 0
            last_access_water(i,6) = nan;
        end
    end
    
    last_access_water = (now - last_access_water) .* 24;
    
    m = [];
    for i = 1:size(last_access_water,1)
        x = last_access_water(i,:);
        x(x < 0) = 0;
        m(i) = nanmin(x); %#ok<AGROW>
    end
    
    message = cell(0);
    
    alert_1 = find(m >= threshold1 & m <= threshold2);
    alert_2 = find(m > threshold2);
    
    silence_list = cell(0,3);
        
    if ~isempty(alert_1) || ~isempty(alert_2)
        if ratrig == 1
            species = 'rats';
            capspecies = 'Rats'; %#ok<NASGU>
            singlespecies = 'Rat';
        else
            species = 'mice';
            capspecies = 'Mice'; %#ok<NASGU>
            singlespecies = 'Mouse';
        end 
        
        textalert = 0;
        subject = [];
        
        rwl = WM_rat_water_list(1:10,[],'all');
        for s = 1:numel(rwl)
            urwl{s} = unique(rwl{s}(:)); %#ok<AGROW>
        end
        
        [ms,order] = sortrows(m','descend');
        RRs = cell(0);
        for i = 1:numel(order)
            RRs{i} = RR{order(i)};
        end
        alert_1s = find(ms >= threshold1 & ms <= threshold2);
        alert_2s = find(ms > threshold2);
        session_alert_1s = cell(0);
        for i = 1:numel(alert_1s)
            for s = 1:numel(rwl)
                if sum(strcmp(urwl{s},RRs{alert_1s(i)})) > 0
                    if s == 10
                        session_alert_1s{i} = 'FW';
                    else
                        session_alert_1s{i} = [num2str(s),' '];
                    end
                    break;
                end
            end
        end
        session_alert_2s = cell(0);
        for i = 1:numel(alert_2s)
            for s = 1:numel(rwl)
                if sum(strcmp(urwl{s},RRs{alert_2s(i)})) > 0
                    if s == 10
                        session_alert_2s{i} = 'FW';
                    else
                        session_alert_2s{i} = [num2str(s),' '];
                    end
                    break;
                end
            end
        end
        
        hours = floor(ms);
        for i = 1:numel(ms)
            minutes(i) = ceil((ms(i) - hours(i)) * 60); %#ok<AGROW>
        end

        try
            map_bucket_drive;
            handles.SilenceListPath = 'X:\Training Room\Alarms\RatWaterAlarm\';
            handles = WA_get_silencelist_file(handles);

            if exist(handles.SilenceListFile,'file')
                load(handles.SilenceListFile)

                expired = [];
                for i = 1:size(silence_list,1)
                    if datenum(silence_list{i,2},'yyyy-mm-dd HH:MM') - now < 0
                        expired(end+1) = i;
                    end
                end
                silence_list(expired,:) = [];

                handles.SilenceList = silence_list;
            else
                handles.SilenceList = cell(0,3);
            end
            silence_list = handles.SilenceList;
        end
        
        if doemail == 1
            %notify lab members via email
            
            %Let's check if the alarm has been silenced for any rats in group 1
            expired = [];
            for i = 1:size(silence_list,1)
                if datenum(silence_list{i,2},'yyyy-mm-dd HH:MM') - now < 0
                    expired(end+1) = i;
                end
            end
            silence_list(expired,:) = [];
              
            silenced = [];
            for i = 1:numel(alert_1s)
                ratname = RRs{alert_1s(i)};
                if sum(strcmp(silence_list(:,1),ratname)) > 0
                    silenced(end+1) = i;
                end
            end
            alert_1s(silenced) = [];

            set_email_sender;
            if ~isempty(alert_2s)
                subject = ['URGENT ',singlespecies,' Water Alarm'];
                textalert = 1;
                message{end+1} = ['The following ',species,' have not had access ',...
                    'to water for at least ',num2str(threshold2),' hours:'];
                message{end+1} = 'ID    Session  Time Since Last Water';
                for i = 1:numel(alert_2s)
                    message{end+1} = [RRs{alert_2s(i)},'  ',session_alert_2s{i},'       ',...
                        sprintf('%02i',hours(alert_2s(i))),':',sprintf('%02i',minutes(alert_2s(i)))]; %#ok<AGROW>
                end
                message{end+1} = ' ';
                message{end+1} = ' ';
            end

            if ~isempty(alert_1s)
                if isempty(subject)
                    subject = [singlespecies,' WATER ALARM'];
                end
                message{end+1} = ['The following ',species,' have not had access ',...
                    'to water for at least ',num2str(threshold1),' hours:'];
                message{end+1} = 'ID    Session  Time Since Last Water';
                for i = 1:numel(alert_1s)
                    message{end+1} = [RRs{alert_1s(i)},'  ',session_alert_1s{i},'       ',...
                        sprintf('%02i',hours(alert_1s(i))),':',sprintf('%02i',minutes(alert_1s(i)))]; %#ok<AGROW>
                end
                message{end+1} = ' ';
                message{end+1} = ' ';
            end

            if ~isempty(message)
                message{end+1} = ['Coordinate response on the lab #',species,' slack channel'];
                message{end+1} = '  ';                                                             
                message{end+1} = '  ';                                                             
                message{end+1} = 'This email was generated by the Brody Lab Automated Email System.';
                IP = get_network_info;
                message{end+1} = ' ';
                if ischar(IP); message{end+1} = ['Email generated by ',IP];
                else,          message{end+1} = 'Email generated by an unknown computer!!!';
                end

                message{end+1} = 'ratter\ExperPort\Utility\AutomatedEmails\checkrat_24hr_water.m';

                rat_slack_email = 'rat_training_alarms-aaaaskt5z5judxh7aoysihlrxm@brodylab.slack.com';
                sendmail(rat_slack_email,subject,message);
                
                rat_slack_email = 'techs-aaaaag3dqd6ppxef2xnzxymn4a@brodylab.slack.com';
                sendmail(rat_slack_email,subject,message);

                c{1} = 'ckopec';
                c{2} = 'jteran';
                for i = 1:numel(alert_1)
                    x = RC{alert_1(i)};
                    bks = find(x == ',' | x==' ');
                    bks = [0,bks,numel(x)+1]; %#ok<AGROW>
                    for j = 1:numel(bks)-1
                        temp = x(bks(j)+1:bks(j+1)-1);
                        if numel(temp) >= 2
                            c{end+1} = temp; %#ok<AGROW>
                        end
                    end
                end
                for i = 1:numel(alert_2)
                    x = RC{alert_2(i)};
                    bks = find(x == ',' | x==' ');
                    bks = [0,bks,numel(x)+1]; %#ok<AGROW>
                    for j = 1:numel(bks)-1
                        temp = x(bks(j)+1:bks(j+1)-1);
                        if numel(temp) >= 2
                            c{end+1} = temp; %#ok<AGROW>
                        end
                    end
                end
                c = unique(c);
                for i = 1:numel(c)
                    sendmail([c{i},'@princeton.edu'],subject,message);
                    pause(1);
                end

                if textalert == 1
                    [E,emails] = bdata('select experimenter, email from ratinfo.contacts where is_alumni=0');
                    for i = 1:numel(emails)
                        puid{i} = emails{i}(1:find(emails{i}=='@',1,'first')-1); %#ok<AGROW>
                    end
                    for i = 1:numel(c)
                        p = find(strcmp(puid,c{i})==1,1,'first');
                        if ~isempty(p)
                            send_text_message(message,subject,E{p});
                        end
                    end
                end
            end
        else
            %not sending an email, bundle data for use by other code
            %columns 1: animal's name
            %columns 2: session 
            %columns 3: time since last access to water
            %columns 4: time remaining until threshold 2 is crossed
            %columns 5: time when threshold 2 is crossed
            
            HH = str2num(datestr(now,'HH'));
            MM = str2num(datestr(now,'MM'));
            
            cnt = 0;
            for i = 1:numel(alert_2s)
                output{i,1} = RRs{alert_2s(i)};
                output{i,2} = session_alert_2s{i};
                output{i,3} = [sprintf('%02i',hours(alert_2s(i))),':',sprintf('%02i',minutes(alert_2s(i)))];
                output{i,4} = '00:00';
                output{i,5} = 'OVER';
                cnt = cnt + 1;
            end
            
            for i = 1:numel(alert_1s)
                output{i+cnt,1} = RRs{alert_1s(i)};
                output{i+cnt,2} = session_alert_1s{i};
                output{i+cnt,3} = [sprintf('%02i',hours(alert_1s(i))),':',sprintf('%02i',minutes(alert_1s(i)))];
                
                hours_remaining = (threshold2 - hours(alert_1s(i))) - 1;
                minutes_remaining = 60 - minutes(alert_1s(i));
                
                output{i+cnt,4} = [sprintf('%02i',hours_remaining),':',sprintf('%02i',minutes_remaining)];
            
                hours_thresholdhit   = HH + hours_remaining;
                minutes_thresholdhit = MM + minutes_remaining;
                
                if minutes_thresholdhit >= 60
                    minutes_thresholdhit = minutes_thresholdhit - 60;
                    hours_thresholdhit   = hours_thresholdhit + 1;
                end
                
                if hours_thresholdhit >= 24
                    hours_thresholdhit = hours_thresholdhit - 24;
                    extra = ' T';
                else
                    extra = '  ';
                end
                
                output{i+cnt,5} = [sprintf('%02i',hours_thresholdhit),':',sprintf('%02i',minutes_thresholdhit),extra];
            end
            
            x = cell(0);
            for i = 1:size(output,1)
                x{i} = [output{i,1},'  ',output{i,2},'     ',output{i,4},'     ',output{i,5},'    '];
            end
            newoutput{1} = x';
            if ~isempty(x) && ~isempty(output{1,4})
                newoutput{2} = output{1,4};
            else
                newoutput{2} = '00:00';
            end
            output = newoutput;
            return
        end
        
    end
    
    if doemail == 1
        if isempty(message)
            message = silence_list;
        end
        output.email    = message;
        output.ratname  = RR;
        output.max_time = m;

        try %#ok<TRYNC>
            LTR = 'abcdefghijklmnopqrstuvwxyz';
            for ltr = 1:26
                file = ['C:\Automated Emails\Schedule\NoWater\',yearmonthday,'_',datestr(now,'HHMM'),LTR(ltr),'_NoRatsWater_Email.mat'];
                if ~exist(file,'file'); save(file,'output'); break; end    
            end
        end
    else
        output{1} = '';
        output{2} = '24:00';
    end
catch %#ok<CTCH>
    if doemail == 1
        senderror_report;
    end
end
    





