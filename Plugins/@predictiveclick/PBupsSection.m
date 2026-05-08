% [x, y] = PBupsSection(obj, action, tname, varargin)
%
% This plugin makes a window that manages the making of Poisson bups, which
% are bups that occur as independent Poisson processes on the left and
% right.
%
% Note: PBupsSection not only controls the generation of the poisson clicks
% trains but it also controls the laser stimulation, and thus incorporates
% all the functionality of StimulatorSection which is therefore not used in the PBups
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
% BWB, Dec. 2008
% significant overhaul, February 2009
% BWB, added functionality to trigger stimulator (laser) line, May 2012
% AGB, slight changes to access new functionality of make_pbup (min_ISI parameter), Nov. 2017
% Thomas Luo (TZL), Analog output for laser modulation, Oct, 2018
% TZL, Dec 2018
%       - Testing Section: Delivering a continuous sound at an amplitude
%       equal to the peak pressure of a click.
%       - Capability to manually correct for asmmetry in sound pressure
%       level between the left and right speaker
%       - Stimulus Properties Section: Option to manually specificy the
%       tones make up a click, option to specify sound pressure level if
%       headphones were used in a rig
% CDK, 190417 changed order operations so gamma is selected first, then 
%             frozen seed is set, then T is resampled, then click train is 
%             generated, and history is pushed. Probe duration trials are
%             excluded from being frozen trials.
% TZL, May, 2019
%       - Added parameter "laser_mW" for note taking
% EYX, Feb 2026
%       - Removed everything related to stimulator (laser), mask, replay, and passive hearing
%       - Removed T_probe and setup related to user-supplied PBups
%       - Removed anti bias computation (but kept hit fraction computation)

function [x, y] = PBupsSection(obj, action, varargin)

GetSoloFunctionArgs(obj);

switch action
    
