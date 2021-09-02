clear all;
close all;
clc
n=1000;
fclk=4.8e6; %freq.of the clock
ts=1/fclk; %sample time at freq clock
t=[0:ts:(n*ts)-ts]; % vector of time
f_sin=80e3; %freq. of the signal
x= 0.5 + 0.4*sin(2*pi*f_sin*t); %signal input
[y,error]=pdm(x); %pdm modulation using pdm function
%%L1 RRS stage T.F at ts
z = tf('z',ts);
L=32; %large of the window/length of the filter
h_l1= ((1-(z^-L))/(1-(z^-1)));
p = bodeoptions
p = bodeoptions('cstprefs')
p.FreqUnits = 'kHz';
p.FreqScale = 'log';
p.PhaseVisible = 'off'
p.Xlim = [10,3000]
p.Ylim = [-100,80]
figure(1)
bodeplot(h_l1,p); %bode plot of the RRS stage (L1 stage of CRRS demodulator)
T = (0:1/fclk:(length(y)/fclk)-(1/fclk)); %vector at fclk freq.
yl1 = lsim(h_l1,y,T); %linear simulation of the T.F. using pdm function 
figure(2)
subplot(211);
plot(t,x);
xlabel('Time[s]'),ylabel('Amplitude');
title('Sine Wave at 80 [kHz]');
subplot(212);
plot(yl1,'-o')
xlabel('samples at ts [s]'),ylabel('Amplitude');
title('Filtered Signal');
figure(3)
subplot(211);
plot(yl1(1:10:length(yl1)),'-o');
xlabel('samples at ts [s]'),ylabel('Amplitude');
title('Decimated Signal');
subplot(212);
plot(5*x);
xlabel('samples at ts [s]'),ylabel('Amplitude');
title('Sine Wave at 80 [kHz]');
ylim([0 10])
%%Demudulation using Delta Sigma Toolbox
OSR = 20; %OSR equal to L length of the filter
H = synthesizeNTF(3,OSR,1); %3rd order noise transfer function 
v = simulateDSM(x,H); %generate a output responde for the sigma delta given a NTF and a signal input
yl2=lsim(h_l1,v,T); %linear simlation using the output of simulateDSM (NTF sigma delta toolbox)
figure(4)
subplot(311)
plot(yl2,'-o');
xlabel('samples at ts [s]'),ylabel('Amplitude');
title('Filtered Signal using simulateDSM');
subplot(312)
plot(yl2(1:10:length(yl2)),'-o');
xlabel('samples at ts [s]'),ylabel('Amplitude');
title('Decimated Signal using simulateDSM');
subplot(313)
plot(5*x);
xlabel('samples at ts [s]'),ylabel('Amplitude');
title('Sine Wave at 80 [kHz]');
ylim([0 10])
figure(5)
[snr_pred,amp] = predictSNR(H,OSR); 
[snr,amp] = simulateSNR(H,OSR);
 plot(amp,snr_pred,'b',amp,snr,'gs');
grid on;
figureMagic([-100 0], 10, 2, ...
[0 100], 10, 1);
xlabel('Input Level, dB');
ylabel('SNR dB');
s=sprintf('peak SNR = %4.1fdB\n',...
max(snr));
text(-65,15,s)
%%the cut frequency is 147 khz 
function [y,error]=pdm(x)
 n = length(x);
 y=0;%zeros(1,999);
 error=0;%zeros(1,1000);
 
 for i=1:1:n
    if x(i)>= error(i)
        y(i)=1;
    else 
        y(i)=0;
    end
    error(i+1)=y(i)-x(i)+error(i);
 end
end

