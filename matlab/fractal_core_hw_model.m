function output = fractal_core_hw_model(input, iter_sum, max, escape, q_f, smooth)

%default assignment
x = real(input);
y = imag(input);
r = 0;

x2 = 0;
y2 = 0;
xy2 = 0;

%precompute the first iteration and half of the next
%take the squares
x2 = x*x;
y2 = y*y;
xy2 = 2*x*y;

%add them to the sums
% x = x2 - y2 + x;
% y = xy2 + y;
% r = x2 + y2;

%now we have a new sum, and the old multiplies

%main loop
for i = 0:max-1
    if(smooth == 0)
        if(r >= escape)
            output = i;
            return;
        end
    else
        if(r >= escape)
            sn = i - log(log(sqrt(r)))/log(2);
            output = sn;
            return;
        end
    end
    
    x_save = x;
    y_save = y;
    
    %calculate sums (second stage)
    y = xy2 + imag(iter_sum);
    x = x2 - y2 + real(iter_sum);
    r = x2 + y2;    
    
    %calculate x^2 and y^2 (first stage)
    y2 = y_save*y_save;
    x2 = x_save*x_save;
    xy2 = x_save*y_save*2;
    

end

%hit escape radius, send zero
output = 0;
return;

end