%% init    
  case 'init'
    if length(varargin) < 2
      error('Need at least two arguments, x and y position, to initialize %s', mfilename);
    end
    x = varargin{1}; y = varargin{2};

    SoloParamHandle(obj, 'my_gui_info', 'value', [x y double(gcf)]);
    
    SoloParamHandle(obj, 'is_frozen', 'value', 0);   
    SoloParamHandle(obj, 'ThisSeed', 'value', 0);   
    SoloParamHandle(obj, 'Bups', 'value', {});
    
    ToggleParam(obj, 'pbup_show', 0, x, y, ...
       'OnString', 'PBup window Showing', ...
       'OffString', 'PBup window Hidden', ...
       'TooltipString', 'Show/Hide PBup window'); next_row(y);
    set_callback(pbup_show, {mfilename, 'show_hide';});  %#ok<NODEF>
    
    screen_size = get(0, 'ScreenSize'); fig = double(gcf);
    SoloParamHandle(obj, 'pbup_fig', ...
        'value', double(figure('Position', [200 50 1220 330], ...
        'closerequestfcn', [mfilename '(' class(obj) ', ''hide''' ');'], 'MenuBar', 'none', ...
        'NumberTitle', 'off', 'Name', 'PBups')), 'saveable', 0);
    origfig_xy = [x y]; 
    
    x = 10;
    next_column(x,3); y=10;    

	% TESTING SECTION
    ToggleParam(obj, 'test_right_speaker', 0, x, y, 'position', [x+200 y 200 20], ...
		'OffString', 'Right speaker off', ...
		'OnString',  'Right speaker on', ...
		'TooltipString', 'Plays a continuous sound from the right speaker');
    ToggleParam(obj, 'test_left_speaker', 0, x, y, 'position', [x y 200 20], ...
		'OffString', 'Left speaker off', ...
		'OnString',  'Left speaker on', ...
		'TooltipString', 'Plays a continuous sound from the left speaker');
    set_callback(test_left_speaker, {mfilename, 'test_left_speaker'});
    set_callback(test_right_speaker, {mfilename, 'test_right_speaker'});
    next_row(y);

    NumeditParam(obj, 'test_gamma', 2, x, y, 'position', [x y 100 20], ...
        'labelfraction', 0.7, ...
        'TooltipString', 'Pushing the Play button will play a sample sound of this gamma');
	set_callback(test_gamma, {mfilename, 'test_gamma'});
	set_callback_on_load(test_gamma, 1);
    
	DispParam(obj, 'test_lrate', 0, x, y, 'position', [x+100 y 100 20], ...
		'labelfraction', 0.65, ...
		'TooltipString', 'left rate of test_gamma');
	DispParam(obj, 'test_rrate', 0, x, y, 'position', [x+200 y 100 20], ...
		'labelfraction', 0.65, ...
		'TooltipString', 'right rate of test_gamma');
	NumeditParam(obj, 'sduration', 1, x, y, 'position', [x+300 y 100 20], ...
		'labelfraction', 0.7, ...
		'TooltipString', 'duration of test sound');
    PushbuttonParam(obj, 'test_play', x, y, 'position', [x+400 y 80 20], ...
        'label', 'test Play');
    PushbuttonParam(obj, 'test_stop', x, y, 'position', [x+480 y 80 20], ...
        'label', 'test Stop');
    set_callback(test_play, {mfilename, 'test_play'});
    set_callback(test_stop, {mfilename, 'test_stop'});
	next_row(y);

    SubheaderParam(obj, 'title1', 'Testing Section', x, y);
    next_row(y, 1.3);
	
	% HITFRAC SECTION
	LogsliderParam(obj, 'HitFracTau', 30, 10, 400, x, y, 'position', [x y 160 20], ...
		'label', 'hits frac tau', ...
		'TooltipString', 'Number of trials back over which to compute fraction correct (display only)');
	set_callback(HitFracTau, {mfilename, 'update_hitfrac'});
	DispParam(obj, 'RtHitFrac', 0, x, y, 'position', [x y+20 160 20]);
	DispParam(obj, 'LtHitFrac', 0, x, y, 'position', [x y+40 160 20]);
	DispParam(obj, 'HitFrac',   0, x, y, 'position', [x y+60 160 20]);
	
	SoloParamHandle(obj, 'LocalPrevSides',  'value', []);

    %%%%% NEW COLUMN %%%%%
    x = 10; y = 10;
    
	% SAMPLE DURATION SECTION
	DispParam(obj, 'T', 0.5, x, y, 'position', [x y 100 20], ...
		'labelfraction', 0.3, ...
		'TooltipString', sprintf(['sample duration, is T_probe with probability p_probe, otherwise drawn between T_min and T_max uniformly'...
                           '\n Note that T controls the maximum sound duration in the RT version of the task!']));
	NumeditParam(obj, 'T_min', 0.2, x, y, 'position', [x+100 y 100 20], ...
		'TooltipString', 'the minimum sample duration');
	NumeditParam(obj, 'T_max', 0.2, x, y, 'position', [x+200 y 100 20], ...
		'TooltipString', 'the maximum sample duration');
	PushbuttonParam(obj, 'T_resample', x, y, 'position', [x+300 y 100 20], ...
		'label', 'Resample', ...
		'TooltipString', 'resample T, the sample duration');
	set_callback({T_min; T_max; T_resample}, {mfilename, 'T_resample'});
	next_row(y);

	SubheaderParam(obj, 'title3', 'Sample Duration Section', x, y);
	next_row(y, 1.3);
    % *********************************************************************
    
    % STIMULUS PROPERTIES SPECIFICATION
    NumeditParam(obj, 'R_gammas', 2, x, y, 'position', [x+50 y 200 20], ...
        'labelfraction', 0.3, ...
        'TooltipString', 'gammas for sounds whose rates in the right ear are larger; these must all be > 0');
	NumeditParam(obj, 'R_pprobs', 0.5, x, y, 'position', [x+250 y 200 20], ...
		'labelfraction', 0.3, ...
		'TooltipString', 'prior probability for R sounds');
    next_row(y);

    NumeditParam(obj, 'L_gammas', -2, x, y, 'position', [x+50 y 200 20], ...
        'labelfraction', 0.3, ...
        'TooltipString', 'gammas for sounds whose rates in the left ear are larger; these must all be < 0');
	NumeditParam(obj, 'L_pprobs', 0.5, x, y, 'position', [x+250 y 200 20], ...
		'labelfraction', 0.3, ...
		'TooltipString', 'prior probability for R sounds');
	PushbuttonParam(obj, 'normalize_pprobs', x, y, 'position', [x+475 y 100 20], ...
		'label', 'normalize', ...
		'TooltipString', 'Normalize pprobs');
	set_callback(normalize_pprobs, {mfilename, 'normalize_pprobs'});
	next_row(y);

	ToggleParam(obj, 'gamma_style', 0, x, y, 'position', [x y 200 20], ...
		'OffString', 'Specify Gammas by Range', ...
		'OnString',  'Use Gammas Below', ...
		'TooltipString', 'write something here');
	set_callback(gamma_style, {mfilename, 'gamma_style'});
	set_callback_on_load(gamma_style, 1);
	NumeditParam(obj, 'easiest', 2.5, x, y, 'position', [x+200 y 150 20], ...
		'labelfraction', 0.4, ...
		'TooltipString', 'the easiest (endpoints) gamma; this value must be positive');
	NumeditParam(obj, 'hardest', 0.5, x, y, 'position', [x+350 y 150 20], ...
		'labelfraction', 0.4, ...
		'TooltipString', 'the hardest (closest to 0 midpoint) gamma; this value must be positive');
	NumeditParam(obj, 'N', 3, x, y, 'position', [x+500 y 60 20], ...
		'labelfraction', 0.4, ...
		'TooltipString', sprintf(['the number of gamma points between easiest and hardest;' ...
		                          '\nnote that there will actually be 2N trial types (l/r)' ...
								  '\nif N == 1, then the range will consist only of the easiest endpoint gammas']));
    set_callback({R_gammas, L_gammas, easiest, hardest, N}, {mfilename, 'gammas'}); %#ok<NODEF>
    next_row(y,0.2);
    next_row(y);

    ToggleParam(obj, 'tone_style', 0, x, y, 'position', [x y 250 20], ...
		'OffString', 'Specify tones by base_freq and ntones', ...
		'OnString',  'Specify tones manually', ...
		'TooltipString', 'S');
    NumeditParam(obj, 'tones', 2000, x, y, 'position', [x+250 y 300 20], ...
        'labelfraction', 0.15, ...
        'TooltipString', 'Tones that make up each click');
    next_row(y);

    NumeditParam(obj,'frozen_frac',0.5,x,y,'position',[x y 120 20],...
        'label','frozen frac','TooltipString','the fraction of trials that use frozen noise','labelfraction',0.65);
    NumeditParam(obj,'n_seeds',10,x,y,'position',[x+120 y 140 20],...
        'label','n frozen seeds','TooltipString','size of the pool of frozen noise seeds to select amongst (a separate pool for each gamma/totalrate combination)',...
        'labelfraction',0.65);
    ToggleParam(obj, 'frozen_trial_rule', 0, x, y, 'position', [x+260 y 130 20], ...
		'OffString', 'Random Sampling', ...
		'OnString',  'Uniform Sampling', ...
		'TooltipString', 'define how frozen seeds are selected, random is true random, uniform ensures all seeds are presented a similar number of times per session');
    
    NumeditParam(obj, 'headphone_attentuation_dB', [20, 20], x, y, 'position', [x+390 y 220 20], ...
        'label', 'headphone atten. (dB)', 'labelfraction',0.7, ...
        'TooltipString', ['[left,right]. The minimum is limited by the ' ...
                          '"HEADPHONE_MAX_C" in Settings_Custom']);
    set_callback({headphone_attentuation_dB}, {mfilename, 'check_headphones'});
    next_row(y);

    NumeditParam(obj, 'bup_width', 3, x, y, 'position', [x y 140 20], ...
        'label', 'bupwidth, ms', 'TooltipString', 'the bup width in units of msec');
    NumeditParam(obj, 'bup_ramp', 2, x, y, 'position', [x+140 y 140 20], ...
        'label', 'bupramp, ms', 'TooltipString', 'the duration in units of msec of the upwards and downwards volume ramps for individual bups');
    NumeditParam(obj, 'base_freq', 2000, x, y, 'position', [x+280 y 150 20], ...
        'TooltipString', 'the base frequency of individual bup; the bup consists of this frequency together with ntones-1 higher octaves','label','base freq, Hz');
    NumeditParam(obj, 'ntones', 5, x, y, 'position', [x+430 y 80 20], ...
        'TooltipString', 'total number of tones used to generate individual bup; so ntones-1 higher octaves are combined with base_freq');
    NumeditParam(obj, 'vol', 0.5, x, y, 'position', [x+510 y 90 20], ...
        'labelfraction', 0.3, ...
        'TooltipString', 'volume multiplier for all sounds; can be a 1x2 vector to specify multiplier for [left_vol right_vol]');    
    next_row(y);
    
	ToggleParam(obj, 'first_bup_stereo', 1, x, y, 'position', [x y 100 20], ...
		'OffString', 'no stereo bup', ...
		'OnString',  'first bup stereo', ...
		'TooltipString', 'If on, an extra stereo bup is added in front of the first bup');
	ToggleParam(obj, 'avoid_collisions', 0, x, y, 'position', [x+100 y 100 20], ...
		'OffString', 'allow collisions', ...
		'OnString',  'prevent collisions', ...
		'TooltipString', 'If not allowed, a refractory period is imposed equal to a single bup width. Otherwise, click waveforms sum and can therefore interfere.');    

    NumeditParam(obj, 'min_ISI', 0, x, y, 'position', [x+300 y 100 20],'labelfraction',0.68, ...
        'TooltipString', 'the minimum time in ms that is allowed between bups','label','min ISI, ms');    
	NumeditParam(obj, 'total_rate', 40, x, y, 'position', [x+400 y 100 20],'labelfraction',0.68, ...
        'TooltipString', 'the sum of left and right bup rates in Hz','label','total rate, Hz');    

    set_callback({tone_style, ntones, base_freq}, {mfilename, 'update_tones'});
    next_row(y);

    SubheaderParam(obj, 'title4', 'Stimulus Properties Section', x, y);
	next_row(y, 1.3);

    DispParam(obj, 'ThisGamma', 0, x, y, 'position', [x y 150 20], ...
        'labelfraction', 0.6, ...
        'TooltipString', 'the gamma of the present trial; if r_R and r_L are the rates of Poisson events on the right and left, then gamma = log(r_R/r_L)');
    DispParam(obj, 'ThisLeftRate', 10, x, y, 'position', [x+150 y 150 20], ...
        'labelfraction', 0.6, ...
        'TooltipString', 'the average rate of Poisson events on the left for this trial');
    DispParam(obj, 'ThisRightRate', 10, x, y, 'position', [x+300 y 150 20], ...
        'labelfraction', 0.6, ...
        'TooltipString', 'the average rate of Poisson events on the right for this trial');
    DispParam(obj, 'is_frozen', 10, x, y, 'position', [x+450 y 100 20], ...
        'labelfraction', 0.8, ...
        'TooltipString', 'whether this trial uses frozen noise');
	next_row(y, 1);

	HeaderParam(obj, 'panel_title', 'PBups plugin, v.2', x, y, 'position', [x y 1200 20]);
	
    % this soloparamhandle stores the actual bup times (in seconds) on the left and right
    % for the present trial, as well as the side response of an ideal
    % observer that counts the number of bups on either side.
    % ThisBupTimes.observer is -1 for left, 1 for right, and 0 if the
    % numbers of bups on either side are equal.
    % ThisBupTimes.left and ThisBupTimes.right are updated as the next
    % sound is prepared and pushed to history to be saved with the data
    SoloParamHandle(obj, 'ThisBupTimes', 'value', {});
    
	% stores the set of gamma values used to make pbups from
	% trial to trial.  
	% these values may be specified either by range or by enumeration
	SoloParamHandle(obj, 'left_gammas', 'value', -2);
	SoloParamHandle(obj, 'right_gammas', 'value', 2);
    
	feval(mfilename, obj, 'gamma_style');
    feval(mfilename, obj, 'show_hide');   
    feval(mfilename, obj, 'check_headphones');
    feval(mfilename, obj, 'update_tones');
    
    figure(fig);
    x = origfig_xy(1); y = origfig_xy(2);

