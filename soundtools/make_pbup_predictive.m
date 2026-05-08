function [snd,lrate,rrate,data] = make_pbup_predictive(total_rate, gamma, srate, T, varargin)
%
% Makes Poisson bups
% bup events from the left and right speakers are independent Poisson
% events
%
% (N.B. from AGB 2017: Although technically since we're dealing with discrete time the buptimes are
% realizations of a Bernoulli process, i.e. a series of Bernoulli trials whose success probability 
% is analogous to the Poisson rate paramter.)
%
% TZL, Dec 2018: a vector of tones can be specified
%
% EYX, Feb 2026: remove distractor, frequency task, fixed_sound, crosstalk, and force_count
%
% =======
% inputs:
%
%	total_rate		total rate (in clicks/sec) of bups from both left and right
%	      speakers (r_L + r_R). Note that if distractor_rate > 0, then total_rate
%	      includes these stereo distractor bups as well.
%
%	gamma		the natural log ratio of right and left rates: log(r_R/r_L)
%
%	srate	sample rate
%
%	T		total time (in sec) of Poisson bup trains to be generated
%
% =========
% varargin:
%
% bup_width
%			width of a bup in msec  (Default 3)
% base_freq       
%           base frequency of an individual bup, in Hz. The individual bup
%           consists of this in combination with ntones-1 octaves above the
%           base frequency. (Default 2000)
% 
% ntones
%           number of tones comprising each individual bup. The bup is the
%           basefreq combined with ntones-1 higher octaves. (Default 5)
% 
% bup_ramp        
%           the duration in msec of the upwards and downwards volume ramps
%           for individual bups. The bup volume ramps up following a cos^2
%           function over this duration and it ramps down in an inverse
%           fashion.
% 
% first_bup_stereo
%			if 1, then the first bup to occur is forced to be stereo
%
% generate_sound
%			if 1, then generate the snd vector
%			if 0, the snd vector will be empty; data will still contain the
%			bups times
%
% min_ISI
%           imposes a minimum ISI (in ms) between bup times. This is implemented by
%           increasing the interval between the Bernoulli trials.
%           AGB 2017.
%
% avoid_collisions
%           imposes a minimum ISI just big enough so that bups can't interfere.
%           Chuck 2010-10-05. Significantly rewritten by AGB 2017.
%
% seed
%           user defined noise seed (output will be deterministic if you
%           supply this)
%
% tones
%           Vector of tones in a click. Not used if task_type == 0
%
% ========
% outputs:
%
% snd		a vector representing the sound generated
%
% lrate		rate of Poisson events generated only on the left
%
% rrate		rate of Poisson events generated only on the right
%
% data		a struct containing the following fields:

% 'left' and 'right' : the actual bup times (in sec, centered in middle of every bup) 
% 'snd' : the sound itself, with bups placed at the times in 'left' and
%           'right'. The length of sound is the number of discrete time samples that most
%           closely approximates the stimulus duration specified in T.
% 'firstLastPossibleTime' : a 2-element vector giving the time, in seconds,
%           when the first and last bup could have occurred, giving the limitations
%           imposed by the bup width (bups can't be so close to the edge they can't
%           play in their entirety) and the sampling frequency. This allows you to
%           avoid the (slightly) incorrect assumption that the bup times
%           could have occurred uniformly on [0,T].
% 'min_ISI' : the min_ISI in ms set by the user (0 by default)
% 'real_min_ISI' : the actual min ISI used (an integer multiple of the
%           sampling period), in sec
% 'n_bup_can_fit' : the length of the Bernoulli process, i.e. the number of
%           discrete bins in which bups can occur.
% 'real_T' : the difference between the times in 'firstLastPossibleTime'
% 'bup_width' : the bup_width set by the user in ms
% 'base_freq' : the base frequency of the bups set by the user in Hz
% 'bup_ramp'  : the length of the one-sided envelope applied to each side
%           of the bup
% 'first_bup_stereo' : whether or not user set the first bup to be a stereo
%           bup, false by default. Note the bug in the implementation of
%           this, that has been maintained for consistency with old code.

