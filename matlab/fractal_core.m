function [output, radius] = fractal_core(input, iter_sum, max, escape, q_f, smooth)

%initialize variables
x = 0;
y = 0;

x2 = 0;
y2 = 0;

r2 = 0;

%quantize the input
real_input = q_f*floor((real(iter_sum)/q_f) + 0.5);
imag_input = q_f*floor((imag(iter_sum)/q_f) + 0.5);

%main loop
for i = 0:max-1
    %comparison (zeroth stage)
    
    if(smooth == 0)
        if(r2 >= escape)
            output = i;
            radius = r2;
            return;
        end
    else
        if(r2 >= escape)
%             sn = i - log10(log10(sqrt(r2)))/log10(2);
%             sn = i - log2(log10(sqrt(r2)));
%             sn = i - log2(0.5*log2(r2)/log2(10));
%             sn = i - log2(0.5*log2(r2)/3.322);
%             sn = i - log2(log2(r2)*3/20);

            smoothed = log2(log2(floor(r2))*3/20);
            smoothed = (2^-4)*floor(smoothed/(2^-4));
            sn = i - smoothed;
            output = sn;

            return;
        end
    end
    
    %quantize the inputs
    x = q_f*floor((x/q_f)+0.5);
    y = q_f*floor((y/q_f)+0.5);
    
    %calculate x^2 and y^2 (first stage)
    y2 = y*y;
    x2 = x*x;
    
    %quantize
    x2 = q_f*floor((x2/q_f)+0.5);
    y2 = q_f*floor((y2/q_f)+0.5);
    
    %calculate sums (second stage)
    y = 2*x*y + imag_input;
    x = x2 - y2 + real_input;

    r2 = x2 + y2;
    
    %quantize the radius
    r2 = q_f*floor((r2/q_f)+0.5);
end

%hit escape radius, send zero
output = 0;
radius = 0;
return;

end