%% adjust_volume
  case 'adjust_volume'
    snd = varargin{1};
    if is_enabled(headphone_attentuation_dB)
        att = value(headphone_attentuation_dB);
        snd(1,:) = snd(1,:)/max(snd(1,:)) * 10^-(att(1)/20);
        snd(2,:) = snd(2,:)/max(snd(2,:)) * 10^-(att(2)/20);
    else
        if numel(value(vol)) == 1
            snd = snd*vol(1);
        else
            snd(1,:) = snd(1,:) * vol(1);
            snd(2,:) = snd(2,:) * vol(2);
        end
        % the volume and left and right speakers are not always matched
        RtoL_speaker_volume_ratio = bSettings('get', 'GENERAL', 'RtoL_speaker_volume_ratio');
        if ~isnan(RtoL_speaker_volume_ratio)
            snd(2,:) = snd(2,:) / RtoL_speaker_volume_ratio;
        end
    end
    x = snd;

%% check_headphones
  case 'check_headphones'
      hp_max_V = bSettings('get', 'GENERAL', 'HEADPHONE_MAX_V');
      if isnan(hp_max_V)
          disable(headphone_attentuation_dB)
          enable(vol)
      else
          enable(headphone_attentuation_dB)
          disable(vol)
      end
      
      % ** Make sure that there are always two values **
      s = value(headphone_attentuation_dB);
      if numel(s) < 2
          s(1,2) = s(1);
      elseif numel(s) > 2;
          s = s(1:2);
      end
      s = s(:)';
      headphone_attentuation_dB.value = s;
      
      % **Ensure minimum attentuation**
      if ~isnan(hp_max_V)
          % The Lynx L22 sound card generates a maximumal signal level of +20
          % dBU, which is equivalent to a  maximum voltage level of:  
          L22_max_V = sqrt(2) * sqrt(0.6) *10^(20/20);
          min_atten = 20*log10(L22_max_V/hp_max_V);
          s = value(headphone_attentuation_dB);
          s(s < min_atten) = min_atten;
          headphone_attentuation_dB.value = s;
          % https://brodylabwiki.princeton.edu/wiki/images/7/7e/Lynx_L22_ma
          % nual.pdf
      end

