% [x, y] = TBupsSection(obj, action, tname, varargin)
%
% This plugin makes a window that manages the making of Poisson bups, which
% are bups that occur as independent Poisson processes on the left and
% right.
%
% Note: TBupsSection not only controls the generation of the poisson clicks
% trains but it also controls the laser stimulation, and thus incorporates
% all the functionality of StimulatorSection which is therefore not used in the TBups
% protocol.
%
% PARAMETERS:
% -----------
%
% obj      Default object argument..
%
% action   One of:
%
%   'init'     Initializes the plugin. Sets up internal variables
%               and the GUI window.
%
% Wynne, Jan 2025 

function [x, y] = TBupsSection(obj, action, varargin)

GetSoloFunctionArgs(obj);

switch action
    
%% init    
  case 'init'
    if length(varargin) < 2
      error('Need at least two arguments, x and y position, to initialize %s', mfilename);
    end
    x = varargin{1}; y = varargin{2};

    SoloParamHandle(obj, 'my_gui_info', 'value', [x y double(gcf)]);
    
    SoloParamHandle(obj, 'Bups', 'value', {});
    
    ToggleParam(obj, 'tbup_show', 0, x, y, ...
       'OnString', 'TBup window Showing', ...
       'OffString', 'TBup window Hidden', ...
       'TooltipString', 'Show/Hide TBup window'); next_row(y);
    set_callback(tbup_show, {mfilename, 'show_hide';});  %#ok<NODEF>
    
    screen_size = get(0, 'ScreenSize'); fig = double(gcf);
    SoloParamHandle(obj, 'tbup_fig', ...
        'value', double(figure('Position', [200 50 600 200], ...
        'closerequestfcn', [mfilename '(' class(obj) ', ''hide''' ');'], 'MenuBar', 'none', ...
        'NumberTitle', 'off', 'Name', 'TBups')), 'saveable', 0);
    origfig_xy = [x y]; 
    
    x = 10;
    y=10;    

	DispParam(obj, 'T', 2, x, y, 'position', [x y 100 20], ...
		'labelfraction', 0.3, ...
		'TooltipString', sprintf(['sample duration, is T_probe with probability p_probe, otherwise drawn between T_min and T_max uniformly'...
                           '\n Note that T controls the maximum sound duration in the RT version of the task!']));
	NumeditParam(obj, 'T_min', 2, x, y, 'position', [x+100 y 100 20], ...
		'TooltipString', 'the minimum sample duration');
	NumeditParam(obj, 'T_max', 2, x, y, 'position', [x+200 y 100 20], ...
		'TooltipString', 'the maximum sample duration');
	PushbuttonParam(obj, 'T_resample', x, y, 'position', [x+300 y 100 20], ...
		'label', 'Resample', ...
		'TooltipString', 'resample T, the sample duration');
	set_callback({T_min; T_max; T_resample;}, {mfilename, 'T_resample'}); %#ok<NODEF>

    NumeditParam(obj, 'post_T', 0.25, x, y, 'position', [x+400 y 100 20], ...
        'TooltipString', 'how much time (s) is added between stim train and go cue');

    MenuParam(obj, 'T_type', {'center','end','beginning'}, 1,x, y, 'position', [x+500 y 100 20], ...
                            'TooltipString', 'where in nic period click train goes if T train < nic')
