function events = extract_events_from_all_data_trans(adt)

events = [];
cnt = 0;
for i = 1:numel(adt)
    
    if numel(adt{i})==2 && adt{i}(1)==1 && numel(adt)>=i+1 && ~isempty(adt{i+1})
        cnt = cnt + 1;
        n = double(adt{i}(2));
        
        
        events(end+1:end+n,1) = adt{i+1}(1:n);
        events(end-n+1:end,2) = cnt;
    end
end

if ~isempty(events)
    events(events(:,1) ~= 255,1) = events(events(:,1) ~= 255,1) + 1;
end
