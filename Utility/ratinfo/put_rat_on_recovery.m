function S=put_rat_on_recovery(ratname,freewateronly,separatemates,recovdays,varargin)
% err=put_rat_on_recovery
%
% Input:
% Takes a ratname or a cell array of ratnames and moves the rat off
% of the training schedule and onto the recovery list
%
% Optional Input:
%   freewateronly: set to 1 to place on free water but not recovery list
%                  set to 0 (default) to place on both lists
%
% Optional Output
% S    0 if everything worked
%      1 if there was an error

if nargin < 2; freewateronly = 0;  end
if nargin < 3; separatemates = 0;  end
if nargin < 4; recovdays     = []; end

if ~isempty(recovdays)
    enddate = [' until ',datestr(now+recovdays,'yyyy-mm-dd')];
else
    enddate = '';
end

if iscell(ratname)
    for rx=1:numel(ratname)
        S(rx)=put_rat_on_recovery(ratname{rx},freewateronly);
    end
else
    
    [oldid, rig, slot, oldexp, comments]=bdata(['select schedentryid, rig, timeslot, experimenter, comments from ratinfo.schedule where date>="',...
        datestr(now,'yyyy-mm-dd'),'" and ratname="',ratname,'" order by date desc']);
    [ratID]=bdata(['select internalID from ratinfo.rats where ratname="',ratname,'"']);
    
    if numel(ratID)==1   
        try
            if ~isempty(oldid)
                %He is on the schedule
                for x=1:numel(oldid)
                    mym(bdata,'update ratinfo.schedule set ratname="", experimenter="", comments="{S}" where schedentryid="{S}"',...
                        ['reserved for ' ratname,enddate,' [[',comments{x},']]'],oldid(x));
                end
                disp(['Rat ',ratname,' removed from the schedule, marked as reserved: Rig ',num2str(rig(x)),', Slot ',num2str(slot(x))]);
            end
            
            %Put on free water
            mym(bdata,'update ratinfo.rats set forceDepWater=0 where internalID="{S}"',ratID);
            
            if freewateronly == 0
                %Flag as recovering only if freewateronly is 0
                mym(bdata,'update ratinfo.rats set recovering=1 where internalID="{S}"',ratID);
                disp(['Rat ',ratname,' set to recovering']);
            end
            
            if separatemates == 1
                %set his cagemate to '' and same for his cagemate
                
                cm = bdata(['select cagemate from ratinfo.rats where internalID=',num2str(ratID)]);
                if iscell(cm) && ~isempty(cm); cm = cm{1}; end
                if ~isempty(cm)
                    mym(bdata,'update ratinfo.rats set cagemate="" where internalID="{S}"',ratID);
                    mateID = bdata(['select internalID from ratinfo.rats where ratname="',cm,'"']);
                    if numel(mateID) == 1
                        mym(bdata,'update ratinfo.rats set cagemate="" where internalID="{S}"',mateID);
                    end
                end
            end
            
            S.err=0;
        catch le
            showerror(le)
            S.err=1;
        end
        
    else
        fprintf('Failed to identify unique rat\n')
    end
end