%% get
  case 'get'
     switch varargin{1},
         case 'nstimuli',
             x = length(left_gammas)+length(right_gammas); %#ok<NODEF>
         case 'nleft',
             x = length(left_gammas); %#ok<NODEF>
         case 'nright',
             x = length(right_gammas); %#ok<NODEF>
		 case 'all_sides',
			 x = [char('l'*ones(1,length(left_gammas))) char('r'*ones(1,length(right_gammas)))]; %#ok<NODEF>
		 case 'sample_duration', 
			 x = value(T);
		 case 'pprobs',
			 x = [value(L_pprobs) value(R_pprobs)];
     end;

%% get_all_bup_times
  case 'get_all_bup_times'
    x = get_history(ThisBupTimes); %#ok<NODEF>
    return;

%% get_all_seeds
case 'get_all_seeds'
    x = get_history(ThisSeed);
    return;

%% get_bup_times  
  case 'get_bup_times',
    x = value(ThisBupTimes); %#ok<NODEF>
    return;

%% make_sounds
  case 'make_this_sound'
	srate = SoundManagerSection(obj, 'get_sample_rate');
	% the sound made is at least 1 sec long, or as long as T
    [snd,lrate,rrate,bpt] = make_pbup_predictive(value(total_rate), value(ThisGamma), srate, value(T), ...
                                        'bup_width', value(bup_width), 'first_bup_stereo', value(first_bup_stereo), ...
                                        'base_freq', value(base_freq), ...
                                        'tones', value(tones), 'bup_ramp', value(bup_ramp),'ntones', value(ntones),...
                                        'avoid_collisions',value(avoid_collisions),'min_ISI',value(min_ISI),...
                                        'seed',value(ThisSeed)); %#ok<NODEF>;        

    snd = PBupsSection(obj, 'adjust_volume', snd);
    bpt.is_probe_trial=0;
        
	if ~SoundManagerSection(obj, 'sound_exists', 'PBupsSound')
		SoundManagerSection(obj, 'declare_new_sound', 'PBupsSound');
		SoundManagerSection(obj, 'set_sound', 'PBupsSound', snd);
	else
		snd_prev = SoundManagerSection(obj, 'get_sound', 'PBupsSound');
		if ~isequal(snd, snd_prev)
			SoundManagerSection(obj, 'set_sound', 'PBupsSound', snd);
        end
    end

	ThisLeftRate.value = lrate;
	ThisRightRate.value = rrate;
    bpt.gamma=value(ThisGamma);
    bpt.is_frozen = value(is_frozen);
    bpt.user_defined_bup=~isempty(value(Bups));
    bpt.tones = value(tones);
    if is_enabled(headphone_attentuation_dB);
        bpt.headphone_attentuation_dB = value(headphone_attentuation_dB);
    end
	ThisBupTimes.value = bpt;

