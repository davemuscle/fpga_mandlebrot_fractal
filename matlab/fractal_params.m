%for the worker method
targettime = 16/1000;
totalpixels = 1920*540;
totalcalcs = 50;

%start iterations from 1 to 1000 and see what clockrate we need
iter = 1:1000;

clkrate = totalpixels.*iter./(totalcalcs*targettime);

highestclk = 550*10^6;
idx = 1;
for i = 1:length(clkrate)

    if(clkrate(i) > highestclk)
        break;
    else
        idx = idx + 1;
    end
end


plot(iter(1:idx), clkrate(1:idx))