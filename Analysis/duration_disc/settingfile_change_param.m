function [] = settingfile_change_param(varargin)

pairs = { ...
    'action','check_setting' ; ...
    'field2check', '' ; ...
    'val4field', [] ; ...
    };
parse_knownargs(varargin,pairs);


global Solo_datadir;

param_setDir = [Solo_datadir filesep 'Settings' filesep 'Shraddha' filesep];
param_indate = '081008a';

outfile_suffix = 'c';

ratlist = { ...
    'S033','S026','S021', ... % 8-10 shift
    'S032', 'S040','S025', ... % 10-12 shift
    'S035','S034','S038','S036','S039', ... % 12-2 shift
    'S029','S018','S027','S030','S028'... % 2-4 shift
    'S041','S042','S043','S044','S045',...        % 4-6 shift
    'S046','S047', 'S031','S016' ...              % 6-8 shift
    };

% -----------
% String version of autoset

param_TimesSection_BadBoySPL = ...
    { ...
    'if ( value(poke_rate_Last15) > 15 | value(to_rate_Last15) > 1.3) && value(trials_since_last_chng) > 10, '; ...
    '	BadBoySPL.value = ''LOUDEST''; '; ...
    '	trials_since_last_chng.value = 0; '; ...
    'elseif ( value(poke_rate_Last15) > 15 | value(to_rate_Last15) > 1) && value(trials_since_last_chng) > 10, '; ...
    '	BadBoySPL.value = ''Louder''; '; ...
    '	trials_since_last_chng.value = 0; '; ...
    'elseif ( value(LeftProb) > 0.9 || value(LeftProb) < 0.1 ), '; ...
    '    BadBoySPL.value = ''LOUDEST''; '; ...
    '    bbspl_loud_tracker.value = 0; '; ...
    'elseif ( value(LeftProb) > 0.7 | value(LeftProb) < 0.3 ), '; ...
    '    BadBoySPL.value = ''Louder''; '; ...
    '    bbspl_loud_tracker.value = 0; '; ...
    'elseif ~strcmpi(value(BadBoySPL),''normal''),'; ...
    '	bbspl_loud_tracker.value = value(bbspl_loud_tracker)+1; '; ...
    'else '; ...
    '	trials_since_last_chng.value = value(trials_since_last_chng) + 1; '; ...
    'end; '; ...
    ' '; ...
    'if value(bbspl_loud_tracker) > 5, '; ...
    '	bbspl_loud_tracker.value = 0; '; ...
    '	BadBoySPL.value = ''normal'';	 '; ...
    '	trials_since_last_chng.value = 0; '; ...
    'end; '; ...
    };

param_SidesSection_LeftProb = ...
    {'sl = value(side_list); if n_done_trials > 0,' ; ...
    '    if n_done_trials < 2,'; ...
    'LeftProb.value = 0.5;' ; ...
    '     MaxSame.value = 3;';...
    'end;' ; ...
    '    if value(onesidemode) > 0,  ' ; ...
    '            mn = max(1, n_done_trials - min(value(last_change), 5));' ; ...
    '        if value(LeftProb) > 0,' ; ...
    '            opprew = LeftRewards;' ; ...
    '        else opprew = RightRewards; ' ; ...
    '        end;' ; ...
    '        opp_hit_ctr.value = sum(opprew(mn:n_done_trials));' ; ...
    '        if opp_hit_ctr > 3,' ; ...
    '            onesidemode.value = 0;' ; ...
    '            last_change.value = 0;' ; ...
    '            LeftProb.value = 0.5;' ; ...
    '            MaxSame.value = 3;' ; ...
    '        else' ; ...
    '            last_change.value = value(last_change) + 1;' ; ...
    '        end;' ; ...
    '    else' ; ...
    '        mn = max(1, n_done_trials - 15);' ; ...
    '        left_trials = sum(sl(mn:n_done_trials));' ; ...
    '        lefthits = sum(LeftRewards(mn:n_done_trials));' ; ...
    '        if left_trials == 0, lefthits=0;' ; ...
    '        else lefthits = lefthits/left_trials;' ; ...
    '        end;' ; ...
    '        tmp = sl(mn:n_done_trials);    ' ; ...
    '        right_trials = length(find(tmp < 1));  ' ; ...
    '' ; ...
    '        righthits = sum(RightRewards(mn:n_done_trials));' ; ...
    '        if right_trials == 0,' ; ...
    '            righthits = 0;' ; ...
    '        else' ; ...
    '            righthits = righthits/right_trials;' ; ...
    '        end;' ; ...
    '        b = lefthits - righthits;' ; ...
    '        bias.value = b;' ; ...
    '      ' ; ...
    '' ; ...
    '        if (b > 0.5 | b < -0.5) & value(last_change) > 10,' ; ...
    '            onesidemode.value = 1;' ; ...
    '            opp_hit_ctr.value = 0;' ; ...
    '            last_change.value = 0;' ; ...
    '            if b > 0.5, LeftProb.value = 0; ' ; ...
    '            else LeftProb.value = 1;        ' ; ...
    '            end;' ; ...
    '            MaxSame.value = ''Inf''; ' ; ...
    '        elseif b > 0.2 & value(last_change) > 10, ' ; ...
    '            LeftProb.value = max(0, value(LeftProb)-0.1) ;' ; ...
    '            last_change.value = 0;' ; ...
    '        elseif b < -0.2 & value(last_change) > 10, ' ; ...
    '            LeftProb.value = min(1, value(LeftProb)+0.1);' ; ...
    '            last_change.value = 0;' ; ...
    '        elseif value(last_change) > 15,' ; ...
    '            LeftProb.value = 0.5;' ; ...
    '            last_change.value = 0;' ; ...
    '        else' ; ...
    '            last_change.value = value(last_change) + 1;' ; ...
    '        end;' ; ...
    '    end;' ; ...
    'end;' ; ...
    };