%% next_trial
  case 'next_trial'  
      % takes an additional argument that specifies the next side choice
	  % and vectors previous_sides and previous_sounds
      % returns the id of the next sound picked
	  % and the sample duration 
	  
      side = varargin{1};

      if isempty(side), % if we are not given which side the next trial is,
          if rand(1) < sum(value(L_pprobs(:))), side = 'l';
          else                             side = 'r';
          end;
      end;

      if value(n_seeds)>1000
          warning('Maximum allowed value of n_seeds is 1000!!!');
          n_seeds.value = 1000;
      end

    % if frozen, set a random seed within a small predetermined range                
    is_frozen.value = rand<value(frozen_frac);

	  LocalPrevSides.value  = varargin{2};

	  feval(mfilename, obj, 'normalize_pprobs');
	  feval(mfilename, obj, 'update_hitfrac');
    
	  if side == 'l',
          if length(L_pprobs)~=length(left_gammas)
              error('Vector of stimulus probabilities is not the same length as the vector of gammas. This can happen if you added free-choice code without adding free-choice gammas (i.e. +/-99)');
          end
		  x = find(cumsum(L_pprobs(:)) > rand(1)/2, 1, 'first');
		  if isempty(x), x = 1; end; % a catch so things don't break
		  ThisGamma.value = left_gammas(x);
		  x = -x;
	  elseif side == 'r',
          if length(R_pprobs)~=length(right_gammas)
              error('Vector of stimulus probabilities is not the same length as the vector of gammas. This can happen if you added free-choice code without adding free-choice gammas (i.e. +/-99)');
          end          
		  x = find(cumsum(R_pprobs(:)) > rand(1)/2, 1, 'first');
		  if isempty(x), x = 1; end; % a catch so things don't break
		  ThisGamma.value = right_gammas(x);
	  end;

      %no frozen seed for side LED trials, which are identified by
      if abs(abs(value(ThisGamma))-99) < eps
          is_frozen.value = false;
      end
      %Needed to move this code below when gamma is generated for this trial
      if value(is_frozen)
          if value(frozen_trial_rule) == 0
            ThisSeed.value = round(value(total_rate)*10)*10^7 + round(value(ThisGamma)*10^2)*10^4 + (side=='r')*10^3 + floor(rand(1)*value(n_seeds)); % this more or less ensures frozen seeds are unique for each possible combination of gamma, side, and total_rate
          else
            %Put code here to ensure uniform sampling;
            feval(mfilename, obj, 'compute_uniform_seed'); 
          end
      else
          c = clock;
          ThisSeed.value = randi(10^9,1) + round(c(6)*1e3);
      end

      %T_resample depends on the seed to it got moved down here
      feval(mfilename, obj, 'T_resample');
      feval(mfilename, obj, 'make_this_sound');
	  feval(mfilename, obj, 'push_history');
      y = value(T);

