function output = mandelbrot_calc(input, max)

% z = 0; to start
% zn = z^2 + c; until abs(z) >= 4

% c = real(input) + j*imag(input)
% z = x + jy

% z^2 = x^2 - y^2 + j(2*x*y)
% xn = x^2 - y^2 + real(input)
% yn = 2*x*y + imag(input)

x = 0;
y = 0;
r2 = 0;

%delta = 2^-14;
delta = 2^-32;
real_input = delta*floor((real(input)/delta) + 0.5);
imag_input = delta*floor((imag(input)/delta) + 0.5);

for i = 0:max-1

    if(r2 >= 4)
        log_r = log(r2)/2;
        nu = log(log_r / log(2))/log(2);
        nu = floor(nu);
        output = floor(i - nu + 1);
        output = i;
        return;
    end
    
    %quantize the inputs
    x = delta*floor((x/delta)+0.5);
    y = delta*floor((y/delta)+0.5);
    
    y2 = y*y;
    x2 = x*x;
    
    x2 = delta*floor((x2/delta)+0.5);
    y2 = delta*floor((y2/delta)+0.5);
    
    y = 2*x*y + imag_input;
    x = x2 - y2 + real_input;

    r2 = x2 + y2;
    

    r2 = delta*floor((r2/delta)+0.5);
end

output = 0;
return;

end

