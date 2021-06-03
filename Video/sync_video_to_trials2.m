function output = sync_video_to_trials2(sessid,data,varargin)

if nargin == 1; data = []; end

[v_pname,v_fname,pd] = bdata(['select video_path, video_file, protocol_data from sessions where sessid=',num2str(sessid)]);
pd = pd{1};
    
if isempty(data)
    map_bucket_drive;
    vfile = [v_pname{1},filesep,v_fname{1}];

    done = 0;
    cnt  = 0;
    C = [];
    framerate = [];
    while done == 0
        cnt = cnt + 1;
        disp(['Analyzing Frames ',num2str(((cnt-1)*1000)+1),' to ',num2str(cnt*1000),'...']);
        x = mmread(vfile,((cnt-1)*1000)+1:cnt*1000);
        if isempty(x.frames); done = 1; break; end %#ok<NASGU>
        for f = 1:numel(x.frames);
            F = x.frames(f).cdata(:,:,1);
            C(end+1) = sum(F(:)); %#ok<AGROW>
        end
        if isempty(framerate)
            framerate = round(1 / mean((x.times(2:end) - x.times(1:end-1))));
        end
    end
else
    C = data.video_luminance;
    framerate = data.framerate;
end

Cdiff = C(2:end) - C(1:end-1);
Ct = 4 * std(Cdiff);

Cevent = [];
lastevent = -99;
for i = 1:numel(Cdiff)-3;
    if Cdiff(i) > Ct && any(Cdiff(i+1:i+3) < -Ct) && i>lastevent+19; 
        Cevent(end+1) = i+1;  %#ok<AGROW>
        lastevent     = i; 
    end
end

Ctime = Cevent / framerate;

allvalve = [pd.leftwatertime;pd.rightwatertime];
allvalve = sortrows(allvalve);
allvalve(isnan(allvalve)) = [];

disp('Aligning video to data...');
input.all_video = Ctime;
input.all_valve = allvalve;

[bestshift1,scale1,score1] = align_video_valve(input); %#ok<NASGU,ASGLU>

input.all_video = input.all_video * scale1;

[bestshift2,scale2,score2] = align_video_valve(input); %#ok<ASGLU>

output.equation = ['F = round(((T + ',num2str(bestshift2),') ./ ',num2str(scale1),') .* ',num2str(framerate),')'];
output.timeshift = bestshift2;
output.timescale = scale1;
output.framerate = framerate;
output.alignment_error = score2(1);
output.fraction_video_events_aligned = score2(2);
output.fraction_valve_events_aligned = score2(3);
output.video_luminance  = C;
output.video_derivative = Cdiff;
output.video_threshold  = Ct;
output.video_events     = Cevent;
output.valve_time       = allvalve;


disp('Alignment COMPLETE');