%% compute uniform seed
case('compute_uniform_seed')
    if value(ThisGamma) > 0
        side = 'r';
    else
        side = 'l';
    end
    
    all_gammas = [value(L_gammas),value(R_gammas)];

    all_seeds = [];
    seed_gammas = [];

    a = round(value(total_rate)*10)*10^7;
    b = round(all_gammas.*10^2).*10^4;
    c = [0,1].*10^3; %neg gamma left trial
    d = 0:value(n_seeds)-1;

    for i = 1:numel(a)
        for j = 1:numel(b)
            for k = 1:numel(c)
                for m = 1:numel(d)
                    if (b(j) > 0 && c(k) == 1000) || (b(j) < 0 && c(k) == 0)
                        all_seeds(end+1) = a(i) + b(j) + c(k) + d(m);
                        seed_gammas(end+1) = all_gammas(j);
                    end
                end
            end
        end
    end

    seed_history = cell2mat(get_history(ThisSeed));

    seed_n = zeros(numel(all_seeds),1);
    for i = 1:numel(all_seeds)
        seed_n(i) = sum(seed_history == all_seeds(i) & violation_history == 0);
    end

    minn = min(seed_n);
    maxn = max(seed_n);

    x = minn:maxn;
    prob = 2.^(((maxn:-1:minn) - minn) + 1);
    p = zeros(size(seed_n));
    for j = 1:numel(x)
        p(seed_n == x(j)) = prob(j);
    end
    
    if side == 'l'
        p((numel(p)/2)+1:end) = 0;
    else
        p(1:(numel(p)/2)) = 0;
    end
    
    if ~isempty(seed_history)
        z = find(all_seeds == seed_history(end));
        if ~isempty(z)
            p(z) = 0;
        end
    end
    true_prob = p./sum(p);

    threshold = [];
    for j = 1:numel(true_prob) 
        threshold(j) = sum(true_prob(1:j));
    end

    seed_pos = find(threshold > rand(1),1,'first');
    ThisSeed.value = all_seeds(seed_pos);
    ThisGamma.value = seed_gammas(seed_pos);
    
%% push_history
  case 'push_history'
	  push_history(ThisBupTimes);
      push_history(is_frozen);
      push_history(ThisSeed);  

%% update_hitfrac
  case 'update_hitfrac',
	PrevSides = colvec(value(LocalPrevSides));

	if ~isempty(hit_history),
		kernel = exp(-(0:length(hit_history)-1)/HitFracTau)';
        kernel = kernel(end:-1:1);
		HitFrac.value = sum(hit_history .* kernel)/sum(kernel);
		
		if ~isempty(PrevSides),
			PrevSides = PrevSides(1:length(hit_history));
		end;
		
		u = find(PrevSides == 'l');
		if isempty(u), LtHitFrac.value = NaN;
		else           LtHitFrac.value = sum(hit_history(u) .* kernel(u))/sum(kernel(u));
		end;
		
		u = find(PrevSides == 'r');
		if isempty(u), RtHitFrac.value = NaN;
		else           RtHitFrac.value = sum(hit_history(u) .* kernel(u))/sum(kernel(u));
		end;
	else
		HitFrac.value   = NaN;
		LtHitFrac.value = NaN;
		RtHitFrac.value = NaN;
	end;
	  