switch action
    case 'change_autoset'
        if isempty(field2check)
            error('empty autoset');
        else
            fname = field2check; %'TimesSection_BadBoySPL';
        end;

        % ------- >>>>
        % Autoset to which to set
        newstr = '';
        for k = 1:rows(eval(['param_' fname]))
            newstr = [newstr eval(['param_' fname '{k}']) ''];
        end;

        % <<<< ----------


        % ------------

        for r = 1:length(ratlist)
            param_ratname = ratlist{r};
            fprintf(1,'\t%s...\n', param_ratname);

            param_ratrow = rat_task_table(param_ratname);
            param_task = param_ratrow{1,2};

            param_sfile = [ 'settings_@' param_task '_Shraddha_' param_ratname '_' param_indate '.mat'];
            param_sfile_out = param_sfile;
            param_sfile_out(end-4) = outfile_suffix;

            try
                load([param_setDir param_ratname filesep param_sfile]);
            catch
                try
                    fprintf(1,'\tCouldn''t find ''a'' file. Looking for b\n');
                    param_sfile(end-4) = 'b';
                    load([param_setDir param_ratname filesep param_sfile]);
                catch
                    error('Error loading file for %s', param_ratname);
                end;
            end;

            % ------->>>>
            % Field to change

            if r == 1,
                ans = questdlg(sprintf('You SURE you want to update\n%s ?', fname), 'Confirm update', 'yes','NO!!!!!', 'NO!!!!!');

                if strcmpi(ans, 'NO!!!!!')
                    fprintf(1,'Not proceeding with update.\n');
                    return;
                end;
            end;

            oldstr = eval(['saved_autoset.' fname ';']);
            if ~isempty(oldstr)
                eval(['saved_autoset.' fname ' = newstr;']);
            else
                fprintf(1,'\t\tEmpty autoset; not updating\n');
            end;

            % <<<<<------------


            save([param_setDir param_ratname filesep param_sfile_out], 'saved','saved_autoset', 'fig_position');

            clear saved saved_autoset fig_position;
        end;

    case 'check_setting'

        fprintf(1,'Checking %s = %i\n', field2check, val4field);
        for r = 1:length(ratlist)
            param_ratname = ratlist{r};
            fprintf(1,'\t%s...\n', param_ratname);

            param_ratrow = rat_task_table(param_ratname);
            param_task = param_ratrow{1,2};

            param_sfile = [ 'settings_@' param_task '_Shraddha_' param_ratname '_' param_indate '.mat'];
            param_sfile_out = param_sfile;
            param_sfile_out(end-4) = outfile_suffix;

            try
                load([param_setDir param_ratname filesep param_sfile]);
            catch
                try
                    fprintf(1,'\tCouldn''t find ''a'' file. Looking for b\n');
                    param_sfile(end-4) = 'b';
                    load([param_setDir param_ratname filesep param_sfile]);
                catch
                    warning('Error loading file for %s', param_ratname);
                end;
            end;

            blah = eval(field2check);

            if blah ~= val4field
                fprintf(1,'\t\t!!! Changed to %i!!!\n', blah);
            end;
        end;
    otherwise
        error('Invalid action');
end;
