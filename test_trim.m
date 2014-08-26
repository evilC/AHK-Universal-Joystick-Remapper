function [] = test_trim()

% Matlab script to test trim axis merge mode for UJR

clear; close all

range1 = 2^16 - 1;
range2 = 2^16 - 1;

ax1 = 0:128:range1;
% ax2 = (range2/4):100:(3*range2/4);
ax2 = (sin((0:1000)*2*pi/500) + 1)*range2/2;

nval1 = 100 * ax1 / range1;
nval3 = merge1(ax1,ax2(1),range1);
nval4 = merge2(ax1,ax2(1),range1,range2);
nval5 = merge3(ax1,ax2(1),range1,range2); 

figure(1)
plot(nval1,nval1,'--k')
hold on
h3 = plot(nval1,nval3,'-b');
h4 = plot(nval1,nval4,':g');
h5 = plot(nval1,nval5,'-.r');
grid on
xlabel('input [%]')
ylabel('output [%]')
axis([0 100 0 100])

for ii = 1:length(ax2)
    nval3 = merge1(ax1,ax2(ii),range1);
    nval4 = merge2(ax1,ax2(ii),range1,range2);
    nval5 = merge3(ax1,ax2(ii),range1,range2); 
    set(h3,'YData',nval3)
    set(h4,'YData',nval4)
    set(h5,'YData',nval5)
    pause(0.001)
end

end

function [nval] = merge1(ax1,ax2,range1)
    val = (ax1 + ax2(1)) / 2;
    nval = 100 * val / range1;
end

function [nval] = merge2(ax1,ax2,range1,range2)
    
    ax1 = ax1 / range1;
    ax2 = ax2 / range2;
    
    nval = 100 * (2*ax1 + (ax2(1) - 0.5)) / 2;

end

function [nval] = merge3(ax1,ax2,range1,range2)
    
    ax1 = ax1 / range1;
    ax2 = ax2 / range2;
    
    ax2 = ax2 *.5 + .25;
    a = 2 - 4*ax2(1);
    b = 4*ax2(1) - 1;
    
    nval = 100 * (a*ax1.^2 + b*ax1);

end