%% update_tones
  case 'update_tones'     
      s = value(base_freq);
      s(s < 0) = 0;
      base_freq.value = s;
      
      s = value(ntones);
      s(s < 0) = 0;
      ntones.value = s;
      
      if tone_style
          enable(tones)
      else
          disable(tones)
      end

      base_freq.value = base_freq(1);
      
      if ~value(tone_style)
          tones.value = value(base_freq) * 2.^(0:value(ntones)-1);
      end

%% test_gamma
  case 'test_gamma'
	srate = SoundManagerSection(obj, 'get_sample_rate');
    [snd,lrate,rrate] = make_pbup_predictive(value(total_rate), value(test_gamma), srate, value(sduration), ...
                     'bup_width', value(bup_width), 'first_bup_stereo', value(first_bup_stereo), ...
                     'base_freq', value(base_freq), ...
                     'ntones', value(ntones), 'bup_ramp', value(bup_ramp), 'generate_sound', 0,...
                     'avoid_collisions',value(avoid_collisions),'min_ISI',value(min_ISI)); 
		
	test_lrate.value = lrate;
	test_rrate.value = rrate;
	
%% test_play
  case 'test_play',
    srate = SoundManagerSection(obj, 'get_sample_rate');

    [snd] = make_pbup_predictive(value(total_rate), value(test_gamma), srate, value(sduration), ...
                        'bup_width', value(bup_width), 'first_bup_stereo', value(first_bup_stereo), ...
                        'tones', value(tones), 'bup_ramp', value(bup_ramp),'ntones', value(ntones),...
                        'avoid_collisions',value(avoid_collisions),'min_ISI',value(min_ISI)); 

    snd = feval(mfilename, obj, 'adjust_volume', snd);             
    
    if ~SoundManagerSection(obj, 'sound_exists', 'TestSound')
      SoundManagerSection(obj, 'declare_new_sound', 'TestSound');
    end

    SoundManagerSection(obj, 'set_sound', 'TestSound', snd);
    SoundManagerSection(obj, 'play_sound', 'TestSound');

%% stop_sound      
  case 'test_stop'
    SoundManagerSection(obj, 'stop_sound', 'TestSound');

%% test_left_speaker
    case 'test_left_speaker'
        if test_left_speaker
            srate = SoundManagerSection(obj, 'get_sample_rate');
            t = 0:(1/srate):1-1/srate;
            din = zeros(size(t));
            for i = 1:numel(value(tones))
                din = din + sin(2*pi*tones(i)*t);
            end
            
            % scale din by the peak of a single bup
            bup = singlebup(srate, 0, ...
                            'tones', value(tones), ...
                            'width', value(bup_width), ...
                            'basefreq', value(base_freq), ...
                            'ramp', value(bup_ramp));
            if is_enabled(headphone_attentuation_dB)
                att = value(headphone_attentuation_dB);
                bup_max = 10^-(att(1)/20);
            else
                bup_max = max(bup)*vol(1);
            end
            din = din/max(din)*bup_max;
            din = [din; zeros(1,numel(din))];
            
            if ~SoundManagerSection(obj, 'sound_exists', 'left_din')
                SoundManagerSection(obj, 'declare_new_sound', 'left_din');
            end
            SoundManagerSection(obj, 'set_sound', 'left_din', din);
            SoundManagerSection(obj, 'loop_sound','left_din', 1);
            SoundManagerSection(obj, 'play_sound', 'left_din');
        else
            if SoundManagerSection(obj, 'sound_exists', 'left_din')
                SoundManagerSection(obj, 'stop_sound', 'left_din');
            end
        end 

