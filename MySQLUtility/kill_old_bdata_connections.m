function kill_old_bdata_connections(age_to_kill,varargin)
%age_to_kill is in hours

if nargin < 1; age_to_kill = 10; end

x = mym(bdata,'show processlist');

%old connections defined as those that have not sent a command in 10 hours
old = find(x.Time > 3600 * age_to_kill); 

disp([num2str(numel(x.Id)),' total collections']);
disp([num2str(numel(old)),' old connections']);

%loop through old connections and kill them
for i = 1:numel(old)
    mym(bdata,['kill ',num2str(x.Id(old(i)))]);
end

disp('COMPLETE');

