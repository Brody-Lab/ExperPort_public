vfile = 'X:\RATTER\Video\Adrian\A327\video_@PBups_Adrian_A327_230913a.mp4'
lfile = 'X:\RATTER\Video\Adrian\A327\video_@PBups_Adrian_A327_230913a.mat'

x = sync_video_to_trials4(928793,lfile,'lr','RED')

load(lfile);

t = x.alltimes;
d = t(2:end)-t(1:end-1);
df = round((d - 0.04) / 0.04);

peh = bdata('select peh from parsed_events where sessid=928793')
peh = peh{1};

for i = 1:numel(peh)
    T(i,:) = peh(i).states.sync_flash;
end
eval(x.equation1);

equation2 = 'F2 = round(((T * 1) + -1304.4795528585 + 0.1) * 25);';
eval(equation2)

z = 0;
mf = 0;
z(1:F(1,1)) = 0;
for i = 2:size(T,1)
    s = [];
    offset = -3:50; 
    for j = 1:numel(offset)
        s(end+1) = sum(x.RED_flash(F(i,:)+offset(j)));
    end
    mf(i) = offset(find(s == max(s),1,'first'));
    
    z(F(i-1,1):F(i,1)) = mf(i);
end

figure; hold on
plot(x.RED_flash);
for i = 1:size(T,1)
    plot(F(i,:),[3e6,3e6],'-r','linewidth',3);
    plot(F2(i,:),[3.5e6,3.5e6],'-g','linewidth',3);
end


gaps = find(df > 0);
gap_size = df(gaps);

rf = x.RED_flash;
at = x.alltimes;
for i = 1:numel(gaps)
    rf = [rf(1:gaps(i)),ones(1,gap_size(i))*nan,rf(gaps(i)+1:end)];
    at = [at(1:gaps(i)),ones(1,gap_size(i))*nan,at(gaps(i)+1:end)];
    gaps(i+1:end) = gaps(i+1:end) + gap_size(i);
end
    
    
    
    
    
    