%             MenuParam(obj, 'stim_type', {'Light Only', 'Sound Only', 'Light AND Sound'}, 2, x,y, ...
%                     'labelfraction', 0.3, ...
%                     'TooltipString', sprintf(['Controls what stimulus indicates correct side.' ...
%                                             '\nIf light only, no sounds and correct side LED turns on.'...
%                                             '\nIf sound only, only the sound train and no LED.'...
%                                             '\nIf light and sound, both.']))
	next_row(y);
    % *********************************************************************
    
    % STIMULUS PROPERTIES SPECIFICATION
    
    % *********************************************************************
    DispParam(obj, 'probe_rate', 40, x,y, 'position', [x y 100 20], ...
        'labelfraction', 0.5, ...
        'TooltipString', 'the underlying click rate ');
	% NumeditParam(obj, 'rate_min', 4, x, y, 'position', [x+100 y 100 20], ...
	% 	'TooltipString', 'the minimum rate in Hz');
	% NumeditParam(obj, 'rate_max', 20, x, y, 'position', [x+200 y 100 20], ...
	% 	'TooltipString', 'the maximum rate in Hz');
    NumeditParam(obj, 'possible_rates', [2 4 8 16 32 40 50 64 128 320], x, y, 'position', [x+100 y 300 20], ...
	 	'TooltipString', 'the maximum rate in Hz');
	PushbuttonParam(obj, 'rate_resample', x, y, 'position', [x+400 y 100 20], ...
		'label', 'Resample', ...
		'TooltipString', 'resample rate, the mean underlying click rate');
	set_callback({possible_rates; rate_resample;}, {mfilename, 'rate_resample'});

    next_row(y);

    ToggleParam(obj, 'tone_style', 0, x, y, 'position', [x y 250 20], ...
		'OffString', 'Specify tones by base_freq and n_tones', ...
		'OnString',  'Specify tones manually', ...
		'TooltipString', 'S');
    NumeditParam(obj, 'tones', 2000, x, y, 'position', [x+250 y 300 20], ...
        'labelfraction', 0.15, ...
        'TooltipString', 'Tones that make up each click');
    
    next_row(y);
    NumeditParam(obj, 'fixed_frac', 1, x, y, 'position', [x y 100 20], ...
        'label','fixed fraction',...
        'TooltipString', 'fraction of click trains that will be fixed vs randomly timed');    
    next_row(y);
    NumeditParam(obj, 'bup_width', 3, x, y, 'position', [x y 100 20], ...
        'label', 'bupwidth, ms', 'TooltipString', 'the bup width in units of msec');
    NumeditParam(obj, 'bup_ramp', 2, x, y, 'position', [x+100 y 100 20], ...
        'label', 'bupramp, ms', 'TooltipString', 'the duration in units of msec of the upwards and downwards volume ramps for individual bups');
    NumeditParam(obj, 'base_freq', [2000], x, y, 'position', [x+200 y 100 20], ...
        'TooltipString', 'the base frequency of individual bup; the bup consists of this frequency together with n_tones-1 higher octaves','label','base freq, Hz');
    NumeditParam(obj, 'n_tones', 5, x, y, 'position', [x+300 y 80 20], ...
        'TooltipString', 'total number of tones used to generate individual bup; so n_tones-1 higher octaves are combined with base_freq');
    NumeditParam(obj, 'vol', 0.15, x, y, 'position', [x+380 y 90 20], ...
        'labelfraction', 0.3, ...
        'TooltipString', 'volume multiplier for all sounds; can be a 1x2 vector to specify multiplier for [left_vol right_vol]');    
    ToggleParam(obj, 'freq_vol', 1, x, y, 'position', [x+470 y 80 20], ...
        'OnString', 'var freq vol', ...
        'OffString', 'flat freq vol', ...
        'TooltipString','if on, multiple entries in the volume param adjusts each frequency separately. if off, adjusts each speaker side');  

    next_row(y);
    NumeditParam(obj, 'side_stim', 0, x, y, 'position', [x y 100 20], ...
        'labelfraction', 0.5, ...
        'TooltipString', 'whether the sound is played on both sides (0), only left (1), or only right (2)');    
	ToggleParam(obj, 'avoid_collisions', 1, x, y, 'position', [x+100 y 100 20], ...
		'OffString', 'allow collisions', ...
		'OnString',  'prevent collisions', ...
		'TooltipString', 'If not allowed, a refractory period is imposed equal to a single bup width. Otherwise, click waveforms sum and can therefore interfere.');    
	% ToggleParam(obj, 'task_type', 0, x, y, 'position', [x+200 y 100 20], ...
	% 	'OffString', 'Frequency Task', ...
	% 	'OnString',  'Sides Task', ...
	% 	'TooltipString', 'Sides task is classic Tbups where clicks come from either the right or left. Frequency makes all clicks stereo with the first base_freq frequency favoring left responses and the second favoring right');    
    
    
    NumeditParam(obj, 'min_ISI', .003, x, y, 'position', [x+200 y 100 20],'labelfraction',0.68, ...
        'TooltipString', 'the minimum time in ms that is allowed between bups','label','min ISI, ms');    
	NumeditParam(obj, 'total_rate',value(probe_rate), x, y, 'position', [x+300 y 100 20],'labelfraction',0.68, ...
        'TooltipString', 'the sum of left and right bup rates in Hz','label','total rate, Hz');    
	NumeditParam(obj, 'crosstalk', 0, x, y, 'position', [x+400 y 100 20],'labelfraction',0.68, ...
		'TooltipString', 'if >0, then is the amount the left clicks leak into the right channel, and vice versa.');    
    ToggleParam(obj, 'vol_on', 1, x, y, 'position', [x+500 y 80 20], ...
        'OnString', 'sound is on with vol multiplier set from vol', ...
        'OffString', 'sound is off fully, equivalent to vol multiplier being 0');  

    set_callback({tone_style, n_tones, base_freq}, {mfilename, 'update_tones'});
    
    next_row(y);
    SubheaderParam(obj, 'title4', 'Stimulus Properties Section', x, y);


    DispParam(obj, 'is_fixed', 1, x, y, 'position', [x+150 y 100 20], ...
        'labelfraction', 0.6, ...
        'TooltipString', 'whether this trial is fixed interval or not');

    
	next_row(y, 1);
	HeaderParam(obj, 'panel_title', 'Tbups plugin', x, y, 'position', [x y 600 20]);
    
	
    % this soloparamhandle stores the actual bup times (in seconds) on the left and right
    % for the present trial, as well as the side response of an ideal
    % observer that counts the number of bups on either side.
    % ThisBupTimes.observer is -1 for left, 1 for right, and 0 if the
    % numbers of bups on either side are equal.
    % ThisBupTimes.left and ThisBupTimes.right are updated as the next
    % sound is prepared and pushed to history to be saved with the data
    SoloParamHandle(obj, 'ThisBupTimes', 'value', {});
    
    % passive auditory stimulation at the end of a trial
    SoloParamHandle(obj, 'ThisPassiveSound', 'value', {});
    
    % this soloparamhandle stores the specification of the stimulator wave
    % fields are: .ison, .channel, .pre, and .dur
    specs.ison = 0;
    specs.channel = 0;
    specs.pulse = 0;
    specs.freq = 0;
    specs.pre = 0;
    specs.dur = 1;
    specs.power=[0 0];
    specs.trigger = '';
    SoloParamHandle(obj, 'StimulatorSpecs', 'value', specs);
    SoloParamHandle(obj, 'MaskSpecs',       'value', specs);
    
	% stores the set of gamma values used to make Tbups from
	% trial to trial.  
	% these values may be specified either by range or by enumeration
	SoloParamHandle(obj, 'alphas', 'value', [1 realmax]);

    % feval(mfilename, obj, 'ARbias');
    feval(mfilename, obj, 'show_hide');   
    feval(mfilename, obj, 'update_tones');
    
    figure(fig);
    x = origfig_xy(1); y = origfig_xy(2);

