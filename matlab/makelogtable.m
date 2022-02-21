%make a look up table for the double log calculation
top = 256;

range = 2:top;

logs_a = log2(range);

%max of logs_b is < 0.5 for 2:255 input
logs_b = log2(logs_a*3/20);

%quantize the output, get the highest dynamic range
maxminimum = -128;
scale = maxminimum / min(logs_b);
scale = 2^floor(log2(scale));
logs_b = floor(logs_b * scale);

rom = {zeros(top,1)};

bitlen = 8;

rom{1} = dec2bin(0,bitlen);

xorvec = uint8((2^bitlen)-1);

for i = 1:length(logs_b)
    
    if(logs_b(i) < 0)
       temp = uint8(abs(logs_b(i)));
       temp = bitxor(temp, xorvec);
       temp = temp + 1;
       rom{i+1} = dec2bin(temp,bitlen);
    else
       rom{i+1} = dec2bin(int8(logs_b(i)),bitlen);
    end

end

fid = fopen(['fractal_smooth_lut.data'], 'wt');
fprintf(fid, '%s\n', rom{:});
fclose(fid);
