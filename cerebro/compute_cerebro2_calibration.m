function [diode1,diode2] = compute_cerebro2_calibration(pwr_set,pulsedur,varargin)

if nargin < 1; pwr_set  = 1000:300:2200; end
if nargin < 2; pulsedur = 2; end

pulsepoints = pulsedur * 68;

[fname,pname] = uigetfile('*.csv');
file = [pname,fname];
f = fopen(file);
x = fread(f);
fclose(f);

nl = find(x == 10);
L = nl(7:end)+1;

x = char(x');

P = [];
for i = 1:numel(L)
    try
        P(i) = str2num(x(L(i)+24:L(i)+30));
    catch
        P(i) = nan;
    end
end
on = find(isnan(P)) + 1;
off = on + pulsepoints;

pwr = [];
try
    for i = 1:numel(on)
        pwr(i) = mean(P(on(i):off(i)));
    end
end


diode1  = polyfit(pwr(1:2:end-1),pwr_set,1);
diode2 = polyfit(pwr(2:2:end),pwr_set,1);

disp(['DIODE 1: ',num2str(diode1(1)),' ',num2str(diode1(2))]);
disp(['DIODE 2: ',num2str(diode2(1)),' ',num2str(diode2(2))]);

figure('color','w'); hold on;
plot(pwr(1:2:end-1),pwr_set,'ok')
plot([0,30],[diode1(2),(30*diode1(1)) + diode1(2)],'-r')
set(gca,'fontsize',18);
xlabel('Power, mW');
ylabel('Cerebro Power Setting');
title('DIODE 1')

figure('color','w'); hold on;
plot(pwr(2:2:end),pwr_set,'ok')
plot([0,30],[diode2(2),(30*diode2(1)) + diode2(2)],'-r')
set(gca,'fontsize',18);
xlabel('Power, mW');
ylabel('Cerebro Power Setting');
title('DIODE 2')

d = P(2:end) - P(1:end-1);
on = find(d > 0.5);
for i = 1:numel(on)
    p(i) = mean(P(on(i)+1:on(i)+44));
end