%% adjust_volume
  case 'adjust_volume'
    snd = varargin{1};

    if vol_on == 0 
        snd = snd*0;
    else
        snd = snd*vol(1);
    end
    % the volume and left and right speakers are not always matched
    RtoL_speaker_volume_ratio = bSettings('get', 'GENERAL', 'RtoL_speaker_volume_ratio');
    if ~isnan(RtoL_speaker_volume_ratio)
        snd(2,:) = snd(2,:) / RtoL_speaker_volume_ratio;
    end
    x = snd;

%% count_this_bups
  case 'count_last_trial_bups'
	  sample_duration = varargin{1};
	  
	  x = time;
	  y = observer;
%% get
  case 'get'
     switch varargin{1},
         case 'nstimuli',
             x = length(left_alphas)+length(right_alphas)+length(endpoint_alphas); %#ok<NODEF>
         case 'nleft',
             x = length(left_alphas)+1; %plus 1 is for endpoint
         case 'nright',
             x = length(right_alphas)+1; %#ok<NODEF>
		 case 'all_sides',
			 x = [char('l'*ones(1,length(left_alphas)+1)) char('r'*ones(1,length(right_alphas)+1))]; %#ok<NODEF>
		 case 'sample_duration', 
			 x = value(T);
		 case 'pprobs',
			 x = [value(l_pprobs) ; value(r_pprobs)]; 
        % case 'ARbias'
        %     x = value(ARbias);
        case 'repProb'
            x = value(repProb);
     end;
%% get_all_bup_times
  case 'get_all_bup_times'
    x = get_history(ThisBupTimes); %#ok<NODEF>
    return;
%% get_bup_times  
  case 'get_bup_times',
    x = value(ThisBupTimes); %#ok<NODEF>
    return;
%% get_this_side_and_rate
  case 'get_this_side_and_rate'
    rates.side = value(side_stim);
    rates.rate = value(probe_rate);
    rates.tot = value(possible_rates);
    x = value(rates);
