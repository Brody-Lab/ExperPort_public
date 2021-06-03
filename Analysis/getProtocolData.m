function data = getProtocolData(rat,dates,protocolPattern,varargin)
    p=inputParser;
    p.KeepUnmatched=true;
    p.addParamValue('byRat',true,@(x)validateattributes(x,{'logical'},{'scalar'}));
    p.addParamValue('getPeh',false,@(x)validateattributes(x,{'logical'},{'scalar'}));
    p.parse(varargin{:});
    params=p.Results;
    %% figure out who the rat(s) is/are
    if isnumeric(dates) && dates(1)>0 % daterange is a sessid
        params.sessIdSupplied=true;
        ratList{1}=rat;
    else
        params.sessIdSupplied=false;
        date_str = parse_daterange(dates);
        if ischar(rat)
            ratList=bdata(['select distinct(ratname) from bdata.sessions where ratname regexp "' rat '" and (' date_str ') order by ratname']);              
        else
            ratList=bdata(['select distinct(ratname) from bdata.sessions where ratname regexp "' strjoin(rat,'|') '" and (' date_str ') order by ratname']);  
        end
        if isempty(ratList)
            error('No rats in bdata.sessions match the pattern "%s" for the dates requested.',rat);
        end
    end
    %% extract protocol data from mySQL server
    if numel(ratList)>1 % multiple rats listed
        for ratIdx = 1:numel(ratList) 
            if ~params.byRat
                if params.sessIdSupplied
                    data = get_sessdata(dates);
                    if ~params.getPeh
                        data = rmfield(data,'peh');         
                    end
                    if any(~ismember(data.ratname,rat))
                        error('Rat name supplied does not match rat corresponding to the sessid(s) supplied.');
                    end
                else
                    if params.getPeh
                        [sessiondate, sessid, protocol, pd, peh, ratname] = ...
                           bdata(['select sessiondate,s.sessid,protocol,protocol_data,peh,ratname from sessions s,parsed_events p where ratname="' ratList{ratIdx} '" and (' date_str ') and s.sessid=p.sessid order by sessiondate']);        
                    else
                        [sessiondate, sessid, protocol, pd, ratname] = ...
                           bdata(['select sessiondate,s.sessid,protocol,protocol_data,ratname from sessions s,parsed_events p where ratname="' ratList{ratIdx} '" and (' date_str ') and s.sessid=p.sessid order by sessiondate']);                      
                    end
                   protocolSessions = ~cellfun(@isempty,regexp(protocol,protocolPattern));
                   if ratIdx==1
                        data=struct('sessiondate',[],'sessid',[],'protocol',[],'pd',[],'ratname',[],'nSessions',0);
                        if params.getPeh
                            data.peh=[];
                        end
                   end
                   data.sessiondate = cat(1,data.sessiondate,sessiondate(protocolSessions));
                   data.sessid = cat(1,data.sessid,sessid(protocolSessions));
                   data.protocol = cat(1,data.protocol,protocol(protocolSessions));
                   data.pd = cat(1,data.pd,pd(protocolSessions));
                   if params.getPeh
                        data.peh = cat(1,data.peh,peh(protocolSessions));
                   end
                   data.ratname = cat(1,data.ratname,ratname(protocolSessions));     
                   data.nSessions = sum(protocolSessions) + data.nSessions;
                end
            else
                if params.sessIdSupplied
                    data(ratIdx) = get_sessdata(dates);
                    if ~params.getPeh
                        data(ratIdx) = rmfield(data(ratIdx),'peh');         
                    end
                    if any(~ismember(data(ratIdx).ratname,ratList{ratIdx}))
                        error('Rat name supplied does not match rat corresponding to the sessid(s) supplied.');
                    end                    
                else
                    if params.getPeh
                        [data(ratIdx).sessiondate, data(ratIdx).sessid, data(ratIdx).protocol, data(ratIdx).pd, data(ratIdx).peh] = ...
                            bdata(['select sessiondate,s.sessid,protocol,protocol_data,peh from sessions s,parsed_events p where s.ratname="' ratList{ratIdx} '" and (' date_str ') and s.sessid=p.sessid order by sessiondate']);                        
                    else
                        [data(ratIdx).sessiondate, data(ratIdx).sessid, data(ratIdx).protocol, data(ratIdx).pd] = ...
                            bdata(['select sessiondate,s.sessid,protocol,protocol_data from sessions s,parsed_events p where s.ratname="' ratList{ratIdx} '" and (' date_str ') and s.sessid=p.sessid order by sessiondate']);                     
                    end
                end
               data(ratIdx).ratname = ratList{ratIdx};
               protocolSessions = ~cellfun(@isempty,regexp(data(ratIdx).protocol,protocolPattern));                    
               data(ratIdx).nSessions=sum(protocolSessions); 
               fields=fieldnames(data);
               for f=1:length(fields)
                   if ~isscalar(data(ratIdx).(fields{f})) && ~ischar(data(ratIdx).(fields{f}))
                       data(ratIdx).(fields{f}) = data(ratIdx).(fields{f})(protocolSessions);
                   end
               end
            end
            if ~all(protocolSessions)
                mssg(0,'Removed %g sessions for rat %s that didn''t match desired protocol pattern.',sum(~protocolSessions),ratList{ratIdx});            
            end
        end                  
    else
        if params.sessIdSupplied
            data = get_sessdata(dates);
            if ~params.getPeh
                data = rmfield(data,'peh');         
            end
            if any(~ismember(data.ratname,rat))
                error('Rat name supplied does not match rat corresponding to the sessid(s) supplied.');
            end
        else  
            if params.getPeh
                [data.sessiondate, data.sessid, data.protocol, data.pd, data.peh,] = ...
                    bdata(['select sessiondate,s.sessid,protocol,protocol_data,peh from sessions s,parsed_events p where s.ratname regexp "' rat '" and (' date_str ') and s.sessid=p.sessid order by sessiondate']);        
            else
                [data.sessiondate, data.sessid, data.protocol, data.pd] = ...
                    bdata(['select sessiondate,s.sessid,protocol,protocol_data from sessions s,parsed_events p where s.ratname regexp "' rat '" and (' date_str ') and s.sessid=p.sessid order by sessiondate']);                  
            end
            data.ratname = ratList{1};
        end
        protocolSessions = ~cellfun(@isempty,regexp(data.protocol,protocolPattern));                 
        data.nSessions=sum(protocolSessions);
        fields=fieldnames(data);
        for f=1:length(fields)
            if ~isscalar(data.(fields{f})) && ~ischar(data.(fields{f}))
                data.(fields{f}) = data.(fields{f})(protocolSessions);
            end
        end
        if any(protocolSessions) 
            if ~all(protocolSessions)
                mssg(0,'Removed %g sessions for rat %s that didn''t match desired protocol pattern.',sum(~protocolSessions),ratList{1});                        
            end
        else
            data=[];
            mssg(0,'No sessions among the sessid(s) supplied that match the desired protocol pattern.');
            return
        end
    end
    
    data = remove_empty_sessions(data);
    
end

function data = remove_empty_sessions(data)
    for i=1:length(data)
        vl_nonempty = ~cellfun(@isempty, data(i).pd);
        if sum(vl_nonempty) == data(i).nSessions
            return
        else
            for field = {'sessiondate', 'sessid', 'protocol', 'pd', 'peh'}; field = field{:};
                if isfield(data(i),field)
                    data(i).(field) = data(i).(field)(vl_nonempty);
                end
            end
            data(i).nSessions = sum(vl_nonempty);
        end
    end
end