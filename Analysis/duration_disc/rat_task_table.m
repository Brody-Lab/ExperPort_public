function [ratrow] = rat_task_table(ratlist,varargin)
% Given a rat name, will return information on which task that rat does and
% the dates during which it was at the sharpening phase of training and the
% psychometric data collection phases

% Possible actions:
% get_ratrow (default)
% case 'get_duration_psych'
% case 'get_pitch_psych'
% case 'get_pitch_basic'
% case 'get_duration_basic'
% case 'get_prepsych_col',
% case 'get_postpsych_col',
% case 'get_sharp_col',
% case 'get_basictask_col',
% case 'get_excluded_col'
% cannula
% cannula__saline
% cannula__muscimol
% cannula__nondays
% cannula__anaesth

% Major changes to behaviour
% Limit on session = 19th July 2007
% SPL randomization = 20th July 2007
% VPD set point = 23rd July 2007
% Turn on psych after 100 trials = 27th July 2007
% Have two phases of psych, one which turns on immediately and one which
% begins with sharpening : Date???

pairs = { ...
    'get_all', 0 ; ...    % returns table
    'get_current', 0; ... % returns only rats that are currently training/testing
    'action', 'get_ratrow' ; ...
    'area_filter', ''; ... % ACx | MGB | mPFC
    'from', '000000' ; ...
    'to', '999999'; ...
    'filter_by_dose', 0 ; ... % set to 1 to retrieve only those muscimol days with the dose specified in the cell
    % muscimoldose
    'usefid', 1 ; ... % fid to fprintf to
    };
parse_knownargs(varargin,pairs);

% print all available actions in this file
if ~iscell(ratlist)
    if strcmpi(ratlist,'actions')
        actionlist = { ...
            'get_ratrow', ...
            'cannula','cannula__saline','cannula__muscimol', 'getdose', 'cannula__anaesth', 'cannula__nondays',...
            'get_duration_psych','get_pitch_psych','get_duration_basic','get_pitch_basic', ...
            'get_prepsych_col', 'get_postpsych_col', 'get_sharp_col', 'get_basictask_col','get_excluded_col', ...
            'notyetflipped'};
        fprintf(1,'Actions:\n');
        for a=1:length(actionlist)
            fprintf(1,'\t%s\n', actionlist{a});
        end;
        return;
    end;
end;
   

NAME_COL = 1;
TASK_COL = 2;
SHARP_COL=3;
PREPSYCH_COL=4;
POSTPSYCH_COL=5;
CURRENT_COL=6;
BASICTASK_COL = 8;
EXCDATE_COL = 7;

rats_on_psych = {};

% Columns are:
% 1. Rat name
% 2. Task: 'd' duration, 'p' pitch
% 3. Sharpening date ranges:  2x1 cell
% 4. Psych date ranges BEFORE lesion: 2x1 cell
% 5. Psych date ranges AFTER lesion: 2x1 cell+
% 6. Current: 0/1
% 7. Exclude dates: Dates of sessions that should be ignored for analyses
% 8. Date ranges for locsamp to SPL randomization (basic task): 2x1 cell