%% make_sounds
  case 'make_this_sound'
	srate = SoundManagerSection(obj, 'get_sample_rate');

    
    feval(mfilename, obj, 'rate_resample');
    this_trial_rate = value(probe_rate);


    [snd,bpt] = make_time_train(this_trial_rate, realmax, value(srate), value(T), 'bup_width',value(bup_width), ...
                'base_freq',value(base_freq),'n_tones',value(n_tones),'bup_ramp',value(bup_ramp),...
                'avoid_collisions',value(avoid_collisions),'min_ISI',value(min_ISI),'force_fixed',value(is_fixed),'side_stim',value(side_stim));
    
    % if we made a click train and there are fewer than 2 bups, this is an
    % impossible trial. try again.
    while bpt.n_bups < 2
        [snd,bpt] = make_time_train(this_trial_rate, realmax, value(srate), value(T), 'bup_width',value(bup_width), ...
                'base_freq',value(base_freq),'n_tones',value(n_tones),'bup_ramp',value(bup_ramp),...
                'avoid_collisions',value(avoid_collisions),'min_ISI',value(min_ISI),'force_fixed',value(is_fixed)); 
    end
    post_T.value = 0;


    snd = feval(mfilename, obj, 'adjust_volume', snd);

	if ~SoundManagerSection(obj, 'sound_exists', 'TBupsSound')
		SoundManagerSection(obj, 'declare_new_sound', 'TBupsSound');
		SoundManagerSection(obj, 'set_sound', 'TBupsSound', snd);
	else
		snd_prev = SoundManagerSection(obj, 'get_sound', 'TBupsSound');
		if ~isequal(snd, snd_prev)
			SoundManagerSection(obj, 'set_sound', 'TBupsSound', snd);
        end
    end

	ThisBupTimes.value = bpt;
%% next_trial
  case 'next_trial'  
      % takes an additional argument that specifies the next side choice
	  
      side = varargin{1};
	  

      %T_resample depends on the seed to it got moved down here
      feval(mfilename, obj, 'T_resample');
      
      feval(mfilename, obj, 'make_this_sound');

	  feval(mfilename, obj, 'push_history');
      x = value(T)+value(post_T);

    
%% push_history
  case 'push_history'
	  push_history(ThisBupTimes);
     % push_history(StimulatorSpecs);
    %   push_history(MaskSpecs);
    %   push_history(is_frozen);
    %   push_history(ThisSeed);  


%% update_tones
  case 'update_tones'     
      s = value(base_freq);
      s(s < 0) = 0;
      base_freq.value = s;
      
      s = value(n_tones);
      s(s < 0) = 0;
      n_tones.value = s;
      
      if  tone_style
          enable(tones)
      else
          disable(tones)
      end

      if ~value(tone_style)
          tones.value = value(base_freq) * 2.^(0:value(n_tones)-1);
      end

%% stop_sound      
  case 'test_stop'
      
    SoundManagerSection(obj, 'stop_sound', 'TestSound');

%% T_resample
  case 'T_resample'
	% if p_probe > 1, p_probe.value = 1; end
	% if p_probe < 0, p_probe.value = 0; end
	% if T_probe < 0, T_probe.value = 0; end % p_probe.value = 0; 
	if T_max < T_min, T_max.value = T_min(1); end
	ThisSeed.value = randi(10^9,1);
       
    T.value = value(T_min)+rand(1)*(T_max-T_min);


    % end
%% rate_resample
case 'rate_resample'	
    if n_done_trials < 2
        probe_rate.value = possible_rates(randi(length(possible_rates)));
        side_stim.value = randi(3)-1;
    else
        counts = StimulusSection(obj, 'get_counts_data');
        big_count = max(max(counts));
        % side_stim.value = randi()
        valid_idx = find(counts < big_count);
        
        if isempty(valid_idx)
            valid_idx = 1:numel(counts);
        end
        
        % pick one (random); convert to row/col if needed
        chosen_lin = valid_idx(randi(numel(valid_idx)));
        [side_stim_ind, probe_rate_ind] = ind2sub(size(counts), chosen_lin);
        side_stim.value = side_stim_ind - 1; % to make 0,1,2
        probe_rate.value = possible_rates(probe_rate_ind);
    end
    % probe_rate.value = randi([value(rate_min),value(rate_max)]);

    
      
%% hide, show_hide
  case 'hide',
    tbup_show.value = 0;
    feval(mfilename, obj, 'show_hide');
    
  case 'show_hide',
    if value(tbup_show) == 1, set(value(tbup_fig), 'Visible', 'on');  %#ok<NODEF>
    else                      set(value(tbup_fig), 'Visible', 'off');
    end;
    
%% close
  case 'close'   
    try %#ok<TRYNC>
        if ishandle(value(tbup_fig)), delete(value(tbup_fig)); end;
        delete_sphandle('owner', ['^@' class(obj) '$'], 'fullname', [mfilename '_' tname]);
    end;
    
%% reinit
  case 'reinit'
    % Get the original GUI position and figure:
    my_gui_info = value(my_gui_info);
    x = my_gui_info(1); y = my_gui_info(2); figure(my_gui_info(3));
    
    % close everything involved with the plugin
    feval(mfilename, obj, 'close');

    % Reinitialise at the original GUI position and figure:
    feval(mfilename, obj, 'init', x, y);
        
%% otherwise    
  otherwise
    warning('%s : action "%s" is unknown!', mfilename, action); %#ok<WNTAG> (This line OK.)

end; %     end of switch action

function [x] = colvec(x)
    if size(x,2) > size(x,1), x = x'; end;
    return;