% N.B.:
% significantly modified by Adrian Bondy (2017) to fix bugs, add features,
% and improve documentation. Significant changes are:
%   1) correct reporting of removal of bups that are too near the beginning
%   or end of the stimulus to play
%   2) correctly defining this exclusion period (was too conservative by
%   one sample before)
%   3) properly implementing the avoid_collisions option
%   4) output includes more information, including the real stimulus
%   duration (an integer multiple of the sampling period) in field
%   'firstLastPossibleTime'
%   5) documentation of bug when first_bup_stereo is true. This bug is
%   preserved for consistency with old code behavior.
%   6) added flag 'min_ISI' which lets the user set the minimum inter-bup
%   interval allowed (on each side separately). This is an extension of
%   "avoid_collisions" which requires a minimum ISI of one bup width
%   exactly. To understand how both of these are implemented, it is worth
%   noting that the buptimes are not, as we usually say, Poisson processes,
%   but rather Bernoulli processes (the discrete analog). A Bernoulli
%   process consists of a series of coin flips with probability p. Without
%   a minimum ISI, the buptimes are a realization of such a process with a
%   coin flip performed at each time sample (the rigs sample at 200kHz).
%   With a minimum ISI imposed, a coin flip is performed at time steps
%   separated by the minimum ISI (or to be more precise, the nearest
%   multiple of the sampling period).

    %% parse and validate args
    pairs = {...
        'bup_width',        3; ...
        'base_freq',        2000; ...
        'ntones',           5; ...
        'bup_ramp',         2; ...
        'first_bup_stereo'  0; ...
        'generate_sound'    1; ...
        'avoid_collisions'  0; ...
        'min_ISI',          0; ...
        'seed',            []; ... % generates a random noise seed up to 10^6 using the current time as a default
        'tones',            []; ...
        }; parseargs(varargin, pairs);

    if isnan(gamma)
        error('Gamma cannot be NaN.');
    end
    if isnan(total_rate)
        error('total rate cannot be NaN.');
    end

    %% make a single bup so I know exactly how many samples it takes up
    tones = unique(tones);
    if ~isempty(tones)
        bup = singlebup(srate, 0,'tones', tones, 'width', bup_width, 'basefreq', base_freq(1), 'ramp', bup_ramp);
    else
        bup = singlebup(srate, 0,'ntones', ntones, 'width', bup_width, 'basefreq', base_freq(1), 'ramp', bup_ramp);
    end

    %% figure out some statistics
    n_bup_samples = length(bup);
    real_bup_width = n_bup_samples/srate;    
    w=floor(n_bup_samples/2);  
    real_min_ISI=round(min_ISI*srate/1000)./srate;
    if avoid_collisions == 1
        real_min_ISI = max(real_bup_width,real_min_ISI);
    elseif real_min_ISI<1./srate 
        real_min_ISI = 1./srate;
    end        
    
    real_T = round(T*srate)./srate; % time in seconds of the entire sound
    
    if real_min_ISI<real_bup_width
        n_bup_can_fit = floor((real_T-(real_bup_width-real_min_ISI))./real_min_ISI); % bups extend beyond their bins, we need to allocate extra room at the ends
    else
        n_bup_can_fit = floor(real_T./real_min_ISI); % the case where we don't have to worry about bups extending beyond their bins    
    end
    
    % make left and right rates    
    lrate = total_rate ./ ( exp(gamma) + 1 ); % doing the calculation for the left rate first avoids numerical underflow for high values of gamma (i.e. so that lrate doesn't end up being exactly 0) - AGB 2017
    rrate = total_rate - lrate;    
        
    %% make bup times
    % set seed
    if ~isempty(seed)
        try
            RandStream.setDefaultStream(RandStream('mt19937ar','Seed',seed))            
        catch
            rng(seed,'twister');
        end
    end
    %
    
    if lrate*real_min_ISI>1
        error('Left rate of %g Hz cannot be realized with a minimum ISI of %1g ms.',lrate,real_min_ISI*1000);
    end
    if rrate*real_min_ISI>1
        error('Right rate of %g Hz cannot be realized with a minimum ISI of %1g ms.',rrate,real_min_ISI*1000);
    end        
    
    % note that this way of "avoiding collisions" involves only allowing a discrete set of times, one bupwidth apart, when a click can occur.
    % You could take other approaches, like sampling from a modified
    % Poisson process with a refractory period
    tp1 = find(rand(1,n_bup_can_fit) < lrate*real_min_ISI);
    tp2 = find(rand(1,n_bup_can_fit) < rrate*real_min_ISI);                 
    
    %% first bup stereo %%
    % 
    % in order not to alter the difference in bup numbers between left and
    % right, the extra stereo bup is placed randomly somewhere between 0 and
    % the earliest bup on either side. 
    % AGB 2017: ***the above, original logic is not true, see note below **    
    if first_bup_stereo
        first_bup = min([tp1 tp2]);
        %% AGB
        % this next line is a bug, bup_width is interpreted as being in seconds, 
        % but it is actually in ms!
        % As a result of the above bug, the first way of making a
        % stereo bup is essentially always chosen, independent of the
        % timing of the bups. "Fixing" this now would result in a significant
        % change from legacy behavior so I have left it as is. Always
        % using the first way of making a bup is....fine, I think. (?)
        bupwidth = bup_width*srate/2;  % should  : bupwidth = bup_width*srate./1000./2
        %%
        if first_bup <= bupwidth % first way of making a stereo bup
            extra_bup = first_bup;
        else % second way of making a stereo bup
            extra_bup = ceil(rand(1)*(first_bup-bupwidth) + bupwidth); 
        end
        tp1 = union(extra_bup, tp1);
        tp2 = union(extra_bup, tp2);
    end

    %%
    % before this line, tp1 and tp2 are the inds of the possible
    % intervals. after this its inds in terms of sound samples
    tp1 = tp1 * round(srate*real_min_ISI); % round is only here to prevent weird floating point errors. srate*real_min_ISI should always be an integer to within machine precision.
    tp2 = tp2 * round(srate*real_min_ISI); 
    

    % now shift times to the center of the sound
    times_range = (n_bup_can_fit-1)*real_min_ISI;
    offset = floor(srate*((real_T-times_range)/2)-10^-10); % the -10^10 is there because I want the following behavior: floor(X) if X is not an integer, and X-1 otherwise
    tp1 = tp1 + offset - (real_min_ISI )*srate+1;
    tp2 = tp2 + offset - (real_min_ISI )*srate+1;  
    firstLastPossibleTime = [1 n_bup_can_fit]*real_min_ISI + offset/srate - real_min_ISI +1./srate;
    
    if firstLastPossibleTime(1)*srate<w
            error('Something has gone wrong. If we''ve correctly determined n_bup_can_fit and offset the times correctly, we shouldn''t hit this line ever.');
    end
        
    %% generate sound waveform
    if generate_sound
        snd = zeros(2, round(real_T*srate) );
        for i = 1:length(tp1) % place left bups
            if tp1(i)>w && tp1(i)+w<=size(snd,2)
                snd(1,tp1(i)-w:tp1(i)+w) = snd(1,tp1(i)-w:tp1(i)+w)+bup;
            end
        end
        for i = 1:length(tp2) % place right bups
            if tp2(i)>w && tp2(i)+w<=size(snd,2)            
                snd(2,tp2(i)-w:tp2(i)+w) = snd(2,tp2(i)-w:tp2(i)+w)+bup;
            end
        end
    else
        snd = [];
    end

    if ~isempty(seed)
        % shuffle seed up to max allowed, using the current time. This is
        % required to make things non-deterministic after fixing the seed.
        seed0 = mod(floor(now*8640000),2^32-1); 
        for i = 1:100
            clockSeed = mod(floor(now*8640000),2^32-1);
            if clockSeed ~= seed0, break; end
            pause(.01); % smallest recommended interval
        end
        try
            RandStream.setDefaultStream(RandStream('mt19937ar','Seed',clockSeed)); % old matlab            
        catch
            rng('shuffle','twister'); % new matlab
        end    
    end
    

    data = struct('left',tp1/srate,'right',tp2/srate,'firstLastPossibleTime',firstLastPossibleTime,'n_bup_samples',n_bup_samples,...
        'real_bup_width',real_bup_width,'min_ISI',min_ISI,'real_min_ISI',real_min_ISI,'n_bup_can_fit',n_bup_can_fit,'real_T',real_T,...
        'bup_width',bup_width,'base_freq',base_freq,'bup_ramp',bup_ramp,'first_bup_stereo',first_bup_stereo,...
        'generate_sound',generate_sound,'avoid_collisions',avoid_collisions,'seed',seed);

end