rat_table = { ...
    'orca',     'p',    {'999999','999999'},{'999999','999999'},{},                     1,{}, {}; ...    % --- TEST RAT
    % ----- Ancient rats added for thesis graphics purposes
    'Qutab',   'd',  {},{'999999','999999'},{'999999','999999'},                     0,{}, {}; ...    
    % ----- ACx round 3 lesion rats
    'S033', 'd',    {},{'090720','090804'},{'090811','999999'},                     1,{}, {}; ...    
    'S038', 'd',    {},{'090710','090722'},{'090728','999999'},                     1,{}, {}; ...    
    'S049', 'd',    {},{'090710','090722'},{'090728','999999'},                     1,{}, {}; ...    
    'S048', 'd',    {},{'090720','090804'},{'090811','999999'},                     1,{}, {}; ...        
    'S029', 'd',    {} {'090623','090629'},{'090707','999999'},                     1,{}, {}; ...    
    % ----- ACx round 2 lesion rats
    'S039', 'd',    {}, {'090119','090128'},{'090201','999999'},                     1,{}, {}; ...    
    'S045', 'd',    {},{'090119','090128'},{'090201','999999'},                     1,{}, {}; ...    
    'S028', 'p',    {},{'090119','090129'},{'090201','999999'},                     1,{}, {}; ...    
    'S044', 'p',    {},{'090119','090129'},{'090201','999999'},                     1,{}, {}; ...    
    'S036', 'p',    {},{'090119','090129'},{'090201','999999'},                     1,{}, {}; ... 
    'S025', 'd',    {},{'090119','090129'},{'090201','999999'},                     1,{}, {}; ...    
    'S050', 'd',    {},{'090119','090129'},{'090201','999999'},                    1,{}, {}; ...    
    'S026', 'p',    {},{'090119','090129'},{'090201','999999'},                     1,{}, {}; ...    
    'S041', 'd',    {},{'090119','090129'},{'090201','999999'},                     1,{}, {}; ...    
    'S016', 'p',    {},{'090119','090130'},{'090201','999999'},                     1,{}, {}; ...    
    'S031', 'd',    {},{'090119','090130'},{'090201','999999'},                     1,{}, {}; ...    
    'S030', 'p',    {},{'090119','090130'},{'090201','999999'},                    1,{}, {}; ...    
    'S047', 'p',    {},{'090119','090131'},{'090201','999999'},                     1,{}, {}; ...    
    'S021', 'd',    {},{'090119','090131'},{'090201','999999'},                     1,{}, {}; ...    
    
    %---- Princeton rats -------
    'S002', 'd',    {'999999','999999'},{'080708','080714'},{'080715', '080828'},                     1,{'080718a','080815a'}, {'071201','071225'}; ...                 % PFC cannula
    'S005', 'd',    {'999999','999999'},{'080728','080803'},{'080804','080828'},                     1,{}, {}; ...
    'S007', 'd',    {'999999','999999'},{'080708','080714'},{'080715','080828'},                     1,{}, {}; ...                                  % PFC cannula
    'S013', 'p',    {'999999','999999'},{'080708','080714'},{'080715','999999'},                     1,{}, {}; ...                                  % PFC cannula
    'S024', 'p',    {'999999','999999'},{'080804','080811'},{'080812','080828'},                     1,{'080809a'}, {}; ...
    'S017', 'p',    {'999999','999999'},{'080804','080810'},{'080811','080828'},                     1,{'080629a'}, {}; ...    
    'S014', 'd',    {'999999','999999'},{'080723','080729'},{'080730','080828'},                     1,{'080524a','080525a'}, {}; ...
    'S018', 'd',    {'999999','999999'},{'999999','999999'},{},                     1,{}, {}; ...
    'S019', 'd',    {'999999','999999'},{'999999','999999'},{},                     1,{}, {}; ...
    'S022', 'd',    {'999999','999999'},{'999999','999999'},{},                     1,{}, {}; ...
    'S023', 'd',    {'999999','999999'},{'999999','999999'},{},                     1,{}, {}; ...
    'S032', 'p',    {'999999','999999'},{'999999','999999'},{},                     1,{}, {}; ...
    'S034', 'p',    {'999999','999999'},{'999999','999999'},{},                     1,{}, {}; ...
    'S035', 'p',    {'999999','999999'},{'999999','999999'},{},                     1,{}, {}; ...
    'S040', 'p',    {'999999','999999'},{'999999','999999'},{},                     1,{}, {}; ...
    'S042', 'd',    {'999999','999999'},{'999999','999999'},{},                     1,{}, {}; ...
    'S043', 'd',    {'999999','999999'},{'999999','999999'},{},                     1,{}, {}; ...
    'S046', 'd',    {'999999','999999'},{'999999','999999'},{},                     1,{}, {}; ...
    'S051', 'd',    {'999999','999999'},{'999999','999999'},{},                     1,{}, {}; ...
    % ---- CSHL non-current rats
    
    % mPFC lesion rats -----------------------
    'Wraith',   'd',    {'071001','999999'},{'071201','071230'},{'080105','999999'},    0,{}, {'070921','999999'}; ...
    'Shadowfax','p',    {'999999','999999'},{'071201','071229'},{'080105','999999'},    0,{'071018a'}, {}; ...
    'Shelob',   'd',    {'070819','999999'},{'071201','071228'},{'080104','999999'},    0,{}, {'070730','070814'}; ...
    'Sherlock', 'p',    {'070925','071015'},{'071201','071227'},{'080104','999999'},    0,{'071018a'}, {}; ...
    'Evenstar', 'p',    {'070828','999999'},{'070926','071015'},{'071022','999999'},    0,{}, {}; ...
    'Moria',    'p',    {'999999','999999'},{'071005','071015'},{'071022','999999'},    0,{}, {}; ...
    'Hudson',   'd',    {'999999','999999'},{'071217','080103'},{'080111','999999'},    0,{'080116a','080116b'}, {'071101','071215'}; ...
    'Nazgul',   'd',    {'999999','999999'},{'071002','071015'},{'071022','999999'},    0,{}, {}; ...
    'Celeborn', 'd',    {'070806','999999'},{'070924','071002'},{'071009','071019'},    0,{'071014a','071015a'}, {'070711','070803'}; ...
    'Treebeard','d',    {'070828','999999'},{'070913','071002'},{'071009','071019'},    0,{}, {'070730','070827'}; ...
    'Watson',   'p',    {'999999','999999'},{'071215','080103'},{'080110','999999'},    0,{'071018a'}, {'070913','070926'}; ...
    % CSHL cannula rats --------------
    'Lascar',   'd',    {'999999','999999'},{'080311','080323'},{},                     0,{'080322a','080428a'}, {}; ...
    'Grimesby', 'p',    {'080104','080204'},{'080424','080504'},{},                     0,{'080116a','080322a','080324a','080329a','080407a','080409a', '080425a','080428a'}, {'071220','080114'}; ...
    'Pips',     'd',    {'999999','999999'},{'080424','080504'},{},                     0,{'080407a','080428a','080527a'}, {'071025','071120'}; ...
    'Blaze',    'p',    {'080217','080221'},{'080424','080504'},{},                     0,{'080428a'}, {}; ...
    % ACx round 1 -----------------------
    'Stark',    'd',    {'999999','999999'},{'080613','080623'},{'080701','080702'},    0,{'080428a'}, {}; ...                     % ACx saline        
    'Beryl',    'p',    {'999999','999999'},{'080420','080509'},{'080515','999999'},    0,{'080428a'}, {}; ...
    'Silver',   'd',    {'999999','999999'},{'080420','080507'},{'080514','999999'},    0,{'080428a'}, {}; ...
    'Hatty',    'p',    {'080206','080212'},{'080501','080511'},{'080519','999999'},    0,{'080428a'}, {}; ...
    'Gimli',    'p',    {'070424','999999'},{'070731','070817'},{'070827','070906'},    0,{}, {}; ... % 100psych on
    'Sauron',   'd',    {'070614','070712'},{'070713','070730'},{'070805','070817'},    0,{}, {}; ... % 100psych on
    'Aragorn',  'p',    {'070417','999999'},{'070705','070727'},{'070804','070817'},    0,{}, {}; ... % 100psych on
    'Boromir',  'd',    {'070620','070701'},{'070705','070729'},{'070806','070820'},    0,{}, {}; ... % 100psych on
    'Executioner', 'p', {'070402','070531'},{'070604','999999'},{},                     0,{}, {}; ... % at 0.5 octave, no psych
    'Lory',     'p' ,   {'070402','070513'},{'070615','070621'},{'070628','070723'},    0,{}, {}; ...
    'Gandalf' , 'p' ,   {'070405','076007'},{'070607','070702'},{'070709','070830'},    0,{}, {}; ...
    'Samwise' , 'd' ,   {'070410','999999'},{'070625','070703'},{'070710','070713'},    0,{}, {}; ...
    'Legolas',  'd',    {'070424','070517'},{'070522','070612'},{'070619','070713'},    0,{}, {}; ...
    'Gryphon',  'd',    {'070315','070427'},{'070514','070601'},{'070611','070703'},    0,{}, {}; ... ... % psych flag was turned on on May 2, but he wasn't really stable till the 14th. Moreover, SPL randdomization was added around then so I needed extra sessiosn around then.
    'Bilbo' ,   'p',    {'070329','070417'},{'070427','070517'},{'070530','070702'},    0,{}, {}; ...
    % MGB --------------
    'Gaffer',   'p',    {'999999','999999'},{'070821','070824'},{'070902','070906'},    0,{}, {}; ...
    'Isildur',  'p',    {'999999','999999'},{'070822','070824'},{'070902','070906'},    0,{}, {}; ...
    'Proudfoot','p',    {'999999','999999'},{'070822','070824'},{'070902','070906'},    0,{}, {}; ...
    'Galadriel','p',    {'999999','999999'},{'070911','070924'},{'071001','071011'},    0,{}, {}; ...    
    'Denethor', 'd',    {'070706','999999'},{'070809','070824'},{'070902','071009'},    0,{}, {'070612','070705'}; ...
    'Balrog',   'd',    {'070728','070828'},{'070829','070917'},{'070924','071003'},    0,{}, {'070702','070726'}; ...
    'Elrond',   'd',    {'070615','999999'},{'070728','070805'},{'070813','070817'},    0,{'070803a'}, {}; ...    
    % Other -------------
    'Rucastle', 'p',    {'999999','999999'},{'080505','999999'},{},                     0,{'080428a'}, {}; ...                     % PFC cannula    
    'Violet',   'd',    {'999999','999999'},{'080528','080603'},{'080505','080515'},    0,{'080428a'}, {}; ...
    'Cushing',  'd',    {'999999','999999'},{'999999','999999'},{},                     0,{'080428a'}, {}; ...
    'Jephro',   'p',    {'999999','999999'},{'999999','999999'},{},                     0,{'080428a'}, {}; ...
    'Canacx',   'd',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Boscombe', 'd',    {'999999','999999'},{'080105','999999'},{},                     0,{'080109b'}, {'071029','071118'}; ...
    'Adler',    'd',    {'999999','999999'},{'080107','999999'},{},                     0,{}, {'071105','071120'}; ...
    'Lestrade', 'p',    {'999999','999999'},{'071201','999999'},{},                     0,{'071018a'}, {'070914','070926'}; ...
    'Hound',    'p',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Stapleton','p',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Gregson',  'p',    {'999999','999999'},{'071201','071230'},{'080105','999999'},    0,{'071018a'}, {'070913','070926'}; ...
    'Meriadoc', 'd',    {'070620','999999'},{'070822','071002'},{'071008','071014'},    0,{}, {}; ...
    'Eowyn',    'd',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ... % 100psych on
    'Smeagol',  'd',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Baby',     'd',    {'070309','070419'},{'070424','070521'},{'070601','070621'},    0,{}, {}; ...
    'Wocky' ,   'd' ,   {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Cheshire', 'p' ,   {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Frodo' ,   'd' ,   {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Faramir',  'd',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Cook',     'd',    {'070418','070503'},{'070418','070503'},{'070510','070604'},    0,{}, {}; ... ...   % Col3 contains dates for 0.6 practice
    'Knave',    'p' ,   {},{'070409','070423'},{'070503','999999'},                     0,{}, {}; ... ... % Col4 &5 contains dates for 1 octave practice
    'Queen',    'p' ,   {},{'070323','070419'},{'070503','999999'},                     0,{'070409a'},{};...   % Col4 & 5contains dates for 0.6 octave practice
    'Hare',     'd',    {'999999','999999'},{'070322','070417'},{'070426', '999999'},   0,{}, {}; ...
    'Duchess',  'd',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Eaglet',   'd',    {'070309','070321'},{'070405','070418'},{'070426','070510'},    0,{}, {}; ...
    'Jabber',   'd' ,   {'070310','070321'},{'070322','070419'},{'070426','070510'},    0,{'070507a','070508a'},{}; ...
    'chanakya', 'p',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...    % --- TEST RAT
    % ---- Princeton non-current rats
    'S012', 'p',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'S009', 'd',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'S010', 'd',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'S003', 'd',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'S027', 'p',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Lucius','d',    {'070829','999999'},{'071228','999999'},{},                    0,{}, {'070802','070827'}; ...
    'Sirius','d',    {'070822','999999'},{'071209','080102'},{'080114','999999'},   0,{}, {'070711','070727'}; ...
    'S001',         'p',    {'071220','071224'},{'999999','999999'},{},                     0,{}, {'071201','071225'}; ...
    'S004',         'p',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    % 'S006',         'p',    {'999999','999999'},{'999999','999999'},{}, 0,{}, {'071126','071225'}; ...
    'S008',         'p',    {'071217','080112'},{'999999','999999'},{},                     0,{}, {'071126','071225'}; ...
    'S011', 'p',    {'999999','999999'},{'999999','999999'},{},                             0,{}, {}; ...
    'S020', 'p',    {'999999','999999'},{'080523','999999'},{},                             0,{'080526a'}, {}; ...
    'Baron',        'd',    {'999999','999999'},{'071210','999999'},{},                     0,{}, {'070827','999999'}; ...
    'Lupin',        'd',    {'070827','999999'},{'071207','999999'},{},                     0,{}, {'070622','070726'}; ...
    'Riddle',       'd',    {'070813','999999'},{'070919','071011'},{'071018','999999'},    0,{}, {'070724','070811'}; ...
    'Ron',          'd',    {'070804','070828'},{'070919','071011'},{'071018','999999'},    0,{'070920a','070921a','070922a'}, {}; ...
    'Hermione',     'p',    {'070801','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Minerva',      'p',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Harry',        'd',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Longbottom',   'd',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Hagrid',       'd',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Snape',        'd',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Draco',        'd',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Dumbledore',   'd',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Fred',         'd',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'George',       'd',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Petunia',      'p',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Ginny',        'p',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Luna',         'p',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Myrtle',       'p',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Lily',         'p',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    'Nick',         'd',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {'070827','999999'}; ...
    'Peeves',       'd',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {'070827','999999'}; ...
    'Percy',        'd',    {'070829','999999'},{'999999','999999'},{},                     0,{}, {'070802','070824'}; ...
    'S006',         'p',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {'071126','071225'}; ...
    'S015', 'p',    {'999999','999999'},{'999999','999999'},{},                     0,{}, {}; ...
    };

% endpoints for rat psychometric curves
psych_bins = { ...
    'Evenstar', [8 16]; ...
    'Sherlock', [8 16]; ...
    'Sherlock', [8 16]; ...
    'Watson',   [8 16]; ...
    'Gregson',  [8 16]; ...
    'Lestrade', [8 16]; ...
    };

% rats with stable psychometric periods that can be used for group analysis
% area-specific psych rats
area_psych = {};
area_psych.duration = {};
area_psych.duration.ACx = {'Boromir','Gryphon','Sauron','Legolas', 'Jabber'};
area_psych.duration.ACxsaline = {'Silver','Stark'};
area_psych.duration.ACx2 = {'S039','S045','S025','S050'};
area_psych.duration.ACx2saline = {'S031','S021'};
area_psych.duration.ACx3 = {'S033','S038','S048','S029'};
area_psych.duration.ACxall = horzcat(area_psych.duration.ACx, area_psych.duration.ACx2);
    area_psych.duration.ACxall = horzcat(area_psych.duration.ACxall, area_psych.duration.ACx3);
area_psych.duration.ACxallsaline = horzcat(area_psych.duration.ACxsaline, area_psych.duration.ACx2saline);
area_psych.duration.MGB = {'Balrog','Denethor','Elrond'}; % Elrond is fake
area_psych.duration.mPFC = {'Celeborn','Treebeard','Nazgul','Shelob','Wraith','Hudson'};
area_psych.duration.other= {};
area_psych.duration.saline = {'Hare','Baby'};

area_psych.pitch = {};
area_psych.pitch.ACx = {'Aragorn','Gimli','Lory','Gandalf','Bilbo'};
area_psych.pitch.ACxsaline={'Hatty','Beryl'};
area_psych.pitch.ACx2 = {'S028','S044','S036','S026','S047'};
area_psych.pitch.ACx2saline={'S030','S016'};
area_psych.pitch.ACx3={};
area_psych.pitch.ACxall = horzcat(area_psych.pitch.ACx, area_psych.pitch.ACx2);
area_psych.pitch.ACxallsaline = horzcat(area_psych.pitch.ACxsaline, area_psych.pitch.ACx2saline);
area_psych.pitch.MGB = {'Galadriel','Isildur','Proudfoot','Gaffer'}; % Isildur, Proudfoot, Gaffer are actually basic
area_psych.pitch.mPFC = {'Moria','Evenstar','Sherlock','Shadowfax','Watson'};
area_psych.pitch.other = {};

% those rats lesioned during steady-state stimulus discrimination; no
% psychometric trials here

area_basic = {};
area_basic.duration={};
area_basic.duration.MGB = {'Elrond'};
area_basic.duration.mPFC = {'Meriadoc'};
area_basic.pitch = {};
area_basic.pitch.ACx= {};
area_basic.pitch.MGB={'Isildur','Proudfoot', 'Gaffer'};
area_basic.pitch.mPFC = {'Minerva','Lily'};

% keys are rats
% value is i-by-3 infusion cell:
%   (1) date (string)
%   (2) liquid infused (character)
%   (3) concentration (double)
% concentration of liquid
% KEY FOR LIQUIDS:
% S - saline
% M - muscimol
% A - anaesthesia only, no infusions.
cannula= {};

cannula.Lascar = { ... %  mPFC
    '080324a', 'M', 1.0 ; ...
    '080325a', 'S', NaN ; ...  First infusion ever -- ignore
    '080327a', 'M', 0.2 ; ...
    '080401a', 'S', NaN ; ...
    '080402a', 'M', 0.4 ; ...
    '080409a', 'S', NaN ; ...
    '080410a', 'M', 0.4 ; ...
    '080411a', 'S', NaN ; ...
    '080414a', 'S', NaN ; ...
    '080415a', 'S', NaN ; ...
    '080416a', 'M', 0.4 ; ...
    '080417a', 'S', NaN ; ...
    '080419a', 'M', 0.6 ; ...
    '080421a', 'M', 0.6 ; ...
    '080423a', 'M', 1.0 ; ...
    };
cannula.Grimesby = { ... % mPFC
        '080409b', 'S', NaN ; ...
        '080410a', 'M', 0.4 ; ...
        '080411a', 'S', NaN ; ...
        '080414a', 'S', NaN ; ...
        '080415a', 'S', NaN ; ...
        '080416a', 'M', 0.4 ; ...
        '080418a', 'A', NaN ; ...
        '080419a', 'A', NaN ; ...
        '080421a', 'S', NaN ; ...
        '080422a', 'M', 0.2 ; ...
        '080423a', 'S', NaN ; ...
    '080506a', 'S', NaN ; ...
    '080509a', 'S', NaN ; ...
    '080513a', 'S', NaN ; ...
    '080515a', 'S', NaN ; ...
    '080521a', 'M', 0.2 ; ...
    '080523a', 'M', 0.2 ; ...
    '080527a', 'M', 0.5 ; ...
    '080531a', 'M', 0.2 ; ...
    '080602a', 'M', 0.2 ; ...
    '080604a', 'M', 0.2 ; ...
    };
cannula.Pips = { ... % mPFC
%         '080414a', 'S', NaN; ...
%         '080415a', 'S', NaN ; ...
%         '080416a', 'M', 0.4 ; ...
%         '080418a', 'A', NaN ; ...
%         '080419a', 'A', NaN ; ...
%         '080421a', 'S', NaN ; ...
%         '080422a', 'M', 0.2 ; ...
%         '080423a', 'S', NaN ; ...
    '080506a', 'S', NaN ; ...
    '080509a', 'S', NaN ; ...
    '080513a', 'S', NaN ; ...
    '080515a', 'S', NaN ; ...
    '080521a', 'M', 0.2 ; ...
    '080523a', 'M', 0.2 ; ...
    '080531a', 'M', 0.2 ; ...
    '080602a', 'M', 0.2 ; ...
    '080604a', 'M', 0.2 ; ...
    '080613a', 'M', 0.2 ; ...
    '080616a', 'M', 0.2 ; ...
    '080619a', 'S', NaN ; ...
    };
cannula.Blaze = { ... % mPFC
        '080421a', 'S', NaN ; ...
        '080422a', 'M', 0.2 ; ...
        '080423a', 'S', NaN ; ...
    '080506a', 'S', NaN ; ...
    '080509a', 'S', NaN ; ...
    '080513a', 'S', NaN ; ...
    '080515a', 'S', NaN ; ...
    '080522a', 'M', 0.2 ; ...
    '080524a', 'M', 0.2 ; ...
    '080528a', 'M', 0.5 ; ...
    '080602a', 'M', 0.2 ; ...
    '080604a', 'M', 0.2 ; ...
    '080613a', 'M', 0.2 ; ...
    '080616a', 'M', 0.2 ; ...
    '080619a', 'S', NaN ; ...
    };

cannula.Rucastle = { ... % MPFC
    '080619a', 'A', NaN ; ...
    '080623a', 'S', NaN ; ...
    '080625a', 'M', 0.2 ; ...
    '080627a', 'S', NaN ; ...
    };

% duration
cannula.S007 = { ...
    '080715a', 'A', NaN ; ...
    '080717a', 'A', NaN ; ...
    '080721a', 'M', 0.01 ; ...
    '080723a', 'M', 0.003 ; ...
    '080725a', 'M', 0.003 ; ...
    '080728a', 'S', NaN ; ...
    '080730a', 'S', NaN ; ...
    '080804a', 'M', 0.003 ; ...
    '080807a', 'M', 0.01 ; ...
    '080811a', 'M', 0.02 ; ...
    '080814a', 'M', 0.04 ; ...
    '080818a', 'M', 0.08 ; ...
    '080821a', 'M', 0.16 ; ...
    '080825a', 'M', 0.08 ; ...
    '080828a', 'M', 0.08 ; ...
    '080823a', 'N', NaN ; ...
    '080824a', 'N', NaN ; ...
    '080826a', 'N', NaN ; ...
    '080827a', 'N', NaN ; ...
    };

cannula.S002 = { ...
    '080715a','A', NaN ; ...
    '080717a','A', NaN ; ...
    '080728a', 'A', NaN ; ...
    '080730a', 'S', NaN ; ...
    '080804a', 'S', NaN ; ...
    '080807a', 'M', 0.003 ; ...
    '080811a', 'M', 0.01 ; ...
    '080814a', 'M', 0.02 ; ...
    '080818a', 'M', 0.08 ; ...
    '080825a', 'M', 0.08 ; ...
    '080828a', 'M', 0.08 ; ...
    '080823a', 'N', NaN ; ...
    '080824a', 'N', NaN ; ...
    '080826a', 'N', NaN ; ...
    '080827a', 'N', NaN ; ...
    };

cannula.S005 = { ...
    '080804a', 'A', NaN ; ...
    '080806a','S', NaN ; ...
    '080811a', 'S', NaN ; ...
    '080814a', 'M', 0.01 ; ...
    '080818a', 'M', 0.04 ; ...
    '080821a', 'M', 0.08 ; ...
    '080825a', 'M', 0.16 ; ... % BAD TIMEPOINT
    '080828a', 'M', 0.08 ; ...
    '080823a', 'N', NaN ; ...
    '080824a', 'N', NaN ; ...
    '080826a', 'N', NaN ; ...
    '080827a', 'N', NaN ; ...
    };

cannula.S014 = { ...
    '080731a', 'A', NaN ; ...
    '080804a','S', NaN ; ...
    '080807a', 'M', 0.003 ; ...
    '080811a', 'M', 0.01 ; ...
    '080814a', 'M', 0.02 ; ...
    '080818a', 'M', 0.04 ; ...
    '080821a', 'M', 0.04 ; ...
    '080825a', 'M', 0.04 ; ...
    '080828a', 'M', 0.04 ; ...
    '080823a', 'N', NaN ; ...
    '080824a', 'N', NaN ; ...
    '080826a', 'N', NaN ; ...
    '080827a', 'N', NaN ; ...
    };

% frequency rats
cannula.S017 = { ...
    '080811a', 'A', NaN ; ...
    '080813a','S', NaN ; ...
    '080818a','M',0.02; ...
    '080821a','M', 0.04 ; ...
    '080825a','M', 0.04 ; ...
    '080828a', 'M', 0.04 ; ...
    '080823a', 'N', NaN ; ...
    '080824a', 'N', NaN ; ...
    '080826a', 'N', NaN ; ...
    '080827a', 'N', NaN ; ...
    };

cannula.S013 = { ...
    '080715a','A', NaN ; ...
    '080717a','A', NaN ; ...
    '080721a','M', 0.01 ; ...
    '080723a', 'M', 0.003 ; ...
    '080725a', 'M' 0.003 ; ...
    '080728a','S', NaN ; ...
    '080730a','S',NaN ; ...
    '080804a','M', 0.003; ...
    '080807a', 'M', 0.01 ; ...
    '080811a','M', 0.02 ; ...
    '080814a', 'M', 0.04 ; ...
    '080818a','M', 0.08; ...
    '080821a','M', 0.04 ; ...
    '080825a','M', 0.04 ; ...
    '080828a', 'M', 0.04 ; ...
    '080823a', 'N', NaN ; ...
    '080824a', 'N', NaN ; ...
    '080826a', 'N', NaN ; ...
    '080827a', 'N', NaN ; ...
    };

cannula.S024 = { ...
    '080812a','A', NaN ; ...
    '080814a','S', NaN ; ...
    '080818a','M', 0.02 ; ...
    '080821a','M', 0.08 ; ...
    '080826a','M', 0.08 ; ...
    '080828a','M', 0.08 ; ...
    '080823a', 'N', NaN ; ...
    '080824a', 'N', NaN ; ...
    '080826a', 'N', NaN ; ...
    '080827a', 'N', NaN ; ...
    };

% dose of muscimol selected for use in impairment analysis
muscimoldose = 0;
muscimoldose.S007=0.08 ;
muscimoldose.S002=0.08 ;
muscimoldose.S005=0.08 ;
muscimoldose.S014=0.04 ;
muscimoldose.S013=0.04 ;
muscimoldose.S017=0.04 ;
muscimoldose.S024=0.08 ;

switch action
    case 'get_ratrow'
        ratrow = {};

        if isstr(ratlist)
            ratlist = {ratlist};
        elseif ~iscell(ratlist)
            error('ratlist should be a cell array');
        end;

        if get_current > 0
            idx = find(cell2mat(rat_table(:,CURRENT_COL)) > 0);
            ratlist = rat_table(idx,NAME_COL);
        elseif get_all > 0
            ratlist = rat_table(:,NAME_COL);
        end;

        for k = 1:length(ratlist)
            idx = find(strcmpi(rat_table(:,NAME_COL), ratlist{k}));
            try
                if ~isempty(idx),
                    if strcmpi(rat_table{idx,TASK_COL},'d')
                        rat_table{idx,TASK_COL} = 'duration_discobj';
                    elseif strcmpi(rat_table{idx,TASK_COL},'p')
                        rat_table{idx,TASK_COL} = 'dual_discobj';
                    else
                        rat_table{idx,TASK_COL} = '@classical2afc_soloobj';
                    end;
                    ratrow = vertcat(ratrow, rat_table(idx,:));
                else
                    warning('\n\tThe rat %s is not in the table.', ratlist{k});
                end;
            catch
                error('issue with %s', ratlist{k});
            end;

            if ~strcmpi(ratlist{k},ratrow{end,NAME_COL}), % Check. Always check.
                error('Whoops! For some weird reason, pulled up the wrong rat info!!');
            end;
        end;

    case 'cannula'
        if iscell(ratlist)
            ratlist = ratlist{1};
        end;
        try
            ratrow = eval(['cannula.' ratlist]);
        catch
            fprintf(usefid, 'Could not retrieve cannula row\n');
            ratrow = {};
        end;

    case 'cannula__saline'
        canrow = rat_task_table(ratlist, 'action', 'cannula');
        if ~isempty(canrow)
            idx = find(strcmpi(canrow(:,2),'S'));
            ratrow = canrow(idx,:);
        else
            ratrow ={};
        end;
    case 'cannula__muscimol'
        canrow = rat_task_table(ratlist, 'action', 'cannula');
        if ~isempty(canrow)
            idx = find(strcmpi(canrow(:,2),'M'));
            ratrow = canrow(idx,:);

            if filter_by_dose > 0
                f = eval(['muscimoldose.' ratlist]);
                fprintf(usefid, 'Dose for %s is %1.2f\n', ratlist, f);
                ratrow = ratrow(cell2mat(ratrow(:,3)) == f, :);
            end;
        else
            ratrow = {};
        end;
        
    case 'getdose'
        if ismember(ratlist, fieldnames(muscimoldose))
            ratrow = eval(['muscimoldose.' ratlist ';']);            
        else
            error('sorry, this rat doesn''t have a muscimol entry!');
        end;

    case 'cannula__anaesth'
        canrow = rat_task_table(ratlist, 'action', 'cannula');
        if ~isempty(canrow)
            idx = find(strcmpi(canrow(:,2),'A'));
            ratrow = canrow(idx,:);
        else
            ratrow = {};
        end;
    case 'cannula__nondays'
        ratentry = rat_task_table(ratlist); lastbase = ratentry{1, rat_task_table('','action', 'get_prepsych_col')}; str=lastbase{2};
        from=yearmonthday(datenum(str2double(str(1:2)),str2double(str(3:4)),str2double(str(5:6)))+1);
        f = get_files(ratlist, 'fromdate', from,'todate',to);
        canrow = rat_task_table(ratlist, 'action','cannula');
        if isempty(canrow), ratrow = f; else
            ratrow  = setdiff(f, canrow(:,1));
        end;
    case 'get_duration_psych'
        ratrow=sub__filter_ratcells(area_psych.duration, area_filter);
    case 'get_pitch_psych'
        ratrow=sub__filter_ratcells(area_psych.pitch, area_filter);
    case 'get_pitch_basic'
        ratrow=sub__filter_ratcells(area_basic.pitch, area_filter);
    case 'get_duration_basic'
        ratrow=sub__filter_ratcells(area_basic.duration, area_filter);

    case 'get_prepsych_col',
        ratrow = PREPSYCH_COL;
    case 'get_postpsych_col',
        ratrow = POSTPSYCH_COL;
    case 'get_sharp_col',
        ratrow = SHARP_COL;
    case 'get_basictask_col',
        ratrow = BASICTASK_COL;
    case 'get_excluded_col'
        ratrow = EXCDATE_COL;
    case 'notyetflipped'
        ratrow = rat_task_table(ratlist);
        postpsychdates=ratrow{1,5}; pp=postpsychdates{2};
        if (str2double(pp(1:2)) > 7)|| (str2double(pp(1:2)) == 7 && str2double(pp(3:4)) > 11)
            ratrow=0;
        else
            ratrow=1;
        end;
                    fprintf(1,'%s -- Not yet flipped?: %i (%s)\n', ratlist, ratrow, pp);
        
    otherwise
        error('invalid action');
end;

function [ratlist] = sub__filter_ratcells(cell2filter, area_filter)

if strcmpi(area_filter,'')
    f = fieldnames(cell2filter);
else
    f = {area_filter};
end;

ratlist = {};
for idx = 1:length(f)
    curr = eval(['cell2filter.' f{idx} ';']);
    ratlist(end+1: (end + length(curr))) = curr;
end;