%% test_right_speaker
    case 'test_right_speaker'
        if test_right_speaker
            srate = SoundManagerSection(obj, 'get_sample_rate');
            t = 0:(1/srate):1;
            din = zeros(size(t));
            for i = 1:numel(value(tones))
                din = din + sin(2*pi*tones(i)*t);
            end
            
            % scale din by the max of a single bup
            bup = singlebup(srate, 0, ...
                            'tones', value(tones), ...
                            'width', value(bup_width), ...
                            'basefreq', value(base_freq), ...
                            'ramp', value(bup_ramp));
            if is_enabled(headphone_attentuation_dB)
                att = value(headphone_attentuation_dB);
                bup_max = 10^-(att(2)/20);
            else
                bup_max = max(bup) * vol(numel(value(vol))); % VOL could be either a scalar or a 1x2 numeric
                RtoL_speaker_volume_ratio = bSettings('get', 'GENERAL', 'RtoL_speaker_volume_ratio');
                if ~isnan(RtoL_speaker_volume_ratio)
                    bup_max = bup_max/sqrt(RtoL_speaker_volume_ratio);
                end
            end
            din = din/max(din)*bup_max;
            din = [zeros(1,numel(din)); din];
            
            if ~SoundManagerSection(obj, 'sound_exists', 'right_din')
                SoundManagerSection(obj, 'declare_new_sound', 'right_din');
            end
            SoundManagerSection(obj, 'set_sound', 'right_din', din);
            SoundManagerSection(obj, 'loop_sound','right_din', 1);
            SoundManagerSection(obj, 'play_sound', 'right_din');
        else
            if SoundManagerSection(obj, 'sound_exists', 'right_din')
                SoundManagerSection(obj, 'stop_sound', 'right_din');
            end
        end 

%% T_resample
  case 'T_resample'
	if T_max < T_min, T_max.value = T_min(1); end
	
    if isempty(value(Bups))
        % set T using the seed, so that frozen noise trials have the same
        % bup sequence AND stimulus duration
        try
            RandStream.setDefaultStream(RandStream('mt19937ar','Seed',value(ThisSeed))); % old matlab            
        catch
            rng(value(ThisSeed),'twister'); % new matlab
        end            
        T.value = value(T_min)+rand(1)*(T_max-T_min);
    else
        b=value(Bups);
        T.value = b.T;
    end

%% normalize_pprobs
  case 'normalize_pprobs'
	nlefts = length(L_pprobs(:));
	p = [L_pprobs(:); R_pprobs(:)];
	p = p/sum(p);
	L_pprobs.value = p(1:nlefts);
	R_pprobs.value = p(nlefts+1:end);

%% gammas
  case 'gammas'
    L_gammas.value = -abs(value(L_gammas)); %#ok<NODEF>
    R_gammas.value = abs(value(R_gammas)); %#ok<NODEF>
	easiest.value = abs(value(easiest)); %#ok<NODEF>
	hardest.value = abs(value(hardest)); %#ok<NODEF>
	if N < 1, N.value = 1; end; %#ok<NODEF>
	feval(mfilename, obj, 'gamma_style');
	
%% gamma_style
  case 'gamma_style'
	if gamma_style == 0, % if we're going by the range
		enable(easiest);
		enable(hardest);
		enable(N);
		disable(L_gammas);
		disable(R_gammas);
		if N == 1,
			g = easiest(1);
		else
			g = linspace(easiest(1), hardest(1), N(1));
		end;
		left_gammas.value  = -g;  % internal soloparam
		right_gammas.value = g;   % internal soloparam
		L_gammas.value = value(left_gammas);  % for display 
		R_gammas.value = value(right_gammas); % for display
		if length(L_pprobs) ~= length(L_gammas),	L_pprobs.value = ones(1, N(1)); end;
		if length(R_pprobs) ~= length(R_gammas),    R_pprobs.value = ones(1, N(1)); end;
		feval(mfilename, obj, 'normalize_pprobs');
	else                 % if we're going by L_gammas and R_gammas
		disable(easiest);
		disable(hardest);
		disable(N);
		enable(L_gammas);
		enable(R_gammas);
		left_gammas.value  = L_gammas(:);
		right_gammas.value = R_gammas(:);
		if length(L_pprobs) ~= length(L_gammas),	L_pprobs.value = ones(1, length(L_gammas)); end;
		if length(R_pprobs) ~= length(R_gammas),    R_pprobs.value = ones(1, length(R_gammas)); end;
		feval(mfilename, obj, 'normalize_pprobs');
	end; 
      
%% hide, show_hide
  case 'hide',
    pbup_show.value = 0;
    feval(mfilename, obj, 'show_hide');
    
  case 'show_hide',
    if value(pbup_show) == 1, set(value(pbup_fig), 'Visible', 'on');  %#ok<NODEF>
    else                      set(value(pbup_fig), 'Visible', 'off');
    end;
    
%% close
  case 'close'   
    try %#ok<TRYNC>
        if ishandle(value(pbup_fig)), delete(value(pbup_fig)); end;
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